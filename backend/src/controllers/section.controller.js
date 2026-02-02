const Section = require('../models/Section');
const Course = require('../models/Course');
const { sendSuccess, sendError, sendNotFound } = require('../utils/response.utils');

// Get all sections for a course
const getSectionsByCourse = async (req, res) => {
  try {
    const { courseId } = req.params;
    
    // Verify course exists
    const course = await Course.findById(courseId);
    if (!course) {
      return sendNotFound(res, 'Course not found');
    }
    
    const sections = await Section.find({ courseId })
      .sort({ order: 1 });
    
    sendSuccess(res, sections, 'Sections retrieved successfully');
  } catch (error) {
    sendError(res, 'Failed to retrieve sections', 500, error.message);
  }
};

// Create section (admin only)
const createSection = async (req, res) => {
  try {
    const { courseId } = req.params;
    const { title, order } = req.body;
    
    // Verify course exists
    const course = await Course.findById(courseId);
    if (!course) {
      return sendNotFound(res, 'Course not found');
    }
    
    const section = await Section.create({
      courseId,
      title,
      order
    });
    
    sendSuccess(res, section, 'Section created successfully', 201);
  } catch (error) {
    sendError(res, 'Failed to create section', 500, error.message);
  }
};

// Update section (admin only)
const updateSection = async (req, res) => {
  try {
    const { sectionId } = req.params;
    const updateData = req.body;
    
    const section = await Section.findByIdAndUpdate(
      sectionId,
      updateData,
      { new: true, runValidators: true }
    );
    
    if (!section) {
      return sendNotFound(res, 'Section not found');
    }
    
    sendSuccess(res, section, 'Section updated successfully');
  } catch (error) {
    sendError(res, 'Failed to update section', 500, error.message);
  }
};

// Delete section (admin only)
const deleteSection = async (req, res) => {
  try {
    const { sectionId } = req.params;
    
    const section = await Section.findByIdAndDelete(sectionId);
    
    if (!section) {
      return sendNotFound(res, 'Section not found');
    }
    
    sendSuccess(res, null, 'Section deleted successfully');
  } catch (error) {
    sendError(res, 'Failed to delete section', 500, error.message);
  }
};

// Reorder sections (admin only)
const reorderSections = async (req, res) => {
  try {
    const { courseId } = req.params;
    const { sections } = req.body; // Array of {sectionId, order}
    
    // Verify course exists
    const course = await Course.findById(courseId);
    if (!course) {
      return sendNotFound(res, 'Course not found');
    }
    
    // Update order for each section
    const updatePromises = sections.map(({ sectionId, order }) =>
      Section.findByIdAndUpdate(sectionId, { order }, { new: true })
    );
    
    await Promise.all(updatePromises);
    
    const updatedSections = await Section.find({ courseId }).sort({ order: 1 });
    
    sendSuccess(res, updatedSections, 'Sections reordered successfully');
  } catch (error) {
    sendError(res, 'Failed to reorder sections', 500, error.message);
  }
};

module.exports = {
  getSectionsByCourse,
  createSection,
  updateSection,
  deleteSection,
  reorderSections
};