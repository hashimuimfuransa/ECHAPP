/**
 * Seed BBB Configuration Script
 * Initializes BigBlueButton credentials from environment variables
 * 
 * Usage: node src/scripts/seedBBBConfig.js
 */

const mongoose = require('mongoose');
const BBBConfig = require('../models/BBBConfig');
require('dotenv').config();

async function seedBBBConfig() {
  try {
    // Connect to database
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/excellencecoaching');
    console.log('Connected to MongoDB');

    const serverUrl = process.env.BBB_SERVER_URL?.replace(/\/$/, '');
    const sharedSecret = process.env.BBB_SHARED_SECRET;

    if (!serverUrl || !sharedSecret) {
      console.error('❌ Error: BBB_SERVER_URL and BBB_SHARED_SECRET must be set in .env file');
      console.log('Example:');
      console.log('BBB_SERVER_URL=https://your-bbb-server.com/bigbluebutton');
      console.log('BBB_SHARED_SECRET=your-secret-here');
      process.exit(1);
    }

    // Check if config already exists
    const existing = await BBBConfig.findOne({ serverUrl, sharedSecret });
    
    if (existing) {
      console.log('✅ BBB config already exists in database:');
      console.log(`   Server URL: ${existing.serverUrl}`);
      console.log(`   Is Active: ${existing.isActive}`);
      console.log(`   Created: ${existing.createdAt}`);
      process.exit(0);
    }

    // Create new config
    const config = await BBBConfig.create({
      serverUrl: serverUrl,
      sharedSecret: sharedSecret,
      isActive: true,
      testStatus: 'pending'
    });

    console.log('✅ BBB config seeded successfully!');
    console.log(`   ID: ${config._id}`);
    console.log(`   Server URL: ${config.serverUrl}`);
    console.log(`   Is Active: ${config.isActive}`);
    console.log(`   Created: ${config.createdAt}`);

  } catch (error) {
    console.error('❌ Error seeding BBB config:', error.message);
    process.exit(1);
  } finally {
    await mongoose.disconnect();
  }
}

// Run if called directly
if (require.main === module) {
  seedBBBConfig();
}

module.exports = seedBBBConfig;
