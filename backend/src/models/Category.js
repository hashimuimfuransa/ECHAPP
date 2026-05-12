const mongoose = require('mongoose');

const categorySchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    trim: true,
    unique: true
  },
  description: {
    type: String,
    required: false,
    trim: true,
    default: ''
  },
  icon: {
    type: String,
    required: false,
    default: 'school'
  },
  subcategories: {
    type: [String],
    default: []
  },
  isPopular: {
    type: Boolean,
    default: false
  },
  isFeatured: {
    type: Boolean,
    default: false
  },
  level: {
    type: Number,
    enum: [1, 2, 3, 4, 5], // 1 = All levels, 2 = Fluency, 3 = In-demand, 4 = Career-ready, 5 = Growth
    default: 1
  },
  courses: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Course'
  }],
  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
  }
});

// Index for search optimization
categorySchema.index({ name: 'text', description: 'text' });

// Performance indexes for common queries
categorySchema.index({ level: 1, name: 1 }); // For getCategoriesByLevel
categorySchema.index({ isPopular: 1, name: 1 }); // For getPopularCategories
categorySchema.index({ isFeatured: 1, name: 1 }); // For getFeaturedCategories
categorySchema.index({ level: 1, isPopular: 1, isFeatured: 1 }); // Compound index for filtering

// Update the updatedAt field before saving
categorySchema.pre('save', function() {
  this.updatedAt = Date.now();
});

module.exports = mongoose.model('Category', categorySchema);