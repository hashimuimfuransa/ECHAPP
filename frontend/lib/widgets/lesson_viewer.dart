import 'dart:math';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excellencecoachinghub/models/lesson.dart';
import 'package:excellencecoachinghub/models/section.dart';
import 'package:excellencecoachinghub/services/api/video_api_service.dart';
import 'package:excellencecoachinghub/services/api/section_service.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/services/api/exam_service.dart';
import 'package:excellencecoachinghub/models/exam.dart' as exam_model;
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/services/download_service.dart';
import 'package:excellencecoachinghub/models/download.dart';
import 'package:excellencecoachinghub/widgets/ai_floating_chat_button.dart';
import 'package:excellencecoachinghub/presentation/widgets/video_player/custom_video_player.dart';
import 'dart:io';

import 'package:excellencecoachinghub/models/certificate.dart';
import 'package:excellencecoachinghub/presentation/providers/download_provider.dart';

// Model for notes sections
class NotesSection {
  final String id;
  final String title;
  final int level; // 1 for main sections (#), 2 for subsections (##)
  final int lineNumber;
  
  NotesSection({
    required this.id,
    required this.title,
    required this.level,
    required this.lineNumber,
  });
}

/// Comprehensive lesson viewer that handles both video and notes content
class LessonViewer extends ConsumerStatefulWidget {
  final Lesson lesson;
  final String courseId;
  final List<Section>? allSections;
  final Map<String, List<Lesson>>? sectionLessons;
  final List<Certificate>? certificates;
  final VoidCallback? onComplete;
  
  const LessonViewer({
    super.key,
    required this.lesson,
    required this.courseId,
    this.allSections,
    this.sectionLessons,
    this.certificates,
    this.onComplete,
  });

  @override
  ConsumerState<LessonViewer> createState() => _LessonViewerState();
}

class _LessonViewerState extends ConsumerState<LessonViewer> {
  Player? _player;
  LessonContent? _lessonContent;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  final VideoApiService _videoService = VideoApiService();
  final ExamService _examService = ExamService();
  final SectionService _sectionService = SectionService();
  List<exam_model.Exam>? _sectionExams;
  bool _examsLoading = false;
  final ScrollController _scrollController = ScrollController();
  
  // Section filtering variables
  List<Section> _courseSections = [];
  List<Lesson> _courseLessons = [];
  String? _selectedSectionId;
  bool _sectionsLoading = false;
  
  // Notes section filtering variables
  List<NotesSection> _notesSections = [];
  String? _selectedNotesSection;
  Map<String, double> _sectionPositions = {};

  @override
  void initState() {
    super.initState();
    _loadLessonContent();
    _loadCourseContent();
  }

  @override
  void didUpdateWidget(LessonViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.lesson.id != oldWidget.lesson.id) {
      _loadLessonContent();
      _loadCourseContent();
    }
  }

  @override
  void dispose() {
    _player?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadLessonContent() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      _lessonContent = await _videoService.getLessonContent(widget.lesson.id);
      
      if (_lessonContent?.videoUrl != null && _lessonContent!.videoUrl!.isNotEmpty) {
        try {
          await _initializeVideoPlayer(_lessonContent!.videoUrl!).timeout(const Duration(seconds: 15));
        } catch (e) {
          print('Warning: Video player initialization timed out or failed: $e');
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      _loadSectionExams().timeout(const Duration(seconds: 5)).catchError((e) {
        return null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _loadCourseContent() async {
    setState(() {
      _sectionsLoading = true;
    });

    try {
      _courseSections = await _sectionService.getSectionsByCourse(widget.courseId);
      final courseContent = await _sectionService.getCourseContent(widget.courseId);
      final sectionsData = courseContent['sections'] as List? ?? [];
      
      _courseLessons = [];
      for (var sectionData in sectionsData) {
        if (sectionData is Map<String, dynamic>) {
          final lessonsData = sectionData['lessons'] as List? ?? [];
          for (var lessonData in lessonsData) {
            if (lessonData is Map<String, dynamic>) {
              _courseLessons.add(Lesson.fromJson(lessonData));
            }
          }
        }
      }
      
      _selectedSectionId = widget.lesson.sectionId;
      
      setState(() {
        _sectionsLoading = false;
      });
    } catch (e) {
      setState(() {
        _sectionsLoading = false;
      });
    }
  }

  void _parseNotesSections(String notesContent) {
    _notesSections = [];
    _sectionPositions = {};
    
    if (notesContent.isEmpty) return;
    
    List<String> lines = notesContent.split('\n');
    NotesSection? currentSection;
    
    for (int i = 0; i < lines.length; i++) {
      String line = lines[i].trim();
      
      if (line.startsWith('# ')) {
        String sectionTitle = line.substring(2).trim();
        if (currentSection != null) _notesSections.add(currentSection);
        currentSection = NotesSection(id: 'section_$i', title: sectionTitle, level: 1, lineNumber: i);
      } else if (line.startsWith('## ')) {
        String sectionTitle = line.substring(3).trim();
        if (currentSection != null) _notesSections.add(currentSection);
        currentSection = NotesSection(id: 'subsection_$i', title: sectionTitle, level: 2, lineNumber: i);
      }
    }
    
    if (currentSection != null) _notesSections.add(currentSection);
  }

  Future<void> _loadSectionExams() async {
    try {
      _sectionExams = await _examService.getExamsBySection(widget.lesson.sectionId);
      setState(() {
        _examsLoading = false;
      });
    } catch (e) {
      setState(() {
        _examsLoading = false;
      });
    }
  }

  String _getWindowsOptimizedUrl(String url) {
    if (Platform.isWindows && !url.contains('type=.mp4') && !url.toLowerCase().contains('.mp4')) {
      return url.contains('?') ? '$url&type=.mp4' : '$url?type=.mp4';
    }
    return url;
  }

  Future<void> _initializeVideoPlayer(String videoUrl) async {
    try {
      if (_player != null) {
        await _player!.dispose();
        _player = null;
      }
      
      final optimizedUrl = _getWindowsOptimizedUrl(videoUrl);
      final downloadService = ref.read(downloadServiceProvider);
      String? localPath = await downloadService.getLocalVideoPathById(widget.lesson.id);
      
      _player = Player(configuration: const PlayerConfiguration(bufferSize: 64 * 1024 * 1024));
      
      if (mounted) setState(() {});
      
      _player!.stream.error.listen((error) {
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = 'Playback error: $error';
          });
        }
      });
      
      if (localPath != null) {
        final path = Platform.isWindows ? localPath.replaceAll('/', '\\') : localPath;
        _player!.open(Media(path));
      } else {
        _player!.open(Media(optimizedUrl));
      }
    } catch (e) {
      setState(() { _hasError = true; });
    }
  }

  Map<String, List<Lesson>> _getSectionLessonsMap() {
    final map = <String, List<Lesson>>{};
    for (var lesson in _courseLessons) {
      if (!map.containsKey(lesson.sectionId)) {
        map[lesson.sectionId] = [];
      }
      map[lesson.sectionId]!.add(lesson);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.surface,
        appBar: AppBar(title: Text(widget.lesson.title), backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.white),
        body: const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
      );
    }

    if (_hasError) {
      return Scaffold(
        backgroundColor: AppTheme.surface,
        appBar: AppBar(title: Text(widget.lesson.title), backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.white),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                const Text('Failed to load lesson content', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(_errorMessage, style: const TextStyle(color: AppTheme.greyColor, fontSize: 14), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ElevatedButton(onPressed: _loadLessonContent, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.white), child: const Text('Retry')),
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
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLessonHeader(),
                const SizedBox(height: 32),
                if (_lessonContent?.videoUrl != null && _lessonContent!.videoUrl!.isNotEmpty)
                  _buildVideoContent(),
                if (_lessonContent?.notes != null && _lessonContent!.notes!.isNotEmpty)
                  _buildNotesContent(),
                if (_sectionExams != null && _sectionExams!.isNotEmpty)
                  _buildExamsSection(),
                _buildNextLessonNavigation(),
                const SizedBox(height: 80), // Space for AI button
              ],
            ),
          ),
          AIFloatingChatButton(
            currentLesson: widget.lesson,
            currentCourse: null,
            allSections: widget.allSections ?? _courseSections,
            sectionLessons: widget.sectionLessons ?? _getSectionLessonsMap(),
          ),
        ],
      ),
    );
  }

  Lesson? _getNextLesson() {
    if (_courseLessons.isEmpty) return null;
    final currentIndex = _courseLessons.indexWhere((l) => l.id == widget.lesson.id);
    if (currentIndex != -1 && currentIndex < _courseLessons.length - 1) {
      return _courseLessons[currentIndex + 1];
    }
    return null;
  }

  Widget _buildNextLessonNavigation() {
    final nextLesson = _getNextLesson();
    if (nextLesson == null) {
      return Container(
        margin: const EdgeInsets.only(top: 40, bottom: 20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.primaryGreen.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            const Icon(Icons.emoji_events_outlined, color: AppTheme.primaryGreen, size: 48),
            const SizedBox(height: 16),
            const Text('Congratulations!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
            const SizedBox(height: 8),
            const Text('You have reached the end of the course content.', style: TextStyle(fontSize: 15, color: AppTheme.greyColor), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (widget.onComplete != null) widget.onComplete!();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Back to Course Page', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 40, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Up Next', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.greyColor)),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => _navigateToNextLesson(nextLesson),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.getCardColor(context),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppTheme.primaryGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: Icon(nextLesson.videoId != null ? Icons.play_circle_fill : Icons.article, color: AppTheme.primaryGreen),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(nextLesson.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('${nextLesson.duration} minutes', style: TextStyle(fontSize: 13, color: AppTheme.greyColor)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.primaryGreen),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _navigateToNextLesson(nextLesson),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: const Text('Complete & Next Lesson', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToNextLesson(Lesson nextLesson) {
    if (widget.onComplete != null) widget.onComplete!();
    
    // Replace current route with next lesson
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => LessonViewer(
          lesson: nextLesson,
          courseId: widget.courseId,
          certificates: widget.certificates,
          onComplete: widget.onComplete,
        ),
      ),
    );
  }

  Widget _buildLessonHeader() {
    final bool isVideoLesson = _lessonContent?.videoUrl != null && _lessonContent!.videoUrl!.isNotEmpty;
    final Color lessonTypeColor = isVideoLesson ? AppTheme.primaryGreen : AppTheme.accent;
    final IconData lessonIcon = isVideoLesson ? Icons.play_circle_fill : Icons.article;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: lessonTypeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                child: Icon(lessonIcon, color: lessonTypeColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.lesson.title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.getTextColor(context), letterSpacing: -0.5)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: AppTheme.greyColor.withOpacity(0.7)),
                        const SizedBox(width: 4),
                        Text('${widget.lesson.duration} minutes', style: TextStyle(fontSize: 13, color: AppTheme.greyColor.withOpacity(0.7), fontWeight: FontWeight.w500)),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: lessonTypeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                          child: Text(isVideoLesson ? 'VIDEO' : 'READING', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: lessonTypeColor)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (widget.lesson.description != null && widget.lesson.description!.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Text(widget.lesson.description!, style: TextStyle(fontSize: 15, color: AppTheme.getTextColor(context).withOpacity(0.7), height: 1.6)),
          ],
        ],
      ),
    );
  }

  Widget _buildVideoContent() {
    final downloadService = ref.watch(downloadServiceProvider);
    final download = downloadService.getDownloadStatus(widget.lesson.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            double maxWidth = constraints.maxWidth;
            if (maxWidth <= 0 || maxWidth == double.infinity) maxWidth = MediaQuery.of(context).size.width - 40;
            double height = maxWidth * 9 / 16;
            double maxHeight = maxWidth > 900 ? 550 : 400; 
            if (height > maxHeight) height = maxHeight;
            if (height < 200) height = 200;
            
            return Container(
              height: height,
              width: maxWidth,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: _player != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: CustomVideoPlayer(externalPlayer: _player, title: widget.lesson.title, description: widget.lesson.description ?? ''),
                    )
                  : const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
            );
          },
        ),
        const SizedBox(height: 16),
        _buildDownloadSection(download),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildDownloadSection(Download? download) {
    final downloadService = ref.read(downloadServiceProvider);
    
    bool isDownloading = download?.isDownloading ?? false;
    double progress = download?.downloadProgress ?? 0.0;
    DownloadStatus status = download?.status ?? DownloadStatus.pending;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.download_for_offline_outlined, color: AppTheme.primaryGreen, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status == DownloadStatus.completed 
                          ? 'Downloaded' 
                          : status == DownloadStatus.paused 
                              ? 'Download Paused'
                              : isDownloading 
                                  ? 'Downloading...' 
                                  : 'Available for offline viewing',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                    ),
                    if (isDownloading || status == DownloadStatus.paused)
                      Text(
                        '${(progress * 100).toStringAsFixed(1)}%',
                        style: TextStyle(fontSize: 11, color: AppTheme.primaryGreen.withOpacity(0.7)),
                      ),
                  ],
                ),
              ),
              if (status == DownloadStatus.completed)
                IconButton(
                  onPressed: () => _confirmDeleteDownload(downloadService),
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  tooltip: 'Delete download',
                )
              else if (isDownloading)
                IconButton(
                  onPressed: () => downloadService.pauseDownload(widget.lesson.id),
                  icon: const Icon(Icons.pause_circle_outline, color: AppTheme.primaryGreen, size: 24),
                  tooltip: 'Pause',
                )
              else if (status == DownloadStatus.paused)
                IconButton(
                  onPressed: () => downloadService.resumeDownload(widget.lesson.id),
                  icon: const Icon(Icons.play_circle_outline, color: AppTheme.primaryGreen, size: 24),
                  tooltip: 'Resume',
                )
              else
                TextButton.icon(
                  onPressed: _downloadVideo,
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Download'),
                  style: TextButton.styleFrom(foregroundColor: AppTheme.primaryGreen),
                ),
            ],
          ),
          if (isDownloading || status == DownloadStatus.paused) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                minHeight: 4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _confirmDeleteDownload(DownloadService downloadService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Download'),
        content: const Text('Are you sure you want to delete this video from your device?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              downloadService.deleteDownload(widget.lesson.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesContent() {
    String notesContent = _lessonContent!.notes ?? '';
    _parseNotesSections(notesContent);
    
    if (notesContent.contains('documents/') || notesContent.contains('.pdf') || notesContent.contains('.doc')) {
      return Container(
        margin: const EdgeInsets.only(top: 24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: AppTheme.getCardColor(context), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.1))),
        child: Column(
          children: [
            const Icon(Icons.hourglass_empty, color: AppTheme.primaryGreen, size: 32),
            const SizedBox(height: 16),
            const Text('Notes Processing', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('The notes for this lesson are currently being processed. Please check back later.', style: TextStyle(fontSize: 16, color: AppTheme.greyColor), textAlign: TextAlign.center),
          ],
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppTheme.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.description_outlined, color: AppTheme.accent, size: 20)),
            const SizedBox(width: 12),
            Text('Lesson Notes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.getTextColor(context), letterSpacing: -0.5)),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: AppTheme.getCardColor(context), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]),
          child: _buildFormattedNotes(notesContent),
        ),
      ],
    );
  }

  Widget _buildFormattedNotes(String notesContent) {
    if (notesContent.contains('#') || notesContent.contains('* ') || notesContent.contains('- ')) {
      return _buildMarkdownLikeContent(notesContent);
    }
    return SelectableText(notesContent, style: TextStyle(fontSize: 16, height: 1.7, color: AppTheme.getTextColor(context).withOpacity(0.85)));
  }

  Widget _buildMarkdownLikeContent(String content) {
    List<Widget> children = [];
    List<String> lines = content.split('\n');
    for (var line in lines) {
      String trimmed = line.trim();
      if (trimmed.startsWith('## ')) {
        children.add(Padding(padding: const EdgeInsets.only(top: 16, bottom: 8), child: Text(trimmed.substring(3), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.getTextColor(context)))));
      } else if (trimmed.startsWith('# ')) {
        children.add(Padding(padding: const EdgeInsets.only(top: 20, bottom: 12), child: Text(trimmed.substring(2), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen))));
      } else if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
        children.add(Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('• ', style: TextStyle(fontSize: 16, color: AppTheme.primaryGreen)), const SizedBox(width: 8), Expanded(child: Text(trimmed.substring(2), style: TextStyle(fontSize: 16, height: 1.6, color: AppTheme.getTextColor(context).withOpacity(0.85))))])));
      } else if (trimmed.isNotEmpty) {
        children.add(Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(trimmed, style: TextStyle(fontSize: 16, height: 1.6, color: AppTheme.getTextColor(context).withOpacity(0.85)))));
      } else {
        children.add(const SizedBox(height: 8));
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }

  Widget _buildExamsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Row(
          children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.quiz_outlined, color: Colors.blue, size: 20)),
            const SizedBox(width: 12),
            Text('Practice Exams', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.getTextColor(context), letterSpacing: -0.5)),
          ],
        ),
        const SizedBox(height: 20),
        ..._sectionExams!.map((exam) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppTheme.getCardColor(context), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.blue.withOpacity(0.1))),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(exam.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('${exam.questionsCount} Questions • ${exam.type.toUpperCase()}', style: TextStyle(fontSize: 13, color: AppTheme.greyColor.withOpacity(0.8))),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => context.push('/learning/${widget.courseId}/exam/${exam.id}', extra: exam),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: const Text('Start'),
              ),
            ],
          ),
        )),
      ],
    );
  }

  void _downloadVideo() async {
    if (_lessonContent?.videoUrl == null || _lessonContent!.videoUrl!.isEmpty) return;
    
    final downloadService = ref.read(downloadServiceProvider);
    try {
      String sanitizedTitle = _sanitizeFilename(widget.lesson.title);
      await downloadService.downloadVideo(
        url: _lessonContent!.videoUrl!,
        fileName: sanitizedTitle,
        originalTitle: widget.lesson.title,
        lessonId: widget.lesson.id,
      );
    } catch (e) {
      print('Download error: $e');
    }
  }

  String _sanitizeFilename(String filename) {
    return filename.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').replaceAll(RegExp(r'\s+'), '_').trim();
  }
}
