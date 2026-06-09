/**
 * Fix script: Drop the global unique customId_1 index on conversations
 * and recreate it as a compound (userId + customId) unique sparse index,
 * so each user can have their own 'support_chat' conversation.
 *
 * Run: node fix_customId_index.js
 */
require('dotenv').config();
const mongoose = require('mongoose');

const MONGODB_URI = process.env.MONGODB_URI || process.env.MONGO_URI;

async function fixIndex() {
  try {
    await mongoose.connect(MONGODB_URI);
    console.log('Connected to MongoDB');

    const db = mongoose.connection.db;
    const collection = db.collection('conversations');

    const indexes = await collection.indexes();
    console.log('Current indexes:', JSON.stringify(indexes, null, 2));

    // Drop the old global unique index if it exists
    const oldIndex = indexes.find(idx => idx.key && idx.key.customId && !idx.key.userId);
    if (oldIndex) {
      console.log('Found old global customId index:', oldIndex.name);
      await collection.dropIndex(oldIndex.name);
      console.log('Dropped:', oldIndex.name);
    } else {
      console.log('No global customId_1 index found — nothing to drop.');
    }

    // Drop compound index if it already exists (idempotent re-run safety)
    const compoundIndex = indexes.find(idx => idx.key && idx.key.userId && idx.key.customId);
    if (compoundIndex) {
      console.log('Compound userId+customId index already exists:', compoundIndex.name);
    } else {
      await collection.createIndex(
        { userId: 1, customId: 1 },
        { unique: true, sparse: true, name: 'userId_1_customId_1' }
      );
      console.log('Created compound unique sparse index: userId_1_customId_1');
    }

    const newIndexes = await collection.indexes();
    console.log('\nFinal indexes:');
    newIndexes.forEach(idx => console.log(JSON.stringify(idx)));

    console.log('\nDone!');
  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  } finally {
    await mongoose.disconnect();
  }
}

fixIndex();
