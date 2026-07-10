const BackupService = require('../services/backup.service');
const { sendSuccess, sendError } = require('../utils/response.utils');

// List available backups (local disk + S3)
const listBackups = async (req, res) => {
  try {
    const [local, s3] = await Promise.all([
      BackupService.listLocalBackups(),
      BackupService.listS3Backups()
    ]);
    sendSuccess(res, { local, s3 }, 'Backups retrieved successfully');
  } catch (error) {
    sendError(res, 'Failed to list backups', 500, error.message);
  }
};

// Trigger an on-demand backup. Restore is intentionally not exposed over HTTP —
// it's a destructive operation and stays CLI-only (scripts/restoreBackup.js).
const runBackup = async (req, res) => {
  try {
    const summary = await BackupService.createBackup({ uploadToS3: true });
    await BackupService.cleanupOldBackups();
    sendSuccess(res, summary, 'Backup created successfully');
  } catch (error) {
    sendError(res, 'Failed to create backup', 500, error.message);
  }
};

module.exports = {
  listBackups,
  runBackup
};
