const mongoose = require('mongoose');
const User = require('./src/models/User');
const Enrollment = require('./src/models/Enrollment');

async function checkEnrollment() {
  try {
    await mongoose.connect('mongodb://localhost:27017/excellencehub');
    console.log('Connected to MongoDB');
    
    // Find the user by email
    const user = await User.findOne({ email: 'mucyo@gmail.com' });
    console.log('User:', user ? { id: user._id, email: user.email, role: user.role } : 'Not found');
    
    if (user) {
      // Check enrollments for this user
      const enrollments = await Enrollment.find({ userId: user._id })
        .populate('courseId', 'title')
        .lean();
      
      console.log('\nUser enrollments:', enrollments.length);
      enrollments.forEach(e => {
        console.log(`- Course: ${e.courseId?.title || 'N/A'} (${e.courseId})`);
        console.log(`  Status: ${e.completionStatus}, Progress: ${e.progress}%`);
      });
      
      // Check specific course from error
      const courseId = '69ff5423c6f32322d658d97b';
      const specificEnrollment = await Enrollment.findOne({ userId: user._id, courseId });
      console.log(`\nSpecific enrollment for course ${courseId}:`, specificEnrollment ? 'Found' : 'Not found');
      
      // Check if course exists
      const Course = require('./src/models/Course');
      const course = await Course.findById(courseId);
      console.log(`Course exists:`, course ? `Yes - ${course.title}` : 'No');
    }
    
  } catch (error) {
    console.error('Error:', error);
  } finally {
    await mongoose.disconnect();
    process.exit(0);
  }
}

checkEnrollment();
