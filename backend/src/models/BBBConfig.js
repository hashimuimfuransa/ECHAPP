const mongoose = require('mongoose');

/**
 * BigBlueButton Configuration Model
 * Stores BBB API credentials in database
 */
const bbbConfigSchema = new mongoose.Schema({
  serverUrl: {
    type: String,
    required: true,
    trim: true
  },
  sharedSecret: {
    type: String,
    required: true
  },
  isActive: {
    type: Boolean,
    default: true
  },
  lastTested: {
    type: Date,
    default: null
  },
  testStatus: {
    type: String,
    enum: ['success', 'failed', 'pending', null],
    default: null
  },
  testMessage: {
    type: String,
    default: null
  }
}, {
  timestamps: true
});

// Ensure only one active config exists
bbbConfigSchema.pre('save', async function() {
  if (this.isActive) {
    // Deactivate other configs
    await this.constructor.updateMany(
      { _id: { $ne: this._id } },
      { isActive: false }
    );
  }
});

// Static method to get active config
bbbConfigSchema.statics.getActiveConfig = async function() {
  return await this.findOne({ isActive: true });
};

// Static method to initialize default config from env (for migration)
bbbConfigSchema.statics.initializeFromEnv = async function() {
  const BBB_SERVER_URL = process.env.BBB_SERVER_URL?.replace(/\/$/, '');
  const BBB_SHARED_SECRET = process.env.BBB_SHARED_SECRET;
  
  if (!BBB_SERVER_URL || !BBB_SHARED_SECRET) {
    console.log('BBB environment variables not set, skipping initialization');
    return null;
  }
  
  // Check if already exists
  const existing = await this.findOne({ 
    serverUrl: BBB_SERVER_URL,
    sharedSecret: BBB_SHARED_SECRET 
  });
  
  if (existing) {
    console.log('BBB config already exists in database');
    return existing;
  }
  
  // Create new config from env
  const config = await this.create({
    serverUrl: BBB_SERVER_URL,
    sharedSecret: BBB_SHARED_SECRET,
    isActive: true
  });
  
  console.log('BBB config initialized from environment variables');
  return config;
};

module.exports = mongoose.model('BBBConfig', bbbConfigSchema);
