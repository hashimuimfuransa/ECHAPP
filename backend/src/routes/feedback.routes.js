const express = require('express');
const router = express.Router();
const feedbackController = require('../controllers/feedback.controller');
const { protect } = require('../middleware/auth.middleware');
const { authorize } = require('../middleware/role.middleware');

// Student routes
router.post('/submit', protect, feedbackController.submitFeedback);

// Admin routes
router.get('/all', protect, authorize('admin'), feedbackController.getAllFeedback);
router.patch('/:id/read', protect, authorize('admin'), feedbackController.markAsRead);
router.delete('/:id', protect, authorize('admin'), feedbackController.deleteFeedback);

module.exports = router;
