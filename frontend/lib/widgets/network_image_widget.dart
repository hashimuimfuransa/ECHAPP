import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:excellencecoachinghub/config/api_config.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/utils/media_proxy.dart';

class NetworkImageWidget extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;

  const NetworkImageWidget({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
  });

  String _getOptimizedUrl(String url) {
    debugPrint('NetworkImageWidget: input imageUrl="$url"');
    // Trim and safely handle URLs that may contain spaces (e.g. filenames like "ChatGPT Image Apr 9, 2026, ...png").
    // CachedNetworkImage ultimately hands this to Uri/http layer, so we need to encode path/query.
    String processedUrl = url.trim();

    if (processedUrl.isEmpty) {
      debugPrint('NetworkImageWidget: optimizedUrl="" (empty input)');
      return processedUrl;
    }


    final apiOrigin = ApiConfig.baseUrl.replaceFirst('/api', '');

    if (processedUrl.startsWith('//')) {
      processedUrl = 'https:$processedUrl';
    } else if (processedUrl.startsWith('/')) {
      processedUrl = '$apiOrigin$processedUrl';
    } else if (!processedUrl.startsWith('http://') &&
        !processedUrl.startsWith('https://')) {
      processedUrl = processedUrl.startsWith('uploads/')
          ? '$apiOrigin/$processedUrl'
          : 'https://d3ofk5ujo941v.cloudfront.net/$processedUrl';
    }

    // Convert S3 URL to CloudFront URL and ensure HTTPS
    if (processedUrl.contains('echcoahing.s3.amazonaws.com')) {
      processedUrl = processedUrl.replaceFirst(
          'echcoahing.s3.amazonaws.com', 'd3ofk5ujo941v.cloudfront.net');
    }
    if (processedUrl.contains('excellencecoachinghub.s3.amazonaws.com')) {
      processedUrl = processedUrl.replaceFirst(
          'excellencecoachinghub.s3.amazonaws.com',
          'd3ofk5ujo941v.cloudfront.net');
    }

    // Ensure it always uses HTTPS for network URLs
    if (processedUrl.startsWith('http://')) {
      processedUrl = processedUrl.replaceFirst('http://', 'https://');
    }

    // Encode any spaces or illegal characters in the URL path/query part.
    // CloudFront/S3 filenames frequently contain spaces.
    try {
      processedUrl = Uri.parse(processedUrl).toString();
    } catch (_) {
      // keep original if parsing fails
    }

    // Encode spaces and other unsafe chars without breaking full URL format.
    // If we encode the entire URL, we might double-encode scheme/host; so we encode only the path/query portion.
    try {
      final uri = Uri.parse(processedUrl);
      final safeUri = uri.hasAbsolutePath
          ? (uri.queryParameters.isEmpty
              ? uri.replace(path: uri.path)
              : uri.replace(path: uri.path, queryParameters: uri.queryParameters))
          : uri;
      processedUrl = safeUri.toString();
    } catch (_) {
      // Fallback: minimally replace spaces.
      processedUrl = processedUrl.replaceAll(' ', '%20');
    }

debugPrint('NetworkImageWidget: optimizedUrl="$processedUrl"');
    return processedUrl;

  }

@override
  Widget build(BuildContext context) {
    final resolvedUrl = mediaProxyUrl(_getOptimizedUrl(imageUrl));
    Widget image = CachedNetworkImage(
      imageUrl: resolvedUrl,
      fadeInDuration: const Duration(milliseconds: 150),
      fadeOutDuration: const Duration(milliseconds: 75),
      // Ensure image is actually fetched immediately (some pages rebuild with new widgets).
      // Note: CachedNetworkImage internally handles caching.

      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => placeholder ?? _buildDefaultPlaceholder(),
      errorWidget: (context, url, error) =>
          errorWidget ?? _buildDefaultErrorWidget(context),
      memCacheWidth: (width != null && width!.isFinite) ? width!.toInt() : null,
      memCacheHeight: (height != null && height!.isFinite) ? height!.toInt() : null,

      cacheManager: CacheManager(
        Config(
          'customCacheKey',
          stalePeriod: const Duration(days: 7),
          maxNrOfCacheObjects: 200,
        ),
      ),
    );

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: image,
      );
    }

    return image;
  }

  Widget _buildDefaultPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: AppTheme.greyColor.withOpacity(0.1),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppTheme.primaryGreen,
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultErrorWidget(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: AppTheme.greyColor.withOpacity(0.1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.broken_image_outlined,
            color: Colors.grey,
            size: 20,
          ),
        ],
      ),
    );
  }
}
