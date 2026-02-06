require('dotenv').config();
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

async function checkUsers() {
  try {
    console.log('Checking Firebase users...');
    const result = await admin.auth().listUsers();
    
    console.log('\nFirebase users:');
    result.users.forEach((user, index) => {
      console.log(`${index + 1}. ${user.displayName || 'No name'} (${user.email}) - Role: ${user.customClaims?.role || 'student'}`);
    });
    
    console.log(`\nTotal Firebase users: ${result.users.length}`);
    
    // Filter out admin users
    const studentUsers = result.users.filter(user => user.customClaims?.role !== 'admin');
    console.log(`Student users (excluding admins): ${studentUsers.length}`);
    
    // Check MongoDB users
    const mongoose = require('mongoose');
    await mongoose.connect(process.env.MONGODB_URI);
    
    const User = require('./src/models/User');
    const mongoUsers = await User.countDocuments({ role: 'student' });
    console.log(`MongoDB student users: ${mongoUsers}`);
    
    const totalUsers = studentUsers.length + mongoUsers;
    console.log(`Total student users: ${totalUsers}`);
    
    await mongoose.connection.close();
    
  } catch (error) {
    console.error('Error:', error.message);
  }
}

checkUsers();