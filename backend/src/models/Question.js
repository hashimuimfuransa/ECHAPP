const mongoose = require('mongoose');

const questionSchema = new mongoose.Schema({
  examId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Exam',
    required: [true, 'Exam ID is required']
  },
  question: {
    type: String,
    required: [true, 'Question is required'],
    maxlength: [1000, 'Question cannot exceed 1000 characters']
  },
  options: [{
    type: String,
    required: [true, 'Options are required'],
    maxlength: [500, 'Option cannot exceed 500 characters']
  }],
  correctAnswer: {
    type: mongoose.Schema.Types.Mixed, // Can be either string (answer text) or number (option index)
    required: [true, 'Correct answer is required']
  },
  points: {
    type: Number,
    default: 1,
    min: [0, 'Points cannot be negative']
  }
}, {
  timestamps: true
});

// Index for better performance
questionSchema.index({ examId: 1 });

module.exports = mongoose.model('Question', questionSchema);