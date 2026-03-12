import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
  bool _isDataSaver = false;
  Timer? _bufferingTimer;
  int _bufferingSeconds = 0;
  bool _showSlowInternetError = false;
  
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  List<StreamSubscription> _subscriptions = [];

  bool get _isMobile => !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);
  bool get _isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  String _getOptimizedUrl(String url) {
    if (url.startsWith('http')) {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows && !url.contains('type=.mp4') && !url.toLowerCase().contains('.mp4')) {
        return url.contains('?') ? '$url&type=.mp4' : '$url?type=.mp4';
      }
      return url;
    }
    // Handle local files
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
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
    if (_isMobile || kIsWeb) {
      _initMobilePlayer();
    } else {
      _initMediaKit();
    }
  }

  void _initMobilePlayer() async {
    final optimizedUrl = _getOptimizedUrl(widget.videoUrl!);
    final isNetwork = optimizedUrl.startsWith('http') || kIsWeb;
    
    // Retrieve saved progress
    Duration startAt = Duration.zero;
    if (widget.videoId != null) {
      startAt = await videoProgressService.getProgress(widget.videoId!);
    }

    if (isNetwork) {
      _vpController = VideoPlayerController.networkUrl(Uri.parse(optimizedUrl));
    } else if (!kIsWeb) {
      _vpController = VideoPlayerController.file(File(optimizedUrl));
    } else {
      _errorMessage = "Local files are not supported on web";
      if (mounted) setState(() => _isInitialized = true);
      return;
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
        
        // Start buffering timer if it's buffering and playing
        if (_isBuffering && _isPlaying) {
          _startBufferingTimer();
        } else {
          _stopBufferingTimer();
        }
      });
    }
  }

  void _startBufferingTimer() {
    if (_bufferingTimer != null) return;
    _bufferingSeconds = 0;
    _bufferingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _bufferingSeconds++;
      if (_bufferingSeconds > 10) { // More than 10 seconds of buffering
        if (mounted) {
          setState(() {
            _showSlowInternetError = true;
          });
        }
        _stopBufferingTimer();
      }
    });
  }

  void _stopBufferingTimer() {
    _bufferingTimer?.cancel();
    _bufferingTimer = null;
    _bufferingSeconds = 0;
    if (_showSlowInternetError && !_isBuffering) {
      if (mounted) {
        setState(() {
          _showSlowInternetError = false;
        });
      }
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
      // Increased default buffer size to 64MB (from 8MB) for smoother playback on high-speed connections
      // If data saver is on, reduce to 16MB (previously 2MB)
      final int bufferSize = _isDataSaver ? 16 * 1024 * 1024 : 64 * 1024 * 1024;
      
      _mkPlayer = mk.Player(
        configuration: mk.PlayerConfiguration(
          bufferSize: bufferSize,
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
      _mkPlayer!.stream.buffering.listen((buffering) {
        if (mounted) {
          setState(() {
            _isBuffering = buffering;
            // Handle slow internet detection
            if (_isBuffering && _isPlaying) {
              _startBufferingTimer();
            } else {
              _stopBufferingTimer();
            }
          });
        }
      }),
      _mkPlayer!.stream.playing.listen((playing) {
        if (mounted) {
          setState(() {
            _isPlaying = playing;
            if (_isBuffering && _isPlaying) {
              _startBufferingTimer();
            } else {
              _stopBufferingTimer();
            }
          });
        }
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
    if (_isMobile || kIsWeb) {
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
      child: Stack(
        children: [
          Chewie(controller: _chewieController!),
          if (_showSlowInternetError)
            _buildSlowInternetOverlay(),
        ],
      ),
    );
  }

  Widget _buildSlowInternetOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_outlined, color: Colors.amber, size: 40),
              const SizedBox(height: 12),
              const Text(
                'Slow Connection Detected',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Try lowering quality, using Data Saver, or check your internet. You can also download this lesson for offline viewing.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _showSlowInternetError = false;
                      });
                    },
                    child: const Text('Dismiss', style: TextStyle(color: Colors.white70)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      _stopBufferingTimer();
                      if (_isMobile || kIsWeb) {
                        _initMobilePlayer();
                      } else {
                        _initMediaKit();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
            if (_isBuffering && _errorMessage == null && !_showSlowInternetError)
              const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
            if (_showSlowInternetError)
              _buildSlowInternetOverlay(),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(_isDataSaver ? Icons.data_usage : Icons.data_usage_outlined, 
                      color: _isDataSaver ? AppTheme.primaryGreen : Colors.white, 
                      size: isSmallScreen ? 20 : 24),
                    onPressed: () {
                      setState(() {
                        _isDataSaver = !_isDataSaver;
                        // Re-initialize player with new buffer size if using media_kit
                        if (!_isMobile && !kIsWeb && widget.externalPlayer == null) {
                          _initMediaKit();
                        }
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_isDataSaver ? 'Data Saver On (Lower Buffer)' : 'Data Saver Off'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    tooltip: 'Data Saver',
                  ),
                  IconButton(
                    icon: Icon(Icons.speed, color: Colors.white, size: isSmallScreen ? 20 : 24),
                    onPressed: _showPlaybackSpeedDialog,
                    tooltip: 'Playback Speed',
                  ),
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
              IconButton(
                icon: Icon(Icons.fullscreen, color: Colors.white, size: isSmallScreen ? 20 : 24),
                onPressed: widget.onFullScreen ?? _toggleFullscreen,
                tooltip: 'Fullscreen',
              ),
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
