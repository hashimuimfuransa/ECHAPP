const express = require('express');
const router = express.Router();
const { getOrphanedVideos, getTrash } = require('../controllers/videoCleanup.controller');
const { protect } = require('../middleware/auth.middleware');
const { authorize } = require('../middleware/role.middleware');

// Admin-only, read-only: view what would be/is cleaned up. Quarantining orphaned
// videos and permanently purging trash are not exposed over HTTP — see
// scripts/quarantineOrphanedVideos.js, scripts/purgeVideoTrash.js, and
// S3_VIDEO_CLEANUP.md for why.
router.get('/orphaned', protect, authorize('admin'), getOrphanedVideos);
router.get('/trash', protect, authorize('admin'), getTrash);

module.exports = router;
