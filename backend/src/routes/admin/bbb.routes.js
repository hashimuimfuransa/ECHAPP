const express = require('express');
const router = express.Router();
const bbbController = require('../../controllers/admin/bbb.controller');
const { authenticate, requireRole } = require('../../middleware/auth.middleware');

/**
 * @route   GET /api/admin/bbb/config
 * @desc    Get current BBB configuration
 * @access  Admin only
 */
router.get('/config', authenticate, requireRole('admin'), bbbController.getBBBConfig);

/**
 * @route   GET /api/admin/bbb/configs
 * @desc    Get all BBB configurations
 * @access  Admin only
 */
router.get('/configs', authenticate, requireRole('admin'), bbbController.getAllBBBConfigs);

/**
 * @route   POST /api/admin/bbb/config
 * @desc    Create or update BBB configuration
 * @access  Admin only
 */
router.post('/config', authenticate, requireRole('admin'), bbbController.updateBBBConfig);

/**
 * @route   POST /api/admin/bbb/test
 * @desc    Test BBB connection
 * @access  Admin only
 */
router.post('/test', authenticate, requireRole('admin'), bbbController.testBBBConnection);

/**
 * @route   DELETE /api/admin/bbb/config/:id
 * @desc    Delete BBB configuration
 * @access  Admin only
 */
router.delete('/config/:id', authenticate, requireRole('admin'), bbbController.deleteBBBConfig);

module.exports = router;
