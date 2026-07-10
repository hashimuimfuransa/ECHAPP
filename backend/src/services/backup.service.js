const mongoose = require('mongoose');
const { EJSON } = require('bson');
const zlib = require('zlib');
const fs = require('fs');
const fsp = require('fs/promises');
const path = require('path');
const cron = require('node-cron');
const { S3Client, PutObjectCommand } = require('@aws-sdk/client-s3');
const s3Service = require('./s3.service');

const BACKUP_DIR = process.env.BACKUP_DIR
  ? path.resolve(process.env.BACKUP_DIR)
  : path.join(__dirname, '../../backups');
const RETENTION_DAYS = parseInt(process.env.BACKUP_RETENTION_DAYS || '14', 10);
const S3_FOLDER = 'backups/database'; // passed as `folder` to s3Service.uploadFile -> key becomes `${S3_FOLDER}/...`
const EXCLUDED_COLLECTIONS = (process.env.BACKUP_EXCLUDE_COLLECTIONS || '')
  .split(',')
  .map((s) => s.trim())
  .filter(Boolean);

// Backups are plain-JSON dumps (via BSON EJSON, which preserves ObjectId/Date/etc.)
// rather than mongodump's BSON archive format. This is deliberate: mongodump/mongorestore
// binaries are not guaranteed to be present on the host (e.g. Render), so the backup
// system is implemented purely with the mongodb driver already used by mongoose.
class BackupService {
  static async ensureBackupDir() {
    await fsp.mkdir(BACKUP_DIR, { recursive: true });
    return BACKUP_DIR;
  }

  static getDb() {
    const db = mongoose.connection && mongoose.connection.db;
    if (!db) {
      throw new Error('Database not connected — cannot run backup/restore');
    }
    return db;
  }

  static getS3Client() {
    return new S3Client({
      region: process.env.AWS_REGION,
      credentials: {
        accessKeyId: process.env.AWS_ACCESS_KEY_ID,
        secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY
      }
    });
  }

  static generateBackupFilename(date = new Date()) {
    const iso = date.toISOString().replace(/[:.]/g, '-');
    return `backup-${iso}.ejson.gz`;
  }

  /**
   * Dumps every collection in the connected database to a single gzip-compressed
   * EJSON file, writes it locally, and (optionally) uploads it to S3.
   */
  static async createBackup({ uploadToS3 = true } = {}) {
    await this.ensureBackupDir();
    const db = this.getDb();

    const collectionInfos = await db.listCollections().toArray();
    const dump = {
      meta: {
        createdAt: new Date().toISOString(),
        dbName: db.databaseName,
        mongooseVersion: require('mongoose/package.json').version
      },
      collections: {}
    };

    let totalDocs = 0;
    for (const { name, type } of collectionInfos) {
      if (type !== 'collection') continue;
      if (EXCLUDED_COLLECTIONS.includes(name)) continue;
      const docs = await db.collection(name).find({}).toArray();
      dump.collections[name] = docs;
      totalDocs += docs.length;
    }

    const serialized = EJSON.stringify(dump);
    const gzipped = zlib.gzipSync(Buffer.from(serialized, 'utf8'));

    const fileName = this.generateBackupFilename();
    const filePath = path.join(BACKUP_DIR, fileName);
    await fsp.writeFile(filePath, gzipped);

    let s3Key = null;
    if (uploadToS3 && process.env.S3_BUCKET_NAME) {
      try {
        // Upload directly (rather than via s3Service.uploadFile) so the S3 key stays
        // exactly `${S3_FOLDER}/${fileName}` — s3Service.uploadFile appends its own
        // timestamp/random suffix for generic collision-avoidance, which would produce
        // a mangled double-timestamped key here since fileName is already unique.
        const key = `${S3_FOLDER}/${fileName}`;
        const client = this.getS3Client();
        await client.send(
          new PutObjectCommand({
            Bucket: process.env.S3_BUCKET_NAME,
            Key: key,
            Body: gzipped,
            ContentType: 'application/gzip',
            Metadata: { 'original-name': fileName }
          })
        );
        s3Key = key;
      } catch (error) {
        // Local backup is already on disk, so an S3 hiccup shouldn't fail the whole job.
        console.error('⚠️  Backup S3 upload failed (local backup retained):', error.message);
      }
    }

    const summary = {
      fileName,
      filePath,
      sizeBytes: gzipped.length,
      collectionsCount: Object.keys(dump.collections).length,
      documentsCount: totalDocs,
      s3Key
    };

    console.log(
      `✅ Backup created: ${fileName} (${summary.collectionsCount} collections, ${totalDocs} documents, ` +
        `${(gzipped.length / 1024 / 1024).toFixed(2)} MB)${s3Key ? ' → uploaded to S3' : ''}`
    );

    return summary;
  }

  static async listLocalBackups() {
    await this.ensureBackupDir();
    const files = await fsp.readdir(BACKUP_DIR);
    const backups = [];
    for (const file of files) {
      if (!file.endsWith('.ejson.gz')) continue;
      const filePath = path.join(BACKUP_DIR, file);
      const stat = await fsp.stat(filePath);
      backups.push({ fileName: file, filePath, sizeBytes: stat.size, createdAt: stat.mtime });
    }
    return backups.sort((a, b) => b.createdAt - a.createdAt);
  }

  static async listS3Backups() {
    if (!process.env.S3_BUCKET_NAME) return [];
    const { ListObjectsV2Command } = require('@aws-sdk/client-s3');
    const client = this.getS3Client();

    const backups = [];
    let continuationToken;
    do {
      const page = await client.send(
        new ListObjectsV2Command({
          Bucket: process.env.S3_BUCKET_NAME,
          Prefix: `${S3_FOLDER}/`,
          ContinuationToken: continuationToken
        })
      );
      for (const obj of page.Contents || []) {
        backups.push({ key: obj.Key, sizeBytes: obj.Size, createdAt: obj.LastModified });
      }
      continuationToken = page.IsTruncated ? page.NextContinuationToken : undefined;
    } while (continuationToken);

    return backups.sort((a, b) => b.createdAt - a.createdAt);
  }

  /** Deletes local backup files (and, if configured, S3 backups) older than BACKUP_RETENTION_DAYS. */
  static async cleanupOldBackups() {
    const cutoff = Date.now() - RETENTION_DAYS * 24 * 60 * 60 * 1000;

    const localBackups = await this.listLocalBackups();
    let deletedLocal = 0;
    for (const backup of localBackups) {
      if (backup.createdAt.getTime() < cutoff) {
        await fsp.unlink(backup.filePath);
        deletedLocal++;
      }
    }
    if (deletedLocal) {
      console.log(`🧹 Removed ${deletedLocal} local backup(s) older than ${RETENTION_DAYS} days`);
    }

    if (process.env.S3_BUCKET_NAME) {
      try {
        const { DeleteObjectCommand } = require('@aws-sdk/client-s3');
        const client = this.getS3Client();
        const s3Backups = await this.listS3Backups();
        let deletedS3 = 0;
        for (const backup of s3Backups) {
          if (backup.createdAt && backup.createdAt.getTime() < cutoff) {
            await client.send(new DeleteObjectCommand({ Bucket: process.env.S3_BUCKET_NAME, Key: backup.key }));
            deletedS3++;
          }
        }
        if (deletedS3) {
          console.log(`🧹 Removed ${deletedS3} S3 backup(s) older than ${RETENTION_DAYS} days`);
        }
      } catch (error) {
        console.error('⚠️  S3 backup cleanup failed:', error.message);
      }
    }
  }

  static async runDailyBackup() {
    try {
      console.log('🗄️  Running scheduled daily database backup...');
      await this.createBackup({ uploadToS3: true });
      await this.cleanupOldBackups();
    } catch (error) {
      console.error('❌ Scheduled database backup failed:', error);
    }
  }

  /**
   * Safety net for hosts where the process isn't guaranteed to be running at the
   * scheduled hour — most notably Render web services, which spin down after a
   * period of no HTTP traffic and only wake back up on the next request. If that
   * happens to be well past the scheduled hour, the cron tick is simply missed
   * (the process wasn't alive to fire it). This checks the most recent backup on
   * every boot and, if it's older than `maxAgeHours`, runs one immediately.
   *
   * This is a fallback, not the primary mechanism — see render.yaml / the "Running
   * on Render" section in DATABASE_BACKUP_SYSTEM.md for the reliable fix, which is
   * a dedicated Render Cron Job that runs independently of the web service's
   * sleep/wake state.
   */
  static async ensureRecentBackup(maxAgeHours = 24) {
    try {
      const backups = process.env.S3_BUCKET_NAME ? await this.listS3Backups() : await this.listLocalBackups();
      const mostRecent = backups[0];
      const ageHours = mostRecent ? (Date.now() - new Date(mostRecent.createdAt).getTime()) / (60 * 60 * 1000) : Infinity;

      if (ageHours > maxAgeHours) {
        console.log(
          `🗄️  Most recent backup is ${mostRecent ? ageHours.toFixed(1) + 'h old' : 'missing'} ` +
            `(over the ${maxAgeHours}h threshold — the service may have been asleep at the scheduled hour). Running a catch-up backup now.`
        );
        await this.runDailyBackup();
      }
    } catch (error) {
      console.error('⚠️  Backup catch-up check failed:', error.message);
    }
  }

  /** Registers the daily cron job. Call once, after the DB connection is established. */
  static schedule(hour = 2, minute = 0) {
    if (process.env.BACKUP_ENABLED === 'false') {
      console.log('🗄️  Database backups disabled via BACKUP_ENABLED=false');
      return;
    }

    const cronExpression = `${minute} ${hour} * * *`;
    console.log(`Scheduling daily database backup at ${String(hour).padStart(2, '0')}:${String(minute).padStart(2, '0')} (cron: "${cronExpression}")`);

    // Cron expression rather than setInterval so a redeploy/restart never delays or
    // skips a day's backup — see notification-scheduler.service.js for the same reasoning.
    cron.schedule(cronExpression, () => {
      this.runDailyBackup().catch((error) => console.error('Scheduled backup failed:', error));
    });

    // Catch-up check shortly after boot, in case the process was asleep/offline
    // through the scheduled hour (see ensureRecentBackup docstring above).
    setTimeout(() => {
      this.ensureRecentBackup().catch((error) => console.error('Backup catch-up check failed:', error));
    }, 15000);
  }

  // ---------------------------------------------------------------------
  // Restore
  // ---------------------------------------------------------------------

  static async downloadS3Backup(key, destPath) {
    const buffer = await s3Service.getFileBuffer(key);
    await fsp.writeFile(destPath, buffer);
    return destPath;
  }

  static async loadBackupFile(filePath) {
    const gzipped = await fsp.readFile(filePath);
    const json = zlib.gunzipSync(gzipped).toString('utf8');
    return EJSON.parse(json);
  }

  /**
   * Restores a backup file into the connected database.
   * mode 'replace' (default): each collection included in the backup is emptied and
   *   repopulated from the dump — the accurate point-in-time restore.
   * mode 'merge': documents are upserted by _id, existing data not in the backup is left alone.
   * `collections`, if given, limits the restore to those collection names.
   * `dryRun` reports what would happen without writing anything.
   */
  static async restoreBackup({ filePath, collections: onlyCollections, mode = 'replace', dryRun = false }) {
    if (!['replace', 'merge'].includes(mode)) {
      throw new Error(`Invalid restore mode "${mode}" — expected "replace" or "merge"`);
    }

    const dump = await this.loadBackupFile(filePath);
    const db = this.getDb();

    const results = [];
    for (const [name, docs] of Object.entries(dump.collections)) {
      if (onlyCollections && onlyCollections.length && !onlyCollections.includes(name)) continue;

      if (dryRun) {
        results.push({ collection: name, documents: docs.length, action: `dry-run (${mode})` });
        continue;
      }

      const coll = db.collection(name);
      if (mode === 'replace') {
        await coll.deleteMany({});
        if (docs.length) await coll.insertMany(docs, { ordered: false });
      } else {
        if (docs.length) {
          const ops = docs.map((doc) => ({
            replaceOne: { filter: { _id: doc._id }, replacement: doc, upsert: true }
          }));
          await coll.bulkWrite(ops, { ordered: false });
        }
      }
      results.push({ collection: name, documents: docs.length, action: mode });
    }

    return { meta: dump.meta, results };
  }
}

module.exports = BackupService;
