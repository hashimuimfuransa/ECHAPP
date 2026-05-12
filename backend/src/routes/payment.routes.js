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
  adminInitiatePayment,
  verifyPayment,
  getMyPayments,
  getPaymentById,
  getAllPayments,
  cancelPayment,
  deletePayment,
  getPaymentStats
} = require('../controllers/payment_workflow.controller');
const { getAdminPaymentsSimple } = require('../controllers/admin_payment_debug.controller');
const { generateInvoice } = require('../controllers/invoice.controller');
const { protect } = require('../middleware/auth.middleware');
const { authorize } = require('../middleware/role.middleware');

// Student routes
router.post('/initiate', protect, initiatePayment);
router.post('/admin-initiate', protect, authorize('admin'), adminInitiatePayment);
router.get('/my-payments', protect, getMyPayments);
router.get('/my', protect, getMyPayments);

// Admin routes
router.get('/', protect, authorize('admin'), getAllPayments);
router.get('/stats', protect, authorize('admin'), getPaymentStats);
router.get('/admin-simple', protect, authorize('admin'), getAdminPaymentsSimple);
router.delete('/cancel/:paymentId', protect, cancelPayment);
router.delete('/:paymentId', protect, authorize('admin'), deletePayment);
router.get('/:paymentId/invoice', protect, authorize('admin'), generateInvoice);

// Specific payment routes (must come BEFORE parameterized routes to avoid conflicts)
router.post('/verify', protect, verifyPayment);
router.put('/verify', protect, authorize('admin'), verifyPayment);
router.get('/:id', protect, getPaymentById);

module.exports = router;