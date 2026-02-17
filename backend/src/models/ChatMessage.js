const mongoose = require('mongoose');

const chatMessageSchema = new mongoose.Schema({
  conversationId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Conversation',
    required: true,
    index: true
  },
  sender: {
    type: String,
    enum: ['user', 'ai'],
    required: true
  },
  message: {
    type: String,
    required: true,
    trim: true
  },
  messageType: {
    type: String,
    enum: ['text', 'voice', 'image'],
    default: 'text'
  },
  originalAudioPath: {
    type: String,
    trim: true
  },
  timestamp: {
    type: Date,
    default: Date.now,
    index: true
  },
  isContextAware: {
    type: Boolean,
    default: false
  },
  context: {
    courseId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Course'
    },
    lessonId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Lesson'
    },
    sectionTitle: String,
    studentLevel: String
  },
  metadata: {
    ipAddress: String,
    userAgent: String,
    deviceId: String
  }
}, {
  timestamps: true
});

// Index for efficient querying
chatMessageSchema.index({ conversationId: 1, timestamp: 1 });
chatMessageSchema.index({ 'context.courseId': 1, timestamp: -1 });
chatMessageSchema.index({ sender: 1, timestamp: -1 });

// Virtual for formatted timestamp
chatMessageSchema.virtual('formattedTimestamp').get(function() {
  return this.timestamp.toLocaleTimeString([], { 
    hour: '2-digit', 
    minute: '2-digit' 
  });
});

// Method to get message preview
chatMessageSchema.methods.getPreview = function(length = 50) {
  if (this.message.length <= length) {
    return this.message;
  }
  return this.message.substring(0, length) + '...';
};

// Static method to get conversation history
chatMessageSchema.statics.getConversationHistory = async function(conversationId, limit = 50) {
  return this.find({ conversationId })
    .sort({ timestamp: 1 })
    .limit(limit)
    .populate('context.courseId', 'title')
    .populate('context.lessonId', 'title');
};

// Static method to get user chat history
chatMessageSchema.statics.getUserChatHistory = async function(userId, limit = 20) {
  const Conversation = mongoose.model('Conversation');
  const conversations = await Conversation.find({ userId })
    .sort({ updatedAt: -1 })
    .limit(limit)
    .populate('courseId', 'title')
    .lean();
  
  return conversations;
};

module.exports = mongoose.model('ChatMessage', chatMessageSchema);