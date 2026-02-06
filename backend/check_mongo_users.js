require('dotenv').config();
const mongoose = require('mongoose');

async function checkMongoUsers() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');
    
    const User = require('./src/models/User');
    const users = await User.find({ role: 'student' }).select('fullName email createdAt');
    
    console.log('\nMongoDB student users:');
    users.forEach((user, index) => {
      console.log(`${index + 1}. ${user.fullName} (${user.email}) - Created: ${user.createdAt}`);
    });
    
    console.log(`\nTotal MongoDB student users: ${users.length}`);
    
    await mongoose.connection.close();
  } catch (error) {
    console.error('Error:', error.message);
  }
}

checkMongoUsers();