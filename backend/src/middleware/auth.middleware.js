const User = require('../models/User');
const { verifyToken } = require('../utils/jwt.utils');
const { sendUnauthorized } = require('../utils/response.utils');
const admin = require('../config/firebase');

const protect = (req, res, next) => {
  console.log('=== AUTH MIDDLEWARE CALLED ===');
  console.log('Request URL:', req.url);
  console.log('Request method:', req.method);
  console.log('Authorization header:', req.headers.authorization);
  
  let token;

  // Check for token in header
  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
    // Get token from header
    token = req.headers.authorization.split(' ')[1];
    
    console.log('Token extracted:', token.substring(0, 10) + '...');
    
    // Try to verify as Firebase ID token first
    admin.auth().verifyIdToken(token)
      .then(async (decodedToken) => {
        console.log('Firebase token verified, UID:', decodedToken.uid);
        
        // Find user by Firebase UID
        req.user = await User.findOne({ firebaseUid: decodedToken.uid }).select('-password');
        
        if (!req.user) {
          console.log('User not found in database');
          return sendUnauthorized(res, 'User not found in database');
        }
        
        if (!req.user.isActive) {
          console.log('User account is deactivated');
          return sendUnauthorized(res, 'User account is deactivated');
        }
        
        console.log('Auth successful, proceeding to next middleware');
        if (typeof next === 'function') {
          next();
        } else {
          console.error('CRITICAL: next is not a function in protect.then');
          return sendError(res, 'Internal Server Error: Middleware chain broken', 500);
        }
      })
      .catch((firebaseError) => {
        console.log('Firebase token verification failed:', firebaseError.message);
        console.log('Trying JWT token verification...');
        
        try {
          const decoded = verifyToken(token);
          console.log('JWT token verified, ID:', decoded.id);
          
          User.findById(decoded.id).select('-password')
            .then((user) => {
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
              if (typeof next === 'function') {
                next();
              } else {
                console.error('CRITICAL: next is not a function in protect.jwt.then');
                return sendError(res, 'Internal Server Error: Middleware chain broken', 500);
              }
            })
            .catch((dbError) => {
              console.log('DB error:', dbError.message);
              return sendUnauthorized(res, 'Not authorized, database error');
            });
        } catch (jwtError) {
          console.log('JWT token verification failed:', jwtError.message);
          return sendUnauthorized(res, 'Not authorized, invalid token');
        }
      });
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