const mongoose = require('mongoose');

/**
 * A reply on a community post. Teacher replies are flagged so the UI can
 * badge them as official guidance, and the post author (or a teacher) can
 * mark one reply as the accepted answer.
 */
const replySchema = new mongoose.Schema({
  authorId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  authorRole: {
    type: String,
    enum: ['student', 'instructor', 'admin'],
    default: 'student'
  },
  content: {
    type: String,
    required: [true, 'Reply content is required'],
    trim: true,
    maxlength: [5000, 'Reply cannot exceed 5000 characters']
  },
  likes: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }],
  isAccepted: {
    type: Boolean,
    default: false
  },
  isEdited: {
    type: Boolean,
    default: false
  }
}, { timestamps: true });

/**
 * Everything that shows up in the Discussions / Help / Announcements feed of
 * a course community. One collection keeps the feed queries simple; `type`
 * decides where an entry surfaces in the UI.
 */
const communityPostSchema = new mongoose.Schema({
  courseId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Course',
    required: [true, 'Course ID is required']
  },
  authorId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: [true, 'Author ID is required']
  },
  authorRole: {
    type: String,
    enum: ['student', 'instructor', 'admin'],
    default: 'student'
  },
  type: {
    type: String,
    enum: ['discussion', 'question', 'announcement', 'help'],
    default: 'discussion'
  },
  /** Only used by help requests — mirrors the "What do you need help with?" picker. */
  helpCategory: {
    type: String,
    enum: ['concept', 'assignment', 'question', 'study_partner', 'technical', 'resource', 'teacher'],
    default: null
  },
  title: {
    type: String,
    trim: true,
    maxlength: [200, 'Title cannot exceed 200 characters']
  },
  content: {
    type: String,
    required: [true, 'Content is required'],
    trim: true,
    maxlength: [10000, 'Content cannot exceed 10000 characters']
  },
  attachments: [{
    name: String,
    url: String,
    mimeType: String,
    size: Number
  }],
  tags: [{
    type: String,
    trim: true,
    lowercase: true
  }],
  likes: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }],
  replies: [replySchema],
  isPinned: {
    type: Boolean,
    default: false
  },
  isResolved: {
    type: Boolean,
    default: false
  },
  isClosed: {
    type: Boolean,
    default: false
  },
  viewCount: {
    type: Number,
    default: 0
  },
  lastActivityAt: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

communityPostSchema.index({ courseId: 1, type: 1, isPinned: -1, lastActivityAt: -1 });
communityPostSchema.index({ courseId: 1, authorId: 1 });
communityPostSchema.index({ courseId: 1, createdAt: -1 });

communityPostSchema.virtual('replyCount').get(function () {
  return this.replies ? this.replies.length : 0;
});

communityPostSchema.virtual('likeCount').get(function () {
  return this.likes ? this.likes.length : 0;
});

communityPostSchema.virtual('hasTeacherAnswer').get(function () {
  if (!this.replies) return false;
  return this.replies.some((r) => r.authorRole === 'instructor' || r.authorRole === 'admin');
});

module.exports = mongoose.model('CommunityPost', communityPostSchema);
