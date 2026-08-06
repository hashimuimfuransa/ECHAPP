const VideoCleanupService = require('../services/videoCleanup.service');
const { sendSuccess, sendError } = require('../utils/response.utils');

// Read-only report of S3 videos not referenced by any Lesson. Actually quarantining
// or permanently deleting them is CLI-only — see scripts/quarantineOrphanedVideos.js
// and scripts/purgeVideoTrash.js — deliberately not exposed as a one-click HTTP action
// given how expensive these files are to replace.
const getOrphanedVideos = async (req, res) => {
  try {
    const graceHours = req.query.graceHours ? parseInt(req.query.graceHours, 10) : undefined;
    const report = await VideoCleanupService.scanOrphaned({ graceHours });
    sendSuccess(res, report, 'Orphaned video scan complete');
  } catch (error) {
    sendError(res, 'Failed to scan for orphaned videos', 500, error.message);
  }
};

// Videos currently quarantined (soft-deleted) awaiting permanent purge.
const getTrash = async (req, res) => {
  try {
    const trash = await VideoCleanupService.listTrash();
    sendSuccess(res, { trash }, 'Video trash retrieved successfully');
  } catch (error) {
    sendError(res, 'Failed to list video trash', 500, error.message);
  }
};

module.exports = {
  getOrphanedVideos,
  getTrash
};
