const admin = require('firebase-admin');

try {
  let serviceAccount;
  
  // Check if we're running on Render (production) or locally
  if (process.env.FIREBASE_SERVICE_ACCOUNT_BASE64) {
    // Production: Read from environment variable
    console.log('🔄 Using Firebase service account from environment variable');
    const serviceAccountJson = Buffer.from(process.env.FIREBASE_SERVICE_ACCOUNT_BASE64, 'base64').toString('utf-8');
    serviceAccount = JSON.parse(serviceAccountJson);
  } else {
    // Development: Read from local file
    console.log('🔄 Using Firebase service account from local file');
    serviceAccount = require('../../serviceAccountKey.json');
  }

  // Initialize Firebase Admin SDK
  if (!admin.apps.length) {
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount)
    });
    console.log('✅ Firebase Admin SDK initialized successfully');
  } else {
    console.log('⚠️ Firebase Admin SDK already initialized');
  }
} catch (error) {
  console.error('❌ Error initializing Firebase Admin SDK:', error.message);
  console.error('Error stack:', error.stack);
  console.warn('⚠️ Running without Firebase - some features may be unavailable');
}

module.exports = admin;