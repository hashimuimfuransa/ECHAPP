const Category = require('../models/Category');
const { successResponse, errorResponse } = require('../utils/response.utils');

// Get all categories
exports.getAllCategories = async (req, res) => {
  try {
    const categories = await Category.find().sort({ level: 1, name: 1 });
    return successResponse(res, categories, 'Categories retrieved successfully');
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

// Get popular categories
exports.getPopularCategories = async (req, res) => {
  try {
    const categories = await Category.find({ isPopular: true }).sort({ name: 1 });
    return successResponse(res, categories, 'Popular categories retrieved successfully');
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

// Get featured categories
exports.getFeaturedCategories = async (req, res) => {
  try {
    const categories = await Category.find({ isFeatured: true }).sort({ name: 1 });
    return successResponse(res, categories, 'Featured categories retrieved successfully');
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

// Get categories by level
exports.getCategoriesByLevel = async (req, res) => {
  try {
    const { level } = req.params;
    const categories = await Category.find({ level: parseInt(level) }).sort({ name: 1 });
    return successResponse(res, categories, `Level ${level} categories retrieved successfully`);
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

// Get category by ID
exports.getCategoryById = async (req, res) => {
  try {
    const { id } = req.params;
    const category = await Category.findById(id).populate('courses');
    
    if (!category) {
      return errorResponse(res, 'Category not found', 404);
    }
    
    return successResponse(res, category, 'Category retrieved successfully');
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

// Create new category
exports.createCategory = async (req, res) => {
  try {
    const { name, description, icon, subcategories, isPopular, isFeatured, level } = req.body;
    
    // Check if category already exists
    const existingCategory = await Category.findOne({ name });
    if (existingCategory) {
      return errorResponse(res, 'Category with this name already exists', 400);
    }
    
    const category = new Category({
      name,
      description,
      icon,
      subcategories,
      isPopular: isPopular || false,
      isFeatured: isFeatured || false,
      level: level || 1
    });
    
    await category.save();
    return successResponse(res, category, 'Category created successfully', 201);
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

// Update category
exports.updateCategory = async (req, res) => {
  try {
    const { id } = req.params;
    const updates = req.body;
    
    const category = await Category.findByIdAndUpdate(
      id,
      updates,
      { new: true, runValidators: true }
    );
    
    if (!category) {
      return errorResponse(res, 'Category not found', 404);
    }
    
    return successResponse(res, category, 'Category updated successfully');
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

// Delete category
exports.deleteCategory = async (req, res) => {
  try {
    const { id } = req.params;
    
    const category = await Category.findByIdAndDelete(id);
    
    if (!category) {
      return errorResponse(res, 'Category not found', 404);
    }
    
    return successResponse(res, null, 'Category deleted successfully');
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

// Search categories
exports.searchCategories = async (req, res) => {
  try {
    const { query } = req.query;
    
    if (!query) {
      return errorResponse(res, 'Search query is required', 400);
    }
    
    const categories = await Category.find({
      $text: { $search: query }
    }).sort({ score: { $meta: 'textScore' } });
    
    return successResponse(res, categories, 'Search results retrieved successfully');
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};