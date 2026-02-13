require('dotenv').config();
const mongoose = require('mongoose');
const Result = require('./src/models/Result');

async function checkResults() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to database');
    
    const results = await Result.find().limit(5);
    console.log('Sample results:');
    results.forEach((r, i) => {
      console.log(`${i + 1}. User: ${r.userId}, Exam: ${r.examId}, Score: ${r.score}/${r.totalPoints}`);
    });
    
    // Check if there are any results at all
    const count = await Result.countDocuments();
    console.log(`\nTotal results in database: ${count}`);
    
    if (count > 0) {
      // Get a real user ID from existing results
      const sampleResult = await Result.findOne();
      console.log(`\nSample user ID for testing: ${sampleResult.userId}`);
    }
    
    await mongoose.connection.close();
  } catch (error) {
    console.error('Error:', error);
    await mongoose.connection.close();
  }
}

checkResults();