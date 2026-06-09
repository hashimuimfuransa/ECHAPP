/**
 * Fix script: Drop and recreate the firebaseUid index as sparse
 * to allow multiple documents with null/missing firebaseUid.
 * 
 * Run: node fix_firebaseUid_index.js
 */
require('dotenv').config();
const mongoose = require('mongoose');

const MONGODB_URI = process.env.MONGODB_URI || process.env.MONGO_URI;

async function fixIndex() {
  try {
    await mongoose.connect(MONGODB_URI);
    console.log('Connected to MongoDB');

    const db = mongoose.connection.db;
    const collection = db.collection('users');

    // List current indexes
    const indexes = await collection.indexes();
    console.log('Current indexes:', JSON.stringify(indexes, null, 2));

    // Check if there's a non-sparse firebaseUid index
    const fbIndex = indexes.find(idx => idx.key && idx.key.firebaseUid);
    if (fbIndex) {
      console.log('Found firebaseUid index:', fbIndex);
      if (!fbIndex.sparse) {
        console.log('Index is NOT sparse. Dropping and recreating...');
        await collection.dropIndex('firebaseUid_1');
        console.log('Dropped old index');
      } else {
        console.log('Index is already sparse. Checking for null documents...');
      }
    }

    // Remove firebaseUid field from documents where it's explicitly null
    const result = await collection.updateMany(
      { firebaseUid: null },
      { $unset: { firebaseUid: '' } }
    );
    console.log(`Unset firebaseUid from ${result.modifiedCount} documents with null value`);

    // Recreate index as sparse + unique
    await collection.createIndex(
      { firebaseUid: 1 },
      { unique: true, sparse: true }
    );
    console.log('Created sparse unique index on firebaseUid');

    // Verify
    const newIndexes = await collection.indexes();
    const newFbIndex = newIndexes.find(idx => idx.key && idx.key.firebaseUid);
    console.log('New firebaseUid index:', newFbIndex);

    console.log('Done!');
  } catch (error) {
    console.error('Error:', error);
  } finally {
    await mongoose.disconnect();
  }
}

fixIndex();
