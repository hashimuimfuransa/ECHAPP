const mongoose = require('mongoose');
const Result = require('./src/models/Result');
const Exam = require('./src/models/Exam');
require('dotenv').config();

async function testExamHistory() {
  try {
    // Connect to database
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to database');
    
    // Test user ID (from actual database)
    const testUserId = '6982fb643367f688df3b664c'; // Real user ID from database
    
    console.log('Searching for results with userId:', testUserId);
    const results = await Result.find({ userId: testUserId })
      .populate({
        path: 'examId',
        select: 'title type courseId sectionId',
        populate: [
          { path: 'courseId', select: 'title' },
          { path: 'sectionId', select: 'title' }
        ]
      })
      .sort({ submittedAt: -1 });
    
    console.log('Found', results.length, 'results for user');
    
    // Transform the results to match the expected frontend structure
    const formattedResults = results.map(result => ({
      _id: result._id,
      resultId: result._id,
      examId: result.examId,
      score: result.score,
      totalPoints: result.totalPoints,
      percentage: result.percentage,
      passed: result.passed,
      message: result.passed ? 'Passed' : 'Failed',
      submittedAt: result.submittedAt,
      createdAt: result.createdAt,
      updatedAt: result.updatedAt
    }));
    
    console.log('Formatted results:');
    console.log(JSON.stringify(formattedResults, null, 2));
    
    // Test the ExamResult.fromJson parsing
    console.log('\nTesting frontend ExamResult.fromJson parsing:');
    for (let i = 0; i < formattedResults.length; i++) {
      const result = formattedResults[i];
      console.log(`Result ${i + 1}:`);
      console.log(`  _id: ${result._id}`);
      console.log(`  resultId: ${result.resultId}`);
      console.log(`  examId type: ${typeof result.examId}`);
      console.log(`  examId value: ${JSON.stringify(result.examId)}`);
      console.log(`  score: ${result.score}`);
      console.log(`  totalPoints: ${result.totalPoints}`);
      console.log(`  percentage: ${result.percentage}`);
      console.log(`  passed: ${result.passed}`);
      console.log(`  message: ${result.message}`);
      console.log(`  submittedAt: ${result.submittedAt}`);
      console.log('');
    }
    
    await mongoose.connection.close();
    console.log('Test completed successfully');
  } catch (error) {
    console.error('Test failed:', error);
    await mongoose.connection.close();
  }
}

testExamHistory();