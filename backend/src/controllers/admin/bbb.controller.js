const BBBConfig = require('../../models/BBBConfig');
const BBBService = require('../../services/bbb.service');
const { sendSuccess, sendError } = require('../../utils/response.utils');

/**
 * Get current BBB configuration (admin only)
 * Returns config without the secret for security
 */
const getBBBConfig = async (req, res) => {
  try {
    const config = await BBBConfig.getActiveConfig();
    
    if (!config) {
      return sendError(res, 'No BBB configuration found', 404);
    }

    // Return config without the secret
    sendSuccess(res, {
      id: config._id,
      serverUrl: config.serverUrl,
      isActive: config.isActive,
      lastTested: config.lastTested,
      testStatus: config.testStatus,
      testMessage: config.testMessage,
      createdAt: config.createdAt,
      updatedAt: config.updatedAt
    }, 'BBB configuration retrieved successfully');
  } catch (error) {
    console.error('Get BBB Config Error:', error);
    sendError(res, 'Failed to retrieve BBB configuration', 500, error.message);
  }
};

/**
 * Create or update BBB configuration (admin only)
 */
const updateBBBConfig = async (req, res) => {
  try {
    const { serverUrl, sharedSecret } = req.body;

    if (!serverUrl || !sharedSecret) {
      return sendError(res, 'serverUrl and sharedSecret are required', 400);
    }

    // Validate URL format
    try {
      new URL(serverUrl);
    } catch {
      return sendError(res, 'Invalid serverUrl format', 400);
    }

    // Clean URL (remove trailing slash)
    const cleanUrl = serverUrl.replace(/\/$/, '');

    // Deactivate existing configs
    await BBBConfig.updateMany({}, { isActive: false });

    // Create new active config
    const config = await BBBConfig.create({
      serverUrl: cleanUrl,
      sharedSecret: sharedSecret,
      isActive: true,
      testStatus: 'pending'
    });

    sendSuccess(res, {
      id: config._id,
      serverUrl: config.serverUrl,
      isActive: config.isActive,
      createdAt: config.createdAt
    }, 'BBB configuration updated successfully', 201);
  } catch (error) {
    console.error('Update BBB Config Error:', error);
    sendError(res, 'Failed to update BBB configuration', 500, error.message);
  }
};

/**
 * Test BBB connection (admin only)
 */
const testBBBConnection = async (req, res) => {
  try {
    const config = await BBBConfig.getActiveConfig();
    
    if (!config) {
      return sendError(res, 'No BBB configuration found', 404);
    }

    // Test connection
    const isAvailable = await BBBService.isAvailable();

    // Update test status in database
    config.lastTested = new Date();
    config.testStatus = isAvailable ? 'success' : 'failed';
    config.testMessage = isAvailable ? 'Connection successful' : 'Failed to connect to BBB server';
    await config.save();

    if (isAvailable) {
      sendSuccess(res, {
        connected: true,
        serverUrl: config.serverUrl,
        lastTested: config.lastTested
      }, 'BBB connection successful');
    } else {
      sendError(res, 'Failed to connect to BBB server', 503, {
        connected: false,
        serverUrl: config.serverUrl,
        message: 'Check your server URL and shared secret'
      });
    }
  } catch (error) {
    console.error('Test BBB Connection Error:', error);
    
    // Update test status
    const config = await BBBConfig.getActiveConfig();
    if (config) {
      config.lastTested = new Date();
      config.testStatus = 'failed';
      config.testMessage = error.message;
      await config.save();
    }

    sendError(res, 'Failed to test BBB connection', 500, error.message);
  }
};

/**
 * Get all BBB configurations (admin only)
 */
const getAllBBBConfigs = async (req, res) => {
  try {
    const configs = await BBBConfig.find().sort({ createdAt: -1 });
    
    // Map to remove secrets
    const sanitizedConfigs = configs.map(config => ({
      id: config._id,
      serverUrl: config.serverUrl,
      isActive: config.isActive,
      lastTested: config.lastTested,
      testStatus: config.testStatus,
      testMessage: config.testMessage,
      createdAt: config.createdAt,
      updatedAt: config.updatedAt
    }));

    sendSuccess(res, sanitizedConfigs, 'BBB configurations retrieved successfully');
  } catch (error) {
    console.error('Get All BBB Configs Error:', error);
    sendError(res, 'Failed to retrieve BBB configurations', 500, error.message);
  }
};

/**
 * Delete BBB configuration (admin only)
 */
const deleteBBBConfig = async (req, res) => {
  try {
    const { id } = req.params;
    
    const config = await BBBConfig.findByIdAndDelete(id);
    
    if (!config) {
      return sendError(res, 'Configuration not found', 404);
    }

    sendSuccess(res, null, 'BBB configuration deleted successfully');
  } catch (error) {
    console.error('Delete BBB Config Error:', error);
    sendError(res, 'Failed to delete BBB configuration', 500, error.message);
  }
};

/**
 * Debug BBB URL construction
 */
const debugBBBUrl = async (req, res) => {
  try {
    const apiUrl = await BBBService.getApiUrl();
    const config = await BBBConfig.getActiveConfig();
    
    sendSuccess(res, {
      apiUrl: apiUrl,
      serverUrl: config?.serverUrl || 'Not configured',
      hasSharedSecret: !!config?.sharedSecret,
      configSource: config ? 'database' : (process.env.BBB_SERVER_URL ? 'environment' : 'none')
    }, 'BBB URL debug info');
  } catch (error) {
    sendError(res, 'Failed to get debug info', 500, error.message);
  }
};

module.exports = {
  getBBBConfig,
  updateBBBConfig,
  testBBBConnection,
  getAllBBBConfigs,
  deleteBBBConfig,
  debugBBBUrl
};
