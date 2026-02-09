const express = require('express');
const router = express.Router();

// Add logging for all requests to this router
router.use((req, res, next) => {
  console.log('=== PAYMENT ROUTER REQUEST ===');
  console.log('Method:', req.method);
  console.log('URL:', req.url);
  console.log('Full URL:', req.originalUrl);
  console.log('Params:', req.params);
  console.log('Query:', req.query);
  next();
});
const { 
  initiatePayment,
  verifyPayment,
  getMyPayments,
  getPaymentById,
  getAllPayments,
  cancelPayment,
  getPaymentStats
} = require('../controllers/payment_workflow.controller');
const { getAdminPaymentsSimple } = require('../controllers/admin_payment_debug.controller');
const { protect, authorize } = require('../middleware/auth.middleware');
const { authorize: roleAuthorize } = require('../middleware/role.middleware');

// Student routes
router.post('/initiate', protect, initiatePayment);
router.get('/my-payments', protect, getMyPayments);
router.get('/my', protect, getMyPayments);

// Admin routes
router.get('/', protect, roleAuthorize('admin'), getAllPayments);
router.get('/stats', protect, roleAuthorize('admin'), getPaymentStats);
router.get('/admin-simple', protect, roleAuthorize('admin'), getAdminPaymentsSimple);
router.delete('/cancel/:paymentId', protect, cancelPayment);

// Specific payment routes (must come BEFORE parameterized routes to avoid conflicts)
router.post('/verify', protect, verifyPayment);
router.put('/verify', protect, roleAuthorize('admin'), verifyPayment);
router.get('/:id', protect, getPaymentById);

module.exports = router;