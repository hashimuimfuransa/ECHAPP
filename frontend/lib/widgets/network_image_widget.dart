import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';

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
    String processedUrl = url;
    
    // Convert S3 URL to CloudFront URL and ensure HTTPS
    if (processedUrl.contains('echcoahing.s3.amazonaws.com')) {
      processedUrl = processedUrl.replaceFirst('echcoahing.s3.amazonaws.com', 'd3ofk5ujo941v.cloudfront.net');
    }

    // Ensure it always uses HTTPS for network URLs
    if (processedUrl.startsWith('http://')) {
      processedUrl = processedUrl.replaceFirst('http://', 'https://');
    }
    
    return processedUrl;
  }

  @override
  Widget build(BuildContext context) {
    Widget image = CachedNetworkImage(
      imageUrl: _getOptimizedUrl(imageUrl),
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => placeholder ?? _buildDefaultPlaceholder(),
      errorWidget: (context, url, error) => errorWidget ?? _buildDefaultErrorWidget(context),
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
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppTheme.primaryGreen,
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
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 24,
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Check your internet\nmake sure it loads faster',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.getTextColor(context).withOpacity(0.6),
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
