const mongoose = require('mongoose');
const Course = require('./src/models/Course');
const Category = require('./src/models/Category');

// Check database connection
mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/echapp')
  .then(async () => {
    console.log('Connected to MongoDB');
    
    // Check course categories
    const courses = await Course.find({}).populate('category', 'name').select('title category categoryId').limit(10);
    console.log('\n=== Course Category Analysis ===');
    console.log('Total courses checked:', courses.length);
    
    let uncategorizedCount = 0;
    let withCategoryCount = 0;
    let withCategoryIdOnly = 0;
    
    courses.forEach(course => {
      console.log(`Course: ${course.title}`);
      console.log(`  - Category object: ${course.category ? course.category.name : 'null'}`);
      console.log(`  - CategoryId: ${course.categoryId || 'null'}`);
      
      if (!course.category && !course.categoryId) {
        uncategorizedCount++;
      } else if (course.category) {
        withCategoryCount++;
      } else if (course.categoryId) {
        withCategoryIdOnly++;
      }
    });
    
    console.log(`\n=== Summary ===`);
    console.log(`Uncategorized (no category): ${uncategorizedCount}`);
    console.log(`With populated category: ${withCategoryCount}`);
    console.log(`With categoryId only: ${withCategoryIdOnly}`);
    
    // Check available categories
    const categories = await Category.find({}).select('name _id');
    console.log(`\n=== Available Categories ===`);
    categories.forEach(cat => {
      console.log(`- ${cat.name} (ID: ${cat._id})`);
    });
    
    process.exit(0);
  })
  .catch(err => {
    console.error('Database connection error:', err);
    process.exit(1);
  });
