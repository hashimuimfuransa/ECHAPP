const User = require('../models/User');
const { generateToken, generateRefreshToken } = require('../utils/jwt.utils');
const { sendSuccess, sendError, sendUnauthorized } = require('../utils/response.utils');
const { OAuth2Client } = require('google-auth-library');
const admin = require('firebase-admin');

// Google OAuth is handled by Firebase, so we don't need separate Google OAuth client
// const CLIENT_ID = process.env.GOOGLE_CLIENT_ID;
// const client = new OAuth2Client(CLIENT_ID);

// Register user
const register = async (req, res) => {
  try {
    const { fullName, email, password, phone } = req.body;

    // Check if user already exists
    const userExists = await User.findOne({ email });
    if (userExists) {
      return sendError(res, 'User already exists with this email', 400);
    }

    // Create user
    const user = await User.create({
      fullName,
      email,
      password,
      phone
    });

    if (user) {
      const token = generateToken({ id: user._id });
      const refreshToken = generateRefreshToken({ id: user._id });

      sendSuccess(res, {
        user: {
          id: user._id,
          fullName: user.fullName,
          email: user.email,
          role: user.role,
          phone: user.phone,
          createdAt: user.createdAt.getTime()
        },
        token,
        refreshToken
      }, 'User registered successfully', 201);
    } else {
      sendError(res, 'Invalid user data', 400);
    }
  } catch (error) {
    sendError(res, 'Registration failed', 500, error.message);
  }
};

// Login user
const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    // Find user and include password for comparison
    const user = await User.findOne({ email }).select('+password');

    if (user && (await user.comparePassword(password))) {
      if (!user.isActive) {
        return sendError(res, 'Account is deactivated', 401);
      }

      const token = generateToken({ id: user._id });
      const refreshToken = generateRefreshToken({ id: user._id });

      sendSuccess(res, {
        user: {
          id: user._id,
          fullName: user.fullName,
          email: user.email,
          role: user.role,
          phone: user.phone,
          createdAt: user.createdAt.getTime()
        },
        token,
        refreshToken
      }, 'Login successful');
    } else {
      sendUnauthorized(res, 'Invalid email or password');
    }
  } catch (error) {
    sendError(res, 'Login failed', 500, error.message);
  }
};

// Refresh token
const refreshToken = async (req, res) => {
  try {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      return sendUnauthorized(res, 'Refresh token is required');
    }

    // Verify refresh token
    const decoded = require('../utils/jwt.utils').verifyRefreshToken(refreshToken);
    
    // Get user
    const user = await User.findById(decoded.id);
    
    if (!user || !user.isActive) {
      return sendUnauthorized(res, 'Invalid refresh token');
    }

    // Generate new tokens
    const newToken = generateToken({ id: user._id });
    const newRefreshToken = generateRefreshToken({ id: user._id });

    sendSuccess(res, {
      token: newToken,
      refreshToken: newRefreshToken
    }, 'Token refreshed successfully');
  } catch (error) {
    sendUnauthorized(res, 'Invalid refresh token');
  }
};

// Get user profile
const getProfile = async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    if (!user) {
      return sendError(res, 'User not found', 404);
    }
    
    sendSuccess(res, {
      id: user._id,
      fullName: user.fullName,
      email: user.email,
      role: user.role,
      phone: user.phone,
      createdAt: user.createdAt.getTime()
    }, 'Profile retrieved successfully');
  } catch (error) {
    sendError(res, 'Failed to retrieve profile', 500, error.message);
  }
};

// Logout user
const logout = async (req, res) => {
  // In a real application, you might want to blacklist the token
  sendSuccess(res, null, 'Logged out successfully');
};

// Google Sign-In - Legacy method, may be deprecated in favor of Firebase auth
const googleSignIn = async (req, res) => {
  try {
    const { idToken } = req.body;
    
    if (!idToken) {
      return sendError(res, 'ID token is required', 400);
    }
    
    // This would be for traditional Google OAuth flow
    // For Firebase Google auth, use firebaseLogin endpoint instead
    // Verify the ID token with Firebase
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    
    // Check if user already exists in our database
    let user = await User.findOne({ firebaseUid: decodedToken.uid });
    
    if (!user) {
      // Create new user from Google/Firebase auth
      console.log('Creating new user from Google/Firebase:', decodedToken.email);
      user = await User.create({
        firebaseUid: decodedToken.uid,
        email: decodedToken.email,
        fullName: decodedToken.name || 'Google User',
        role: 'student',
        provider: 'google',
        isVerified: decodedToken.email_verified || false,
        isActive: true,
        password: undefined // No password for Google auth users
      });
    }
    
    // Generate tokens
    const token = generateToken({ id: user._id });
    const refreshToken = generateRefreshToken({ id: user._id });
    
    sendSuccess(res, {
      user: {
        id: user._id,
        firebaseUid: user.firebaseUid,
        fullName: user.fullName,
        email: user.email,
        role: user.role,
        provider: user.provider,
        createdAt: user.createdAt.getTime()
      },
      token,
      refreshToken
    }, 'Google Sign-In successful', 200);
  } catch (error) {
    console.error('Google Sign-In Error:', error);
    sendError(res, 'Google authentication failed', 500, error.message);
  }
};

// Firebase login/signup - handles both new and existing users
const firebaseLogin = async (req, res) => {
  try {
    const { idToken } = req.body;
    
    if (!idToken) {
      return sendError(res, 'Firebase ID token is required', 400);
    }

    // Verify Firebase ID token
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    
    // Check if user already exists in our database
    let user = await User.findOne({ firebaseUid: decodedToken.uid });
    
    if (!user) {
      // Case 1: New user (signup) - create user in MongoDB
      console.log('Creating new user from Firebase:', decodedToken.email);
      user = await User.create({
        firebaseUid: decodedToken.uid,
        email: decodedToken.email,
        fullName: decodedToken.name || 'Firebase User',
        role: 'student',
        provider: 'firebase',
        isVerified: decodedToken.email_verified || false,
        isActive: true,
        // Firebase users don't need password
        password: undefined
      });
    } else {
      // Case 2: Existing user (login) - user already in MongoDB
      console.log('Existing user logging in:', user.email);
      // Optionally update user info if it changed in Firebase
      if (decodedToken.name && user.fullName !== decodedToken.name) {
        user.fullName = decodedToken.name;
        await user.save();
      }
    }
    
    // Generate our own JWT token for subsequent requests
    const token = generateToken({ id: user._id });
    const refreshToken = generateRefreshToken({ id: user._id });
    
    sendSuccess(res, {
      user: {
        id: user._id,
        firebaseUid: user.firebaseUid,
        fullName: user.fullName,
        email: user.email,
        role: user.role,
        provider: user.provider,
        createdAt: user.createdAt.getTime()  // Convert to milliseconds for Dart DateTime
      },
      token,
      refreshToken
    }, 'Authentication successful');
    
  } catch (error) {
    console.error('Firebase login error:', error);
    if (error.code === 'auth/argument-error') {
      return sendError(res, 'Invalid Firebase ID token', 401);
    }
    sendError(res, 'Authentication failed', 500, error.message);
  }
};

module.exports = {
  register,
  login,
  refreshToken,
  getProfile,
  logout,
  googleSignIn,
  firebaseLogin
};