const mongoose = require('mongoose');

/**
 * A student-organised study meeting inside a course community.
 *
 * Distinct from the teacher-run `LiveSession` (BigBlueButton) model: these are
 * lightweight peer sessions that carry a topic, an agenda and an RSVP list.
 * `meetingLink` is free-form for now so groups can drop in whatever tool they
 * already use until an in-app meeting backend is wired up.
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
    min: [10, 'A session must last at least 10 minutes']
  },
  agenda: [{
    type: String,
    trim: true,
    maxlength: [300, 'Agenda item cannot exceed 300 characters']
  }],
  maxParticipants: {
    type: Number,
    default: 10,
    min: 2
  },
  participants: [{
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    joinedAt: {
      type: Date,
      default: Date.now
    }
  }],
  meetingLink: {
    type: String,
    trim: true
  },
  status: {
    type: String,
    enum: ['scheduled', 'cancelled', 'completed'],
    default: 'scheduled'
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

studySessionSchema.index({ courseId: 1, scheduledAt: 1 });
studySessionSchema.index({ groupId: 1, scheduledAt: 1 });

studySessionSchema.virtual('participantCount').get(function () {
  return this.participants ? this.participants.length : 0;
});

module.exports = mongoose.model('StudySession', studySessionSchema);
