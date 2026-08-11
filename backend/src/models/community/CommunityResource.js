const mongoose = require('mongoose');

/**
 * Files, links and notes shared inside a course community.
 *
 * `source` splits the UI into "Teacher resources" (authoritative) and
 * "Student resources" (peer-shared). Student uploads can additionally be
 * approved by a teacher, which is what quality control hangs off.
 */
const communityResourceSchema = new mongoose.Schema({
  courseId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Course',
    required: [true, 'Course ID is required']
  },
  uploadedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  source: {
    type: String,
    enum: ['teacher', 'student'],
    default: 'student'
  },
  title: {
    type: String,
    required: [true, 'Resource title is required'],
    trim: true,
    maxlength: [200, 'Title cannot exceed 200 characters']
  },
  description: {
    type: String,
    trim: true,
    maxlength: [2000, 'Description cannot exceed 2000 characters']
  },
  type: {
    type: String,
    enum: ['document', 'link', 'video', 'note'],
    default: 'link'
  },
  url: {
    type: String,
    trim: true
  },
  fileName: String,
  mimeType: String,
  size: Number,
  /** Free-text notes live inline instead of behind a URL. */
  body: {
    type: String,
    trim: true,
    maxlength: [10000, 'Note cannot exceed 10000 characters']
  },
  isApproved: {
    type: Boolean,
    default: false
  },
  approvedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    default: null
  },
  likes: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }],
  downloadCount: {
    type: Number,
    default: 0
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

communityResourceSchema.index({ courseId: 1, source: 1, createdAt: -1 });

communityResourceSchema.virtual('likeCount').get(function () {
  return this.likes ? this.likes.length : 0;
});

module.exports = mongoose.model('CommunityResource', communityResourceSchema);
