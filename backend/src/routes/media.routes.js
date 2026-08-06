const express = require('express');
const router = express.Router();
const axios = require('axios');

/**
 * Media proxy endpoint.
 *
 * The Flutter web app renders images/videos through XHR/fetch, which is
 * subject to CORS. Files served directly from the CloudFront/S3 CDN do not
 * (currently) return an `Access-Control-Allow-Origin` header, so the browser
 * blocks them on the web version. Desktop/mobile apps are unaffected because
 * their native network stacks do not enforce CORS.
 *
 * This endpoint fetches the requested media server-side (no CORS on the
 * server) and streams the bytes back to the browser with the proper CORS
 * headers. The frontend routes its CloudFront media URLs through this proxy on
 * web only.
 *
 * Use: GET /api/media/proxy?url=<fully-encoded CloudFront/S3 media URL>
 *
 * For security, only media hosted on the known CloudFront/S3 domains is
 * allowed. Requests for arbitrary hosts are rejected.
 */

// Domains we are willing to proxy. Lower-case, no protocol.
const ALLOWED_HOSTS = [
  'd3ofk5ujo941v.cloudfront.net',
  'echcoahing.s3.amazonaws.com',
  'excellencecoachinghub.s3.amazonaws.com',
];

// Max bytes we will relay through memory. Larger streams still work but are
// streamed through disk/pipe rather than buffered fully in memory.
const MAX_BUFFER_BYTES = 50 * 1024 * 1024; // 50 MB

function isAllowedMediaUrl(url) {
  try {
    const parsed = new URL(url);
    const host = parsed.hostname.toLowerCase();
    return ALLOWED_HOSTS.some((allowed) => host === allowed || host.endsWith(`.${allowed}`));
  } catch (_) {
    return false;
  }
}

router.get('/proxy', async (req, res) => {
  const requestedUrl = req.query.url;

  if (!requestedUrl || typeof requestedUrl !== 'string') {
    return res.status(400).json({ success: false, message: 'Missing "url" query parameter' });
  }

  if (!isAllowedMediaUrl(requestedUrl)) {
    return res.status(403).json({
      success: false,
      message: 'Only media hosted on the configured CloudFront/S3 domain is allowed',
    });
  }

  try {
    const upstream = await axios.get(requestedUrl, {
      responseType: 'arraybuffer',
      maxContentLength: MAX_BUFFER_BYTES,
      maxBodyLength: MAX_BUFFER_BYTES,
      timeout: 60000,
      headers: {
        // Forward a browser-like User-Agent; some buckets reject empty ones.
        'User-Agent':
          'Mozilla/5.0 (ExcellenceCoachingHub MediaProxy/1.0)',
      },
    });

    const contentType =
      upstream.headers['content-type'] || 'application/octet-stream';
    const buffer = Buffer.from(upstream.data);

    // CORS headers so the browser lets the web app use the bytes.
    res.set({
      'Content-Type': contentType,
      'Content-Length': buffer.length,
      'Cache-Control': 'public, max-age=86400', // 1 day
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, HEAD, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      'X-Proxy-Source': 'EchBackendMediaProxy',
    });

    return res.send(buffer);
  } catch (error) {
    const status = error.response ? error.response.status : 502;
    console.error(`MediaProxy: failed to fetch ${requestedUrl}:`, error.message);
    return res.status(status).json({
      success: false,
      message: 'Failed to fetch media',
      error: error.message,
    });
  }
});

// Handle CORS preflight for the proxy endpoint.
router.options('/proxy', (req, res) => {
  res.set({
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, HEAD, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    'Access-Control-Max-Age': '86400',
  });
  res.sendStatus(204);
});

module.exports = router;
