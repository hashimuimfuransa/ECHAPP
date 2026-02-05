// Simple in-memory store for upload progress (in production, use Redis or database)
const uploadProgressStore = new Map();

class UploadProgressService {
  /**
   * Store upload progress for a given upload ID
   */
  static updateProgress(uploadId, progress, status, message) {
    const progressData = {
      uploadId,
      progress,
      status,
      message,
      timestamp: new Date().toISOString()
    };
    
    uploadProgressStore.set(uploadId, progressData);
    
    // Clean up old entries after 1 hour
    this.cleanupOldEntries();
    
    return progressData;
  }

  /**
   * Get upload progress for a given upload ID
   */
  static getProgress(uploadId) {
    return uploadProgressStore.get(uploadId) || null;
  }

  /**
   * Remove an upload progress entry
   */
  static removeProgress(uploadId) {
    return uploadProgressStore.delete(uploadId);
  }

  /**
   * Clean up old entries to prevent memory leaks
   */
  static cleanupOldEntries() {
    const now = Date.now();
    for (const [uploadId, progressData] of uploadProgressStore) {
      const timeDiff = now - new Date(progressData.timestamp).getTime();
      if (timeDiff > 3600000) { // 1 hour in milliseconds
        uploadProgressStore.delete(uploadId);
      }
    }
  }

  /**
   * Generate a unique upload ID
   */
  static generateUploadId() {
    return `upload_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }
}

module.exports = UploadProgressService;