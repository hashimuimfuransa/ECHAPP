/**
 * List videos currently quarantined in trash/videos/ (soft-deleted, not yet
 * permanently purged).
 *
 * Usage:
 *   node scripts/listVideoTrash.js
 */
require('dotenv').config();
const VideoCleanupService = require('../src/services/videoCleanup.service');

const formatSize = (bytes) => `${(bytes / 1024 / 1024).toFixed(2)} MB`;

(async () => {
  const trash = await VideoCleanupService.listTrash();

  console.log(`\nQuarantined videos (${trash.length}):`);
  if (!trash.length) {
    console.log('  (none)');
  } else {
    for (const t of trash) {
      console.log(`  ${t.key}  ${formatSize(t.sizeBytes)}  quarantined ${new Date(t.lastModified).toISOString()}  (was: ${t.originalKey})`);
    }
  }

  process.exit(0);
})().catch((error) => {
  console.error('❌ Failed to list video trash:', error);
  process.exit(1);
});
