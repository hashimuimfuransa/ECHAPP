require('dotenv').config();
const mongoose = require('mongoose');
const Result = require('./src/models/Result');
const Exam = require('./src/models/Exam'); // Import Exam model for population

async function checkPopulation() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to database');
    
    const results = await Result.find({ userId: '6982fb643367f688df3b664c' })
      .populate('examId');
    
    console.log('Results with population:');
    results.forEach((r, i) => {
      console.log(`${i + 1}. Result ID: ${r._id}`);
      console.log(`   Exam ID: ${r.examId}`);
      console.log(`   Exam ID type: ${typeof r.examId}`);
      if (r.examId) {
        console.log(`   Exam title: ${r.examId.title}`);
        console.log(`   Exam type: ${r.examId.type}`);
      } else {
        console.log('   No exam data found');
      }
      console.log('');
    });
    
    await mongoose.connection.close();
  } catch (error) {
    console.error('Error:', error);
    await mongoose.connection.close();
  }
}

checkPopulation();