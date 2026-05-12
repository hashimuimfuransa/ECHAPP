const mongoose = require('mongoose');
const Enrollment = require('./src/models/Enrollment');
const Course = require('./src/models/Course');
const CourseExpirationService = require('./src/services/course-expiration.service');

// MongoDB connection
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/excellencecoachinghub';

async function testExpiration() {
  try {
    await mongoose.connect(MONGODB_URI);
    console.log('Connected to MongoDB');

    // Check current enrollments with expiration dates
    const now = new Date();
    console.log('Current time:', now.toISOString());

    // Find all enrollments with accessExpirationDate
    const enrollmentsWithExpiration = await Enrollment.find({
      accessExpirationDate: { $ne: null }
    }).populate('courseId', 'title accessDuration accessDurationUnit');

    console.log(`\nFound ${enrollmentsWithExpiration.length} enrollments with expiration dates:`);
    
    for (const enrollment of enrollmentsWithExpiration) {
      const isExpired = enrollment.accessExpirationDate < now;
      console.log(`\nUser: ${enrollment.userId}`);
      console.log(`Course: ${enrollment.courseId?.title || 'Unknown'}`);
      console.log(`Enrolled: ${enrollment.enrollmentDate}`);
      console.log(`Expires: ${enrollment.accessExpirationDate}`);
      console.log(`Status: ${isExpired ? 'EXPIRED' : 'ACTIVE'}`);
      
      if (isExpired) {
        console.log('❌ This enrollment should have been removed!');
      }
    }

    // Find expired enrollments that should be processed
    const expiredEnrollments = await Enrollment.find({
      accessExpirationDate: { $ne: null, $lt: now }
    });
    
    console.log(`\n🔍 Found ${expiredEnrollments.length} expired enrollments that should be processed`);

    // Run the expiration service manually
    console.log('\n🚀 Running CourseExpirationService.checkExpiredEnrollments()...');
    const result = await CourseExpirationService.checkExpiredEnrollments();
    console.log('Result:', result);

    // Check again after processing
    const remainingExpired = await Enrollment.find({
      accessExpirationDate: { $ne: null, $lt: now }
    });
    console.log(`\n✅ After processing: ${remainingExpired.length} expired enrollments remain`);

  } catch (error) {
    console.error('Error:', error);
  } finally {
    await mongoose.disconnect();
  }
}

testExpiration();
