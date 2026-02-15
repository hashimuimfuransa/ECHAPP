// Test script to verify text answer handling in exam history
const mongoose = require('mongoose');
const Result = require('./src/models/Result');
const Question = require('./src/models/Question');
require('dotenv').config();

async function testTextAnswers() {
  try {
    // Connect to database
    await mongoose.connect(process.env.MONGO_URI);
    console.log('Connected to database');
    
    // Find a recent exam result with text answers
    const results = await Result.find({}).sort({ submittedAt: -1 }).limit(5);
    console.log(`Found ${results.length} recent results`);
    
    for (const result of results) {
      console.log('\n=== RESULT ===');
      console.log('Result ID:', result._id);
      console.log('Exam ID:', result.examId);
      console.log('Submitted at:', result.submittedAt);
      
      // Check each answer
      console.log('Answers:');
      for (const answer of result.answers) {
        console.log(`  Question ID: ${answer.questionId}`);
        console.log(`  Selected Option: ${answer.selectedOption}`);
        console.log(`  Answer Text: ${answer.answerText}`);
        console.log(`  Earned Points: ${answer.earnedPoints}`);
        console.log('  ---');
      }
      
      // Get questions for this exam
      if (result.examId) {
        const questions = await Question.find({ examId: result.examId });
        console.log(`Questions for exam ${result.examId}:`);
        for (const question of questions) {
          console.log(`  ${question._id}: ${question.question} (${question.type})`);
        }
      }
    }
    
    await mongoose.connection.close();
  } catch (error) {
    console.error('Error:', error);
  }
}

testTextAnswers();