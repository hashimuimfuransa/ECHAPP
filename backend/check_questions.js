const mongoose = require('mongoose');
require('dotenv').config();

// Connect to MongoDB
mongoose.connect(process.env.MONGODB_URI);

const db = mongoose.connection;
db.on('error', console.error.bind(console, 'MongoDB connection error:'));
db.once('open', async () => {
  console.log('Connected to MongoDB');
  
  try {
    // Import the Question model
    const Question = require('./src/models/Question');
    
    // Find the latest verb-to-be exam (ID: 6989b116511fbbd47b6ce567)
    const examId = '6989b116511fbbd47b6ce567';
    
    // Find all questions for this exam
    const questions = await Question.find({ examId: examId });
    
    console.log(`Found ${questions.length} questions for exam ${examId}:`);
    questions.forEach((question, index) => {
      console.log(`\n--- Question ${index + 1} ---`);
      console.log(`ID: ${question._id}`);
      console.log(`Question: ${question.question}`);
      console.log(`Options: ${question.options.join(', ')}`);
      console.log(`Correct Answer Index: ${question.correctAnswer}`);
      console.log(`Points: ${question.points}`);
    });
    
    // Close connection
    mongoose.connection.close();
  } catch (error) {
    console.error('Error:', error);
    mongoose.connection.close();
  }
});