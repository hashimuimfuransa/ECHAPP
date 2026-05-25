import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:better_player_enhanced/better_player.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/services/video_progress_service.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';
import 'dart:io';
import 'dart:async';

class OptimizedVideoPlayer extends StatefulWidget {
  final String? videoId;
  final String? videoUrl;
  final String title;
  final String description;
  final bool showAppBar;
  final VoidCallback? onFullScreen;

  const OptimizedVideoPlayer({
    super.key,
    this.videoId,
    this.videoUrl,
    required this.title,
    required this.description,
    this.showAppBar = false,
    this.onFullScreen,
  }) : assert(videoUrl != null);

  @override
  State<OptimizedVideoPlayer> createState() => _OptimizedVideoPlayerState();
}

class _OptimizedVideoPlayerState extends State<OptimizedVideoPlayer> {
  BetterPlayerController? _betterPlayerController;
  bool _isInitialized = false;
  String? _errorMessage;
  bool _isOffline = false;
  StreamSubscription? _connectivitySubscription;
  bool _isDataSaver = false;
  double _playbackSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _initConnectivityListener();
    _initPlayer();
  }

  void _initConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final isNowOffline = results.isEmpty || results.contains(ConnectivityResult.none);
      
      if (!isNowOffline && _isOffline) {
        // Back online, retry if there was an error
        if (_errorMessage != null) {
          _retryPlayback();
        }
      }
      
      if (mounted) {
        setState(() {
          _isOffline = isNowOffline;
        });
      }
    });
  }

  String _getOptimizedUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    
    // Convert S3 URL to CloudFront URL and ensure HTTPS
    String processedUrl = url;
    if (processedUrl.contains('echcoahing.s3.amazonaws.com')) {
      processedUrl = processedUrl.replaceFirst('echcoahing.s3.amazonaws.com', 'd3ofk5ujo941v.cloudfront.net');
    }

    if (processedUrl.startsWith('http://')) {
      processedUrl = processedUrl.replaceFirst('http://', 'https://');
    }

    // For HLS streaming, ensure .m3u8 extension for adaptive streaming
    if (processedUrl.startsWith('https') && !processedUrl.contains('.m3u8') && !processedUrl.contains('.mpd')) {
      // If it's a regular MP4, we'll still play it but better_player will handle it
      // For production, you should convert videos to HLS format
    }

    // Handle local files
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      return processedUrl.replaceAll('/', '\\');
    }
    return processedUrl;
  }

  void _initPlayer() async {
    if (widget.videoUrl == null) {
      setState(() {
        _errorMessage = "Video source is missing (URL is null)";
        _isInitialized = true;
      });
      return;
    }

    final optimizedUrl = _getOptimizedUrl(widget.videoUrl);
    if (optimizedUrl.isEmpty) {
      setState(() {
        _errorMessage = "Video URL is empty";
        _isInitialized = true;
      });
      return;
    }

    // Retrieve saved progress
    Duration startAt = Duration.zero;
    if (widget.videoId != null) {
      startAt = await videoProgressService.getProgress(widget.videoId!);
    }

    final isNetwork = optimizedUrl.startsWith('http') || kIsWeb;

    BetterPlayerConfiguration betterPlayerConfiguration = BetterPlayerConfiguration(
      aspectRatio: 16 / 9,
      autoPlay: false,
      looping: false,
      fit: BoxFit.contain,
      controlsConfiguration: BetterPlayerControlsConfiguration(
        enablePlayPause: true,
        enableMute: true,
        enableFullscreen: widget.onFullScreen != null,
        enableProgressBar: true,
        enableProgressText: true,
        enableSkips: true,
        enablePlaybackSpeed: true,
        enableQualities: true,
        controlBarColor: Colors.black54,
        progressBarPlayedColor: AppTheme.primaryGreen,
        progressBarHandleColor: AppTheme.primaryGreen,
        progressBarBufferedColor: AppTheme.primaryGreen.withOpacity(0.3),
        progressBarBackgroundColor: Colors.grey,
        iconsColor: Colors.white,
      ),
      handleLifecycle: true,
      errorBuilder: (context, errorMessage) {
        return _buildErrorPlaceholder(
          icon: Icons.error_outline,
          title: 'Playback Error',
          message: errorMessage ?? 'Something went wrong while playing this video.',
          onRetry: _retryPlayback,
        );
      },
      placeholder: Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
        ),
      ),
    );

    // Configure for adaptive streaming if using HLS/DASH
    BetterPlayerDataSource betterPlayerDataSource;
    if (isNetwork) {
      betterPlayerDataSource = BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        optimizedUrl,
        notificationConfiguration: BetterPlayerNotificationConfiguration(
          showNotification: false,
        ),
        cacheConfiguration: BetterPlayerCacheConfiguration(
          useCache: true,
          preCacheSize: 10 * 1024 * 1024, // 10MB pre-cache
          maxCacheSize: 100 * 1024 * 1024, // 100MB max cache
          maxCacheFileSize: 50 * 1024 * 1024, // 50MB per file
        ),
        bufferingConfiguration: BetterPlayerBufferingConfiguration(
          minBufferMs: 15000, // 15 seconds minimum buffer
          maxBufferMs: 50000, // 50 seconds maximum buffer
          bufferForPlaybackMs: 2500, // 2.5 seconds for playback start
          bufferForPlaybackAfterRebufferMs: 5000, // 5 seconds after rebuffer
        ),
      );
    } else if (!kIsWeb) {
      betterPlayerDataSource = BetterPlayerDataSource(
        BetterPlayerDataSourceType.file,
        optimizedUrl,
      );
    } else {
      setState(() {
        _errorMessage = "Local files are not supported on web";
        _isInitialized = true;
      });
      return;
    }

    try {
      _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);
      await _betterPlayerController!.setupDataSource(betterPlayerDataSource);

      if (startAt > Duration.zero) {
        await _betterPlayerController!.seekTo(startAt);
      }

      // Listen to position changes for progress saving
      _betterPlayerController!.addEventsListener((event) {
        if (event.betterPlayerEventType == BetterPlayerEventType.progress) {
          final position = _betterPlayerController!.videoPlayerController!.value.position;
          if (widget.videoId != null && position.inSeconds % 5 == 0 && position.inSeconds > 0) {
            videoProgressService.saveProgress(widget.videoId!, position);
          }
        }
      });

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to load video: $error";
          _isInitialized = true;
        });
      }
    }
  }

  void _retryPlayback() {
    setState(() {
      _errorMessage = null;
      _isInitialized = false;
    });
    
    _betterPlayerController?.removeEventsListener((event) {});
    _betterPlayerController?.dispose();
    _betterPlayerController = null;
    
    _initPlayer();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _betterPlayerController?.removeEventsListener((event) {});
    _betterPlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isOffline) {
      return _buildErrorPlaceholder(
        icon: Icons.wifi_off_outlined,
        title: 'No Internet Connection',
        message: 'Please check your network settings and try again.',
        onRetry: _retryPlayback,
      );
    }

    if (_errorMessage != null) {
      return _buildErrorPlaceholder(
        icon: Icons.error_outline,
        title: 'Playback Error',
        message: 'Something went wrong while playing this video.\n$_errorMessage',
        onRetry: _retryPlayback,
      );
    }

    if (!_isInitialized || _betterPlayerController == null) {
      return Container(
        color: Colors.black,
        height: ResponsiveBreakpoints.isDesktop(context) ? 400 : 200,
        child: const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
      );
    }

    if (widget.showAppBar) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          backgroundColor: AppTheme.primaryGreen,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.data_usage),
              onPressed: () {
                setState(() {
                  _isDataSaver = !_isDataSaver;
                });
                _betterPlayerController?.setVolume(_isDataSaver ? 0.5 : 1.0);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_isDataSaver ? 'Data Saver On' : 'Data Saver Off'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              tooltip: 'Data Saver',
            ),
            IconButton(
              icon: const Icon(Icons.fullscreen),
              onPressed: widget.onFullScreen ?? () => _betterPlayerController?.toggleFullScreen(),
            ),
          ],
        ),
        body: _buildPlayer(),
      );
    }

    return _buildPlayer();
  }

  Widget _buildPlayer() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: BetterPlayer(
        controller: _betterPlayerController!,
      ),
    );
  }

  Widget _buildErrorPlaceholder({
    required IconData icon,
    required String title,
    required String message,
    required VoidCallback onRetry,
  }) {
    return Container(
      color: Colors.black,
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white70, size: 48),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
