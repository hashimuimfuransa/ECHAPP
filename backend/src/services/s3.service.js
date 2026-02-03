const {
  S3Client,
  PutObjectCommand,
  GetObjectCommand,
  DeleteObjectCommand,
  HeadObjectCommand
} = require('@aws-sdk/client-s3');
const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');
const crypto = require('crypto');
const path = require('path');

class S3Service {
  constructor() {
    this.client = new S3Client({
      region: process.env.AWS_REGION,
      credentials: {
        accessKeyId: process.env.AWS_ACCESS_KEY_ID,
        secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY
      }
    });
    
    this.bucketName = process.env.S3_BUCKET_NAME;
    this.bucketUrl = process.env.S3_BUCKET_URL;
  }

  // Generate unique key for file storage
  generateFileKey(originalName, folder = 'uploads') {
    const ext = path.extname(originalName);
    const basename = path.basename(originalName, ext);
    const timestamp = Date.now();
    const randomString = crypto.randomBytes(8).toString('hex');
    return `${folder}/${basename}-${timestamp}-${randomString}${ext}`;
  }

  // Upload file to S3
  async uploadFile(buffer, originalName, contentType, folder = 'uploads') {
    try {
      const key = this.generateFileKey(originalName, folder);
      
      const command = new PutObjectCommand({
        Bucket: this.bucketName,
        Key: key,
        Body: buffer,
        ContentType: contentType,
        Metadata: {
          'original-name': originalName
        }
      });

      const response = await this.client.send(command);
      
      return {
        key: key,
        url: `${this.bucketUrl}/${key}`,
        bucket: this.bucketName,
        etag: response.ETag
      };
    } catch (error) {
      throw new Error(`Failed to upload file: ${error.message}`);
    }
  }

  // Generate signed URL for private file access
  async generateSignedUrl(key, expiresIn = 3600) { // 1 hour default
    try {
      const command = new GetObjectCommand({
        Bucket: this.bucketName,
        Key: key
      });

      const signedUrl = await getSignedUrl(this.client, command, {
        expiresIn: expiresIn
      });

      return signedUrl;
    } catch (error) {
      throw new Error(`Failed to generate signed URL: ${error.message}`);
    }
  }

  // Generate streaming URL for video content
  async generateStreamingUrl(key, expiresIn = 3600) {
    // For video streaming, we can use the same signed URL approach
    // AWS S3 supports byte-range requests which enables efficient streaming
    return await this.generateSignedUrl(key, expiresIn);
  }

  // Get file metadata
  async getFileMetadata(key) {
    try {
      const command = new HeadObjectCommand({
        Bucket: this.bucketName,
        Key: key
      });

      const response = await this.client.send(command);
      
      return {
        key: key,
        size: response.ContentLength,
        contentType: response.ContentType,
        lastModified: response.LastModified,
        etag: response.ETag
      };
    } catch (error) {
      throw new Error(`Failed to get file metadata: ${error.message}`);
    }
  }

  // Delete file from S3
  async deleteFile(key) {
    try {
      const command = new DeleteObjectCommand({
        Bucket: this.bucketName,
        Key: key
      });

      await this.client.send(command);
      
      return {
        success: true,
        message: 'File deleted successfully'
      };
    } catch (error) {
      throw new Error(`Failed to delete file: ${error.message}`);
    }
  }

  // Check if file exists
  async fileExists(key) {
    try {
      await this.getFileMetadata(key);
      return true;
    } catch (error) {
      return false;
    }
  }

  // Upload image specifically
  async uploadImage(buffer, originalName, contentType = 'image/jpeg') {
    return await this.uploadFile(buffer, originalName, contentType, 'images');
  }

  // Upload video specifically
  async uploadVideo(buffer, originalName, contentType = 'video/mp4') {
    return await this.uploadFile(buffer, originalName, contentType, 'videos');
  }

  // Get public URL (for publicly accessible files)
  getPublicUrl(key) {
    return `${this.bucketUrl}/${key}`;
  }
}

module.exports = new S3Service();