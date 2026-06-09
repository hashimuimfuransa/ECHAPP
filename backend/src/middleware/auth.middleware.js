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
    // Get token from header
    token = req.headers.authorization.split(' ')[1];
    
    if (token && token.length > 0) {
      console.log('Token extracted:', token.substring(0, 10) + '...');
    } else {
      console.log('Invalid or missing token format');
    }
    
    // Try to verify as Firebase ID token first
    try {
      const decodedToken = await admin.auth().verifyIdToken(token);
      console.log('Firebase token verified, UID:', decodedToken.uid);
      
      // Find user by Firebase UID
      req.user = await User.findOne({ firebaseUid: decodedToken.uid }).select('-password');
      
      // Fallback: teacher/admin accounts created directly in MongoDB (no firebaseUid set yet)
      // Try to find by email and auto-link the firebaseUid so future logins resolve by UID
      if (!req.user && decodedToken.email) {
        const userByEmail = await User.findOne({ email: decodedToken.email.toLowerCase() });
        if (userByEmail) {
          console.log('User not found by firebaseUid, found by email — linking firebaseUid:', decodedToken.uid);
          userByEmail.firebaseUid = decodedToken.uid;
          await userByEmail.save();
          req.user = await User.findById(userByEmail._id).select('-password');
        }
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
      return next();
    } catch (firebaseError) {
      console.log('Firebase token verification failed:', firebaseError.message);
      console.log('Trying JWT token verification...');
      
      try {
        const decoded = verifyToken(token);
        console.log('JWT token verified, ID:', decoded.id);
        
        const user = await User.findById(decoded.id).select('-password');
        if (!user) {
          console.log('User not found in database');
          return sendUnauthorized(res, 'User not found in database');
        }
        
        if (!user.isActive) {
          console.log('User account is deactivated');
          return sendUnauthorized(res, 'User account is deactivated');
        }
        
        req.user = user;
        console.log('Auth successful, proceeding to next middleware');
        return next();
      } catch (jwtError) {
        console.log('JWT token verification failed:', jwtError.message);
        return sendUnauthorized(res, 'Not authorized, invalid token');
      }
    }
  } else {
    console.log('No authorization header provided');
    return sendUnauthorized(res, 'Not authorized, no token provided');
  }
};

const optionalProtect = (req, res, next) => {
  console.log('=== OPTIONAL AUTH MIDDLEWARE CALLED ===');
  
  let token;

  // Check for token in header
  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
    token = req.headers.authorization.split(' ')[1];
    
    // Try to verify as Firebase ID token
    admin.auth().verifyIdToken(token)
      .then(async (decodedToken) => {
        req.user = await User.findOne({ firebaseUid: decodedToken.uid }).select('-password');
        if (typeof next === 'function') next();
      })
      .catch((firebaseError) => {
        // If Firebase verification fails, try JWT verification
        try {
          const decoded = verifyToken(token);
          User.findById(decoded.id).select('-password')
            .then((user) => {
              req.user = user;
              if (typeof next === 'function') next();
            })
            .catch(() => {
              if (typeof next === 'function') next();
            });
        } catch (jwtError) {
          console.log('Optional Auth: Invalid token');
          if (typeof next === 'function') next();
        }
      });
  } else {
    if (typeof next === 'function') next();
  }
};

module.exports = { protect, optionalProtect };