const User = require('../models/User');
const { verifyToken } = require('../utils/jwt.utils');
const { sendUnauthorized } = require('../utils/response.utils');
const admin = require('firebase-admin');

const protect = async (req, res, next) => {
  let token;

  // Check for token in header
  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
    try {
      // Get token from header
      token = req.headers.authorization.split(' ')[1];

      // Verify Firebase ID token
      const decodedToken = await admin.auth().verifyIdToken(token);
      
      // Find user by Firebase UID
      req.user = await User.findOne({ firebaseUid: decodedToken.uid }).select('-password');
      
      if (!req.user) {
        return sendUnauthorized(res, 'User not found in database');
      }
      
      if (!req.user.isActive) {
        return sendUnauthorized(res, 'User account is deactivated');
      }
      
      next();
    } catch (error) {
      return sendUnauthorized(res, 'Not authorized, invalid token');
    }
  } else {
    return sendUnauthorized(res, 'Not authorized, no token provided');
  }
};

module.exports = { protect };