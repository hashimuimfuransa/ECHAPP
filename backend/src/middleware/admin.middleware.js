const { sendError } = require('../utils/response.utils');

const adminOnly = (req, res, next) => {
  // Check if user is authenticated (should already be handled by protect middleware)
  if (!req.user) {
    return sendError(res, 'Not authorized, no user found', 401);
  }

  // Check if user has admin role
  if (req.user.role !== 'admin') {
    return sendError(res, 'Access denied. Admin role required.', 403);
  }

  // User is authenticated and has admin role
  if (typeof next === 'function') {
    next();
  } else {
    console.error('CRITICAL: next is not a function in adminOnly middleware');
    return sendError(res, 'Internal Server Error: Middleware chain broken', 500);
  }
};

module.exports = { adminOnly };