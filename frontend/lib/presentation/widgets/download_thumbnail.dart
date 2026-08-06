import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/models/download.dart';

/// Preview image for a download.
///
/// Shows the artwork saved next to the file — a book's cover, a course's image
/// — read straight off disk so it works with no connection. When there is none
/// (or the file has gone), it falls back to a tinted tile carrying the file
/// type, which still reads as a deliberate cover rather than a bare icon.
class DownloadThumbnail extends StatelessWidget {
  const DownloadThumbnail({
    super.key,
    required this.download,
    this.width = 56,
    this.height = 56,
    this.borderRadius = 12,
    this.showTypeBadge = true,
  });

  final Download download;
  final double width;
  final double height;
  final double borderRadius;

  /// Draws the play triangle over videos and the format tag over documents.
  /// Turn off on very small tiles where the badge would crowd the image.
  final bool showTypeBadge;

  Color get _accent {
    if (download.isBook) return Colors.blue;
    switch (download.type) {
      case DownloadType.video:
        return AppTheme.primaryGreen;
      case DownloadType.notes:
        return Colors.blue;
      case DownloadType.material:
        return AppTheme.accent;
    }
  }

  IconData get _fallbackIcon {
    if (download.isBook) return Icons.menu_book_rounded;
    switch (download.type) {
      case DownloadType.video:
        return Icons.play_circle_fill;
      case DownloadType.notes:
        return Icons.description;
      case DownloadType.material:
        return _isPdf ? Icons.picture_as_pdf : Icons.attach_file;
    }
  }

  bool get _isPdf => p.extension(download.localPath).toLowerCase() == '.pdf';

  /// Short tag shown on documents: PDF, TXT, EPUB…
  String? get _formatTag {
    if (download.type == DownloadType.video) return null;
    final extension = p.extension(download.localPath).replaceFirst('.', '');
    return extension.isEmpty ? null : extension.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final path = download.thumbnailPath;
    final hasImage = path != null && path.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasImage)
              Image.file(
                File(path),
                fit: BoxFit.cover,
                // The image can be deleted from under us, and a half-written
                // file can fail to decode; either way fall back to the tile.
                errorBuilder: (context, error, stackTrace) => _buildFallback(context),
                gaplessPlayback: true,
              )
            else
              _buildFallback(context),
            if (showTypeBadge && hasImage) ..._buildBadges(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBadges() {
    // A scrim keeps white covers from swallowing the badge.
    return [
      if (download.type == DownloadType.video) ...[
        Container(color: Colors.black.withOpacity(0.18)),
        const Center(
          child: Icon(Icons.play_circle_fill, color: Colors.white, size: 26),
        ),
      ] else if (_formatTag != null)
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 2),
            color: Colors.black.withOpacity(0.55),
            child: Text(
              _formatTag!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
    ];
  }

  Widget _buildFallback(BuildContext context) {
    final accent = _accent;
    final tag = _formatTag;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent.withOpacity(0.22), accent.withOpacity(0.08)],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_fallbackIcon, color: accent, size: height >= 64 ? 30 : 22),
          if (tag != null && height >= 56) ...[
            const SizedBox(height: 4),
            Text(
              tag,
              style: TextStyle(
                color: accent,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
