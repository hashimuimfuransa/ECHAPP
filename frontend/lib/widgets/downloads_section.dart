import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/services/download_service.dart';
import 'package:excellencecoachinghub/models/download.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';
import 'package:excellencecoachinghub/presentation/providers/download_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:excellencecoachinghub/presentation/widgets/video_player/custom_video_player.dart';
import 'package:excellencecoachinghub/presentation/widgets/video_player/optimized_video_player.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'dart:io';

class DownloadsSection extends ConsumerWidget {
  const DownloadsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadService = ref.watch(downloadServiceProvider);
    final downloads = downloadService.getAllDownloads();
    
    if (downloads.isEmpty) {
      return Container(); // Don't show section if no downloads
    }

    // Show only first 3 downloads, sorted by status (downloading first)
    final sortedDownloads = List<Download>.from(downloads)
      ..sort((a, b) {
        if (a.status == DownloadStatus.downloading && b.status != DownloadStatus.downloading) return -1;
        if (a.status != DownloadStatus.downloading && b.status == DownloadStatus.downloading) return 1;
        return 0;
      });
    
    final recentDownloads = sortedDownloads.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My Downloads',
              style: TextStyle(
                color: AppTheme.getTextColor(context),
                fontSize: ResponsiveBreakpoints.isDesktop(context) ? 24 : 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: () => context.go('/downloads'),
              child: const Text(
                'View All',
                style: TextStyle(
                  color: AppTheme.primaryGreen,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 190,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: recentDownloads.length,
            itemBuilder: (context, index) {
              final download = recentDownloads[index];
              return _buildDownloadCard(context, download, downloadService);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDownloadCard(BuildContext context, Download download, DownloadService downloadService) {
    bool isCompleted = download.status == DownloadStatus.completed;
    bool isDownloading = download.status == DownloadStatus.downloading;
    bool isPaused = download.status == DownloadStatus.paused;
    Color statusColor = _getStatusColor(download.status);
    
    // Get icon and color based on download type
    IconData typeIcon;
    Color typeColor;
    String typeLabel;
    
    switch (download.type) {
      case DownloadType.video:
        typeIcon = isCompleted ? Icons.play_circle_fill : Icons.video_file;
        typeColor = isCompleted ? AppTheme.primaryGreen : AppTheme.accent;
        typeLabel = 'Video';
        break;
      case DownloadType.notes:
        typeIcon = Icons.description;
        typeColor = Colors.blue;
        typeLabel = 'Notes';
        break;
      case DownloadType.material:
        typeIcon = download.url.toLowerCase().endsWith('.pdf') ? Icons.picture_as_pdf : Icons.attach_file;
        typeColor = download.url.toLowerCase().endsWith('.pdf') ? Colors.red : AppTheme.accent;
        typeLabel = download.url.toLowerCase().endsWith('.pdf') ? 'PDF' : 'Material';
        break;
    }

    return Container(
      width: 240,
      margin: const EdgeInsets.only(right: 15),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: typeColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: isCompleted ? () => _openDownloadedContent(context, download) : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 70,
              width: double.infinity,
              decoration: BoxDecoration(
                color: (isCompleted ? typeColor : AppTheme.greyColor).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                typeIcon,
                color: isCompleted ? typeColor : AppTheme.greyColor,
                size: 30,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              download.originalTitle,
              style: TextStyle(
                color: AppTheme.getTextColor(context),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _getStatusText(download.status),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    typeLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: typeColor,
                    ),
                  ),
                ),
                if (isDownloading || isPaused) ...[
                  const SizedBox(width: 8),
                  Text(
                    '${(download.downloadProgress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.greyColor),
                  ),
                ],
              ],
            ),
            const Spacer(),
            if (isDownloading || isPaused)
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: download.downloadProgress,
                  backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isPaused ? AppTheme.greyColor : AppTheme.primaryGreen,
                  ),
                  minHeight: 3,
                ),
              )
            else if (isCompleted)
              Row(
                children: [
                  Icon(Icons.check_circle, color: typeColor, size: 14),
                  const SizedBox(width: 4),
                  Text('Available Offline', style: TextStyle(fontSize: 11, color: typeColor, fontWeight: FontWeight.w500)),
                ],
              ),
          ],
        ),
      ),
    ),
  );
  }

  Color _getStatusColor(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.downloading:
        return Colors.blue;
      case DownloadStatus.completed:
        return AppTheme.primaryGreen;
      case DownloadStatus.failed:
        return Colors.red;
      case DownloadStatus.paused:
        return Colors.orange;
      case DownloadStatus.pending:
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.downloading:
        return 'Downloading';
      case DownloadStatus.completed:
        return 'Completed';
      case DownloadStatus.failed:
        return 'Failed';
      case DownloadStatus.paused:
        return 'Paused';
      case DownloadStatus.pending:
      default:
        return 'Pending';
    }
  }

  void _openDownloadedContent(BuildContext context, Download download) {
    switch (download.type) {
      case DownloadType.video:
        _playDownloadedVideo(context, download);
        break;
      case DownloadType.notes:
        _openNotesOrMaterial(context, download);
        break;
      case DownloadType.material:
        _openNotesOrMaterial(context, download);
        break;
    }
  }

  void _playDownloadedVideo(BuildContext context, Download download) async {
    print('Playing downloaded video:');
    print('  localPath: ${download.localPath}');
    print('  fileName: ${download.fileName}');
    print('  lessonId: ${download.lessonId}');

    // Verify the file exists before trying to play
    final file = File(download.localPath);
    if (!await file.exists()) {
      print('File does not exist at: ${download.localPath}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Video file not found. Please download again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check file size to ensure it's not empty
    final fileSize = await file.length();
    print('  File size: $fileSize bytes');
    if (fileSize == 0) {
      print('File is empty, cannot play');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Video file is corrupted. Please download again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check file header to verify it's a valid MP4
    try {
      final bytes = await file.openRead(0, 12).first;
      if (bytes.length < 12) {
        print('File is too small to be a valid video');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video file is corrupted. Please download again.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // MP4 files start with 'ftyp' (bytes: 66 74 79 70) at offset 4
      final isMp4 = bytes[4] == 0x66 && bytes[5] == 0x74 && bytes[6] == 0x79 && bytes[7] == 0x70;
      print('  File header check: isMp4=$isMp4');
      print('  First 12 bytes: $bytes');

      if (!isMp4) {
        print('File is not a valid MP4 file');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video file is corrupted or invalid format. Please download again.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    } catch (e) {
      print('Error reading file header: $e');
      // If header check fails, continue anyway - the file might still be valid
      print('Skipping header check, attempting to play video anyway');
    }

    // Check if file has .mp4 extension, if not add it
    String videoPath = download.localPath;
    if (!videoPath.toLowerCase().endsWith('.mp4')) {
      videoPath = '$videoPath.mp4';
      final fileWithExt = File(videoPath);
      if (!await fileWithExt.exists()) {
        print('File with .mp4 extension does not exist at: $videoPath');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video file not found. Please download again.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // For Android, use raw path without file:// prefix (ExoPlayer needs raw path)
    // For iOS, use file:// prefix
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      if (videoPath.startsWith('file://')) {
        videoPath = videoPath.replaceFirst('file://', '');
      }
    } else if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      if (!videoPath.startsWith('file://')) {
        videoPath = 'file://$videoPath';
      }
    }

    print('  Final video path: $videoPath');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          // Use better_player_enhanced for mobile, CustomVideoPlayer for desktop
          if (kIsWeb || (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
            return OptimizedVideoPlayer(
              videoId: download.lessonId,
              videoUrl: videoPath,
              title: download.originalTitle,
              description: 'Local video file',
              showAppBar: true,
            );
          } else {
            return CustomVideoPlayer(
              videoId: download.lessonId,
              videoUrl: videoPath,
              title: download.originalTitle,
              description: 'Local video file',
              showAppBar: true,
            );
          }
        },
      ),
    );
  }

  void _openNotesOrMaterial(BuildContext context, Download download) {
    // Check if it's a PDF
    if (download.url.toLowerCase().endsWith('.pdf') || download.localPath.toLowerCase().endsWith('.pdf')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: Text(download.originalTitle),
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            body: SfPdfViewer.file(
              File(download.localPath),
            ),
          ),
        ),
      );
    } else {
      // For non-PDF materials, show a dialog with the URL or content
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(download.originalTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('This material is available at:'),
              const SizedBox(height: 8),
              SelectableText(download.url.isNotEmpty ? download.url : download.localPath),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }
}
