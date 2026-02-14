import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/services/download_service.dart';
import 'package:excellencecoachinghub/models/download.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import 'dart:async';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  final DownloadService _downloadService = DownloadService();
  List<Download> _downloads = [];
  List<Download> _filteredDownloads = [];
  bool _isLoading = true;
  String _searchQuery = '';
  DownloadStatus? _statusFilter;

  @override
  void initState() {
    super.initState();
    _loadDownloads();
  }

  Future<void> _loadDownloads() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _downloads = _downloadService.getAllDownloads();
      _applyFilters();
    } catch (e) {
      print('Error loading downloads: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteDownload(Download download) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Download'),
        content: Text('Are you sure you want to delete "${download.originalTitle}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (result == true) {
      final deleted = await _downloadService.deleteDownload(download.lessonId);
      if (deleted) {
        _loadDownloads(); // Refresh the list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Download deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete download'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Play downloaded video from local storage
  void _playDownloadedVideo(Download download) {
    // Navigate to video player with local file path
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _LocalVideoPlayer(
          filePath: download.localPath,
          title: download.fileName,
        ),
      ),
    );
  }

  void _applyFilters() {
    setState(() {
      _filteredDownloads = _downloads.where((download) {
        // Apply search filter
        bool matchesSearch = _searchQuery.isEmpty || 
            download.originalTitle.toLowerCase().contains(_searchQuery.toLowerCase());
        
        // Apply status filter
        bool matchesStatus = _statusFilter == null || download.status == _statusFilter;
        
        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }

  void _onStatusFilterChanged(DownloadStatus? status) {
    setState(() {
      _statusFilter = status;
      _applyFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Downloads'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          // Filter button
          PopupMenuButton<DownloadStatus?>(
            icon: const Icon(Icons.filter_list),
            onSelected: _onStatusFilterChanged,
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<DownloadStatus?>(
                  value: null,
                  child: Text('All Status'),
                ),
                const PopupMenuItem<DownloadStatus?>(
                  value: DownloadStatus.completed,
                  child: Text('Completed'),
                ),
                const PopupMenuItem<DownloadStatus?>(
                  value: DownloadStatus.downloading,
                  child: Text('Downloading'),
                ),
                const PopupMenuItem<DownloadStatus?>(
                  value: DownloadStatus.failed,
                  child: Text('Failed'),
                ),
              ];
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search downloads...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          // Downloads list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryGreen),
                  )
                : _filteredDownloads.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.download_outlined,
                              size: 80,
                              color: AppTheme.greyColor.withOpacity(0.3),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'No downloads found',
                              style: TextStyle(
                                fontSize: 18,
                                color: AppTheme.greyColor,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _searchQuery.isEmpty && _statusFilter == null
                                  ? 'Download videos to watch them offline'
                                  : 'Try adjusting your search or filters',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.greyColor.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadDownloads,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredDownloads.length,
                          itemBuilder: (context, index) {
                            final download = _filteredDownloads[index];
                            return _buildDownloadItem(download);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadItem(Download download) {
    Color statusColor = _getStatusColor(download.status);
    String statusText = _getStatusText(download.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: download.status == DownloadStatus.completed 
            ? () => _playDownloadedVideo(download)
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.video_file,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        download.originalTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.blackColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: statusColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (download.status == DownloadStatus.downloading)
                            Text(
                              '${(download.downloadProgress * 100).round()}%',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.greyColor,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (String value) {
                    if (value == 'delete') {
                      _deleteDownload(download);
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    return [
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red[700]),
                            const SizedBox(width: 8),
                            const Text('Delete'),
                          ],
                        ),
                      ),
                    ];
                  },
                ),
              ],
            ),
            if (download.status == DownloadStatus.downloading)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: LinearProgressIndicator(
                  value: download.downloadProgress,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                ),
              ),
            if (download.status == DownloadStatus.completed)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green[700],
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Downloaded',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[700],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      DateFormat('MMM dd, yyyy').format(DateTime.now()),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.greyColor,
                      ),
                    ),
                  ],
                ),
              ),
            if (download.status == DownloadStatus.failed)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.error,
                      color: Colors.red[700],
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Failed to download',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red[700],
                      ),
                    ),
                  ],
                ),
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
        return Colors.green;
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
}

// Local Video Player Widget with enhanced features for downloaded videos
class _LocalVideoPlayer extends StatefulWidget {
  final String filePath;
  final String title;

  const _LocalVideoPlayer({
    required this.filePath,
    required this.title,
  });

  @override
  State<_LocalVideoPlayer> createState() => _LocalVideoPlayerState();
}

class _LocalVideoPlayerState extends State<_LocalVideoPlayer> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;
  bool _isPlaying = false;
  bool _showControls = true;
  bool _isFullscreen = false;
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.filePath));
    _initializeVideoPlayerFuture = _controller.initialize().then((_) {
      setState(() {});
      _controller.addListener(() {
        setState(() {
          _isPlaying = _controller.value.isPlaying;
        });
      });
      // Auto-hide controls after 3 seconds
      _startHideControlsTimer();
    });
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _isPlaying) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _isFullscreen ? null : AppBar(
        title: Text(widget.title),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen),
            onPressed: _toggleFullscreen,
          ),
        ],
      ),
      body: Container(
        color: Colors.black,
        child: _buildVideoPlayer(),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return FutureBuilder(
      future: _initializeVideoPlayerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return GestureDetector(
            onTap: () {
              setState(() {
                _showControls = !_showControls;
              });
              if (_showControls && _isPlaying) {
                _startHideControlsTimer();
              }
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Black background
                Container(
                  color: Colors.black,
                  child: AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  ),
                ),
                // Play button overlay when paused
                if (!_isPlaying && !_showControls)
                  Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black26,
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 60,
                    ),
                  ),
                // Controls overlay
                if (_showControls) _buildVideoControls(),
              ],
            ),
          );
        } else {
          return Container(
            color: Colors.black,
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildVideoControls() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black54,
            Colors.transparent,
            Colors.black54,
          ],
          stops: [0.0, 0.2, 1.0],
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top controls
          if (_isFullscreen)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    if (_isFullscreen) {
                      _toggleFullscreen();
                    } else {
                      Navigator.pop(context);
                    }
                  },
                ),
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                IconButton(
                  icon: const Icon(Icons.fullscreen_exit, color: Colors.white),
                  onPressed: _toggleFullscreen,
                ),
              ],
            ),
          
          // Middle play/pause button
          Center(
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: IconButton(
                icon: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  color: AppTheme.primaryGreen,
                  size: 50,
                ),
                onPressed: _togglePlayPause,
              ),
            ),
          ),
          
          // Bottom controls
          Column(
            children: [
              // Progress bar
              Row(
                children: [
                  Text(
                    _formatDuration(_controller.value.position),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: VideoProgressIndicator(
                      _controller,
                      allowScrubbing: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      colors: const VideoProgressColors(
                        playedColor: AppTheme.primaryGreen,
                        bufferedColor: Colors.white30,
                        backgroundColor: Colors.white24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _formatDuration(_controller.value.duration),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              
              // Control buttons row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.replay_10, color: Colors.white, size: 24),
                    onPressed: () => _seekBackward(10),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_previous, color: Colors.white, size: 24),
                    onPressed: () => _seekBackward(30),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: IconButton(
                      icon: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: AppTheme.primaryGreen,
                        size: 32,
                      ),
                      onPressed: _togglePlayPause,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next, color: Colors.white, size: 24),
                    onPressed: () => _seekForward(30),
                  ),
                  IconButton(
                    icon: const Icon(Icons.forward_10, color: Colors.white, size: 24),
                    onPressed: () => _seekForward(10),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
    // Restart hide timer when controls are shown
    if (_showControls) {
      _startHideControlsTimer();
    }
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });
    
    if (_isFullscreen) {
      // Enter fullscreen
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      // Exit fullscreen
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  void _seekForward(int seconds) {
    final newPosition = _controller.value.position + Duration(seconds: seconds);
    _controller.seekTo(newPosition);
    // Show controls temporarily
    setState(() {
      _showControls = true;
    });
    _startHideControlsTimer();
  }

  void _seekBackward(int seconds) {
    final newPosition = _controller.value.position - Duration(seconds: seconds);
    _controller.seekTo(newPosition);
    // Show controls temporarily
    setState(() {
      _showControls = true;
    });
    _startHideControlsTimer();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    
    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    } else {
      return '$minutes:$seconds';
    }
  }
}
