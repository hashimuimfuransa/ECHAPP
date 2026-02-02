const mongoose = require('mongoose');
const Category = require('../src/models/Category');
require('dotenv').config();

const categories = [
  {
    name: 'Academic Coaching',
    description: 'Primary, Secondary, University, Nursery, Exams, Research',
    icon: '📚',
    subcategories: ['Primary', 'Secondary', 'University', 'Nursery', 'Exams', 'Research'],
    isPopular: true,
    isFeatured: true,
    level: 1
  },
  {
    name: 'Professional Coaching',
    description: 'Leadership, Executive, Project Management, CPA/CAT/ACCA',
    icon: '💼',
    subcategories: ['Leadership', 'Executive', 'Project Management', 'CPA/CAT/ACCA'],
    isFeatured: true,
    level: 5
  },
  {
    name: 'Business & Entrepreneurship Coaching',
    description: 'Startup, Strategy, Finance, Marketing, Innovation',
    icon: '🚀',
    subcategories: ['Startup', 'Strategy', 'Finance', 'Marketing', 'Innovation'],
    isPopular: true,
    isFeatured: true,
    level: 3
  },
  {
    name: 'Language Coaching',
    description: 'English, French, Kinyarwanda, Business Communication',
    icon: '🗣️',
    subcategories: ['English', 'French', 'Kinyarwanda', 'Business Communication'],
    level: 2
  },
  {
    name: 'Technical & Digital Coaching',
    description: 'AI, Data, Cybersecurity, Cloud, Dev, Digital Marketing',
    icon: '💻',
    subcategories: ['AI', 'Data', 'Cybersecurity', 'Cloud', 'Dev', 'Digital Marketing'],
    isFeatured: true,
    level: 3
  },
  {
    name: 'Job Seeker Coaching',
    description: 'Career choice, skills, exams, interview, resume',
    icon: '🎯',
    subcategories: ['Career choice', 'Skills', 'Exams', 'Interview', 'Resume'],
    isFeatured: true,
    level: 4
  },
  {
    name: 'Personal & Corporate Development',
    description: 'Communication, EI, Time, Team, HR, Ethics',
    icon: '🌱',
    subcategories: ['Communication', 'Emotional Intelligence', 'Time Management', 'Team Building', 'HR', 'Ethics'],
    level: 5
  }
];

async function seedCategories() {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    // Clear existing categories
    await Category.deleteMany({});
    console.log('Cleared existing categories');

    // Insert new categories
    const insertedCategories = await Category.insertMany(categories);
    console.log(`Inserted ${insertedCategories.length} categories:`);
    insertedCategories.forEach(cat => {
      console.log(`- ${cat.name}`);
    });

    console.log('Categories seeded successfully!');
    process.exit(0);
  } catch (error) {
    console.error('Error seeding categories:', error);
    process.exit(1);
  }
}

seedCategories();