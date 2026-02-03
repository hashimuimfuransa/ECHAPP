const mongoose = require('mongoose');

const courseSchema = new mongoose.Schema({
  title: {
    type: String,
    required: [true, 'Course title is required'],
    trim: true,
    maxlength: [200, 'Title cannot exceed 200 characters']
  },
  description: {
    type: String,
    required: [true, 'Course description is required'],
    maxlength: [2000, 'Description cannot exceed 2000 characters']
  },
  price: {
    type: Number,
    required: [true, 'Price is required'],
    min: [0, 'Price cannot be negative']
  },
  duration: {
    type: Number,
    required: [true, 'Duration is required'],
    min: [0, 'Duration cannot be negative']
  },
  level: {
    type: String,
    required: [true, 'Level is required'],
    enum: ['beginner', 'intermediate', 'advanced']
  },
  thumbnail: {
    type: String,
    default: null
  },
  isPublished: {
    type: Boolean,
    default: false
  },
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  category: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Category'
  },
  type: {
    type: String,
    required: false // Making it optional to avoid breaking existing functionality
  },
  learningObjectives: [{
    type: String
  }],
  requirements: [{
    type: String
  }]
}, {
  timestamps: true
});

// Index for better search performance
courseSchema.index({ title: 'text', description: 'text' });
courseSchema.index({ level: 1 });
courseSchema.index({ price: 1 });
courseSchema.index({ isPublished: 1 });

module.exports = mongoose.model('Course', courseSchema);