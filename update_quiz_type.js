const mongoose = require('mongoose');
const Quiz = require('./backend/src/models/Quiz');

// MongoDB connection string - update with your actual connection
const MONGODB_URI = 'mongodb://localhost:27017/excellencehub';

async function updateQuizType() {
  try {
    // Connect to MongoDB
    await mongoose.connect(MONGODB_URI);
    console.log('Connected to MongoDB');

    // Update the specific quiz by ID
    const quizId = '6a01f8a346f4f2cb8d53c14b';
    const result = await Quiz.findByIdAndUpdate(
      quizId,
      { type: 'exam' },
      { new: true }
    );

    if (result) {
      console.log('Quiz updated successfully:');
      console.log('- ID:', result._id);
      console.log('- Title:', result.title);
      console.log('- Type:', result.type);
    } else {
      console.log('Quiz not found with ID:', quizId);
    }

  } catch (error) {
    console.error('Error updating quiz:', error);
  } finally {
    // Close the connection
    await mongoose.connection.close();
    console.log('MongoDB connection closed');
  }
}

// Run the update
updateQuizType();
