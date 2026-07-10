/**
 * Restore a database backup created by backup.service.js.
 *
 * This is a destructive operation (in the default "replace" mode it empties every
 * restored collection before repopulating it) so it is deliberately CLI-only —
 * there is no HTTP endpoint for it. It also refuses to write anything unless
 * --yes is passed, so you can safely rehearse with a dry run first.
 *
 * Usage:
 *   node scripts/restoreBackup.js --latest --dry-run
 *   node scripts/restoreBackup.js --latest --yes
 *   node scripts/restoreBackup.js --file=./backups/backup-2026-07-10T02-00-00-000Z.ejson.gz --yes
 *   node scripts/restoreBackup.js --s3-key=backups/database/backup-....ejson.gz --yes
 *   node scripts/restoreBackup.js --latest --collections=User,Course --mode=merge --yes
 *
 * Flags:
 *   --file=<path>          Restore from a local backup file
 *   --s3-key=<key>          Restore from a specific S3 object key (downloaded first)
 *   --latest                Restore the most recent backup (checks local, then S3)
 *   --collections=a,b,c     Only restore these collections (default: all in the backup)
 *   --mode=replace|merge    replace = empty + repopulate each collection (default)
 *                           merge   = upsert documents by _id, leave other data untouched
 *   --dry-run               Show what would happen without writing anything
 *   --yes                   Required to actually perform a non-dry-run restore
 */
require('dotenv').config();
const path = require('path');
const os = require('os');
const mongoose = require('mongoose');
const connectDB = require('../src/config/database');
const BackupService = require('../src/services/backup.service');

function parseArgs(argv) {
  const args = { dryRun: false, yes: false, mode: 'replace' };
  for (const arg of argv) {
    if (arg === '--latest') args.latest = true;
    else if (arg === '--dry-run') args.dryRun = true;
    else if (arg === '--yes') args.yes = true;
    else if (arg.startsWith('--file=')) args.file = arg.slice('--file='.length);
    else if (arg.startsWith('--s3-key=')) args.s3Key = arg.slice('--s3-key='.length);
    else if (arg.startsWith('--collections=')) args.collections = arg.slice('--collections='.length).split(',').map((s) => s.trim()).filter(Boolean);
    else if (arg.startsWith('--mode=')) args.mode = arg.slice('--mode='.length);
  }
  return args;
}

(async () => {
  const args = parseArgs(process.argv.slice(2));

  if (!args.file && !args.s3Key && !args.latest) {
    console.error('Specify one of --file=<path>, --s3-key=<key>, or --latest. See script header for usage.');
    process.exit(1);
  }

  if (!args.dryRun && !args.yes) {
    console.error('Refusing to restore without --yes (this overwrites live data). Add --dry-run first to preview, or --yes to proceed.');
    process.exit(1);
  }

  await connectDB();

  let filePath = args.file;

  if (args.s3Key) {
    filePath = path.join(os.tmpdir(), path.basename(args.s3Key));
    console.log(`Downloading s3://${process.env.S3_BUCKET_NAME}/${args.s3Key} ...`);
    await BackupService.downloadS3Backup(args.s3Key, filePath);
  } else if (args.latest) {
    const local = await BackupService.listLocalBackups();
    if (local.length) {
      filePath = local[0].filePath;
      console.log(`Using latest local backup: ${filePath}`);
    } else {
      const s3Backups = await BackupService.listS3Backups();
      if (!s3Backups.length) {
        console.error('No local or S3 backups found.');
        process.exit(1);
      }
      const key = s3Backups[0].key;
      filePath = path.join(os.tmpdir(), path.basename(key));
      console.log(`No local backups found. Downloading latest from S3: ${key}`);
      await BackupService.downloadS3Backup(key, filePath);
    }
  }

  console.log(`\nRestore plan: file=${filePath} mode=${args.mode} collections=${args.collections ? args.collections.join(',') : 'ALL'} dryRun=${args.dryRun}\n`);

  const { meta, results } = await BackupService.restoreBackup({
    filePath,
    collections: args.collections,
    mode: args.mode,
    dryRun: args.dryRun
  });

  console.log(`Backup created at: ${meta.createdAt} (db: ${meta.dbName})`);
  console.table(results);

  if (args.dryRun) {
    console.log('\nDry run only — no data was written. Re-run with --yes to apply.');
  } else {
    console.log('\n✅ Restore complete.');
  }

  await mongoose.disconnect();
  process.exit(0);
})().catch((error) => {
  console.error('❌ Restore failed:', error);
  process.exit(1);
});
