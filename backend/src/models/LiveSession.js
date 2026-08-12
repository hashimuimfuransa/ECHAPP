const mongoose = require('mongoose');

const liveSessionSchema = new mongoose.Schema({
  teacherId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: [true, 'Teacher ID is required']
  },
  courseId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Course',
    required: [true, 'Course ID is required']
  },
  sectionId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Section',
    required: [true, 'Section ID is required']
  },
  lessonId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Lesson',
    default: null
  },
  title: {
    type: String,
    required: [true, 'Session title is required'],
    trim: true,
    maxlength: [200, 'Title cannot exceed 200 characters']
  },
  description: {
    type: String,
    maxlength: [1000, 'Description cannot exceed 1000 characters']
  },
  scheduledAt: {
    type: Date,
    required: [true, 'Schedule date is required']
  },
  duration: {
    type: Number,
    required: [true, 'Duration is required'],
    min: [15, 'Duration must be at least 15 minutes'],
    max: [180, 'Duration cannot exceed 180 minutes']
  },
  expectedEndTime: {
    type: Date,
    default: null
  },
  bbbMeetingId: {
    type: String,
    default: null
  },
  bbbInternalMeetingId: {
    type: String,
    default: null
  },
  bbbModeratorUrl: {
    type: String,
    default: null
  },
  bbbAttendeeUrl: {
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
    enum: ['scheduled', 'live', 'ended', 'cancelled'],
    default: 'scheduled'
  },
  recordingUrl: {
    type: String,
    default: null
  },
  recordingDuration: {
    type: Number,
    default: 0
  },
  recordingFormat: {
    type: String,
    enum: ['video', 'presentation', null],
    default: null
  },
  /** Every playback format BBB produced for this session. */
  recordingFormats: [{
    type: { type: String },
    url: String,
    duration: Number,
    size: Number
  }],
  /** Direct mp4, present only when the BBB server produces a video format. */
  recordingDownloadUrl: {
    type: String,
    default: null
  },
  recordingParticipants: {
    type: Number,
    default: 0
  },
  /**
   * The teacher reviews the recording, then decides whether students may keep
   * a copy. Watching is allowed as soon as it exists; downloading is opt-in,
   * matching how peer study sessions behave.
   */
  allowRecordingDownload: {
    type: Boolean,
    default: false
  },
  /** Lets a teacher hide a recording that did not come out usable. */
  isRecordingPublished: {
    type: Boolean,
    default: true
  },
  endedAt: {
    type: Date,
    default: null
  },
  maxParticipants: {
    type: Number,
    default: 100,
    min: [1, 'Must allow at least 1 participant'],
    max: [500, 'Cannot exceed 500 participants']
  },
  settings: {
    enableChat: {
      type: Boolean,
      default: true
    },
    enableWebcam: {
      type: Boolean,
      default: true
    },
    muteOnEntry: {
      type: Boolean,
      default: true
    },
    allowRecording: {
      type: Boolean,
      default: true
    },
    waitingRoom: {
      type: Boolean,
      default: false
    }
  },
  participantCount: {
    type: Number,
    default: 0
  },
  attendees: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }],
  attendedAt: [{
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    joinedAt: {
      type: Date,
      default: Date.now
    },
    duration: {
      type: Number,
      default: 0 // in minutes
    }
  }],
  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

// Indexes for better query performance
liveSessionSchema.index({ teacherId: 1, status: 1 });
liveSessionSchema.index({ courseId: 1, status: 1 });
liveSessionSchema.index({ sectionId: 1, lessonId: 1 });
liveSessionSchema.index({ scheduledAt: 1 });
liveSessionSchema.index({ status: 1, scheduledAt: 1 });
liveSessionSchema.index({ bbbMeetingId: 1 });

module.exports = mongoose.model('LiveSession', liveSessionSchema);
