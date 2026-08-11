const mongoose = require('mongoose');

/**
 * Coursework a teacher publishes into the course community. Group assignments
 * are submitted once per study group; individual ones once per student.
 */
const communityAssignmentSchema = new mongoose.Schema({
  courseId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Course',
    required: [true, 'Course ID is required']
  },
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  title: {
    type: String,
    required: [true, 'Assignment title is required'],
    trim: true,
    maxlength: [200, 'Title cannot exceed 200 characters']
  },
  description: {
    type: String,
    trim: true,
    maxlength: [10000, 'Description cannot exceed 10000 characters']
  },
  type: {
    type: String,
    enum: ['individual', 'group'],
    default: 'individual'
  },
  minGroupSize: {
    type: Number,
    default: 2,
    min: 1
  },
  maxGroupSize: {
    type: Number,
    default: 6,
    min: 1
  },
  dueDate: {
    type: Date,
    required: [true, 'Due date is required']
  },
  maxMarks: {
    type: Number,
    default: 20,
    min: [1, 'Maximum marks must be at least 1']
  },
  attachments: [{
    name: String,
    url: String,
    mimeType: String,
    size: Number
  }],
  allowLateSubmission: {
    type: Boolean,
    default: false
  },
  isPublished: {
    type: Boolean,
    default: true
  }
}, {
  timestamps: true
});

communityAssignmentSchema.index({ courseId: 1, isPublished: 1, dueDate: 1 });
communityAssignmentSchema.index({ createdBy: 1 });

module.exports = mongoose.model('CommunityAssignment', communityAssignmentSchema);
