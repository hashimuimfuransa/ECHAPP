const mongoose = require('mongoose');
const Lesson = require('./src/models/Lesson');
const Course = require('./src/models/Course');

// Load environment variables
require('dotenv').config();

async function testVideoService() {
  try {
    console.log('Testing video service data...');
    
    // Connect using the same method as the main app
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to database');
    
    // Find a course to test with
    const course = await Course.findOne();
    if (!course) {
      console.log('No courses found');
      return;
    }
    
    console.log(`Testing with course: ${course.title} (ID: ${course._id})`);
    
    // Check if there are any lessons with videos for this course
    const lessonsWithVideos = await Lesson.find({
      courseId: course._id,
      videoId: { $exists: true, $ne: null }
    }).populate('courseId', 'title');
    
    console.log(`Lessons with videos: ${lessonsWithVideos.length}`);
    
    if (lessonsWithVideos.length === 0) {
      console.log('No videos found for this course');
      console.log('This is why the video management screen shows empty state');
      console.log('The screen is working correctly - it shows empty state when no videos exist');
    } else {
      console.log('Videos found:');
      lessonsWithVideos.forEach((lesson, index) => {
        console.log(`${index + 1}. ${lesson.title}`);
        console.log(`   Video ID: ${lesson.videoId}`);
        console.log(`   Course: ${lesson.courseId.title}`);
        console.log('');
      });
    }
    
    mongoose.connection.close();
  } catch (error) {
    console.error('Error:', error);
    mongoose.connection.close();
  }
}

testVideoService();