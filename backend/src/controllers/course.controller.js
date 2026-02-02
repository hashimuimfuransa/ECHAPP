const Course = require('../models/Course');
const Enrollment = require('../models/Enrollment');
const { sendSuccess, sendError, sendNotFound } = require('../utils/response.utils');

// Get all courses
const getCourses = async (req, res) => {
  try {
    const { page = 1, limit = 10, search, level, minPrice, maxPrice, category } = req.query;
    
    // Build filter object
    const filter = { isPublished: true };
    
    if (search) {
      filter.$or = [
        { title: { $regex: search, $options: 'i' } },
        { description: { $regex: search, $options: 'i' } }
      ];
    }
    
    if (level) {
      filter.level = level;
    }
    
    if (category) {
      // Check if category is a valid ObjectId, if not try to find by name
      const ObjectId = require('mongoose').Types.ObjectId;
      if (ObjectId.isValid(category)) {
        filter.category = category;
      } else {
        // If it's not a valid ObjectId, try to find category by name and get its ID
        const Category = require('../models/Category');
        const categoryDoc = await Category.findOne({ 
          $or: [
            { name: { $regex: category, $options: 'i' } },
            { name: category.replace(/_/g, ' ') } // Handle underscore-to-space conversion
          ]
        });
        
        if (categoryDoc) {
          filter.category = categoryDoc._id;
        }
      }
    }
    
    if (minPrice || maxPrice) {
      filter.price = {};
      if (minPrice) filter.price.$gte = Number(minPrice);
      if (maxPrice) filter.price.$lte = Number(maxPrice);
    }
    
    let query = Course.find(filter).populate('createdBy', 'fullName');
    
    if (category) {
      query = query.populate('category', 'name');
    }
    
    const courses = await query
      .limit(limit * 1)
      .skip((page - 1) * limit)
      .sort({ createdAt: -1 });
    
    const total = await Course.countDocuments(filter);
    
    sendSuccess(res, {
      courses,
      totalPages: Math.ceil(total / limit),
      currentPage: Number(page),
      total
    }, 'Courses retrieved successfully');
  } catch (error) {
    sendError(res, 'Failed to retrieve courses', 500, error.message);
  }
};

// Get course by ID
const getCourseById = async (req, res) => {
  try {
    const course = await Course.findById(req.params.id)
      .populate('createdBy', 'fullName');
    
    if (!course) {
      return sendNotFound(res, 'Course not found');
    }
    
    if (!course.isPublished && req.user?.role !== 'admin') {
      return sendNotFound(res, 'Course not found');
    }
    
    sendSuccess(res, course, 'Course retrieved successfully');
  } catch (error) {
    sendError(res, 'Failed to retrieve course', 500, error.message);
  }
};

// Get course details with sections and lessons
const getCourseDetails = async (req, res) => {
  try {
    const courseId = req.params.id;
    
    // Check if user is enrolled (if authenticated)
    let isEnrolled = false;
    if (req.user) {
      const enrollment = await Enrollment.findOne({
        userId: req.user.id,
        courseId: courseId
      });
      isEnrolled = !!enrollment;
    }
    
    const course = await Course.findById(courseId)
      .populate('createdBy', 'fullName');
    
    if (!course) {
      return sendNotFound(res, 'Course not found');
    }
    
    if (!course.isPublished && req.user?.role !== 'admin') {
      return sendNotFound(res, 'Course not found');
    }
    
    // Get sections and lessons (this would be implemented in next steps)
    const sections = []; // Placeholder for now
    
    sendSuccess(res, {
      course,
      sections,
      isEnrolled
    }, 'Course details retrieved successfully');
  } catch (error) {
    sendError(res, 'Failed to retrieve course details', 500, error.message);
  }
};

// Create course (admin only)
const createCourse = async (req, res) => {
  try {
    const { title, description, price, duration, level, thumbnail, categoryId } = req.body;
    
    const courseData = {
      title,
      description,
      price,
      duration,
      level,
      thumbnail,
      createdBy: req.user.id
    };
    
    // Add category if provided
    if (categoryId) {
      courseData.category = categoryId;
    }
    
    const course = await Course.create(courseData);
    
    sendSuccess(res, course, 'Course created successfully', 201);
  } catch (error) {
    sendError(res, 'Failed to create course', 500, error.message);
  }
};

// Update course (admin only)
const updateCourse = async (req, res) => {
  try {
    const course = await Course.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true, runValidators: true }
    );
    
    if (!course) {
      return sendNotFound(res, 'Course not found');
    }
    
    sendSuccess(res, course, 'Course updated successfully');
  } catch (error) {
    sendError(res, 'Failed to update course', 500, error.message);
  }
};

// Delete course (admin only)
const deleteCourse = async (req, res) => {
  try {
    const course = await Course.findByIdAndDelete(req.params.id);
    
    if (!course) {
      return sendNotFound(res, 'Course not found');
    }
    
    sendSuccess(res, null, 'Course deleted successfully');
  } catch (error) {
    sendError(res, 'Failed to delete course', 500, error.message);
  }
};

module.exports = {
  getCourses,
  getCourseById,
  getCourseDetails,
  createCourse,
  updateCourse,
  deleteCourse
};