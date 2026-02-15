const Lesson = require('../models/Lesson');
const Section = require('../models/Section');
const Course = require('../models/Course');
const { sendSuccess, sendError, sendNotFound } = require('../utils/response.utils');

// Get all lessons for a section
const getLessonsBySection = async (req, res) => {
  try {
    const { sectionId } = req.params;
    
    // Verify section exists
    const section = await Section.findById(sectionId);
    if (!section) {
      return sendNotFound(res, 'Section not found');
    }
    
    const lessons = await Lesson.find({ sectionId })
      .sort({ order: 1 });
    
    sendSuccess(res, lessons, 'Lessons retrieved successfully');
  } catch (error) {
    sendError(res, 'Failed to retrieve lessons', 500, error.message);
  }
};

// Get lesson by ID
const getLessonById = async (req, res) => {
  try {
    const { lessonId } = req.params;
    
    const lesson = await Lesson.findById(lessonId);
    
    if (!lesson) {
      return sendNotFound(res, 'Lesson not found');
    }
    
    sendSuccess(res, lesson, 'Lesson retrieved successfully');
  } catch (error) {
    sendError(res, 'Failed to retrieve lesson', 500, error.message);
  }
};

// Create lesson (admin only)
const createLesson = async (req, res) => {
  try {
    const { sectionId } = req.params;
    const { title, description, videoId, notes, order, duration } = req.body;
    
    // Verify section exists
    const section = await Section.findById(sectionId);
    if (!section) {
      return sendNotFound(res, 'Section not found');
    }
    
    // If notes field looks like a document path, process it with AI to organize notes
    let processedNotes = notes;
    if (notes && (notes.includes('documents/') || notes.includes('.pdf') || notes.includes('.doc') || notes.includes('.docx'))) {
      try {
        const S3Service = require('../services/s3_service');
        const DocumentProcessingService = require('../services/document_processing_service');
        const GrokService = require('../services/grok_service');
        
        if (GrokService.isConfigured()) {
          // Fetch the document from S3
          const documentBuffer = await S3Service.getFileBuffer(notes);
          
          if (documentBuffer) {
            // Determine MIME type based on file extension
            let mimeType = 'application/pdf'; // default
            if (notes.toLowerCase().includes('.docx')) {
              mimeType = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
            } else if (notes.toLowerCase().includes('.doc')) {
              mimeType = 'application/msword';
            } else if (notes.toLowerCase().includes('.txt')) {
              mimeType = 'text/plain';
            }
            
            // Organize the notes using Groq AI
            processedNotes = await GrokService.organizeNotes({
              buffer: documentBuffer,
              mimetype: mimeType,
              originalname: notes.split('/').pop()
            }, mimeType);
            
            console.log('Successfully organized notes using Groq AI for lesson');
          }
        }
      } catch (aiError) {
        console.error('Error processing document for notes organization:', aiError);
        // Fall back to using the original notes
        processedNotes = notes;
      }
    }
    
    const lesson = await Lesson.create({
      sectionId,
      courseId: section.courseId,
      title,
      description,
      videoId,
      notes: processedNotes, // Use processed notes instead of original
      order,
      duration
    });
    
    sendSuccess(res, lesson, 'Lesson created successfully', 201);
  } catch (error) {
    sendError(res, 'Failed to create lesson', 500, error.message);
  }
};

// Update lesson (admin only)
const updateLesson = async (req, res) => {
  try {
    const { lessonId } = req.params;
    const updateData = req.body;
    
    const lesson = await Lesson.findByIdAndUpdate(
      lessonId,
      updateData,
      { new: true, runValidators: true }
    );
    
    if (!lesson) {
      return sendNotFound(res, 'Lesson not found');
    }
    
    sendSuccess(res, lesson, 'Lesson updated successfully');
  } catch (error) {
    sendError(res, 'Failed to update lesson', 500, error.message);
  }
};

// Delete lesson (admin only)
const deleteLesson = async (req, res) => {
  try {
    const { lessonId } = req.params;
    
    const lesson = await Lesson.findByIdAndDelete(lessonId);
    
    if (!lesson) {
      return sendNotFound(res, 'Lesson not found');
    }
    
    sendSuccess(res, null, 'Lesson deleted successfully');
  } catch (error) {
    sendError(res, 'Failed to delete lesson', 500, error.message);
  }
};

// Reorder lessons (admin only)
const reorderLessons = async (req, res) => {
  try {
    const { sectionId } = req.params;
    const { lessonIds } = req.body; // Array of lesson IDs in new order
    
    // Verify section exists
    const section = await Section.findById(sectionId);
    if (!section) {
      return sendNotFound(res, 'Section not found');
    }
    
    // Update order for each lesson
    const updatePromises = lessonIds.map((lessonId, index) =>
      Lesson.findByIdAndUpdate(lessonId, { order: index + 1 }, { new: true })
    );
    
    await Promise.all(updatePromises);
    
    const updatedLessons = await Lesson.find({ sectionId }).sort({ order: 1 });
    
    sendSuccess(res, updatedLessons, 'Lessons reordered successfully');
  } catch (error) {
    sendError(res, 'Failed to reorder lessons', 500, error.message);
  }
};

// Get course content with sections and lessons
const getCourseContent = async (req, res) => {
  try {
    const { courseId } = req.params;
    
    // Verify course exists
    const course = await Course.findById(courseId);
    if (!course) {
      return sendNotFound(res, 'Course not found');
    }
    
    // Get all sections for the course
    const sections = await Section.find({ courseId })
      .sort({ order: 1 });
    
    // Get all lessons for each section
    const sectionsWithLessons = await Promise.all(
      sections.map(async (section) => {
        const lessons = await Lesson.find({ sectionId: section._id })
          .sort({ order: 1 });
        
        return {
          ...section.toObject(),
          lessons
        };
      })
    );
    
    sendSuccess(res, {
      course,
      sections: sectionsWithLessons
    }, 'Course content retrieved successfully');
  } catch (error) {
    sendError(res, 'Failed to retrieve course content', 500, error.message);
  }
};

module.exports = {
  getLessonsBySection,
  getLessonById,
  createLesson,
  updateLesson,
  deleteLesson,
  reorderLessons,
  getCourseContent
};