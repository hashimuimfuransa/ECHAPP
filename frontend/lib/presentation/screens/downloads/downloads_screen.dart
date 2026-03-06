import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/services/download_service.dart';
import 'package:excellencecoachinghub/models/download.dart';
import 'package:excellencecoachinghub/presentation/providers/download_provider.dart';
import 'package:intl/intl.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:excellencecoachinghub/presentation/widgets/video_player/custom_video_player.dart';
import 'dart:io';

class DownloadsScreen extends ConsumerStatefulWidget {
  const DownloadsScreen({super.key});

  @override
  ConsumerState<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends ConsumerState<DownloadsScreen> {
  String _searchQuery = '';
  DownloadStatus? _statusFilter;

  @override
  Widget build(BuildContext context) {
    final downloadService = ref.watch(downloadServiceProvider);
    final downloads = downloadService.getAllDownloads();
    
    final filteredDownloads = downloads.where((download) {
      bool matchesSearch = _searchQuery.isEmpty || 
          download.originalTitle.toLowerCase().contains(_searchQuery.toLowerCase());
      bool matchesStatus = _statusFilter == null || download.status == _statusFilter;
      return matchesSearch && matchesStatus;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        leading: context.canPop() ? IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
          tooltip: 'Back',
        ) : null,
        title: const Text('My Downloads'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<DownloadStatus?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (status) => setState(() => _statusFilter = status),
            itemBuilder: (context) => [
              const PopupMenuItem(value: null, child: Text('All Status')),
              const PopupMenuItem(value: DownloadStatus.completed, child: Text('Completed')),
              const PopupMenuItem(value: DownloadStatus.downloading, child: Text('Downloading')),
              const PopupMenuItem(value: DownloadStatus.paused, child: Text('Paused')),
              const PopupMenuItem(value: DownloadStatus.failed, child: Text('Failed')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search downloads...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppTheme.getCardColor(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (query) => setState(() => _searchQuery = query),
            ),
          ),
          Expanded(
            child: filteredDownloads.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredDownloads.length,
                    itemBuilder: (context, index) => _buildDownloadItem(filteredDownloads[index], downloadService),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.download_outlined, size: 80, color: AppTheme.greyColor.withOpacity(0.3)),
          const SizedBox(height: 20),
          const Text('No downloads found', style: TextStyle(fontSize: 18, color: AppTheme.greyColor, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(
            _searchQuery.isEmpty && _statusFilter == null
                ? 'Download videos to watch them offline'
                : 'Try adjusting your search or filters',
            style: TextStyle(fontSize: 14, color: AppTheme.greyColor.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadItem(Download download, DownloadService downloadService) {
    final bool isCompleted = download.status == DownloadStatus.completed;
    final bool isDownloading = download.status == DownloadStatus.downloading;
    final bool isPaused = download.status == DownloadStatus.paused;
    final bool isFailed = download.status == DownloadStatus.failed;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: InkWell(
        onTap: isCompleted ? () => _playVideo(download) : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (isCompleted ? AppTheme.primaryGreen : AppTheme.accent).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isCompleted ? Icons.play_circle_fill : Icons.video_file,
                      color: isCompleted ? AppTheme.primaryGreen : AppTheme.accent,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          download.originalTitle,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildStatusBadge(download.status),
                            if (isDownloading || isPaused) ...[
                              const SizedBox(width: 8),
                              Text(
                                '${(download.downloadProgress * 100).toStringAsFixed(1)}%',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.greyColor),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  _buildActions(download, downloadService),
                ],
              ),
              if (isDownloading || isPaused) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: download.downloadProgress,
                    backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isPaused ? AppTheme.greyColor : AppTheme.primaryGreen,
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(DownloadStatus status) {
    Color color;
    String text;
    
    switch (status) {
      case DownloadStatus.completed:
        color = AppTheme.primaryGreen;
        text = 'COMPLETED';
        break;
      case DownloadStatus.downloading:
        color = Colors.blue;
        text = 'DOWNLOADING';
        break;
      case DownloadStatus.paused:
        color = Colors.orange;
        text = 'PAUSED';
        break;
      case DownloadStatus.failed:
        color = Colors.red;
        text = 'FAILED';
        break;
      case DownloadStatus.pending:
        color = Colors.grey;
        text = 'PENDING';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _buildActions(Download download, DownloadService downloadService) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (download.status == DownloadStatus.downloading)
          IconButton(
            icon: const Icon(Icons.pause_circle_outline, color: Colors.blue),
            onPressed: () => downloadService.pauseDownload(download.lessonId),
            tooltip: 'Pause',
          )
        else if (download.status == DownloadStatus.paused || download.status == DownloadStatus.failed)
          IconButton(
            icon: const Icon(Icons.play_circle_outline, color: Colors.blue),
            onPressed: () => downloadService.resumeDownload(download.lessonId),
            tooltip: 'Resume',
          ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppTheme.greyColor),
          onSelected: (value) {
            if (value == 'delete') _confirmDelete(download, downloadService);
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _confirmDelete(Download download, DownloadService downloadService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Download'),
        content: Text('Are you sure you want to delete "${download.originalTitle}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              downloadService.deleteDownload(download.lessonId);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _playVideo(Download download) {
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
