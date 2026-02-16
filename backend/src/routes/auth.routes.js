const express = require('express');
const router = express.Router();
const { register, login, refreshToken, getProfile, logout, googleSignIn, firebaseLogin, forgotPassword, resetPassword } = require('../controllers/auth.controller');
const { protect } = require('../middleware/auth.middleware');

// Public routes
router.post('/register', register);
router.post('/login', login);
router.post('/refresh-token', refreshToken);
router.post('/google', googleSignIn);
router.post('/forgot-password', forgotPassword);
router.post('/reset-password', resetPassword);

// Firebase authentication route
router.post('/firebase-login', firebaseLogin);

// Protected routes
router.get('/profile', protect, getProfile);
router.post('/logout', protect, logout);

module.exports = router;