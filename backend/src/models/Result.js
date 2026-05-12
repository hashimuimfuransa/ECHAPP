const mongoose = require('mongoose');

const resultSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  examId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Quiz',
    required: true
  },
  answers: [{
    type: mongoose.Schema.Types.Mixed,
    default: []
  }],
  score: {
    type: Number,
    default: 0
  },
  totalScore: {
    type: Number,
    default: 0
  },
  passed: {
    type: Boolean,
    default: false
  },
  submittedAt: {
    type: Date,
    default: Date.now
  },
  gradedAt: {
    type: Date
  },
  feedback: {
    type: String,
    trim: true
  },
  timeSpent: {
    type: Number,
    default: 0
  }
});

// Add indexes for better performance
resultSchema.index({ userId: 1, examId: 1, submittedAt: -1 });

module.exports = mongoose.model('Result', resultSchema);
