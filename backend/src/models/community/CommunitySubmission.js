const mongoose = require('mongoose');

/**
 * A submission against a CommunityAssignment. For group assignments the
 * whole group shares one submission document, and every member listed in
 * `members` receives the grade.
 *
 * Named `CommunitySubmission` because the legacy exam `Submission` model
 * (backend/models/Submission.js) already owns the `Submission` model name.
 */
const communitySubmissionSchema = new mongoose.Schema({
  assignmentId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'CommunityAssignment',
    required: true
  },
  courseId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Course',
    required: true
  },
  groupId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'StudyGroup',
    default: null
  },
  submittedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  /** Everyone the grade applies to (the submitter alone for individual work). */
  members: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }],
  comment: {
    type: String,
    trim: true,
    maxlength: [3000, 'Comment cannot exceed 3000 characters']
  },
  files: [{
    name: String,
    url: String,
    mimeType: String,
    size: Number
  }],
  status: {
    type: String,
    enum: ['submitted', 'under_review', 'returned'],
    default: 'submitted'
  },
  isLate: {
    type: Boolean,
    default: false
  },
  submittedAt: {
    type: Date,
    default: Date.now
  },
  grade: {
    score: {
      type: Number,
      default: null,
      min: 0
    },
    feedback: {
      type: String,
      trim: true,
      maxlength: [5000, 'Feedback cannot exceed 5000 characters']
    },
    gradedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null
    },
    gradedAt: {
      type: Date,
      default: null
    }
  }
}, {
  timestamps: true
});

// One submission per group (group work) or per student (individual work)
communitySubmissionSchema.index(
  { assignmentId: 1, groupId: 1 },
  { unique: true, partialFilterExpression: { groupId: { $type: 'objectId' } } }
);
// `$type: 'null'` (rather than `groupId: null`) keeps this a valid partial
// filter expression — individual submissions always store an explicit null.
communitySubmissionSchema.index(
  { assignmentId: 1, submittedBy: 1 },
  { unique: true, partialFilterExpression: { groupId: { $type: 'null' } } }
);
communitySubmissionSchema.index({ courseId: 1, status: 1, submittedAt: -1 });
communitySubmissionSchema.index({ members: 1 });

module.exports = mongoose.model('CommunitySubmission', communitySubmissionSchema);
