const mongoose = require('mongoose');

/**
 * Chat messages for a course community. `scope` decides the room:
 *  - `course` — the shared course chat (every enrolled student + teacher)
 *  - `group`  — a private study-group chat (members only)
 */
const communityMessageSchema = new mongoose.Schema({
  courseId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Course',
    required: [true, 'Course ID is required']
  },
  scope: {
    type: String,
    enum: ['course', 'group'],
    default: 'course'
  },
  groupId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'StudyGroup',
    default: null
  },
  senderId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  senderRole: {
    type: String,
    enum: ['student', 'instructor', 'admin'],
    default: 'student'
  },
  content: {
    type: String,
    trim: true,
    maxlength: [5000, 'Message cannot exceed 5000 characters']
  },
  attachments: [{
    name: String,
    url: String,
    mimeType: String,
    size: Number
  }],
  replyTo: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'CommunityMessage',
    default: null
  },
  readBy: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }],
  isDeleted: {
    type: Boolean,
    default: false
  }
}, {
  timestamps: true
});

communityMessageSchema.index({ courseId: 1, scope: 1, groupId: 1, createdAt: -1 });
communityMessageSchema.index({ groupId: 1, createdAt: -1 });

module.exports = mongoose.model('CommunityMessage', communityMessageSchema);
