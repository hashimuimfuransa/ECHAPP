const mongoose = require('mongoose');

const examSchema = new mongoose.Schema({
  courseId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Course',
    required: [true, 'Course ID is required']
  },
  sectionId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Section',
    required: [true, 'Section ID is required']
  },
  title: {
    type: String,
    required: [true, 'Exam title is required'],
    trim: true,
    maxlength: [200, 'Title cannot exceed 200 characters']
  },
  type: {
    type: String,
    required: [true, 'Exam type is required'],
    enum: ['quiz', 'pastpaper', 'final']
  },
  passingScore: {
    type: Number,
    required: [true, 'Passing score is required'],
    min: [0, 'Passing score cannot be negative'],
    max: [100, 'Passing score cannot exceed 100']
  },
  timeLimit: {
    type: Number, // in minutes
    default: 0
  },
  isPublished: {
    type: Boolean,
    default: false
  },
  questionsCount: {
    type: Number,
    default: 0
  }
}, {
  timestamps: true
});

// Index for better performance
examSchema.index({ courseId: 1 });
examSchema.index({ type: 1 });
examSchema.index({ sectionId: 1 }); // Add index for section-based queries

module.exports = mongoose.model('Exam', examSchema);