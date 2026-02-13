const User = require('../models/User');
const { verifyToken } = require('../utils/jwt.utils');
const { sendUnauthorized } = require('../utils/response.utils');
const admin = require('../config/firebase');

const protect = async (req, res, next) => {
  console.log('=== AUTH MIDDLEWARE CALLED ===');
  console.log('Request URL:', req.url);
  console.log('Request method:', req.method);
  console.log('Authorization header:', req.headers.authorization);
  
  let token;

  // Check for token in header
  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
    try {
      // Get token from header
      token = req.headers.authorization.split(' ')[1];
      
      console.log('Token extracted:', token.substring(0, 10) + '...');

      // Verify Firebase ID token
      const decodedToken = await admin.auth().verifyIdToken(token);
      
      console.log('Token verified, UID:', decodedToken.uid);
      
      // Find user by Firebase UID
      req.user = await User.findOne({ firebaseUid: decodedToken.uid }).select('-password');
      
      console.log('User found:', !!req.user);
      if (req.user) {
        console.log('User role:', req.user.role);
        console.log('User ID:', req.user._id);
        console.log('User email:', req.user.email);
        console.log('User isActive:', req.user.isActive);
      }
      
      if (!req.user) {
        console.log('User not found in database');
        return sendUnauthorized(res, 'User not found in database');
      }
      
      if (!req.user.isActive) {
        console.log('User account is deactivated');
        return sendUnauthorized(res, 'User account is deactivated');
      }
      
      console.log('Auth successful, proceeding to next middleware');
      next();
    } catch (error) {
      console.log('Auth error:', error.message);
      console.error('Full auth error:', error);
      return sendUnauthorized(res, 'Not authorized, invalid token');
    }
  } else {
    console.log('No authorization header provided');
    return sendUnauthorized(res, 'Not authorized, no token provided');
  }
};

module.exports = { protect };