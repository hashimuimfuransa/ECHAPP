const mongoose = require('mongoose');

/**
 * Opt-in record backing "Find Study Partners". A student only appears in the
 * partner list for a course after explicitly publishing one of these, so the
 * feature never exposes someone who did not ask to be matched.
 */
const studyPartnerProfileSchema = new mongoose.Schema({
  courseId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Course',
    required: [true, 'Course ID is required']
  },
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  goal: {
    type: String,
    trim: true,
    maxlength: [300, 'Goal cannot exceed 300 characters']
  },
  topics: [{
    type: String,
    trim: true
  }],
  availability: [{
    type: String,
    enum: ['mornings', 'afternoons', 'evenings', 'weekends', 'flexible']
  }],
  note: {
    type: String,
    trim: true,
    maxlength: [1000, 'Note cannot exceed 1000 characters']
  },
  isActive: {
    type: Boolean,
    default: true
  }
}, {
  timestamps: true
});

studyPartnerProfileSchema.index({ courseId: 1, userId: 1 }, { unique: true });
studyPartnerProfileSchema.index({ courseId: 1, isActive: 1, updatedAt: -1 });

module.exports = mongoose.model('StudyPartnerProfile', studyPartnerProfileSchema);
