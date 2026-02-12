const admin = require('firebase-admin');

try {
  const serviceAccount = require('../../serviceAccountKey.json');

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
  console.warn('⚠️ Running without Firebase - some features may be unavailable');
}

module.exports = admin;