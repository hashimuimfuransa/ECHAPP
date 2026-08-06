/**
 * Quarantine orphaned S3 videos: moves them from videos/ to trash/videos/, where
 * they sit untouched until scripts/purgeVideoTrash.js permanently removes them
 * after the retention window. Nothing is ever permanently deleted by this script —
 * that's the point, since these videos are expensive to replace. See
 * S3_VIDEO_CLEANUP.md for the full workflow and scripts/restoreVideoFromTrash.js
 * for how to undo a mistaken quarantine.
 *
 * Deliberately CLI-only, same reasoning as scripts/restoreBackup.js: this is not
 * reachable from the admin panel with a single click.
 *
 * Usage:
 *   node scripts/quarantineOrphanedVideos.js --dry-run
 *   node scripts/quarantineOrphanedVideos.js --yes
 *   node scripts/quarantineOrphanedVideos.js --yes --limit=10
 *   node scripts/quarantineOrphanedVideos.js --yes --key=videos/some-file-123-abc.mp4
 *
 * Flags:
 *   --older-than=<hours>   Override the default grace period (VIDEO_ORPHAN_GRACE_HOURS)
 *   --limit=<n>             Only quarantine the first n orphans found (default: 25).
 *                           A hard cap so a bug in the scan logic can't quarantine
 *                           your whole library in one run — re-run to process more.
 *   --key=<s3-key>          Quarantine only this specific key (must still be orphaned)
 *   --dry-run               Show what would be quarantined without changing anything
 *   --yes                   Required to actually quarantine anything
 */
require('dotenv').config();
const mongoose = require('mongoose');
const connectDB = require('../src/config/database');
const VideoCleanupService = require('../src/services/videoCleanup.service');

const formatSize = (bytes) => `${(bytes / 1024 / 1024).toFixed(2)} MB`;
const DEFAULT_LIMIT = 25;

function parseArgs(argv) {
  const args = { dryRun: false, yes: false, limit: DEFAULT_LIMIT };
  for (const arg of argv) {
    if (arg === '--dry-run') args.dryRun = true;
    else if (arg === '--yes') args.yes = true;
    else if (arg.startsWith('--older-than=')) args.graceHours = parseInt(arg.slice('--older-than='.length), 10);
    else if (arg.startsWith('--limit=')) args.limit = parseInt(arg.slice('--limit='.length), 10);
    else if (arg.startsWith('--key=')) args.key = arg.slice('--key='.length);
  }
  return args;
}

(async () => {
  const args = parseArgs(process.argv.slice(2));

  if (!args.dryRun && !args.yes) {
    console.error('Refusing to quarantine anything without --yes. Add --dry-run first to preview, or --yes to proceed.');
    process.exit(1);
  }

  await connectDB();
  const report = await VideoCleanupService.scanOrphaned({ graceHours: args.graceHours });

  let targets = report.orphaned;
  if (args.key) {
    targets = targets.filter((v) => v.key === args.key);
    if (!targets.length) {
      console.error(`"${args.key}" is not currently orphaned (either it's referenced by a lesson, within the grace period, or doesn't exist). Nothing to do.`);
      process.exit(1);
    }
  } else {
    targets = targets.slice(0, args.limit);
  }

  if (!targets.length) {
    console.log('No orphaned videos to quarantine.');
    await mongoose.disconnect();
    process.exit(0);
  }

  console.log(`\n${args.dryRun ? 'Would quarantine' : 'Quarantining'} ${targets.length} video(s) (of ${report.orphaned.length} orphaned found):`);
  for (const v of targets) {
    console.log(`  ${v.key}  ${formatSize(v.sizeBytes)}`);
  }
  const totalBytes = targets.reduce((sum, v) => sum + (v.sizeBytes || 0), 0);
  console.log(`Total: ${formatSize(totalBytes)}\n`);

  if (args.dryRun) {
    console.log('Dry run only — no data was moved. Re-run with --yes to quarantine these.');
    await mongoose.disconnect();
    process.exit(0);
  }

  const results = await VideoCleanupService.quarantine(targets.map((v) => v.key));
  const succeeded = results.filter((r) => r.success);
  const failed = results.filter((r) => !r.success);

  console.log(`✅ Quarantined ${succeeded.length} video(s) to trash/videos/.`);
  if (failed.length) {
    console.log(`❌ Failed to quarantine ${failed.length}:`);
    for (const f of failed) console.log(`  ${f.key}: ${f.error}`);
  }
  console.log('\nThese are recoverable until purged — see scripts/restoreVideoFromTrash.js and scripts/purgeVideoTrash.js.');

  await mongoose.disconnect();
  process.exit(failed.length ? 1 : 0);
})().catch((error) => {
  console.error('❌ Quarantine failed:', error);
  process.exit(1);
});
