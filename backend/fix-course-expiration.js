// Run this with: node fix-course-expiration.js
const mongoose = require('mongoose');
const Enrollment = require('./src/models/Enrollment');
const Course = require('./src/models/Course');

// Use your actual MongoDB connection string
const MONGODB_URI = 'mongodb://localhost:27017/excellencecoachinghub';

async function fixCourseExpiration() {
  try {
    await mongoose.connect(MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    const courseId = '69d3d8977d2f3fe836371e90'; // Your course ID
    
    // 1. Update course to have 1-day access
    const course = await Course.findByIdAndUpdate(courseId, {
      accessDuration: 1,
      accessDurationUnit: 'days',
      accessDurationDays: 1
    });
    
    console.log(`✅ Updated course: ${course.title} with 1-day access duration`);

    // 2. Update existing enrollments with expiration dates
    const enrollments = await Enrollment.find({ courseId });
    
    for (const enrollment of enrollments) {
      if (!enrollment.accessExpirationDate) {
        const expirationDate = new Date(enrollment.enrollmentDate);
        expirationDate.setDate(expirationDate.getDate() + 1);
        
        await Enrollment.findByIdAndUpdate(enrollment._id, {
          accessExpirationDate: expirationDate
        });
        
        console.log(`✅ Set expiration for ${enrollment.userId}: ${expirationDate.toISOString()}`);
      }
    }

    console.log('🎉 Fix completed! Refresh your course analytics page.');
    
  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await mongoose.disconnect();
  }
}

fixCourseExpiration();
