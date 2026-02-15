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
  type: {
    type: String,
    enum: ['mcq', 'true_false', 'fill_blank', 'open'], // Support all question types
    default: 'mcq',
    required: true
  },
  options: [{
    type: String,
    maxlength: [500, 'Option cannot exceed 500 characters']
  }],
  correctAnswer: {
    type: mongoose.Schema.Types.Mixed, // Can be either string (answer text) or number (option index)
    required: function() {
      // correctAnswer is required for mcq and true_false, but optional for open and fill_blank
      return this.type === 'mcq' || this.type === 'true_false';
    }
  },
  points: {
    type: Number,
    default: 1,
    min: [0, 'Points cannot be negative']
  },
  section: {
    type: String,
    maxlength: [100, 'Section name cannot exceed 100 characters'],
    required: false
  }
}, {
  timestamps: true
});



// Index for better performance
questionSchema.index({ examId: 1 });

module.exports = mongoose.model('Question', questionSchema);