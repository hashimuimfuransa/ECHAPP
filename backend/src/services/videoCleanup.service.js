const {
  S3Client,
  ListObjectsV2Command,
  CopyObjectCommand,
  DeleteObjectCommand
} = require('@aws-sdk/client-s3');
const Lesson = require('../models/Lesson');

const VIDEO_PREFIX = 'videos/';
const TRASH_PREFIX = 'trash/videos/';
const DEFAULT_GRACE_HOURS = parseInt(process.env.VIDEO_ORPHAN_GRACE_HOURS || '48', 10);
const DEFAULT_TRASH_RETENTION_DAYS = parseInt(process.env.VIDEO_TRASH_RETENTION_DAYS || '30', 10);

// Videos are expensive to re-shoot/re-upload, so every step here is deliberately
// conservative: scanning is read-only, "deletion" only ever moves an object into
// trash/ (see quarantine()), and a separate, explicit purge step is required to
// actually remove data. See S3_VIDEO_CLEANUP.md for the full workflow and rationale.
class VideoCleanupService {
  static getS3Client() {
    return new S3Client({
      region: process.env.AWS_REGION,
      credentials: {
        accessKeyId: process.env.AWS_ACCESS_KEY_ID,
        secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY
      }
    });
  }

  /** Lesson.videoId is sometimes a bare S3 key, sometimes a full CloudFront/S3 URL. Normalize to a bare key. */
  static extractKey(videoId) {
    if (!videoId) return null;
    if (!/^https?:\/\//i.test(videoId)) return videoId;
    try {
      return decodeURIComponent(new URL(videoId).pathname.replace(/^\/+/, ''));
    } catch {
      return videoId;
    }
  }

  static async listObjectsUnderPrefix(prefix) {
    if (!process.env.S3_BUCKET_NAME) return [];
    const client = this.getS3Client();
    const objects = [];
    let continuationToken;
    do {
      const page = await client.send(
        new ListObjectsV2Command({
          Bucket: process.env.S3_BUCKET_NAME,
          Prefix: prefix,
          ContinuationToken: continuationToken
        })
      );
      for (const obj of page.Contents || []) {
        // ListObjectsV2 returns the prefix itself as a zero-byte "directory marker" object sometimes
        if (obj.Key === prefix) continue;
        objects.push({ key: obj.Key, sizeBytes: obj.Size, lastModified: obj.LastModified });
      }
      continuationToken = page.IsTruncated ? page.NextContinuationToken : undefined;
    } while (continuationToken);
    return objects;
  }

  static async listS3Videos() {
    return this.listObjectsUnderPrefix(VIDEO_PREFIX);
  }

  static async listTrash() {
    const objects = await this.listObjectsUnderPrefix(TRASH_PREFIX);
    return objects.map((o) => ({ ...o, originalKey: o.key.slice(TRASH_PREFIX.length - VIDEO_PREFIX.length) }));
  }

  /** Every S3 key under videos/ currently referenced by a Lesson document. */
  static async listReferencedVideoKeys() {
    const lessons = await Lesson.find({ videoId: { $ne: null } }).select('videoId').lean();
    return new Set(lessons.map((l) => this.extractKey(l.videoId)).filter(Boolean));
  }

  /**
   * Finds S3 video objects that no Lesson currently references.
   * `graceHours` excludes recently-uploaded objects — protects videos mid-upload
   * (presigned client upload happens before the lesson record is saved) or lessons
   * being actively edited from being flagged before they're even linked up.
   */
  static async scanOrphaned({ graceHours = DEFAULT_GRACE_HOURS } = {}) {
    const [allVideos, referencedKeys] = await Promise.all([
      this.listS3Videos(),
      this.listReferencedVideoKeys()
    ]);

    const cutoff = Date.now() - graceHours * 60 * 60 * 1000;
    const orphaned = allVideos.filter(
      (v) => !referencedKeys.has(v.key) && new Date(v.lastModified).getTime() < cutoff
    );

    return {
      graceHours,
      scannedCount: allVideos.length,
      referencedCount: referencedKeys.size,
      orphaned: orphaned.sort((a, b) => a.lastModified - b.lastModified),
      totalOrphanedBytes: orphaned.reduce((sum, v) => sum + (v.sizeBytes || 0), 0)
    };
  }

  static trashKeyFor(key) {
    return `${TRASH_PREFIX}${key.slice(VIDEO_PREFIX.length)}`;
  }

  static originalKeyFor(trashKey) {
    return `${VIDEO_PREFIX}${trashKey.slice(TRASH_PREFIX.length)}`;
  }

  /**
   * Soft-deletes videos: copies each key to trash/videos/... then removes the
   * original. Nothing is permanently deleted here — see purgeTrash().
   */
  static async quarantine(keys) {
    const client = this.getS3Client();
    const results = [];
    for (const key of keys) {
      const trashKey = this.trashKeyFor(key);
      try {
        await client.send(
          new CopyObjectCommand({
            Bucket: process.env.S3_BUCKET_NAME,
            CopySource: `${process.env.S3_BUCKET_NAME}/${encodeURIComponent(key)}`,
            Key: trashKey
          })
        );
        await client.send(new DeleteObjectCommand({ Bucket: process.env.S3_BUCKET_NAME, Key: key }));
        results.push({ key, trashKey, success: true });
      } catch (error) {
        results.push({ key, trashKey, success: false, error: error.message });
      }
    }
    return results;
  }

  /** Undoes a quarantine: moves a trash object back to its original videos/ location. */
  static async restoreFromTrash(trashKey) {
    const client = this.getS3Client();
    const originalKey = this.originalKeyFor(trashKey);
    await client.send(
      new CopyObjectCommand({
        Bucket: process.env.S3_BUCKET_NAME,
        CopySource: `${process.env.S3_BUCKET_NAME}/${encodeURIComponent(trashKey)}`,
        Key: originalKey
      })
    );
    await client.send(new DeleteObjectCommand({ Bucket: process.env.S3_BUCKET_NAME, Key: trashKey }));
    return { trashKey, restoredKey: originalKey };
  }

  /** Permanently deletes trash/videos/ objects older than retentionDays. This is the only irreversible step. */
  static async purgeTrash({ retentionDays = DEFAULT_TRASH_RETENTION_DAYS, dryRun = true } = {}) {
    const client = this.getS3Client();
    const cutoff = Date.now() - retentionDays * 24 * 60 * 60 * 1000;
    const trash = await this.listTrash();
    const due = trash.filter((t) => new Date(t.lastModified).getTime() < cutoff);

    if (dryRun) {
      return { retentionDays, dryRun: true, due, deletedCount: 0 };
    }

    let deletedCount = 0;
    for (const item of due) {
      await client.send(new DeleteObjectCommand({ Bucket: process.env.S3_BUCKET_NAME, Key: item.key }));
      deletedCount++;
    }
    return { retentionDays, dryRun: false, due, deletedCount };
  }
}

module.exports = VideoCleanupService;
