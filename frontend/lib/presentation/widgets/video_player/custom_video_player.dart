import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart' as mk;
import 'package:media_kit_video/media_kit_video.dart' as mkv;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/services/video_progress_service.dart';
import 'dart:io';
import 'dart:async';

class CustomVideoPlayer extends StatefulWidget {
  final String? videoId;
  final String? videoUrl;
  final mk.Player? externalPlayer;
  final String title;
  final String description;
  final bool showAppBar;
  final VoidCallback? onFullScreen;

  const CustomVideoPlayer({
    super.key,
    this.videoId,
    this.videoUrl,
    this.externalPlayer,
    required this.title,
    required this.description,
    this.showAppBar = false,
    this.onFullScreen,
  }) : assert(videoUrl != null || externalPlayer != null);

  @override
  State<CustomVideoPlayer> createState() => _CustomVideoPlayerState();
}

class _CustomVideoPlayerState extends State<CustomVideoPlayer> {
  // Media Kit (Desktop)
  mk.Player? _mkPlayer;
  mkv.VideoController? _mkVideoController;
  
  // Chewie / Video Player (Mobile/Android)
  VideoPlayerController? _vpController;
  ChewieController? _chewieController;
  
  bool _isPlaying = false;
  bool _isBuffering = false;
  bool _showControls = true;
  double _playbackSpeed = 1.0;
  bool _isInitialized = false;
  String? _errorMessage;
  
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  List<StreamSubscription> _subscriptions = [];

  bool get _isAndroid => Platform.isAndroid;

  String _getOptimizedUrl(String url) {
    if (url.startsWith('http')) {
      if (Platform.isWindows && !url.contains('type=.mp4') && !url.toLowerCase().contains('.mp4')) {
        return url.contains('?') ? '$url&type=.mp4' : '$url?type=.mp4';
      }
      return url;
    }
    // Handle local files
    if (Platform.isWindows) {
      return url.replaceAll('/', '\\');
    }
    return url;
  }

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  void _initPlayer() {
    if (_isAndroid) {
      _initMobilePlayer();
    } else {
      _initMediaKit();
    }
  }

  void _initMobilePlayer() async {
    final optimizedUrl = _getOptimizedUrl(widget.videoUrl!);
    final isNetwork = optimizedUrl.startsWith('http');
    
    // Retrieve saved progress
    Duration startAt = Duration.zero;
    if (widget.videoId != null) {
      startAt = await videoProgressService.getProgress(widget.videoId!);
    }

    if (isNetwork) {
      _vpController = VideoPlayerController.networkUrl(Uri.parse(optimizedUrl));
    } else {
      _vpController = VideoPlayerController.file(File(optimizedUrl));
    }

    try {
      await _vpController!.initialize();
      
      if (startAt > Duration.zero) {
        await _vpController!.seekTo(startAt);
      }

      _chewieController = ChewieController(
        videoPlayerController: _vpController!,
        aspectRatio: 16 / 9,
        autoPlay: false,
        looping: false,
        showControls: true,
        placeholder: const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
        materialProgressColors: ChewieProgressColors(
          playedColor: AppTheme.primaryGreen,
          handleColor: AppTheme.primaryGreen,
          backgroundColor: Colors.grey,
          bufferedColor: AppTheme.primaryGreen.withOpacity(0.3),
        ),
      );

      _vpController!.addListener(_mobilePlayerListener);

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

  void _mobilePlayerListener() {
    if (_vpController == null) return;
    
    final position = _vpController!.value.position;
    
    // Save progress periodically (every 5 seconds)
    if (widget.videoId != null && position.inSeconds % 5 == 0 && position.inSeconds > 0) {
      videoProgressService.saveProgress(widget.videoId!, position);
    }

    if (mounted) {
      setState(() {
        _position = position;
        _duration = _vpController!.value.duration;
        _isPlaying = _vpController!.value.isPlaying;
        _isBuffering = _vpController!.value.isBuffering;
      });
    }
  }

  void _initMediaKit() async {
    // Retrieve saved progress
    Duration startAt = Duration.zero;
    if (widget.videoId != null) {
      startAt = await videoProgressService.getProgress(widget.videoId!);
    }

    if (widget.externalPlayer != null) {
      _mkPlayer = widget.externalPlayer!;
      _isInitialized = true;
    } else {
      _mkPlayer = mk.Player(
        configuration: const mk.PlayerConfiguration(
          bufferSize: 32 * 1024 * 1024,
        ),
      );
      
      final optimizedUrl = _getOptimizedUrl(widget.videoUrl!);
      
      _mkPlayer!.open(mk.Media(optimizedUrl)).then((_) {
        if (startAt > Duration.zero) {
          _mkPlayer!.seek(startAt);
        }
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      }).catchError((error) {
        if (mounted) {
          setState(() {
            _errorMessage = "Failed to load video: $error";
            _isInitialized = true;
          });
        }
      });
    }

    _mkVideoController = mkv.VideoController(
      _mkPlayer!,
      configuration: const mkv.VideoControllerConfiguration(
        enableHardwareAcceleration: true,
      ),
    );
    _setupMediaKitSubscriptions();
  }

  void _setupMediaKitSubscriptions() {
    if (_mkPlayer == null) return;
    
    for (final s in _subscriptions) {
      s.cancel();
    }
    _subscriptions = [
      _mkPlayer!.stream.playing.listen((playing) {
        if (mounted) setState(() => _isPlaying = playing);
      }),
      _mkPlayer!.stream.buffering.listen((buffering) {
        if (mounted) setState(() => _isBuffering = buffering);
      }),
      _mkPlayer!.stream.position.listen((position) {
        if (mounted) {
          setState(() => _position = position);
          // Save progress periodically (every 5 seconds)
          if (widget.videoId != null && position.inSeconds % 5 == 0 && position.inSeconds > 0) {
            videoProgressService.saveProgress(widget.videoId!, position);
          }
        }
      }),
      _mkPlayer!.stream.duration.listen((duration) {
        if (mounted) {
          setState(() {
            _duration = duration;
            _isInitialized = true;
          });
        }
      }),
      _mkPlayer!.stream.error.listen((error) {
        if (mounted) setState(() => _errorMessage = error.toString());
      }),
    ];
  }

  @override
  void dispose() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    if (widget.externalPlayer == null) {
      _mkPlayer?.dispose();
    }
    _vpController?.removeListener(_mobilePlayerListener);
    _vpController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isAndroid) {
      return _buildMobilePlayer();
    }
    
    if (widget.showAppBar) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          backgroundColor: AppTheme.primaryGreen,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.speed),
              onPressed: _showPlaybackSpeedDialog,
            ),
            IconButton(
              icon: const Icon(Icons.fullscreen),
              onPressed: widget.onFullScreen ?? _toggleFullscreen,
            ),
          ],
        ),
        body: _buildMediaKitPlayer(),
      );
    }
    return _buildMediaKitPlayer();
  }

  Widget _buildMobilePlayer() {
    if (_errorMessage != null) {
      return Container(
        color: Colors.black,
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 50),
              const SizedBox(height: 10),
              Text('Playback Error: $_errorMessage', style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    if (_chewieController == null || !_vpController!.value.isInitialized) {
      return Container(
        color: Colors.black,
        height: 200,
        child: const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
      );
    }

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Chewie(controller: _chewieController!),
    );
  }

  Widget _buildMediaKitPlayer() {
    if (!_isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _showControls = !_showControls;
        });
      },
      child: Container(
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: mkv.Video(
                controller: _mkVideoController!,
                fit: BoxFit.contain,
                fill: Colors.black,
              ),
            ),
            if (_errorMessage != null)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 50),
                    const SizedBox(height: 10),
                    Text('Playback Error: $_errorMessage', style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
                  ],
                ),
              ),
            if (_isBuffering && _errorMessage == null)
              const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
            if (_showControls) _buildMediaKitControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaKitControls() {
    final bool isSmallScreen = MediaQuery.of(context).size.width < 600;
    
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black54],
        ),
      ),
      padding: EdgeInsets.all(isSmallScreen ? 10 : 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            children: [
              Text(_formatDuration(_position), style: TextStyle(color: Colors.white, fontSize: isSmallScreen ? 10 : 12)),
              const SizedBox(width: 8),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: isSmallScreen ? 2 : 4,
                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: isSmallScreen ? 4 : 6),
                    overlayShape: RoundSliderOverlayShape(overlayRadius: isSmallScreen ? 10 : 14),
                    activeTrackColor: AppTheme.primaryGreen,
                    inactiveTrackColor: Colors.white24,
                    thumbColor: AppTheme.primaryGreen,
                  ),
                  child: Slider(
                    value: _position.inMilliseconds.toDouble().clamp(0, _duration.inMilliseconds.toDouble()),
                    min: 0,
                    max: _duration.inMilliseconds.toDouble() > 0 ? _duration.inMilliseconds.toDouble() : 1.0,
                    onChanged: (value) {
                      _mkPlayer!.seek(Duration(milliseconds: value.toInt()));
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(_formatDuration(_duration), style: TextStyle(color: Colors.white, fontSize: isSmallScreen ? 10 : 12)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(icon: Icon(Icons.replay_10, color: Colors.white, size: isSmallScreen ? 24 : 30), onPressed: () => _mkPlayer!.seek(_position - const Duration(seconds: 10))),
              SizedBox(width: isSmallScreen ? 15 : 30),
              Container(
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                child: IconButton(
                  icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: AppTheme.primaryGreen, size: isSmallScreen ? 30 : 40),
                  onPressed: () => _mkPlayer!.playOrPause(),
                ),
              ),
              SizedBox(width: isSmallScreen ? 15 : 30),
              IconButton(icon: Icon(Icons.forward_10, color: Colors.white, size: isSmallScreen ? 24 : 30), onPressed: () => _mkPlayer!.seek(_position + const Duration(seconds: 10))),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  void _showPlaybackSpeedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Playback Speed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((speed) {
            return ListTile(
              title: Text('${speed}x'),
              selected: _playbackSpeed == speed,
              onTap: () {
                if (_isAndroid) {
                  _vpController!.setPlaybackSpeed(speed);
                } else {
                  _mkPlayer!.setRate(speed);
                }
                setState(() => _playbackSpeed = speed);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _toggleFullscreen() {
    if (widget.onFullScreen != null) {
      widget.onFullScreen!();
      return;
    }
  }
}
