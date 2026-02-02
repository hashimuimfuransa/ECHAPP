const Payment = require('../models/Payment');
const Course = require('../models/Course');
const { sendSuccess, sendError, sendNotFound } = require('../utils/response.utils');

// Initiate payment
const initiatePayment = async (req, res) => {
  try {
    const { courseId, paymentMethod } = req.body;
    const userId = req.user.id;

    // Check if course exists
    const course = await Course.findById(courseId);
    if (!course) {
      return sendNotFound(res, 'Course not found');
    }

    if (course.price <= 0) {
      return sendError(res, 'This course is free', 400);
    }

    // Check if payment already exists
    const existingPayment = await Payment.findOne({ 
      userId, 
      courseId, 
      status: { $in: ['pending', 'completed'] } 
    });
    
    if (existingPayment) {
      if (existingPayment.status === 'completed') {
        return sendError(res, 'Payment already completed for this course', 400);
      }
      return sendSuccess(res, existingPayment, 'Payment already initiated');
    }

    // Generate unique transaction ID
    const transactionId = `TXN_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

    // Create payment record
    const payment = await Payment.create({
      userId,
      courseId,
      amount: course.price,
      paymentMethod,
      transactionId,
      status: 'pending'
    });

    // In a real implementation, you would integrate with MTN MoMo or Airtel Money APIs here
    // For now, we'll simulate the payment process

    sendSuccess(res, {
      paymentId: payment._id,
      transactionId: payment.transactionId,
      amount: payment.amount,
      currency: payment.currency,
      paymentMethod: payment.paymentMethod,
      message: 'Payment initiated successfully. Please complete the payment using your mobile money app.'
    }, 'Payment initiated successfully', 201);
  } catch (error) {
    sendError(res, 'Failed to initiate payment', 500, error.message);
  }
};

// Verify payment
const verifyPayment = async (req, res) => {
  try {
    const { transactionId } = req.body;
    const userId = req.user.id;

    const payment = await Payment.findOne({ transactionId, userId });
    if (!payment) {
      return sendNotFound(res, 'Payment not found');
    }

    if (payment.status === 'completed') {
      return sendSuccess(res, payment, 'Payment already verified');
    }

    // In a real implementation, you would verify with the mobile money provider
    // For simulation, we'll mark as completed after 5 seconds
    setTimeout(async () => {
      payment.status = 'completed';
      payment.paymentDate = new Date();
      await payment.save();
    }, 5000);

    sendSuccess(res, {
      paymentId: payment._id,
      transactionId: payment.transactionId,
      status: 'pending',
      message: 'Payment verification in progress. Please check back in a few moments.'
    }, 'Payment verification initiated');
  } catch (error) {
    sendError(res, 'Failed to verify payment', 500, error.message);
  }
};

// Get user's payment history
const getMyPayments = async (req, res) => {
  try {
    const userId = req.user.id;
    
    const payments = await Payment.find({ userId })
      .populate('courseId', 'title price')
      .sort({ createdAt: -1 });

    sendSuccess(res, payments, 'Payment history retrieved successfully');
  } catch (error) {
    sendError(res, 'Failed to retrieve payment history', 500, error.message);
  }
};

// Get payment by ID
const getPaymentById = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    const payment = await Payment.findOne({ _id: id, userId })
      .populate('courseId', 'title price');

    if (!payment) {
      return sendNotFound(res, 'Payment not found');
    }

    sendSuccess(res, payment, 'Payment retrieved successfully');
  } catch (error) {
    sendError(res, 'Failed to retrieve payment', 500, error.message);
  }
};

// Admin: Get all payments
const getAllPayments = async (req, res) => {
  try {
    const { page = 1, limit = 10, status } = req.query;
    
    const filter = {};
    if (status) {
      filter.status = status;
    }
    
    const payments = await Payment.find(filter)
      .populate('userId', 'fullName email')
      .populate('courseId', 'title price')
      .limit(limit * 1)
      .skip((page - 1) * limit)
      .sort({ createdAt: -1 });
    
    const total = await Payment.countDocuments(filter);
    
    sendSuccess(res, {
      payments,
      totalPages: Math.ceil(total / limit),
      currentPage: Number(page),
      total
    }, 'Payments retrieved successfully');
  } catch (error) {
    sendError(res, 'Failed to retrieve payments', 500, error.message);
  }
};

module.exports = {
  initiatePayment,
  verifyPayment,
  getMyPayments,
  getPaymentById,
  getAllPayments
};