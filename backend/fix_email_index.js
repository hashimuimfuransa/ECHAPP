require('dotenv').config();
const mongoose = require('mongoose');

async function fixEmailIndex() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    const db = mongoose.connection.db;
    const collection = db.collection('users');

    // List current indexes
    const indexes = await collection.indexes();
    console.log('\nCurrent indexes on users collection:');
    indexes.forEach(idx => console.log(JSON.stringify(idx)));

    // Check if email_1 index exists and whether it is sparse
    const emailIndex = indexes.find(idx => idx.key && idx.key.email === 1);
    if (!emailIndex) {
      console.log('\nNo email_1 index found. Nothing to fix.');
    } else if (emailIndex.sparse) {
      console.log('\nemail_1 index is already sparse. No fix needed.');
    } else {
      console.log('\nemail_1 index is NOT sparse — dropping and recreating as sparse...');
      await collection.dropIndex('email_1');
      console.log('Dropped email_1 index.');
      await collection.createIndex({ email: 1 }, { unique: true, sparse: true });
      console.log('Recreated email_1 as unique+sparse index.');
    }

    // Also verify phone_1 index is sparse
    const phoneIndex = indexes.find(idx => idx.key && idx.key.phone === 1);
    if (phoneIndex && !phoneIndex.sparse) {
      console.log('\nphone_1 index is NOT sparse — dropping and recreating as sparse...');
      await collection.dropIndex('phone_1');
      await collection.createIndex({ phone: 1 }, { unique: true, sparse: true });
      console.log('Recreated phone_1 as unique+sparse index.');
    }

    const newIndexes = await collection.indexes();
    console.log('\nFinal indexes:');
    newIndexes.forEach(idx => console.log(JSON.stringify(idx)));

    await mongoose.connection.close();
    console.log('\nDone. Connection closed.');
  } catch (error) {
    console.error('Migration error:', error);
    process.exit(1);
  }
}

fixEmailIndex();
