const mongoose = require('mongoose');

const sectionSchema = new mongoose.Schema({
  courseId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Course',
    required: [true, 'Course ID is required']
  },
  title: {
    type: String,
    required: [true, 'Section title is required'],
    trim: true,
    maxlength: [200, 'Title cannot exceed 200 characters']
  },
  order: {
    type: Number,
    required: [true, 'Order is required'],
    min: [0, 'Order cannot be negative']
  }
}, {
  timestamps: true
});

// Index for better performance
sectionSchema.index({ courseId: 1, order: 1 });

module.exports = mongoose.model('Section', sectionSchema);