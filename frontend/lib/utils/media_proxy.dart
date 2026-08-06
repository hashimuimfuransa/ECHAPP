import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:excellencecoachinghub/config/api_config.dart';

/// Media URL helper for the Flutter **web** build.
///
/// Flutter web renders images through XHR/fetch, which is subject to CORS. The
/// CloudFront/S3 CDN does not currently return an `Access-Control-Allow-Origin`
/// header, so browsers block direct CDN image/video requests on the website
/// version. Desktop and mobile apps are unaffected because their native
/// network stacks don't enforce CORS.
///
/// This routes CDN-hosted media through the backend media proxy
/// (`GET /api/media/proxy?url=...`) which streams the bytes back with the
/// proper CORS headers. On non-web platforms the original URL is returned
/// unchanged.
String mediaProxyUrl(String? url) {
  if (!kIsWeb || url == null || url.isEmpty) return url ?? '';
  if (!url.contains('cloudfront.net') && !url.contains('amazonaws.com')) {
    return url;
  }
  final apiOrigin = ApiConfig.baseUrl.replaceFirst('/api', '');
  return '$apiOrigin/api/media/proxy?url=${Uri.encodeComponent(url)}';
}
