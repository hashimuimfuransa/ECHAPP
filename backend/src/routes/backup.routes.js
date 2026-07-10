const express = require('express');
const router = express.Router();
const { listBackups, runBackup } = require('../controllers/backup.controller');
const { protect } = require('../middleware/auth.middleware');
const { authorize } = require('../middleware/role.middleware');

// Admin-only: view backup history and trigger an on-demand backup.
// Restoring is not exposed over HTTP — see scripts/restoreBackup.js.
router.get('/', protect, authorize('admin'), listBackups);
router.post('/run', protect, authorize('admin'), runBackup);

module.exports = router;
