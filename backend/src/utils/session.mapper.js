const StudySession = require('../models/community/StudySession');
const { toPublicMember } = require('./community.utils');

/**
 * Single source of truth for how a study session is presented to the app.
 *
 * Lives here rather than in the session controller because the group
 * workspace renders the same cards: when it had its own trimmed-down mapping,
 * organisers lost their "Open the room" button and live sessions vanished from
 * the group tab entirely.
 */
/** Shapes a session for the app, including what *this* caller may do with it. */
const mapSession = (session, userId, isTeacher = false) => {
  const organiserId = String(
    session.createdBy && (session.createdBy._id || session.createdBy)
  );
  const isOrganiser = organiserId === String(userId);
  const canModerate = isOrganiser || isTeacher;

  const participants = session.participants || [];
  const mine = participants.find(
    (p) => String(p.userId && (p.userId._id || p.userId)) === String(userId)
  );

  const now = new Date();
  const start = session.scheduledAt ? new Date(session.scheduledAt) : null;
  const expectedEndAt = start
    ? new Date(start.getTime() + (session.durationMinutes || 60) * 60 * 1000)
    : null;
  const earlyMs = StudySession.EARLY_JOIN_MINUTES * 60 * 1000;
  const lateMs = StudySession.LATE_JOIN_MINUTES * 60 * 1000;
  const withinWindow = start
    ? now.getTime() >= start.getTime() - earlyMs &&
      now.getTime() <= expectedEndAt.getTime() + lateMs
    : false;

  const isActive = session.status === 'scheduled' || session.status === 'live';
  const isFull = participants.length >= session.maxParticipants;

  // The organiser may open the room any time before the session's window
  // closes; attendees wait for the narrower join window.
  const beforeEnd = expectedEndAt
    ? now.getTime() <= expectedEndAt.getTime() + lateMs
    : false;
  const moderatorCanOpen = canModerate && isActive && beforeEnd;

  return {
    id: String(session._id),
    topic: session.topic,
    description: session.description || '',
    scheduledAt: session.scheduledAt,
    expectedEndAt,
    durationMinutes: session.durationMinutes,
    agenda: session.agenda || [],
    maxParticipants: session.maxParticipants,
    participantCount: participants.length,
    participants: participants.map((p) =>
      p.userId && p.userId.fullName
        ? { ...toPublicMember(p.userId), attended: Boolean(p.attendedAt) }
        : { id: String(p.userId), attended: Boolean(p.attendedAt) }
    ),
    isJoined: Boolean(mine),
    hasAttended: Boolean(mine && mine.attendedAt),
    status: session.status,
    isLive: session.status === 'live',
    isPast: expectedEndAt ? now > expectedEndAt : false,
    meetingProvider: session.meetingProvider,
    meetingLink: session.meetingProvider === 'external' ? session.meetingLink || null : null,
    startedAt: session.startedAt,
    endedAt: session.endedAt,
    recordingUrl: session.recordingUrl,
    recordingDuration: session.recordingDuration || 0,
    group:
      session.groupId && session.groupId.name
        ? { id: String(session.groupId._id), name: session.groupId.name }
        : null,
    organiser:
      session.createdBy && session.createdBy.fullName
        ? toPublicMember(session.createdBy)
        : null,
    isMine: isOrganiser,
    canModerate,
    /** The organiser can open the room at any point before the session ends. */
    canStart: moderatorCanOpen && session.status !== 'live',
    /**
     * Whether this caller can enter right now.
     *
     * For an attendee the gate is simply "the room is open" — an organiser who
     * starts early does so precisely so people can come in, and holding them
     * to the pre-start window would lock them out of a live room.
     */
    canJoin: moderatorCanOpen ||
        (session.status === 'live' && beforeEnd && (Boolean(mine) || !isFull)),
    isFull,
    isWithinJoinWindow: withinWindow,
    createdAt: session.createdAt
  };
};


/** Population every session mapping needs to fill in people and group names. */
const SESSION_POPULATE = [
  { path: 'createdBy', select: 'fullName avatar role lastActive' },
  { path: 'participants.userId', select: 'fullName avatar role lastActive' },
  { path: 'groupId', select: 'name' }
];

module.exports = { mapSession, SESSION_POPULATE };
