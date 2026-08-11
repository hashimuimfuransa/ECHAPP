const mongoose = require('mongoose');

/**
 * Tracks which members of a course community were recently active.
 *
 * Privacy note: we deliberately store only a coarse activity area
 * ("community", "lesson", "group"...) and never an exact location or the
 * specific lesson title, so the UI can show "Active now" without exposing
 * what a student is actually doing.
 */
const coursePresenceSchema = new mongoose.Schema({
  courseId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Course',
    required: true
  },
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  area: {
    type: String,
    enum: ['community', 'lesson', 'group', 'chat', 'assignment'],
    default: 'community'
  },
  lastSeenAt: {
    type: Date,
    default: Date.now
  },
  // Students can hide themselves from the "who is studying now" list
  isVisible: {
    type: Boolean,
    default: true
  }
}, {
  timestamps: true
});

coursePresenceSchema.index({ courseId: 1, userId: 1 }, { unique: true });
coursePresenceSchema.index({ courseId: 1, lastSeenAt: -1 });
// Drop stale presence rows after 7 days so the collection stays small
coursePresenceSchema.index({ lastSeenAt: 1 }, { expireAfterSeconds: 60 * 60 * 24 * 7 });

/** A member counts as "active now" if seen within this window. */
coursePresenceSchema.statics.ACTIVE_WINDOW_MINUTES = 5;

coursePresenceSchema.statics.touch = async function (courseId, userId, area = 'community') {
  return this.findOneAndUpdate(
    { courseId, userId },
    { $set: { lastSeenAt: new Date(), area }, $setOnInsert: { isVisible: true } },
    { upsert: true, new: true, setDefaultsOnInsert: true }
  );
};

coursePresenceSchema.statics.activeCount = async function (courseId) {
  const cutoff = new Date(Date.now() - this.ACTIVE_WINDOW_MINUTES * 60 * 1000);
  return this.countDocuments({ courseId, lastSeenAt: { $gte: cutoff }, isVisible: true });
};

module.exports = mongoose.model('CoursePresence', coursePresenceSchema);
