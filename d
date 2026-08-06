const express = require('express');
const router = express.Router();
const axios = require('axios');

/**
 * Media proxy endpoint.
 *
 * The Flutter web app renders images/videos through XHR/fetch, which is
 * subject to CORS. Files served directly from the CloudFront/S3 CDN do not
 * (currently) return an `Access-Control-Allow-Origin` header, so the browser
 * blocks them on the web version.
 *
 * This endpoint fetches the requested media server-side and streams the bytes
 * back to the browser with the proper CORS headers.
 *
 * IMPORTANT for VIDEO:
 * HTML5 <video> elements (used by Flutter web's video_player/Chewie) REQUIRE
 * HTTP `Range` request support to play and seek.
 *
 * The OLD proxy buffered the whole file in memory with a hard 50MB limit
 * (`maxContentLength`), so any video larger than 50MB failed with
 * "maxContentLength size of 52428800 exceeded" and the browser reported
 * MEDIA_ERR_SRC_NOT_SUPPORTED. This version STREAMS the upstream response
 * (no in-memory buffer, no size limit) and forwards the client's `Range`
 * header so the browser can play and seek.
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

function isAllowedMediaUrl(url) {
  try {
    const parsed = new URL(url);
    const host = parsed.hostname.toLowerCase();
    return ALLOWED_HOSTS.some((allowed) => host === allowed || host.endsWith(`.${allowed}`));
  } catch (_) {
    return false;
  }
}

const PROXY_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, HEAD, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, Range, If-Range, Content-Range, Accept-Ranges',
  'Access-Control-Expose-Headers':
    'Content-Type, Content-Length, Content-Range, Accept-Ranges, Content-Disposition, Cache-Control',
  'Access-Control-Max-Age': '86400',
};

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

  // Forward the client's Range header (if any) so the browser can play/seek.
  const rangeHeader = req.headers.range;
  const upstreamHeaders = {
    'User-Agent': 'Mozilla/5.0 (ExcellenceCoachingHub MediaProxy/1.0)',
  };
  if (rangeHeader) {
    upstreamHeaders['Range'] = rangeHeader;
  }

  try {
    // Stream the upstream response instead of buffering the whole file.
    const upstream = await axios.get(requestedUrl, {
      responseType: 'stream',
      timeout: 60000,
      maxRedirects: 5,
      headers: upstreamHeaders,
    });

    const contentType =
      upstream.headers['content-type'] || 'application/octet-stream';
    const contentLength =
      upstream.headers['content-length'] || upstream.headers['x-amz-meta-content-length'];

    // Apply CORS headers.
    res.set({
      ...PROXY_HEADERS,
      'Content-Type': contentType,
      'Cache-Control': 'public, max-age=86400',
      'X-Proxy-Source': 'EchBackendMediaProxy',
    });

    // The upstream honored our Range request -> relay a 206 Partial Content so
    // the browser's video element can play and seek.
    if (upstream.status === 206 && rangeHeader) {
      res.status(206);
      if (upstream.headers['content-range']) {
        res.set('Content-Range', upstream.headers['content-range']);
      }
      if (contentLength) {
        res.set('Content-Length', contentLength);
      }
      res.set('Accept-Ranges', 'bytes');
    } else {
      // Full response (no range requested / upstream ignored it).
      res.status(upstream.status || 200);
      if (contentLength) {
        res.set('Content-Length', contentLength);
      }
      res.set('Accept-Ranges', 'bytes');
    }

    // Pipe the upstream stream to the client; destroy on client disconnect.
    upstream.data.pipe(res);
    upstream.data.on('error', (err) => {
      console.error('MediaProxy: stream error for', requestedUrl, ':', err.message);
      if (!res.headersSent) {
        res.status(502).json({ success: false, message: 'Stream error', error: err.message });
      } else {
        res.destroy();
      }
    });
    req.on('close', () => {
      // Abort the upstream request if the client goes away.
      try {
        upstream.data.destroy();
      } catch (_) {
        /* noop */
      }
    });
  } catch (error) {
    const status = error.response ? error.response.status : 502;
    console.error(`MediaProxy: failed to fetch ${requestedUrl}:`, error.message);
    if (!res.headersSent) {
      return res.status(status).json({
        success: false,
        message: 'Failed to fetch media',
        error: error.message,
      });
    }
  }
});

// Handle CORS preflight for the proxy endpoint.
router.options('/proxy', (req, res) => {
  res.set(PROXY_HEADERS);
  res.sendStatus(204);
});

module.exports = router;
