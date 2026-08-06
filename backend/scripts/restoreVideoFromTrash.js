/**
 * Undo a quarantine: moves a video from trash/videos/ back to its original
 * videos/ location. Use this if scripts/quarantineOrphanedVideos.js flagged
 * something it shouldn't have, before scripts/purgeVideoTrash.js permanently
 * removes it.
 *
 * Note: this restores the S3 object only. If the Lesson document that referenced
 * it was also deleted, you'll additionally need to re-link a lesson to this key
 * (or restore the DB from a backup — see DATABASE_BACKUP_SYSTEM.md).
 *
 * Usage:
 *   node scripts/restoreVideoFromTrash.js --key=trash/videos/some-file-123-abc.mp4
 */
require('dotenv').config();
const VideoCleanupService = require('../src/services/videoCleanup.service');

function parseArgs(argv) {
  const args = {};
  for (const arg of argv) {
    if (arg.startsWith('--key=')) args.key = arg.slice('--key='.length);
  }
  return args;
}

(async () => {
  const args = parseArgs(process.argv.slice(2));
  if (!args.key) {
    console.error('Specify --key=trash/videos/<file> (see scripts/listVideoTrash.js for available keys).');
    process.exit(1);
  }
  if (!args.key.startsWith('trash/videos/')) {
    console.error('--key must be a trash/videos/... key, not the original videos/... key.');
    process.exit(1);
  }

  const result = await VideoCleanupService.restoreFromTrash(args.key);
  console.log(`✅ Restored ${result.trashKey} -> ${result.restoredKey}`);

  process.exit(0);
})().catch((error) => {
  console.error('❌ Restore from trash failed:', error);
  process.exit(1);
});
