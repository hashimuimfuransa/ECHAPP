import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/services/download_service.dart';
import 'package:excellencecoachinghub/models/download.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';
import 'package:excellencecoachinghub/presentation/providers/download_provider.dart';
import 'package:excellencecoachinghub/presentation/widgets/video_player/custom_video_player.dart';
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
              onPressed: () => context.push('/downloads'),
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
          color: AppTheme.primaryGreen.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: isCompleted ? () => _playDownloadedVideo(context, download) : null,
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
                color: (isCompleted ? AppTheme.primaryGreen : AppTheme.accent).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isCompleted ? Icons.play_circle_fill : Icons.video_file,
                color: isCompleted ? AppTheme.primaryGreen : AppTheme.accent,
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
              const Row(
                children: [
                  Icon(Icons.check_circle, color: AppTheme.primaryGreen, size: 14),
                  SizedBox(width: 4),
                  Text('Available Offline', style: TextStyle(fontSize: 11, color: AppTheme.primaryGreen, fontWeight: FontWeight.w500)),
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

  void _playDownloadedVideo(BuildContext context, Download download) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomVideoPlayer(
          videoId: download.lessonId,
          videoUrl: download.localPath,
          title: download.originalTitle,
          description: 'Local video file',
          showAppBar: true,
        ),
      ),
    );
  }
}
