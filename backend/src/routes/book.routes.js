const express = require('express');
const router = express.Router();
const {
  createBook,
  getAllBooks,
  getAllBooksForAdmin,
  getBookById,
  updateBook,
  deleteBook,
  uploadBookFiles
} = require('../controllers/book.controller');
const { protect } = require('../middleware/auth.middleware');
const { authorize } = require('../middleware/role.middleware');

// Public route to get all published books (for library)
router.get('/', getAllBooks);

// Public route to get a single book by ID
router.get('/:id', getBookById);

// Admin routes
router.post('/upload-files', protect, authorize('admin'), uploadBookFiles);
router.post('/', protect, authorize('admin'), createBook);
router.get('/admin/all', protect, authorize('admin'), getAllBooksForAdmin);
router.put('/:id', protect, authorize('admin'), updateBook);
router.delete('/:id', protect, authorize('admin'), deleteBook);

module.exports = router;
