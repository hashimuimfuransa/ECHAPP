const mongoose = require('mongoose');

const resultSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: [true, 'User ID is required']
  },
  examId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Exam',
    required: [true, 'Exam ID is required']
  },
  answers: [{
    questionId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Question',
      required: true
    },
    selectedOption: {
      type: mongoose.Schema.Types.Mixed, // Can be Number (MCQ/TrueFalse) or String (Open/FillBlank)
      required: true
    },
    answerText: {
      type: String, // Store text answer for open and fill_blank questions
      required: false
    }
  }],
  score: {
    type: Number,
    required: [true, 'Score is required'],
    min: [0, 'Score cannot be negative']
  },
  totalPoints: {
    type: Number,
    required: [true, 'Total points is required'],
    min: [0, 'Total points cannot be negative']
  },
  percentage: {
    type: Number,
    required: [true, 'Percentage is required'],
    min: [0, 'Percentage cannot be negative'],
    max: [100, 'Percentage cannot exceed 100']
  },
  passed: {
    type: Boolean,
    required: [true, 'Pass status is required']
  },
  submittedAt: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

// Index for better performance
resultSchema.index({ userId: 1 });
resultSchema.index({ examId: 1 });
resultSchema.index({ passed: 1 });

module.exports = mongoose.model('Result', resultSchema);