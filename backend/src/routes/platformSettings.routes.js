const express = require('express');
const router = express.Router();
const { getSettings, updateSettings } = require('../controllers/platformSettings.controller');
const { protect } = require('../middleware/auth.middleware');
const { authorize } = require('../middleware/role.middleware');

// Public route to get settings (needed by students to see payment info)
router.get('/', getSettings);

// Protected admin route to update settings
router.put('/', protect, authorize('admin'), updateSettings);

module.exports = router;
