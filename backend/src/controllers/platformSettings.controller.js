const PlatformSettings = require('../models/PlatformSettings');
const { sendSuccess, sendError } = require('../utils/response.utils');

/**
 * Get platform settings
 */
exports.getSettings = async (req, res) => {
  try {
    let settings = await PlatformSettings.findOne({ key: 'general' });
    
    if (!settings) {
      // Create default settings if not exists
      settings = await PlatformSettings.create({ key: 'general' });
    }
    
    sendSuccess(res, settings, 'Platform settings retrieved successfully');
  } catch (error) {
    sendError(res, 'Failed to retrieve platform settings', 500, error.message);
  }
};

/**
 * Update platform settings
 */
exports.updateSettings = async (req, res) => {
  try {
    let settings = await PlatformSettings.findOne({ key: 'general' });
    
    if (!settings) {
      settings = new PlatformSettings({ key: 'general' });
    }
    
    // Update fields
    if (req.body.paymentInfo) {
      // Deep merge for paymentInfo
      settings.paymentInfo = { 
        ...settings.paymentInfo.toObject(), 
        ...req.body.paymentInfo 
      };
      
      // Also handle nested objects in paymentInfo if necessary
      if (req.body.paymentInfo.mtn_momo) {
        settings.paymentInfo.mtn_momo = { ...settings.paymentInfo.mtn_momo, ...req.body.paymentInfo.mtn_momo };
      }
      if (req.body.paymentInfo.airtel_money) {
        settings.paymentInfo.airtel_money = { ...settings.paymentInfo.airtel_money, ...req.body.paymentInfo.airtel_money };
      }
      if (req.body.paymentInfo.bank_transfer) {
        settings.paymentInfo.bank_transfer = { ...settings.paymentInfo.bank_transfer, ...req.body.paymentInfo.bank_transfer };
      }
      if (req.body.paymentInfo.contactSupport) {
        settings.paymentInfo.contactSupport = { ...settings.paymentInfo.contactSupport, ...req.body.paymentInfo.contactSupport };
      }
    }
    
    if (req.body.platformInfo) {
      settings.platformInfo = { 
        ...settings.platformInfo.toObject(), 
        ...req.body.platformInfo 
      };
    }
    
    await settings.save();
    
    sendSuccess(res, settings, 'Platform settings updated successfully');
  } catch (error) {
    sendError(res, 'Failed to update platform settings', 500, error.message);
  }
};
