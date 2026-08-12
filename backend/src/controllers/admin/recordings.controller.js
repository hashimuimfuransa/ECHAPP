const mongoose = require('mongoose');
const LiveSession = require('../../models/LiveSession');
const StudySession = require('../../models/community/StudySession');
const BBBService = require('../../services/bbb.service');
const { sendSuccess, sendError, sendNotFound } = require('../../utils/response.utils');

/**
 * Platform-wide recordings library for administrators.
 *
 * Admins are the only people who can take a course recording off the platform,
 * so they need one place to find every recording rather than hunting through
 * each course's live sessions.
 */

const mapLive = (s) => ({
  id: String(s._id),
  kind: 'live',
  title: s.title,
  courseId: s.courseId ? String(s.courseId._id || s.courseId) : null,
  courseTitle: s.courseId && s.courseId.title ? s.courseId.title : null,
  teacherName: s.teacherId && s.teacherId.fullName ? s.teacherId.fullName : null,
  scheduledAt: s.scheduledAt,
  endedAt: s.endedAt,
  durationMinutes: s.recordingDuration || 0,
  participants: s.recordingParticipants || (s.attendees || []).length,
  playbackUrl: s.recordingUrl || null,
  downloadUrl: s.recordingDownloadUrl || null,
  hasDownloadableFile: Boolean(s.recordingDownloadUrl),
  isPublished: s.isRecordingPublished !== false,
  bbbMeetingId: s.bbbMeetingId || null
});

const mapStudy = (s) => ({
  id: String(s._id),
  kind: 'study',
  title: s.topic,
  courseId: s.courseId ? String(s.courseId._id || s.courseId) : null,
  courseTitle: s.courseId && s.courseId.title ? s.courseId.title : null,
  teacherName: s.createdBy && s.createdBy.fullName ? s.createdBy.fullName : null,
  scheduledAt: s.scheduledAt,
  endedAt: s.endedAt,
  durationMinutes: s.recordingDuration || 0,
  participants: s.recordingParticipants || (s.participants || []).length,
  playbackUrl: s.recordingUrl || null,
  downloadUrl: s.recordingDownloadUrl || null,
  hasDownloadableFile: Boolean(s.recordingDownloadUrl),
  isPublished: s.isRecordingPublished !== false,
  bbbMeetingId: s.bbbMeetingId || null
});

class AdminRecordingsController {
  /**
   * Every recording on the platform, newest first.
   *
   * `kind` narrows to teacher-led classes or peer study sessions; `courseId`
   * and `search` narrow further. Only sessions that actually produced a
   * recording are listed.
   */
  async list(req, res) {
    try {
      const {
        kind = 'all',
        courseId,
        search = '',
        page = 1,
        limit = 30
      } = req.query;

      const pageNum = Math.max(1, parseInt(page, 10) || 1);
      const limitNum = Math.min(100, Math.max(1, parseInt(limit, 10) || 30));

      const courseFilter =
        courseId && mongoose.Types.ObjectId.isValid(courseId)
          ? { courseId }
          : {};

      const liveQuery = {
        recordingUrl: { $ne: null },
        ...courseFilter,
        ...(search.trim() ? { title: { $regex: search.trim(), $options: 'i' } } : {})
      };
      const studyQuery = {
        recordingUrl: { $ne: null },
        ...courseFilter,
        ...(search.trim() ? { topic: { $regex: search.trim(), $options: 'i' } } : {})
      };

      const wantLive = kind === 'all' || kind === 'live';
      const wantStudy = kind === 'all' || kind === 'study';

      const [live, study, liveTotal, studyTotal] = await Promise.all([
        wantLive
          ? LiveSession.find(liveQuery)
              .sort({ endedAt: -1, scheduledAt: -1 })
              .limit(200)
              .populate('courseId', 'title')
              .populate('teacherId', 'fullName')
              .lean()
          : [],
        wantStudy
          ? StudySession.find(studyQuery)
              .sort({ endedAt: -1, scheduledAt: -1 })
              .limit(200)
              .populate('courseId', 'title')
              .populate('createdBy', 'fullName')
              .lean()
          : [],
        wantLive ? LiveSession.countDocuments(liveQuery) : 0,
        wantStudy ? StudySession.countDocuments(studyQuery) : 0
      ]);

      // Merge and sort as one list — an admin thinks in "recordings", not in
      // which subsystem produced them.
      const all = [...live.map(mapLive), ...study.map(mapStudy)].sort((a, b) => {
        const aAt = new Date(a.endedAt || a.scheduledAt || 0).getTime();
        const bAt = new Date(b.endedAt || b.scheduledAt || 0).getTime();
        return bAt - aAt;
      });

      const start = (pageNum - 1) * limitNum;
      const recordings = all.slice(start, start + limitNum);

      return sendSuccess(res, {
        recordings,
        stats: {
          total: all.length,
          liveClasses: liveTotal,
          studySessions: studyTotal,
          downloadable: all.filter((r) => r.hasDownloadableFile).length
        },
        pagination: {
          page: pageNum,
          limit: limitNum,
          totalPages: Math.max(1, Math.ceil(all.length / limitNum))
        }
      }, 'Recordings loaded');
    } catch (error) {
      console.error('Error listing recordings:', error);
      return sendError(res, 'Failed to load recordings', 500, error.message);
    }
  }

  /**
   * Re-ask BBB about one recording.
   *
   * Useful when a recording finished processing after the last sweep, or when
   * the video format was installed on the BBB server later than the session.
   */
  async refresh(req, res) {
    try {
      const { kind, sessionId } = req.params;
      const Model = kind === 'study' ? StudySession : LiveSession;

      const session = await Model.findById(sessionId);
      if (!session) return sendNotFound(res, 'Session not found');
      if (!session.bbbMeetingId) {
        return sendError(res, 'This session has no meeting to look up', 400);
      }

      const recordings = await BBBService.getRecordings(session.bbbMeetingId);
      const ready = recordings.find((r) => r.published && r.playback);

      if (!ready) {
        session.recordingCheckedAt = new Date();
        await session.save();
        return sendSuccess(res, { processing: true }, 'Still processing on the video server');
      }

      session.recordingUrl = ready.playback;
      session.recordingDownloadUrl = ready.downloadUrl || null;
      session.recordingFormats = ready.formats || [];
      session.recordingDuration = ready.duration || 0;
      session.recordingParticipants = ready.participants || 0;
      await session.save();

      return sendSuccess(res, {
        playbackUrl: session.recordingUrl,
        downloadUrl: session.recordingDownloadUrl,
        hasDownloadableFile: Boolean(session.recordingDownloadUrl),
        durationMinutes: session.recordingDuration
      }, 'Recording refreshed');
    } catch (error) {
      console.error('Error refreshing recording:', error);
      return sendError(res, 'Failed to refresh the recording', 500, error.message);
    }
  }

  /** Hide or restore a recording for everyone below admin level. */
  async setPublished(req, res) {
    try {
      const { kind, sessionId } = req.params;
      const Model = kind === 'study' ? StudySession : LiveSession;

      const session = await Model.findById(sessionId);
      if (!session) return sendNotFound(res, 'Session not found');

      session.isRecordingPublished = req.body.isPublished !== false;
      await session.save();

      return sendSuccess(res, {
        isPublished: session.isRecordingPublished
      }, session.isRecordingPublished ? 'Recording visible' : 'Recording hidden');
    } catch (error) {
      console.error('Error updating recording visibility:', error);
      return sendError(res, 'Failed to update the recording', 500, error.message);
    }
  }
}

module.exports = new AdminRecordingsController();
