const Payment = require('../models/Payment');
const { sendSuccess, sendError, sendNotFound } = require('../utils/response.utils');

// Simple admin payment fetch for debugging
const getAdminPaymentsSimple = async (req, res) => {
  try {
    console.log('=== ADMIN PAYMENTS SIMPLE DEBUG ===');
    console.log('User in request:', req.user);
    console.log('User role:', req.user?.role);
    console.log('User ID:', req.user?.id);
    
    // Use actual database query
    const payments = await Payment.find()
      .populate('userId', 'fullName email')
      .populate('courseId', 'title price')
      .limit(20)
      .sort({ createdAt: -1 });
    
    console.log('Found payments:', payments.length);
    
    sendSuccess(res, {
      payments,
      totalPages: 1,
      currentPage: 1,
      total: payments.length
    }, 'Admin payments retrieved successfully');
    
  } catch (error) {
    console.error('Error in getAdminPaymentsSimple:', error);
    sendError(res, 'Failed to retrieve admin payments', 500, error.message);
  }
};

module.exports = { getAdminPaymentsSimple };