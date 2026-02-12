require('dotenv').config();
const mongoose = require('mongoose');
const connectDB = require('./src/config/database');

// Import all models
require('./src/models/User');
require('./src/models/Course');
require('./src/models/Section');
require('./src/models/Enrollment');
require('./src/models/Exam');

async function testEnrollments() {
  try {
    await connectDB();
    console.log('Connected to database');
    
    const Enrollment = mongoose.model('Enrollment');
    const Exam = mongoose.model('Exam');
    const Section = mongoose.model('Section');
    
    // Check enrollments
    const enrollments = await Enrollment.find({});
    console.log('Total enrollments:', enrollments.length);
    
    // Check exams
    const exams = await Exam.find({});
    console.log('Total exams:', exams.length);
    exams.forEach((exam, index) => {
      console.log(`Exam ${index + 1}:`, {
        id: exam._id,
        title: exam.title,
        courseId: exam.courseId,
        sectionId: exam.sectionId,
        isPublished: exam.isPublished
      });
    });
    
    // Check sections
    const sections = await Section.find({});
    console.log('Total sections:', sections.length);
    sections.forEach((section, index) => {
      console.log(`Section ${index + 1}:`, {
        id: section._id,
        title: section.title,
        courseId: section.courseId,
        order: section.order
      });
    });
    
    process.exit(0);
  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

testEnrollments();