const mongoose = require('mongoose');
const crypto = require('crypto');

const passwordResetTokenSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  token: {
    type: String,
    required: true,
    unique: true
  },
  expiresAt: {
    type: Date,
    required: true
  },
  used: {
    type: Boolean,
    default: false
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

// Index for automatic cleanup of expired tokens
passwordResetTokenSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });

// Generate a secure reset token
passwordResetTokenSchema.statics.generateToken = function(userId) {
  const token = crypto.randomBytes(32).toString('hex');
  const expiresAt = new Date(Date.now() + 60 * 60 * 1000); // 1 hour expiration
  
  return this.create({
    userId,
    token,
    expiresAt
  });
};

// Find valid token
passwordResetTokenSchema.statics.findValidToken = function(token) {
  return this.findOne({
    token,
    expiresAt: { $gt: new Date() },
    used: false
  }).populate('userId');
};

// Mark token as used
passwordResetTokenSchema.methods.markAsUsed = function() {
  this.used = true;
  return this.save();
};

module.exports = mongoose.model('PasswordResetToken', passwordResetTokenSchema);