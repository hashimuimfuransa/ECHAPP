/**
 * Permanently deletes quarantined videos from trash/videos/ that have been there
 * longer than the retention window. This is the ONLY irreversible step in the
 * whole video-cleanup workflow — everything before this (scan, quarantine) is
 * read-only or reversible. See S3_VIDEO_CLEANUP.md.
 *
 * Usage:
 *   node scripts/purgeVideoTrash.js --dry-run
 *   node scripts/purgeVideoTrash.js --yes
 *   node scripts/purgeVideoTrash.js --yes --older-than=45
 *
 * Flags:
 *   --older-than=<days>   Override the default retention window (VIDEO_TRASH_RETENTION_DAYS)
 *   --dry-run             Show what would be purged without deleting anything
 *   --yes                 Required to actually delete anything
 */
require('dotenv').config();
const VideoCleanupService = require('../src/services/videoCleanup.service');

const formatSize = (bytes) => `${(bytes / 1024 / 1024).toFixed(2)} MB`;

function parseArgs(argv) {
  const args = { dryRun: false, yes: false };
  for (const arg of argv) {
    if (arg === '--dry-run') args.dryRun = true;
    else if (arg === '--yes') args.yes = true;
    else if (arg.startsWith('--older-than=')) args.retentionDays = parseInt(arg.slice('--older-than='.length), 10);
  }
  return args;
}

(async () => {
  const args = parseArgs(process.argv.slice(2));

  if (!args.dryRun && !args.yes) {
    console.error('Refusing to permanently delete anything without --yes. Add --dry-run first to preview, or --yes to proceed.');
    process.exit(1);
  }

  const result = await VideoCleanupService.purgeTrash({
    retentionDays: args.retentionDays,
    dryRun: args.dryRun || !args.yes
  });

  console.log(`\nRetention window: ${result.retentionDays} days.`);
  console.log(`${result.dryRun ? 'Would permanently delete' : 'Permanently deleted'} ${result.due.length} video(s):`);
  if (!result.due.length) {
    console.log('  (none)');
  } else {
    for (const v of result.due) {
      console.log(`  ${v.key}  ${formatSize(v.sizeBytes)}  quarantined ${new Date(v.lastModified).toISOString()}`);
    }
  }

  if (result.dryRun) {
    console.log('\nDry run only — nothing was deleted. Re-run with --yes to permanently delete these.');
  } else {
    console.log(`\n✅ Purge complete. ${result.deletedCount} video(s) permanently removed.`);
  }

  process.exit(0);
})().catch((error) => {
  console.error('❌ Purge failed:', error);
  process.exit(1);
});
