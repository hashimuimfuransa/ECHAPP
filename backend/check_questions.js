const mongoose = require('mongoose');
const Question = require('./src/models/Question');
require('dotenv').config();

async function checkQuestions() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to database');
    
    const questions = await Question.find({ examId: '6991ee526cfa11c580f43af8' });
    console.log('Questions for exam:');
    questions.forEach(q => {
      console.log(`${q._id}: ${q.question} (${q.type}) - Correct: ${q.correctAnswer}`);
    });
    
    await mongoose.connection.close();
  } catch (error) {
    console.error('Error:', error);
  }
}

checkQuestions();