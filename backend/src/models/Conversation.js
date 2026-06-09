const mongoose = require('mongoose');

const conversationSchema = new mongoose.Schema({
  userId: {
    type: String,
    required: true,
    index: true
  },
  customId: {
    type: String,
    sparse: true,
    index: true
  },
  title: {
    type: String,
    trim: true,
    default: 'New Conversation'
  },
  courseId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Course'
  },
  lessonId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Lesson'
  },
  sectionTitle: {
    type: String,
    trim: true
  },
  studentLevel: {
    type: String,
    enum: ['beginner', 'intermediate', 'advanced', 'platform_user', 'student', 'instructor', 'admin'],
    default: 'beginner'
  },
  isActive: {
    type: Boolean,
    default: true
  },
  messageCount: {
    type: Number,
    default: 0
  },
  lastMessageAt: {
    type: Date,
    default: Date.now
  },
  metadata: {
    deviceInfo: {
      platform: String,
      version: String,
      model: String
    },
    ipAddress: String,
    userAgent: String
  }
}, {
  timestamps: true
});

// Indexes for efficient querying
conversationSchema.index({ userId: 1, lastMessageAt: -1 });
conversationSchema.index({ userId: 1, isActive: 1 });
conversationSchema.index({ courseId: 1, createdAt: -1 });
conversationSchema.index({ userId: 1, customId: 1 }, { unique: true, sparse: true });

// Virtual for message preview
conversationSchema.virtual('preview').get(function() {
  return this.title || 'New Conversation';
});

// Virtual for formatted last activity
conversationSchema.virtual('lastActivity').get(function() {
  const now = new Date();
  const lastActivity = this.lastMessageAt || this.updatedAt;
  const diffInHours = Math.floor((now - lastActivity) / (1000 * 60 * 60));
  
  if (diffInHours < 1) {
    const diffInMinutes = Math.floor((now - lastActivity) / (1000 * 60));
    return diffInMinutes <= 1 ? 'Just now' : `${diffInMinutes}m ago`;
  } else if (diffInHours < 24) {
    return `${diffInHours}h ago`;
  } else {
    const diffInDays = Math.floor(diffInHours / 24);
    return diffInDays === 1 ? '1 day ago' : `${diffInDays} days ago`;
  }
});

// Pre-save middleware to update lastMessageAt
conversationSchema.pre('save', function() {
  if (this.isModified('messageCount') && this.messageCount > 0) {
    this.lastMessageAt = new Date();
  }
});

// Static method to get user conversations
conversationSchema.statics.getUserConversations = async function(userId, limit = 20) {
  return this.find({ userId, isActive: true })
    .sort({ lastMessageAt: -1 })
    .limit(limit)
    .populate('courseId', 'title')
    .populate('lessonId', 'title')
    .lean();
};

// Static method to create or get existing conversation
conversationSchema.statics.getOrCreateConversation = async function(userId, context = {}) {
  const title = context.sectionTitle ||
               (context.lessonId ? 'Lesson Chat' :
               (context.courseId ? 'Course Chat' :
               (context.customId ? 'Platform Support' : 'General Chat')));

  let normalizedStudentLevel = context.studentLevel || 'beginner';
  if (normalizedStudentLevel.toLowerCase() === 'platform user') {
    normalizedStudentLevel = 'platform_user';
  }

  const filter = { userId };
  if (context.customId) filter.customId = context.customId;
  else if (context.courseId) filter.courseId = context.courseId;
  else if (context.lessonId) filter.lessonId = context.lessonId;
  else if (context.sectionTitle) filter.sectionTitle = context.sectionTitle;

  const setOnInsert = {
    title,
    studentLevel: normalizedStudentLevel,
    isActive: true,
    messageCount: 0,
    lastMessageAt: new Date()
  };
  if (context.courseId) setOnInsert.courseId = context.courseId;
  if (context.lessonId) setOnInsert.lessonId = context.lessonId;
  if (context.sectionTitle) setOnInsert.sectionTitle = context.sectionTitle;

  const conversation = await this.findOneAndUpdate(
    filter,
    { $setOnInsert: setOnInsert },
    { upsert: true, new: true, setDefaultsOnInsert: true }
  );

  return conversation;
};

// Method to increment message count
conversationSchema.methods.incrementMessageCount = async function() {
  await this.constructor.findByIdAndUpdate(this._id, {
    $inc: { messageCount: 1 },
    $set: { lastMessageAt: new Date() }
  });
  this.messageCount += 1;
  this.lastMessageAt = new Date();
};

// Method to archive conversation
conversationSchema.methods.archive = async function() {
  this.isActive = false;
  await this.save();
};

// Method to get conversation context
conversationSchema.methods.getContext = function() {
  return {
    courseId: this.courseId,
    lessonId: this.lessonId,
    sectionTitle: this.sectionTitle,
    studentLevel: this.studentLevel
  };
};

module.exports = mongoose.model('Conversation', conversationSchema);