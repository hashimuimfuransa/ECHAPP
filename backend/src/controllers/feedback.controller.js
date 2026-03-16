const Feedback = require('../models/Feedback');
const User = require('../models/User');

class FeedbackController {
  // Submit feedback (Student)
  async submitFeedback(req, res) {
    try {
      const { content } = req.body;
      const userId = req.user.id;

      if (!content || content.trim().length === 0) {
        return res.status(400).json({
          success: false,
          message: 'Feedback content is required'
        });
      }

      const feedback = new Feedback({
        userId,
        content
      });

      await feedback.save();

      res.status(201).json({
        success: true,
        message: 'Feedback submitted successfully',
        data: feedback
      });
    } catch (error) {
      console.error('Error submitting feedback:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to submit feedback',
        error: error.message
      });
    }
  }

  // Get all feedback (Admin)
  async getAllFeedback(req, res) {
    try {
      const feedbacks = await Feedback.find()
        .populate('userId', 'fullName email profilePicture')
        .sort({ createdAt: -1 });

      res.status(200).json({
        success: true,
        message: 'Feedbacks fetched successfully',
        data: feedbacks
      });
    } catch (error) {
      console.error('Error fetching feedbacks:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch feedbacks',
        error: error.message
      });
    }
  }

  // Mark feedback as read (Admin)
  async markAsRead(req, res) {
    try {
      const { id } = req.params;
      
      const feedback = await Feedback.findByIdAndUpdate(
        id,
        { isRead: true },
        { new: true }
      );

      if (!feedback) {
        return res.status(404).json({
          success: false,
          message: 'Feedback not found'
        });
      }

      res.status(200).json({
        success: true,
        message: 'Feedback marked as read',
        data: feedback
      });
    } catch (error) {
      console.error('Error marking feedback as read:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to mark feedback as read',
        error: error.message
      });
    }
  }

  // Delete feedback (Admin)
  async deleteFeedback(req, res) {
    try {
      const { id } = req.params;
      
      const feedback = await Feedback.findByIdAndDelete(id);

      if (!feedback) {
        return res.status(404).json({
          success: false,
          message: 'Feedback not found'
        });
      }

      res.status(200).json({
        success: true,
        message: 'Feedback deleted successfully'
      });
    } catch (error) {
      console.error('Error deleting feedback:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to delete feedback',
        error: error.message
      });
    }
  }
}

module.exports = new FeedbackController();
