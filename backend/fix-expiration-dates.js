const mongoose = require('mongoose');
const Enrollment = require('./src/models/Enrollment');
const Course = require('./src/models/Course');

// MongoDB connection
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/excellencecoachinghub';

async function fixExpirationDates() {
  try {
    await mongoose.connect(MONGODB_URI);
    console.log('Connected to MongoDB');

    // Find the specific course from your screenshot
    const courseId = '69d3d8977d2f3fe836371e90';
    const course = await Course.findById(courseId);
    
    if (!course) {
      console.log('Course not found');
      return;
    }

    console.log('Course found:', course.title);
    console.log('Current accessDuration:', course.accessDuration);

    // If course doesn't have access duration, set it to 1 day
    if (!course.accessDuration) {
      await Course.findByIdAndUpdate(courseId, {
        accessDuration: 1,
        accessDurationUnit: 'days',
        accessDurationDays: 1
      });
      console.log('Updated course with 1-day access duration');
    }

    // Update all existing enrollments for this course
    const enrollments = await Enrollment.find({ courseId });
    console.log(`Found ${enrollments.length} enrollments to update`);

    for (const enrollment of enrollments) {
      if (!enrollment.accessExpirationDate) {
        // Set expiration to 1 day after enrollment date
        const expirationDate = new Date(enrollment.enrollmentDate);
        expirationDate.setDate(expirationDate.getDate() + 1);
        
        await Enrollment.findByIdAndUpdate(enrollment._id, {
          accessExpirationDate: expirationDate
        });
        
        console.log(`Updated enrollment for user ${enrollment.userId}: expires ${expirationDate.toISOString()}`);
      }
    }

    console.log('✅ Fix completed successfully');
  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await mongoose.disconnect();
  }
}

fixExpirationDates();
