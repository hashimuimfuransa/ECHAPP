const mongoose = require('mongoose');

/** A single message inside a one-to-one conversation. */
const directMessageSchema = new mongoose.Schema({
  conversationId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'DirectConversation',
    required: true,
    index: true
  },
  senderId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  recipientId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
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
  /**
   * Optional pointer back to what prompted the message — a course, a lesson,
   * an assignment — so "Message about NPV Practice Group" keeps its context.
   */
  context: {
    courseId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Course',
      default: null
    },
    label: { type: String, trim: true, default: null }
  },
  replyTo: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'DirectMessage',
    default: null
  },
  readAt: {
    type: Date,
    default: null
  },
  isDeleted: {
    type: Boolean,
    default: false
  }
}, {
  timestamps: true
});

directMessageSchema.index({ conversationId: 1, createdAt: -1 });
directMessageSchema.index({ recipientId: 1, readAt: 1 });

module.exports = mongoose.model('DirectMessage', directMessageSchema);
