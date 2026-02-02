const express = require('express');
const router = express.Router();
const { 
  getAllCategories,
  getPopularCategories,
  getFeaturedCategories,
  getCategoriesByLevel,
  getCategoryById,
  createCategory,
  updateCategory,
  deleteCategory,
  searchCategories
} = require('../controllers/category.controller');
const { protect } = require('../middleware/auth.middleware');
const { authorize } = require('../middleware/role.middleware');

// Public routes
router.get('/', getAllCategories);
router.get('/popular', getPopularCategories);
router.get('/featured', getFeaturedCategories);
router.get('/level/:level', getCategoriesByLevel);
router.get('/search', searchCategories);
router.get('/:id', getCategoryById);

// Admin routes
router.post('/', protect, authorize('admin'), createCategory);
router.put('/:id', protect, authorize('admin'), updateCategory);
router.delete('/:id', protect, authorize('admin'), deleteCategory);

module.exports = router;