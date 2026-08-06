/**
 * Read-only scan for S3 videos (under videos/) that no Lesson document references.
 * Safe to run any time — writes nothing. This is step 1 of the cleanup workflow;
 * see S3_VIDEO_CLEANUP.md.
 *
 * Usage:
 *   node scripts/findOrphanedVideos.js [--older-than=<hours>]
 */
require('dotenv').config();
const mongoose = require('mongoose');
const connectDB = require('../src/config/database');
const VideoCleanupService = require('../src/services/videoCleanup.service');

const formatSize = (bytes) => `${(bytes / 1024 / 1024).toFixed(2)} MB`;

function parseArgs(argv) {
  const args = {};
  for (const arg of argv) {
    if (arg.startsWith('--older-than=')) args.graceHours = parseInt(arg.slice('--older-than='.length), 10);
  }
  return args;
}

(async () => {
  const args = parseArgs(process.argv.slice(2));

  await connectDB();
  const report = await VideoCleanupService.scanOrphaned({ graceHours: args.graceHours });

  console.log(`\nScanned ${report.scannedCount} video(s) in S3, ${report.referencedCount} referenced by lessons.`);
  console.log(`Grace period: ${report.graceHours}h (objects newer than this are never flagged, even if unreferenced).\n`);

  if (!report.orphaned.length) {
    console.log('No orphaned videos found.');
  } else {
    console.log(`Orphaned videos (${report.orphaned.length}), oldest first:`);
    for (const v of report.orphaned) {
      console.log(`  ${v.key}  ${formatSize(v.sizeBytes)}  last modified ${new Date(v.lastModified).toISOString()}`);
    }
    console.log(`\nTotal reclaimable: ${formatSize(report.totalOrphanedBytes)}`);
    console.log('\nNothing was changed. To quarantine these (move to trash/, reversible), run:');
    console.log('  node scripts/quarantineOrphanedVideos.js --dry-run');
  }

  await mongoose.disconnect();
  process.exit(0);
})().catch((error) => {
  console.error('❌ Orphan scan failed:', error);
  process.exit(1);
});
