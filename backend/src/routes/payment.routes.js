const express = require('express');
const router = express.Router();
const { 
  initiatePayment,
  verifyPayment,
  getMyPayments,
  getPaymentById,
  getAllPayments
} = require('../controllers/payment.controller');
const { protect, authorize } = require('../middleware/auth.middleware');
const { authorize: roleAuthorize } = require('../middleware/role.middleware');

// Student routes
router.post('/initiate', protect, initiatePayment);
router.post('/verify', protect, verifyPayment);
router.get('/my-payments', protect, getMyPayments);
router.get('/:id', protect, getPaymentById);

// Admin routes
router.get('/', protect, roleAuthorize('admin'), getAllPayments);

module.exports = router;