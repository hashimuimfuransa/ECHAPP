import 'dart:math';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excellence_coaching_hub/models/lesson.dart';
import 'package:excellence_coaching_hub/services/api/video_api_service.dart';
import 'package:excellence_coaching_hub/config/app_theme.dart';
import 'package:excellence_coaching_hub/services/api/exam_service.dart';
import 'package:excellence_coaching_hub/models/exam.dart' as exam_model;
import 'package:go_router/go_router.dart';
import 'package:excellence_coaching_hub/services/download_service.dart';
import 'package:excellence_coaching_hub/models/download.dart';
import 'dart:io';

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
  final ExamService _examService = ExamService();
  List<exam_model.Exam>? _sectionExams;
  bool _examsLoading = false;
  final ScrollController _scrollController = ScrollController();
  final DownloadService _downloadService = DownloadService();
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  Download? _currentDownload;

  @override
  void initState() {
    super.initState();
    _loadLessonContent();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadLessonContent() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Get fresh lesson content from API to ensure we have the latest extracted notes
      _lessonContent = await _videoService.getLessonContent(widget.lesson.id);
      
      // If there's video content, initialize video player
      if (_lessonContent?.videoUrl != null && _lessonContent!.videoUrl!.isNotEmpty) {
        await _initializeVideoPlayer(_lessonContent!.videoUrl!);
      }

      // Load exams for the section
      await _loadSectionExams();

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

  // Load exams for the current section
  Future<void> _loadSectionExams() async {
    try {
      _sectionExams = await _examService.getExamsBySection(widget.lesson.sectionId);
      setState(() {
        _examsLoading = false;
      });
    } catch (e) {
      print('Failed to load section exams: $e');
      setState(() {
        _examsLoading = false;
      });
    }
  }

  Future<void> _initializeVideoPlayer(String videoUrl) async {
    try {
      // Check if video is already downloaded locally
      String? localPath = await _downloadService.getLocalVideoPath('lesson_${widget.lesson.id}');
      
      if (localPath != null) {
        // Use local file if available
        _videoController = VideoPlayerController.file(File(localPath));
      } else {
        // Use network URL if not downloaded
        _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      }
      
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
                // Scroll to video content
                _scrollToVideo();
              },
            ),
          if (_lessonContent?.notes != null && _lessonContent!.notes!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.description),
              onPressed: () {
                // Scroll to notes content
                _scrollToNotes();
              },
            ),
          if (_sectionExams != null && _sectionExams!.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.menu_book),
              onSelected: (String value) {
                if (value == 'take-exam') {
                  // Navigate to first exam
                  if (_sectionExams != null && _sectionExams!.isNotEmpty) {
                    context.push('/learning/${widget.courseId}/exam', extra: {'examId': _sectionExams![0].id});
                  }
                }
              },
              itemBuilder: (BuildContext context) {
                return [
                  PopupMenuItem<String>(
                    value: 'take-exam',
                    child: Row(
                      children: [
                        Icon(Icons.quiz, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        const Text('Take Exam'),
                      ],
                    ),
                  ),
                ];
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
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
            
            // Exams section (if available)
            _buildExamsSection(),
            
            // Empty state if no content
            if ((_lessonContent?.videoUrl == null || _lessonContent!.videoUrl!.isEmpty) &&
                (_lessonContent?.notes == null || _lessonContent!.notes!.isEmpty) &&
                (_sectionExams == null || _sectionExams!.isEmpty))
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
          child: Row(
            children: [
              const Text(
                'Video Content',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.blackColor,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.play_circle_fill,
                      size: 14,
                      color: Colors.red[700],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.lesson.duration} min',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            double height = constraints.maxWidth * 9 / 16; // Maintain 16:9 aspect ratio
            if (height > 300) height = 300; // Max height
            return Container(
              height: height,
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
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: AppTheme.primaryGreen),
                            SizedBox(height: 16),
                            Text(
                              'Loading video...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            );
          },
        ),
        const SizedBox(height: 12),
        // Video info section
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: AppTheme.greyColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.lesson.description ?? 'No description available',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.greyColor,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        // Download button section
        if (_lessonContent?.videoUrl != null && _lessonContent!.videoUrl!.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isDownloading 
                          ? null  // Disable button during download
                          : () => _downloadVideo(),
                        icon: _isDownloading 
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                          : const Icon(Icons.download, size: 16),
                        label: Text(_isDownloading ? 'Downloading...' : 'Download Video'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isDownloading ? Colors.grey[600] : AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        // Navigate to downloads screen
                        context.push('/downloads');
                      },
                      icon: const Icon(Icons.download_done),
                      tooltip: 'View Downloads',
                    ),
                  ],
                ),
                if (_isDownloading)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: LinearProgressIndicator(
                      value: _downloadProgress,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildNotesContent() {
    // Parse the organized notes from the content
    String notesContent = _lessonContent!.notes ?? '';
    
    // Debug: Print the notes content to console
    print('DEBUG: Notes content for lesson ${widget.lesson.id}:');
    print('Content length: ${notesContent.length}');
    print('Content preview: ${notesContent.substring(0, min(200, notesContent.length))}');
    
    // Check if content looks like an S3 link
    if (notesContent.contains('documents/') || notesContent.contains('.pdf') || notesContent.contains('.doc')) {
      print('WARNING: Notes still contain S3 document link instead of extracted content');
      // Show a user-friendly message instead of the S3 link
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppTheme.primaryGreen,
                  size: 24,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Notes Processing',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.blackColor,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'The notes for this lesson are currently being processed. Please check back later to see the extracted content.',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: AppTheme.greyColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
    
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
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.05),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _buildFormattedNotes(notesContent),
        ),
      ],
    );
  }

  // Method to build formatted notes with proper organization
  Widget _buildFormattedNotes(String notesContent) {
    // Check if the notes content contains structured data from AI
    if (notesContent.contains('#') || 
        notesContent.contains('##') || 
        notesContent.contains('* ') || 
        notesContent.contains('- ')) {
      // Parse as markdown-like content
      return _buildMarkdownLikeContent(notesContent);
    } else {
      // Regular text content
      return SelectableText(
        notesContent,
        style: const TextStyle(
          fontSize: 16,
          height: 1.6,
          color: AppTheme.blackColor,
        ),
      );
    }
  }

  // Build markdown-like content with headings and lists
  Widget _buildMarkdownLikeContent(String content) {
    List<Widget> children = [];
    List<String> lines = content.split('\n');
    
    for (int i = 0; i < lines.length; i++) {
      String line = lines[i].trim();
      
      if (line.startsWith('## ')) {
        // Subheading
        children.add(
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Text(
              line.substring(3), // Remove '## '
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.blackColor,
              ),
            ),
          ),
        );
      } else if (line.startsWith('# ')) {
        // Main heading
        children.add(
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 12),
            child: Text(
              line.substring(2), // Remove '# '
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryGreen,
              ),
            ),
          ),
        );
      } else if (line.startsWith('- ') || line.startsWith('* ')) {
        // List item
        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '• ',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    line.substring(2), // Remove '- ' or '* '
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: AppTheme.blackColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (line.isNotEmpty) {
        // Regular paragraph
        children.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              line,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
                color: AppTheme.blackColor,
              ),
            ),
          ),
        );
      } else if (line.isEmpty && i < lines.length - 1) {
        // Empty line - add some space
        children.add(const SizedBox(height: 8));
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _buildExamsSection() {
    if (_sectionExams == null || _sectionExams!.isEmpty) {
      return Container();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: const Text(
            'Exams',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.blackColor,
            ),
          ),
        ),
        Column(
          children: _sectionExams!.map((exam) {
            return Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.borderGrey,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.05),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exam.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.blackColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getExamTypeColor(exam.type).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          exam.type.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _getExamTypeColor(exam.type),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${exam.questionsCount} questions',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.greyColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      context.push('/learning/${widget.courseId}/exam', extra: {'examId': exam.id});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Take Exam'),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Helper method to get color based on exam type
  Color _getExamTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'quiz':
        return Colors.blue;
      case 'pastpaper':
        return Colors.orange;
      case 'final':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Scroll to video content section
  void _scrollToVideo() {
    // In a real implementation, we would use GlobalKey to locate the video section
    // For now, just animate to top
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // Scroll to notes content section
  void _scrollToNotes() {
    // In a real implementation, we would use GlobalKey to locate the notes section
    // For now, just animate to top
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // Download video method
  void _downloadVideo() async {
    if (_lessonContent?.videoUrl == null || _lessonContent!.videoUrl!.isEmpty) {
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      await _downloadService.downloadVideo(
        url: _lessonContent!.videoUrl!,
        fileName: 'lesson_${widget.lesson.id}',
        lessonId: widget.lesson.id,
        onProgress: (progress) {
          setState(() {
            _downloadProgress = progress;
          });
        },
        onSuccess: () {
          setState(() {
            _isDownloading = false;
            _currentDownload = _downloadService.getDownloadStatus(widget.lesson.id);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Video downloaded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        },
        onError: (error) {
          setState(() {
            _isDownloading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Download failed: $error'),
              backgroundColor: Colors.red,
            ),
          );
        },
      );
    } catch (e) {
      setState(() {
        _isDownloading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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