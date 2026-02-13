require('dotenv').config();
const mongoose = require('mongoose');

async function checkS3Links() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to database');
    
    const Lesson = require('./src/models/Lesson');
    
    // Find lessons with S3 document links
    const s3Lessons = await Lesson.find({ 
      notes: { $regex: 'documents/|\\.pdf|\\.doc' } 
    });
    
    console.log(`Found ${s3Lessons.length} lessons with S3 links:`);
    s3Lessons.forEach(lesson => {
      console.log(`ID: ${lesson._id}`);
      console.log(`Title: ${lesson.title}`);
      console.log(`Notes: ${lesson.notes.substring(0, 100)}...`);
      console.log('---');
    });
    
    // Find lessons with processed notes
    const processedLessons = await Lesson.find({ 
      notes: { $regex: '#|##|\\* |- ' } 
    });
    
    console.log(`\nFound ${processedLessons.length} lessons with processed notes:`);
    processedLessons.forEach(lesson => {
      console.log(`ID: ${lesson._id}`);
      console.log(`Title: ${lesson.title}`);
      console.log(`Notes preview: ${lesson.notes.substring(0, 100)}...`);
      console.log('---');
    });
    
  } catch (error) {
    console.error('Error:', error);
  } finally {
    await mongoose.connection.close();
    console.log('Database connection closed');
  }
}

checkS3Links();