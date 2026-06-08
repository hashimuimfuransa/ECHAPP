const express = require('express');
const router = express.Router();
const bbbController = require('../../controllers/admin/bbb.controller');
const { authenticate } = require('../../middleware/auth.middleware');
const { authorize } = require('../../middleware/role.middleware');

/**
 * @route   GET /api/admin/bbb/config
 * @desc    Get current BBB configuration
 * @access  Admin only
 */
router.get('/config', authenticate, authorize('admin'), bbbController.getBBBConfig);

/**
 * @route   GET /api/admin/bbb/configs
 * @desc    Get all BBB configurations
 * @access  Admin only
 */
router.get('/configs', authenticate, authorize('admin'), bbbController.getAllBBBConfigs);

/**
 * @route   POST /api/admin/bbb/config
 * @desc    Create or update BBB configuration
 * @access  Admin only
 */
router.post('/config', authenticate, authorize('admin'), bbbController.updateBBBConfig);

/**
 * @route   POST /api/admin/bbb/test
 * @desc    Test BBB connection
 * @access  Admin only
 */
router.post('/test', authenticate, authorize('admin'), bbbController.testBBBConnection);

/**
 * @route   DELETE /api/admin/bbb/config/:id
 * @desc    Delete BBB configuration
 * @access  Admin only
 */
router.delete('/config/:id', authenticate, authorize('admin'), bbbController.deleteBBBConfig);

module.exports = router;
