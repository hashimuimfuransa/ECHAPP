const mongoose = require('mongoose');
require('dotenv').config();

// Connect to MongoDB
mongoose.connect(process.env.MONGODB_URI);

const db = mongoose.connection;
db.on('error', console.error.bind(console, 'MongoDB connection error:'));
db.once('open', async () => {
  console.log('Connected to MongoDB');
  
  try {
    // Import the Exam model
    const Exam = require('./src/models/Exam');
    
    // Find all exams
    const exams = await Exam.find({});
    
    console.log(`Found ${exams.length} exams:`);
    exams.forEach((exam, index) => {
      console.log(`\n--- Exam ${index + 1} ---`);
      console.log(`ID: ${exam._id}`);
      console.log(`Title: ${exam.title}`);
      console.log(`Type: ${exam.type}`);
      console.log(`Course ID: ${exam.courseId}`);
      console.log(`Section ID: ${exam.sectionId}`);
      console.log(`Questions Count: ${exam.questionsCount}`);
      console.log(`Created: ${exam.createdAt}`);
      console.log(`Published: ${exam.isPublished}`);
    });
    
    // Close connection
    mongoose.connection.close();
  } catch (error) {
    console.error('Error:', error);
    mongoose.connection.close();
  }
});