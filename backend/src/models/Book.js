const mongoose = require('mongoose');

const bookSchema = new mongoose.Schema({
  title: {
    type: String,
    required: [true, 'Book title is required'],
    trim: true,
    maxlength: [200, 'Title cannot exceed 200 characters']
  },
  author: {
    type: String,
    required: [true, 'Author is required'],
    trim: true,
    maxlength: [100, 'Author name cannot exceed 100 characters']
  },
  description: {
    type: String,
    trim: true,
    maxlength: [2000, 'Description cannot exceed 2000 characters']
  },
  pdfUrl: {
    type: String,
    required: [true, 'PDF URL is required']
  },
  pdfS3Key: {
    type: String,
    required: [true, 'PDF S3 key is required']
  },
  coverUrl: {
    type: String,
    default: null
  },
  coverS3Key: {
    type: String,
    default: null
  },
  language: {
    type: String,
    default: 'en',
    trim: true
  },
  subject: {
    type: String,
    required: [true, 'Subject is required'],
    trim: true
  },
  academicCategory: {
    type: String,
    trim: true
  },
  relatedCourses: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Course'
  }],
  downloadCount: {
    type: Number,
    default: 0
  },
  isPublished: {
    type: Boolean,
    default: false
  },
  uploadedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  fileSize: {
    type: Number,
    default: 0
  },
  pages: {
    type: Number,
    default: null
  },
  textContent: {
    type: String,
    default: null
  }
}, {
  timestamps: true
});

// Index for better search performance
bookSchema.index({ title: 'text', author: 'text', description: 'text' });
bookSchema.index({ subject: 1 });
bookSchema.index({ isPublished: 1 });
bookSchema.index({ uploadedBy: 1 });

module.exports = mongoose.model('Book', bookSchema);
