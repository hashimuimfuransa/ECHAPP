const cron = require('node-cron');
const StudySession = require('../models/community/StudySession');
const BBBService = require('./bbb.service');
const CommunityNotificationService = require('./community-notification.service');

/**
 * Keeps peer study sessions moving without anyone having to babysit them:
 *
 *  1. Countdown reminders — a day before, 30 minutes before, and at start time
 *  2. Auto-completes sessions whose time has passed
 *  3. Pulls BigBlueButton recordings once they finish processing
 *
 * Runs on a short cron (every 5 minutes) rather than setInterval so a redeploy
 * cannot shift the schedule, matching `notification-scheduler.service.js`.
 *
 * Every stage is guarded by a timestamp on the session document, so a restart
 * mid-sweep can neither double-send a reminder nor skip one.
 */
class CommunitySessionSchedulerService {
  /** How wide a net each reminder stage casts, in minutes. */
  static WINDOWS = {
    dayBefore: { min: 22 * 60, max: 26 * 60 },
    thirtyMinutes: { min: 20, max: 40 },
    starting: { min: -5, max: 5 }
  };

  /**
   * Fire whichever countdown reminders are due.
   *
   * A session only ever gets the stages it is still eligible for: one created
   * an hour before it starts skips the day-before reminder entirely rather
   * than firing it late.
   */
  static async sendReminders() {
    const now = Date.now();
    let sent = 0;

    for (const [stage, window] of Object.entries(this.WINDOWS)) {
      const from = new Date(now + window.min * 60 * 1000);
      const to = new Date(now + window.max * 60 * 1000);

      const due = await StudySession.find({
        status: 'scheduled',
        scheduledAt: { $gte: from, $lte: to },
        [`reminders.${stage}`]: null,
        'participants.0': { $exists: true }
      })
        .select('courseId topic scheduledAt participants reminders')
        .lean();

      for (const session of due) {
        // Claim the stage before notifying: if the notification fan-out is
        // slow and the next sweep overlaps, the guard is already written.
        const claimed = await StudySession.updateOne(
          { _id: session._id, [`reminders.${stage}`]: null },
          { $set: { [`reminders.${stage}`]: new Date() } }
        );
        if (claimed.modifiedCount === 0) continue;

        await CommunityNotificationService.sessionReminder({
          recipientIds: session.participants.map((p) => String(p.userId)),
          courseId: String(session.courseId),
          sessionId: String(session._id),
          topic: session.topic,
          scheduledAt: session.scheduledAt,
          stage
        });
        sent += 1;
      }
    }

    return sent;
  }

  /**
   * Close out sessions whose window has fully passed.
   *
   * A live session gets the full grace period before being force-completed, so
   * a group that overruns slightly is not cut off mid-conversation.
   */
  static async completeFinishedSessions() {
    const now = new Date();

    const candidates = await StudySession.find({
      status: { $in: ['scheduled', 'live'] },
      scheduledAt: { $lte: now }
    })
      .select('status scheduledAt durationMinutes participants bbbMeetingId bbbModeratorPw meetingProvider')
      .lean();

    let completed = 0;

    for (const session of candidates) {
      const graceMinutes =
        session.status === 'live' ? StudySession.LATE_JOIN_MINUTES : 15;
      const endsAt =
        new Date(session.scheduledAt).getTime() +
        (session.durationMinutes || 60) * 60 * 1000 +
        graceMinutes * 60 * 1000;

      if (now.getTime() < endsAt) continue;

      if (session.status === 'live' && session.bbbMeetingId && session.meetingProvider === 'bbb') {
        try {
          await BBBService.endMeeting(session.bbbMeetingId, session.bbbModeratorPw || '');
        } catch (e) {
          console.log('Auto-end BBB meeting failed (likely already closed):', e.message);
        }
      }

      await StudySession.updateOne(
        { _id: session._id, status: { $in: ['scheduled', 'live'] } },
        { $set: { status: 'completed', endedAt: now } }
      );
      completed += 1;
    }

    return completed;
  }

  /**
   * Ask BBB for recordings of recently-finished sessions.
   *
   * BBB processes recordings asynchronously — often several minutes after the
   * room closes — so this retries on each sweep for a day, then gives up
   * rather than polling a recording that will never arrive.
   */
  static async collectRecordings() {
    const now = Date.now();
    const oneDayAgo = new Date(now - 24 * 60 * 60 * 1000);
    const fiveMinutesAgo = new Date(now - 5 * 60 * 1000);

    const pending = await StudySession.find({
      status: 'completed',
      meetingProvider: 'bbb',
      bbbMeetingId: { $ne: null },
      recordingUrl: null,
      endedAt: { $gte: oneDayAgo },
      $or: [
        { recordingCheckedAt: null },
        { recordingCheckedAt: { $lte: fiveMinutesAgo } }
      ]
    })
      .select('courseId topic bbbMeetingId participants')
      .limit(25)
      .lean();

    let found = 0;

    for (const session of pending) {
      try {
        const recordings = await BBBService.getRecordings(session.bbbMeetingId);
        const published = recordings.find((r) => r.published && r.playback);

        if (!published) {
          await StudySession.updateOne(
            { _id: session._id },
            { $set: { recordingCheckedAt: new Date() } }
          );
          continue;
        }

        // Only notify on the write that actually set the URL, so a race
        // between sweeps cannot announce the same recording twice.
        const claimed = await StudySession.updateOne(
          { _id: session._id, recordingUrl: null },
          {
            $set: {
              recordingUrl: published.playback,
              recordingDuration: published.duration || 0,
              recordingCheckedAt: new Date()
            }
          }
        );
        if (claimed.modifiedCount === 0) continue;

        await CommunityNotificationService.sessionRecordingReady({
          recipientIds: (session.participants || []).map((p) => String(p.userId)),
          courseId: String(session.courseId),
          sessionId: String(session._id),
          topic: session.topic
        });
        found += 1;
      } catch (error) {
        console.error(`Recording lookup failed for session ${session._id}:`, error.message);
      }
    }

    return found;
  }

  static async sweep() {
    try {
      const [reminders, completed, recordings] = await Promise.all([
        this.sendReminders(),
        this.completeFinishedSessions(),
        this.collectRecordings()
      ]);

      if (reminders || completed || recordings) {
        console.log(
          `📅 Study sessions: ${reminders} reminder(s), ${completed} completed, ` +
          `${recordings} recording(s) published`
        );
      }
    } catch (error) {
      console.error('Study session sweep failed:', error.message);
    }
  }

  static schedule(everyMinutes = 5) {
    const expression = `*/${everyMinutes} * * * *`;
    console.log(`Scheduling study session checks every ${everyMinutes} minutes (cron: "${expression}")`);

    // Give the database connection a moment before the first sweep.
    setTimeout(() => this.sweep(), 15000);

    cron.schedule(expression, () => this.sweep());
  }
}

module.exports = CommunitySessionSchedulerService;
