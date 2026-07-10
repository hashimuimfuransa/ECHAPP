/**
 * List available database backups (local disk and S3).
 *
 * Usage:
 *   node scripts/listBackups.js
 */
require('dotenv').config();
const BackupService = require('../src/services/backup.service');

const formatSize = (bytes) => `${(bytes / 1024 / 1024).toFixed(2)} MB`;

(async () => {
  const local = await BackupService.listLocalBackups();
  console.log(`\nLocal backups (${local.length}):`);
  if (!local.length) console.log('  (none)');
  for (const b of local) {
    console.log(`  ${b.fileName}  ${formatSize(b.sizeBytes)}  ${b.createdAt.toISOString()}`);
  }

  const s3 = await BackupService.listS3Backups();
  console.log(`\nS3 backups (${s3.length}):`);
  if (!s3.length) console.log('  (none, or S3 not configured)');
  for (const b of s3) {
    console.log(`  ${b.key}  ${formatSize(b.sizeBytes)}  ${new Date(b.createdAt).toISOString()}`);
  }

  process.exit(0);
})().catch((error) => {
  console.error('❌ Failed to list backups:', error);
  process.exit(1);
});
