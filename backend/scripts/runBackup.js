/**
 * Manually trigger a database backup on demand (outside of the daily cron schedule).
 *
 * Usage:
 *   node scripts/runBackup.js [--no-s3]
 */
require('dotenv').config();
const mongoose = require('mongoose');
const connectDB = require('../src/config/database');
const BackupService = require('../src/services/backup.service');

(async () => {
  const uploadToS3 = !process.argv.includes('--no-s3');

  await connectDB();
  const summary = await BackupService.createBackup({ uploadToS3 });
  await BackupService.cleanupOldBackups();

  console.log('\nBackup summary:');
  console.log(JSON.stringify(summary, null, 2));

  await mongoose.disconnect();
  process.exit(0);
})().catch((error) => {
  console.error('❌ Backup failed:', error);
  process.exit(1);
});
