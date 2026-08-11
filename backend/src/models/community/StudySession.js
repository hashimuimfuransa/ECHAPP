const mongoose = require('mongoose');

/**
 * A student-organised study meeting inside a course community.
 *
 * Distinct from the teacher-run `LiveSession`: those are scheduled by staff
 * against a lesson and always record. These are peer sessions — any member can
 * create one, classmates RSVP, and the organiser opens the room when it is
 * time.
 *
 * Both run on the same BigBlueButton server through `BBBService`. The BBB
 * meeting is created lazily (on first join) rather than at scheduling time, so
 * a session that nobody turns up to never consumes a room on the BBB server.
 */
const studySessionSchema = new mongoose.Schema({
  courseId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Course',
    required: [true, 'Course ID is required']
  },
  groupId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'StudyGroup',
    default: null
  },
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  topic: {
    type: String,
    required: [true, 'Session topic is required'],
    trim: true,
    maxlength: [200, 'Topic cannot exceed 200 characters']
  },
  description: {
    type: String,
    trim: true,
    maxlength: [2000, 'Description cannot exceed 2000 characters']
  },
  scheduledAt: {
    type: Date,
    required: [true, 'Session date and time is required']
  },
  durationMinutes: {
    type: Number,
    default: 60,
    min: [10, 'A session must last at least 10 minutes'],
    max: [240, 'A session cannot run longer than 4 hours']
  },
  agenda: [{
    type: String,
    trim: true,
    maxlength: [300, 'Agenda item cannot exceed 300 characters']
  }],
  maxParticipants: {
    type: Number,
    default: 10,
    min: 2,
    max: [100, 'A study session cannot exceed 100 participants']
  },
  participants: [{
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    /** When they said they were coming (RSVP), not when they showed up. */
    joinedAt: {
      type: Date,
      default: Date.now
    },
    /** First time they actually entered the meeting room. */
    attendedAt: {
      type: Date,
      default: null
    },
    attendanceMinutes: {
      type: Number,
      default: 0
    }
  }],

  // ── Meeting room ───────────────────────────────────────────────
  /**
   * `bbb` runs on the platform's BigBlueButton server; `external` means the
   * organiser pasted their own link (Meet, Zoom...) and we just hand it over.
   * A session falls back to `external` when BBB is not configured.
   */
  meetingProvider: {
    type: String,
    enum: ['bbb', 'external'],
    default: 'bbb'
  },
  /** Organiser-supplied link, used when meetingProvider is `external`. */
  meetingLink: {
    type: String,
    trim: true
  },
  bbbMeetingId: {
    type: String,
    default: null,
    index: true
  },
  bbbInternalMeetingId: {
    type: String,
    default: null
  },
  bbbModeratorPw: {
    type: String,
    default: null
  },
  bbbAttendeePw: {
    type: String,
    default: null
  },

  status: {
    type: String,
    enum: ['scheduled', 'live', 'completed', 'cancelled'],
    default: 'scheduled'
  },
  startedAt: {
    type: Date,
    default: null
  },
  endedAt: {
    type: Date,
    default: null
  },

  // ── Recording ──────────────────────────────────────────────────
  recordingUrl: {
    type: String,
    default: null
  },
  recordingDuration: {
    type: Number,
    default: 0
  },
  /** Last time the scheduler asked BBB whether the recording had processed. */
  recordingCheckedAt: {
    type: Date,
    default: null
  },

  /**
   * Timestamps of reminders already sent. Recording them makes the scheduler
   * idempotent — a redeploy mid-window cannot double-notify, and a missed
   * window cannot silently skip.
   */
  reminders: {
    dayBefore: { type: Date, default: null },
    thirtyMinutes: { type: Date, default: null },
    starting: { type: Date, default: null }
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

studySessionSchema.index({ courseId: 1, scheduledAt: 1 });
studySessionSchema.index({ groupId: 1, scheduledAt: 1 });
// Drives the reminder sweep
studySessionSchema.index({ status: 1, scheduledAt: 1 });

studySessionSchema.virtual('participantCount').get(function () {
  return this.participants ? this.participants.length : 0;
});

/** When the session is expected to wrap up. */
studySessionSchema.virtual('expectedEndAt').get(function () {
  if (!this.scheduledAt) return null;
  return new Date(
    new Date(this.scheduledAt).getTime() + (this.durationMinutes || 60) * 60 * 1000
  );
});

/** Participants can enter this many minutes before the scheduled start. */
studySessionSchema.statics.EARLY_JOIN_MINUTES = 15;
/** Grace period after the expected end during which the room stays open. */
studySessionSchema.statics.LATE_JOIN_MINUTES = 30;

/**
 * Whether the room can be entered right now. Outside this window the meeting
 * is either too far off or long finished, and we avoid spinning up a BBB room.
 */
studySessionSchema.methods.isWithinJoinWindow = function (now = new Date()) {
  if (!this.scheduledAt) return false;
  const start = new Date(this.scheduledAt).getTime();
  const early = this.constructor.EARLY_JOIN_MINUTES * 60 * 1000;
  const late = this.constructor.LATE_JOIN_MINUTES * 60 * 1000;
  const end = start + (this.durationMinutes || 60) * 60 * 1000;
  return now.getTime() >= start - early && now.getTime() <= end + late;
};

/**
 * Whether the session has not yet run its course.
 *
 * The organiser is held to this rather than the narrow join window: opening
 * the room early to set up (or because everyone already turned up) is a
 * deliberate act, and making them wait served no one.
 */
studySessionSchema.methods.isBeforeEnd = function (now = new Date()) {
  if (!this.scheduledAt) return false;
  const end =
    new Date(this.scheduledAt).getTime() + (this.durationMinutes || 60) * 60 * 1000;
  return now.getTime() <= end + this.constructor.LATE_JOIN_MINUTES * 60 * 1000;
};

studySessionSchema.methods.isParticipant = function (userId) {
  const id = String(userId);
  return (this.participants || []).some((p) => String(p.userId) === id);
};

/** Stable, collision-free BBB meeting id derived from this document. */
studySessionSchema.methods.buildMeetingId = function () {
  return `ech-study-${this._id}`;
};

module.exports = mongoose.model('StudySession', studySessionSchema);
