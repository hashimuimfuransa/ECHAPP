import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excellence_coaching_hub/models/lesson.dart';
import 'package:excellence_coaching_hub/services/api/video_api_service.dart';
import 'package:excellence_coaching_hub/config/app_theme.dart';

/// Comprehensive lesson viewer that handles both video and notes content
class LessonViewer extends ConsumerStatefulWidget {
  final Lesson lesson;
  final String courseId;
  
  const LessonViewer({
    super.key,
    required this.lesson,
    required this.courseId,
  });

  @override
  ConsumerState<LessonViewer> createState() => _LessonViewerState();
}

class _LessonViewerState extends ConsumerState<LessonViewer> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  LessonContent? _lessonContent;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  final VideoApiService _videoService = VideoApiService();

  @override
  void initState() {
    super.initState();
    _loadLessonContent();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Future<void> _loadLessonContent() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Get lesson content from API
      _lessonContent = await _videoService.getLessonContent(widget.lesson.id);
      
      // If there's video content, initialize video player
      if (_lessonContent?.videoUrl != null && _lessonContent!.videoUrl!.isNotEmpty) {
        await _initializeVideoPlayer(_lessonContent!.videoUrl!);
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _initializeVideoPlayer(String videoUrl) async {
    try {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      await _videoController!.initialize();
      
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: false,
        looping: false,
        aspectRatio: 16 / 9,
        allowFullScreen: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppTheme.primaryGreen,
          handleColor: AppTheme.primaryGreen,
          backgroundColor: AppTheme.borderGrey,
          bufferedColor: AppTheme.greyColor.withOpacity(0.3),
        ),
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(
              color: AppTheme.primaryGreen,
            ),
          ),
        ),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading video',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  errorMessage,
                  style: const TextStyle(
                    color: AppTheme.greyColor,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      print('Error initializing video player: $e');
      // Don't set error state here as we can still show notes
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.surface,
        appBar: AppBar(
          title: Text(widget.lesson.title),
          backgroundColor: AppTheme.primaryGreen,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
        ),
      );
    }

    if (_hasError) {
      return Scaffold(
        backgroundColor: AppTheme.surface,
        appBar: AppBar(
          title: Text(widget.lesson.title),
          backgroundColor: AppTheme.primaryGreen,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Failed to load lesson content',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.blackColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage,
                  style: const TextStyle(
                    color: AppTheme.greyColor,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loadLessonContent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text(widget.lesson.title),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          if (_lessonContent?.videoUrl != null && _lessonContent!.videoUrl!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.video_library),
              onPressed: () {
                // Focus on video content
              },
            ),
          if (_lessonContent?.notes != null && _lessonContent!.notes!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.description),
              onPressed: () {
                // Focus on notes content
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lesson title and info
            _buildLessonHeader(),
            
            const SizedBox(height: 24),
            
            // Video content (if available)
            if (_lessonContent?.videoUrl != null && _lessonContent!.videoUrl!.isNotEmpty)
              _buildVideoContent(),
            
            // Notes content (if available)
            if (_lessonContent?.notes != null && _lessonContent!.notes!.isNotEmpty)
              _buildNotesContent(),
            
            // Empty state if no content
            if ((_lessonContent?.videoUrl == null || _lessonContent!.videoUrl!.isEmpty) &&
                (_lessonContent?.notes == null || _lessonContent!.notes!.isEmpty))
              _buildEmptyContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
                  _lessonContent?.videoUrl != null && _lessonContent!.videoUrl!.isNotEmpty
                      ? Icons.video_library
                      : Icons.description,
                  color: AppTheme.primaryGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.lesson.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.blackColor,
                      ),
                    ),
                    if (widget.lesson.description != null && widget.lesson.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          widget.lesson.description!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.greyColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 16,
                color: AppTheme.greyColor,
              ),
              const SizedBox(width: 4),
              Text(
                '${widget.lesson.duration} minutes',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.greyColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVideoContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: const Text(
            'Video Content',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.blackColor,
            ),
          ),
        ),
        Container(
          height: 250,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _chewieController != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Chewie(controller: _chewieController!),
                )
              : Container(
                  color: Colors.black,
                  child: const Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryGreen),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildNotesContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: const Text(
            'Lesson Notes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.blackColor,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.borderGrey,
              width: 1,
            ),
          ),
          child: Text(
            _lessonContent!.notes!,
            style: const TextStyle(
              fontSize: 16,
              height: 1.6,
              color: AppTheme.blackColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyContent() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.borderGrey,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.info_outline,
            size: 64,
            color: AppTheme.greyColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Content Available',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.blackColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This lesson doesn\'t have any video or notes content yet.',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.greyColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}