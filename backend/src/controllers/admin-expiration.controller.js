const CourseExpirationService = require('../services/course-expiration.service');
const { sendSuccess, sendError } = require('../utils/response.utils');

// Manual trigger for course expiration checks (admin only)
const manualExpirationCheck = async (req, res) => {
  try {
    console.log('🔧 Manual expiration check triggered by admin:', req.user.email);
    
    const result = await CourseExpirationService.checkExpiredEnrollments();
    
    sendSuccess(res, result, 'Expiration check completed successfully');
  } catch (error) {
    console.error('Manual expiration check failed:', error);
    sendError(res, 'Failed to run expiration check', 500);
  }
};

module.exports = {
  manualExpirationCheck
};
