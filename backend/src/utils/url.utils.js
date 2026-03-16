/**
 * Utility functions for URL manipulation
 */

const S3_DOMAIN = process.env.S3_BUCKET_URL ? process.env.S3_BUCKET_URL.replace(/^https?:\/\//, '') : 'echcoahing.s3.amazonaws.com';
const CLOUDFRONT_DOMAIN = process.env.CLOUDFRONT_URL ? process.env.CLOUDFRONT_URL.replace(/^https?:\/\//, '') : 'd3ofk5ujo941v.cloudfront.net';

/**
 * Transforms an S3 URL to a CloudFront URL
 * @param {string} url - The original URL
 * @returns {string} - The transformed URL
 */
const toCloudFront = (url) => {
  if (!url || typeof url !== 'string') return url;
  
  if (url.includes(S3_DOMAIN)) {
    return url.replace(S3_DOMAIN, CLOUDFRONT_DOMAIN);
  }
  
  return url;
};

/**
 * Transforms URLs in an object or array of objects
 * @param {any} data - The data to transform
 * @param {string[]} fields - The fields that contain URLs
 * @returns {any} - The transformed data
 */
const transformUrls = (data, fields = ['thumbnail', 'videoUrl', 'url']) => {
  if (!data) return data;
  
  // Handle Mongoose documents
  if (data.toObject && typeof data.toObject === 'function') {
    data = data.toObject();
  }
  
  if (Array.isArray(data)) {
    return data.map(item => transformUrls(item, fields));
  }
  
  if (typeof data === 'object' && data !== null) {
    // Avoid processing BSON types like ObjectId or Buffers
    if (data._bsontype || data.constructor.name === 'ObjectID' || data.constructor.name === 'Buffer') {
      return data;
    }

    const newData = { ...data };
    
    fields.forEach(field => {
      if (newData[field] && typeof newData[field] === 'string') {
        newData[field] = toCloudFront(newData[field]);
      }
    });
    
    // Recursively check for nested objects (like courseId in enrollment)
    for (const key in newData) {
      if (newData[key] && typeof newData[key] === 'object' && key !== '_id' && !key.endsWith('Id')) {
        newData[key] = transformUrls(newData[key], fields);
      }
    }
    
    return newData;
  }
  
  return data;
};

module.exports = {
  toCloudFront,
  transformUrls
};
