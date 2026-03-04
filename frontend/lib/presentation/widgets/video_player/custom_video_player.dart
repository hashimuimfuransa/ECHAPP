import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'dart:io';
import 'dart:async';

class CustomVideoPlayer extends StatefulWidget {
  final String? videoUrl;
  final Player? externalPlayer;
  final String title;
  final String description;
  final bool showAppBar;
  final VoidCallback? onFullScreen;

  const CustomVideoPlayer({
    super.key,
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
  late Player _player;
  late VideoController _videoController;
  bool _isPlaying = false;
  bool _isBuffering = false;
  bool _showControls = true;
  double _volume = 1.0;
  double _playbackSpeed = 1.0;
  bool _isInitialized = false;
  String? _errorMessage;
  
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  Duration _buffer = Duration.zero;

  List<StreamSubscription> _subscriptions = [];

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
    if (widget.externalPlayer != null) {
      _player = widget.externalPlayer!;
      _isInitialized = true;
    } else {
      _player = Player(
        configuration: const PlayerConfiguration(
          bufferSize: 64 * 1024 * 1024, // 64MB buffer for low internet
        ),
      );
      final optimizedUrl = _getOptimizedUrl(widget.videoUrl!);
      _player.open(Media(optimizedUrl)).then((_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      });
    }

    _videoController = VideoController(_player);
    _setupSubscriptions();
  }

  void _setupSubscriptions() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    _subscriptions = [
      _player.stream.playing.listen((playing) {
        if (mounted) {
          setState(() {
            _isPlaying = playing;
          });
        }
      }),
      _player.stream.buffering.listen((buffering) {
        if (mounted) {
          setState(() {
            _isBuffering = buffering;
          });
        }
      }),
      _player.stream.position.listen((position) {
        if (mounted) {
          setState(() {
            _position = position;
          });
        }
      }),
      _player.stream.duration.listen((duration) {
        if (mounted) {
          setState(() {
            _duration = duration;
          });
        }
      }),
      _player.stream.buffer.listen((buffer) {
        if (mounted) {
          setState(() {
            _buffer = buffer;
          });
        }
      }),
      _player.stream.volume.listen((volume) {
        if (mounted) {
          setState(() {
            _volume = volume / 100.0;
          });
        }
      }),
      _player.stream.rate.listen((rate) {
        if (mounted) {
          setState(() {
            _playbackSpeed = rate;
          });
        }
      }),
      _player.stream.error.listen((error) {
        if (mounted) {
          setState(() {
            _errorMessage = error.toString();
          });
        }
      }),
    ];
  }

  @override
  void didUpdateWidget(CustomVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.externalPlayer != oldWidget.externalPlayer || 
        widget.videoUrl != oldWidget.videoUrl) {
      if (oldWidget.externalPlayer == null && widget.externalPlayer == null) {
        // Both use internal player, re-open media if URL changed
        if (widget.videoUrl != oldWidget.videoUrl) {
          final optimizedUrl = _getOptimizedUrl(widget.videoUrl!);
          _player.open(Media(optimizedUrl));
        }
      } else {
        // Switching between internal/external or external changed, full re-init
        _disposeInternalPlayer();
        _initPlayer();
      }
    }
  }

  void _disposeInternalPlayer() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    _subscriptions = [];
    if (widget.externalPlayer == null) {
      _player.dispose();
    }
  }

  @override
  void dispose() {
    _disposeInternalPlayer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        body: _buildVideoPlayer(),
      );
    }
    return _buildVideoPlayer();
  }

  Widget _buildVideoPlayer() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showControls = !_showControls;
        });
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: Video(controller: _videoController),
          ),
          if (_errorMessage != null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 50),
                  const SizedBox(height: 10),
                  Text(
                    'Playback Error: $_errorMessage',
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          if (_isBuffering && _errorMessage == null)
            const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryGreen,
              ),
            ),
          if (!_isPlaying && !_showControls && !_isBuffering)
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
          if (_showControls) _buildVideoControls(),
        ],
      ),
    );
  }

  Widget _buildVideoControls() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black54,
          ],
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Progress bar
          Row(
            children: [
              Text(
                _formatDuration(_position),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                    activeTrackColor: AppTheme.primaryGreen,
                    inactiveTrackColor: Colors.white24,
                    thumbColor: AppTheme.primaryGreen,
                  ),
                  child: Slider(
                    value: _position.inMilliseconds.toDouble().clamp(0, _duration.inMilliseconds.toDouble()),
                    min: 0,
                    max: _duration.inMilliseconds.toDouble(),
                    onChanged: (value) {
                      _player.seek(Duration(milliseconds: value.toInt()));
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _formatDuration(_duration),
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.replay_10, color: Colors.white, size: 30),
                onPressed: () => _seekBackward(10),
              ),
              const SizedBox(width: 20),
              Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: IconButton(
                  icon: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: AppTheme.primaryGreen,
                    size: 40,
                  ),
                  onPressed: _togglePlayPause,
                ),
              ),
              const SizedBox(width: 20),
              IconButton(
                icon: const Icon(Icons.forward_10, color: Colors.white, size: 30),
                onPressed: () => _seekForward(10),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Volume and speed controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(
                  _volume == 0 ? Icons.volume_off : Icons.volume_up,
                  color: Colors.white,
                ),
                onPressed: _toggleMute,
              ),
              Text(
                '${(_volume * 100).toInt()}%',
                style: const TextStyle(color: Colors.white),
              ),
              IconButton(
                icon: const Icon(Icons.speed, color: Colors.white),
                onPressed: _showPlaybackSpeedDialog,
              ),
              Text(
                '${_playbackSpeed}x',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _togglePlayPause() {
    _player.playOrPause();
  }

  void _toggleMute() {
    setState(() {
      _volume = _volume == 0 ? 1.0 : 0.0;
      _player.setVolume(_volume * 100);
    });
  }

  void _toggleFullscreen() {
    // media_kit handles fullscreen via VideoController
  }

  void _seekForward(int seconds) {
    _player.seek(_position + Duration(seconds: seconds));
  }

  void _seekBackward(int seconds) {
    _player.seek(_position - Duration(seconds: seconds));
  }

  void _showPlaybackSpeedDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Playback Speed',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ...[0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((speed) => ListTile(
              title: Text('${speed}x'),
              trailing: _playbackSpeed == speed
                  ? const Icon(Icons.check, color: AppTheme.primaryGreen)
                  : null,
              onTap: () {
                setState(() {
                  _playbackSpeed = speed;
                  _player.setRate(speed);
                });
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
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
