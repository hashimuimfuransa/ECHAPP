const express = require('express');
const router = express.Router();
const { register, login, refreshToken, getProfile, logout, googleSignIn, firebaseLogin, forgotPassword, resetPassword, verifyResetToken, resetUserDevice } = require('../controllers/auth.controller');
const { protect } = require('../middleware/auth.middleware');
const { adminOnly } = require('../middleware/admin.middleware');

// Public routes
router.post('/register', register);
router.post('/login', login);
router.post('/refresh-token', refreshToken);
router.post('/google', googleSignIn);
router.post('/forgot-password', forgotPassword);
router.post('/reset-password', resetPassword);
router.post('/verify-reset-token', verifyResetToken);

// Firebase authentication route
router.post('/firebase-login', firebaseLogin);

// Protected routes
router.get('/profile', protect, getProfile);
router.post('/logout', protect, logout);

// Admin routes for device management
router.put('/admin/users/:userId/device-reset', protect, adminOnly, resetUserDevice);

module.exports = router;