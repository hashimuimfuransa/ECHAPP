import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
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
import 'package:excellencecoachinghub/widgets/student_guide_widget.dart';
import 'package:excellencecoachinghub/widgets/ai_chat_dialog.dart';
import 'package:excellencecoachinghub/services/ai_chat_service.dart';
import 'package:excellencecoachinghub/presentation/widgets/video_player/custom_video_player.dart';
import 'dart:io';

import 'package:excellencecoachinghub/presentation/providers/course_provider.dart';
import 'package:excellencecoachinghub/models/certificate.dart';
import 'package:excellencecoachinghub/presentation/providers/download_provider.dart';
import 'package:url_launcher/url_launcher.dart';

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
  final GlobalKey<StudentGuideWidgetState> _guideKey = GlobalKey<StudentGuideWidgetState>();
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

  // AI Chat state
  bool _isChatExpanded = false;
  final RealAIChatService _aiChatService = RealAIChatService();
  final String _conversationId = 'conversation_${DateTime.now().millisecondsSinceEpoch}';

  // Summarization and TTS state
  bool _isSummarizing = false;
  String? _notesSummary;
  bool _showSummary = false;
  bool _isReading = false;
  final FlutterTts _flutterTts = FlutterTts();
  bool _showPdfNotes = false; // Toggle between organized and PDF notes

  @override
  void initState() {
    super.initState();
    _loadData();
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      
      // Platform optimizations for mobile speed and reliability
      if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android)) {
        await _flutterTts.setSharedInstance(true);
        if (defaultTargetPlatform == TargetPlatform.iOS) {
          await _flutterTts.setIosAudioCategory(IosTextToSpeechAudioCategory.playback, [
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
            IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
            IosTextToSpeechAudioCategoryOptions.mixWithOthers,
            IosTextToSpeechAudioCategoryOptions.defaultToSpeaker
          ]);
        }
      }
      
      _flutterTts.setCompletionHandler(() {
        if (mounted) setState(() => _isReading = false);
      });
      
      _flutterTts.setErrorHandler((msg) {
        print('TTS Error: $msg');
        if (mounted) setState(() => _isReading = false);
      });
    } catch (e) {
      print('TTS Init Error: $e');
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _player?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(LessonViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.lesson.id != oldWidget.lesson.id) {
      if (_isReading) {
        _flutterTts.stop();
        _isReading = false;
      }
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _hasError = false;
      _sectionsLoading = true;
      _examsLoading = true;
      _notesSummary = null;
      _showSummary = false;
    });

    try {
      // 1. PRIORITIZE: Load lesson content (notes) FIRST for instant display
      // This is the most important content for the user
      _lessonContent = await ref.read(lessonContentProvider(widget.lesson.id).future);
      
      if (mounted) {
        setState(() {
          _isLoading = false; // Show notes immediately!
        });
      }

      // 2. Load all other data in parallel in the background
      final results = await Future.wait([
        ref.read(courseContentProvider(widget.courseId).future),
        ref.read(lessonExamsProvider(widget.lesson.sectionId).future),
        _sectionService.getSectionsByCourse(widget.courseId),
      ]);

      final courseContent = results[0] as Map<String, dynamic>;
      _sectionExams = results[1] as List<exam_model.Exam>;
      _courseSections = results[2] as List<Section>;

      // Process course lessons from course content
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

      // PRE-FETCH: Now that we have courseLessons, pre-fetch next lesson
      final nextLesson = _getNextLesson();
      if (nextLesson != null) {
        ref.read(lessonContentProvider(nextLesson.id).future);
        ref.read(lessonExamsProvider(nextLesson.sectionId).future);
      }

      // Initialize video player if needed (already in background)
      if (_lessonContent?.videoUrl != null && _lessonContent!.videoUrl!.isNotEmpty) {
        _initializeVideoPlayer(_lessonContent!.videoUrl!).catchError((e) {
          print('Warning: Video player initialization failed: $e');
        });
      }

      if (mounted) {
        setState(() {
          _sectionsLoading = false;
          _examsLoading = false;
        });

        // Show welcome message from AI coach
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && _guideKey.currentState != null) {
            _guideKey.currentState!.updateState(
              StudentGuideState.greeting,
              message: "I'm here to help with this lesson on ${widget.lesson.title}! Need a summary or explanation? Just ask! 👋",
            );
          }
        });
      }
    } catch (e) {
      print('Error loading lesson data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _sectionsLoading = false;
          _examsLoading = false;
          _hasError = _lessonContent == null; // Only show error if we couldn't even load notes
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _summarizeNotes() async {
    if (_lessonContent?.notes == null || _lessonContent!.notes!.isEmpty) return;
    
    if (_notesSummary != null) {
      setState(() => _showSummary = !_showSummary);
      return;
    }

    setState(() => _isSummarizing = true);

    try {
      final contextObj = AIChatContext(
        currentLesson: widget.lesson.copyWith(notes: _lessonContent!.notes),
        allSections: widget.allSections ?? _courseSections,
        sectionLessons: widget.sectionLessons ?? _getSectionLessonsMap(),
      );

      final response = await _aiChatService.sendMessage(
        _conversationId,
        "Please provide a concise and clear summary of these lesson notes. Focus on the key takeaways and main concepts. Use bullet points for readability. DO NOT include any introductory or concluding remarks, just the summary itself.",
        contextObj,
      );

      if (mounted) {
        setState(() {
          _isSummarizing = false;
          _notesSummary = response.message;
          _showSummary = true;
        });
        
        // Also show a brief notification that it's ready
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI Summary generated!'),
            duration: Duration(seconds: 2),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSummarizing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate summary: $e')),
        );
      }
    }
  }

  Future<void> _toggleVoiceReader() async {
    if (_lessonContent?.notes == null || _lessonContent!.notes!.isEmpty) return;

    if (_isReading) {
      await _flutterTts.stop();
      if (mounted) setState(() => _isReading = false);
    } else {
      // Clean up markdown efficiently for faster TTS start
      final String rawNotes = _lessonContent!.notes!;
      
      // Use efficient cleaning to avoid blocking UI
      String cleanText = rawNotes
          .replaceAll(RegExp(r'#+\s*'), '') 
          .replaceAll(RegExp(r'[\*\-_]'), '') 
          .replaceAll(RegExp(r'!\[.*?\]\(.*?\)|\[.*?\]\(.*?\)') , '') 
          .trim();

      if (cleanText.isEmpty) return;

      setState(() => _isReading = true);
      
      // Execute speak without awaiting to keep the button responsive
      _flutterTts.speak(cleanText).then((_) {
        // Started successfully
      }).catchError((e) {
        if (mounted) setState(() => _isReading = false);
        print("TTS Speak Error: $e");
      });
    }
  }

  String _getWindowsOptimizedUrl(String url) {
    String processedUrl = url;
    
    // Convert S3 URL to CloudFront URL and ensure HTTPS
    if (processedUrl.contains('echcoahing.s3.amazonaws.com')) {
      processedUrl = processedUrl.replaceFirst('echcoahing.s3.amazonaws.com', 'd3ofk5ujo941v.cloudfront.net');
    }

    // Ensure it always uses HTTPS for network URLs
    if (processedUrl.startsWith('http://')) {
      processedUrl = processedUrl.replaceFirst('http://', 'https://');
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows && !processedUrl.contains('type=.mp4') && !processedUrl.toLowerCase().contains('.mp4')) {
      return processedUrl.contains('?') ? '$processedUrl&type=.mp4' : '$processedUrl?type=.mp4';
    }
    return processedUrl;
  }

  Future<void> _initializeVideoPlayer(String videoUrl) async {
    // Better Player on Android/Web handles its own initialization within CustomVideoPlayer
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    try {
      if (_player != null) {
        await _player!.dispose();
        _player = null;
      }
      
      final optimizedUrl = _getWindowsOptimizedUrl(videoUrl);
      final downloadService = ref.read(downloadServiceProvider);
      String? localPath = await downloadService.getLocalVideoPathById(widget.lesson.id);
      
      _player = Player(configuration: const PlayerConfiguration(
        bufferSize: 32 * 1024 * 1024,
      ));
      
      if (mounted) setState(() {});
      
      _player!.stream.error.listen((error) {
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = 'Playback error: $error';
          });
        }
      });
      
      if (!mounted) return;
      
      if (localPath != null) {
        final path = (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) ? localPath.replaceAll('/', '\\') : localPath;
        _player!.open(Media(path));
      } else {
        _player!.open(Media(optimizedUrl));
      }
    } catch (e) {
      if (mounted) setState(() { _hasError = true; });
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
                ElevatedButton(onPressed: _loadData, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.white), child: const Text('Retry')),
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
                if ((_lessonContent?.notes != null && _lessonContent!.notes!.isNotEmpty) || 
                    (_lessonContent?.notesPdfUrl != null && _lessonContent!.notesPdfUrl!.isNotEmpty))
                  _buildNotesContent(),
                if (_sectionExams != null && _sectionExams!.isNotEmpty)
                  _buildExamsSection(),
                _buildNextLessonNavigation(),
                SizedBox(height: MediaQuery.of(context).size.width < 600 ? 100 : 250), // Space for AI button
              ],
            ),
          ),
          // Student Guide Character + AI integration
          Positioned(
            bottom: 20,
            right: 20,
            child: StudentGuideWidget(
              key: _guideKey,
              initialState: StudentGuideState.greeting,
              config: const GuideConfig(
                character: GuideCharacter.guide,
                isAiMode: true, // Enable AI features (glow, etc)
              ),
              message: 'How can I help you with this lesson?',
              autoDismiss: false,
              onTap: () {
                setState(() {
                  _isChatExpanded = !_isChatExpanded;
                });
              },
            ),
          ),

          // AI Chat overlay (appears when expanded)
          if (_isChatExpanded)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _isChatExpanded = false), // Close when tapping outside
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Center(
                    child: GestureDetector(
                      onTap: () {}, // Prevent closing when tapping on dialog
                      child: ModernAIChatDialog(
                        currentCourse: null, // LessonViewer doesn't have course object easily accessible, passing null is fine
                        currentLesson: widget.lesson.copyWith(
                          notes: _lessonContent?.notes,
                        ),
                        allSections: widget.allSections ?? _courseSections,
                        sectionLessons: widget.sectionLessons ?? _getSectionLessonsMap(),
                        chatService: _aiChatService,
                        conversationId: _conversationId,
                        guideKey: _guideKey,
                        onClose: () => setState(() => _isChatExpanded = false),
                      ),
                    ),
                  ),
                ),
              ),
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
              child: (kIsWeb || defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: CustomVideoPlayer(
                        videoId: widget.lesson.id,
                        videoUrl: _lessonContent!.videoUrl,
                        title: widget.lesson.title,
                        description: widget.lesson.description ?? '',
                      ),
                    )
                  : _player != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: CustomVideoPlayer(
                            videoId: widget.lesson.id,
                            externalPlayer: _player,
                            title: widget.lesson.title,
                            description: widget.lesson.description ?? '',
                          ),
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
        border: Border.all(color: (status == DownloadStatus.failed ? Colors.red : AppTheme.primaryGreen).withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                status == DownloadStatus.completed ? Icons.check_circle : Icons.cloud_download, 
                color: status == DownloadStatus.failed ? Colors.red : AppTheme.primaryGreen, 
                size: 20
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status == DownloadStatus.completed 
                          ? 'Available Offline' 
                          : status == DownloadStatus.failed 
                              ? 'Download Failed' 
                              : isDownloading 
                                  ? 'Downloading...' 
                                  : status == DownloadStatus.paused 
                                      ? 'Download Paused' 
                                      : 'Download for Offline Study',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    if (isDownloading || status == DownloadStatus.paused || status == DownloadStatus.failed)
                      Text(
                        status == DownloadStatus.failed 
                            ? 'Tap to try again' 
                            : '${(max(0, progress) * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 11, 
                          color: (status == DownloadStatus.failed ? Colors.red : AppTheme.primaryGreen).withOpacity(0.7)
                        ),
                      ),
                  ],
                ),
              ),
              if (status == DownloadStatus.completed)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton.icon(
                      onPressed: () => context.go('/downloads'),
                      icon: const Icon(Icons.folder_open, size: 18, color: AppTheme.primaryGreen),
                      label: const Text('View in Downloads', style: TextStyle(color: AppTheme.primaryGreen, fontSize: 12)),
                    ),
                    IconButton(
                      onPressed: () => _confirmDeleteDownload(downloadService),
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      tooltip: 'Delete download',
                    ),
                  ],
                )
              else if (isDownloading)
                IconButton(
                  onPressed: () => downloadService.pauseDownload(widget.lesson.id),
                  icon: const Icon(Icons.pause_circle_outline, color: AppTheme.primaryGreen, size: 24),
                  tooltip: 'Pause',
                )
              else if (status == DownloadStatus.paused || status == DownloadStatus.failed)
                IconButton(
                  onPressed: () => downloadService.resumeDownload(widget.lesson.id),
                  icon: Icon(
                    status == DownloadStatus.failed ? Icons.refresh : Icons.play_circle_outline, 
                    color: status == DownloadStatus.failed ? Colors.red : AppTheme.primaryGreen, 
                    size: 24
                  ),
                  tooltip: status == DownloadStatus.failed ? 'Retry' : 'Resume',
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
          if (isDownloading || status == DownloadStatus.paused || status == DownloadStatus.failed) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress < 0 ? null : progress,
                backgroundColor: (status == DownloadStatus.failed ? Colors.red : AppTheme.primaryGreen).withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(status == DownloadStatus.failed ? Colors.red : AppTheme.primaryGreen),
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

  void _parseNotesSections(String notes) {
    if (notes.isEmpty) {
      _notesSections = [];
      return;
    }
    
    final sections = <NotesSection>[];
    final lines = notes.split('\n');
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.startsWith('## ')) {
        sections.add(NotesSection(
          id: 'section_$i',
          title: line.substring(3).trim(),
          level: 2,
          lineNumber: i,
        ));
      } else if (line.startsWith('# ')) {
        sections.add(NotesSection(
          id: 'section_$i',
          title: line.substring(2).trim(),
          level: 1,
          lineNumber: i,
        ));
      }
    }
    
    _notesSections = sections;
  }

  Widget _buildNotesContent() {
    if (_lessonContent == null) return const SizedBox.shrink();
    
    bool hasOrganized = _lessonContent!.notes != null && _lessonContent!.notes!.isNotEmpty && 
                       !(_lessonContent!.notes!.contains('documents/') || _lessonContent!.notes!.contains('.pdf'));
    bool hasPdf = _lessonContent!.notesPdfUrl != null && _lessonContent!.notesPdfUrl!.isNotEmpty;
    
    // If we only have PDF, force PDF view
    if (!hasOrganized && hasPdf) {
      _showPdfNotes = true;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8), 
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.1), 
                borderRadius: BorderRadius.circular(10),
              ), 
              child: const Icon(Icons.description_outlined, color: AppTheme.accent, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Lesson Notes', 
              style: TextStyle(
                fontSize: 20, 
                fontWeight: FontWeight.w800, 
                color: AppTheme.getTextColor(context), 
                letterSpacing: -0.5,
              ),
            ),
            const Spacer(),
            if (hasOrganized && !_showPdfNotes) ...[
              // AI Summary Button
              _buildActionButton(
                onPressed: _summarizeNotes,
                icon: Icons.auto_awesome,
                label: _notesSummary != null ? (_showSummary ? 'Hide Summary' : 'View Summary') : 'Summarize',
                color: AppTheme.primaryGreen,
                isLoading: _isSummarizing,
              ),
              const SizedBox(width: 8),
              // Voice Reader Button
              _buildActionButton(
                onPressed: _toggleVoiceReader,
                icon: _isReading ? Icons.stop_circle : Icons.volume_up,
                label: _isReading ? 'Stop' : 'Read',
                color: Colors.orange,
                isSecondary: true,
              ),
            ],
          ],
        ),
        const SizedBox(height: 15),
        
        // Toggle between Organized and PDF if both exist
        if (hasOrganized && hasPdf)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              children: [
                _buildToggleButton(
                  isSelected: !_showPdfNotes,
                  onPressed: () => setState(() => _showPdfNotes = false),
                  icon: Icons.format_align_left,
                  label: 'Organized Notes',
                ),
                const SizedBox(width: 12),
                _buildToggleButton(
                  isSelected: _showPdfNotes,
                  onPressed: () => setState(() => _showPdfNotes = true),
                  icon: Icons.picture_as_pdf,
                  label: 'Unorganized (PDF)',
                ),
              ],
            ),
          ),

        if (_showPdfNotes && hasPdf)
          _buildPdfNotesView()
        else if (hasOrganized)
          _buildOrganizedNotesView()
        else if (_lessonContent!.notes != null && (_lessonContent!.notes!.contains('documents/') || _lessonContent!.notes!.contains('.pdf')))
          _buildProcessingView()
        else
          const SizedBox.shrink(),
      ],
    );
  }

  Widget _buildToggleButton({
    required bool isSelected,
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryGreen : AppTheme.getCardColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.primaryGreen : AppTheme.borderGrey,
              width: 1.5,
            ),
            boxShadow: isSelected ? [
              BoxShadow(
                color: AppTheme.primaryGreen.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ] : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : AppTheme.greyColor,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : AppTheme.greyColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPdfNotesView() {
    final pdfUrl = _lessonContent!.notesPdfUrl!;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context), 
        borderRadius: BorderRadius.circular(24), 
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04), 
            blurRadius: 20, 
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          const Icon(Icons.picture_as_pdf, color: AppTheme.primaryGreen, size: 64),
          const SizedBox(height: 20),
          const Text(
            'PDF Notes Available',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'This lesson contains the original unorganized notes in PDF format.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.greyColor, fontSize: 15),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              final uri = Uri.parse(pdfUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open PDF Viewer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingView() {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context), 
        borderRadius: BorderRadius.circular(20), 
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.1)),
      ),
      child: const Column(
        children: [
          Icon(Icons.hourglass_empty, color: AppTheme.primaryGreen, size: 32),
          SizedBox(height: 16),
          Text('Notes Processing', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          Text('The notes for this lesson are currently being processed. Please check back later.', style: TextStyle(fontSize: 16, color: AppTheme.greyColor), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildOrganizedNotesView() {
    String notesContent = _lessonContent!.notes ?? '';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AI Summary Section
        if (_showSummary && _notesSummary != null) ...[
          _buildSummaryCard(_notesSummary!),
          const SizedBox(height: 24),
        ],
        
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.getCardColor(context), 
            borderRadius: BorderRadius.circular(24), 
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04), 
                blurRadius: 20, 
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isReading) 
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.record_voice_over, color: Colors.orange, size: 16),
                      const SizedBox(width: 8),
                      const Text(
                        'Reading aloud...', 
                        style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              _buildFormattedNotes(notesContent),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String summary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.1)),
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
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome, color: AppTheme.primaryGreen, size: 18),
              ),
              const SizedBox(width: 12),
              const Text(
                'AI Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => setState(() => _showSummary = false),
                icon: const Icon(Icons.close, size: 20),
                color: AppTheme.primaryGreen.withOpacity(0.5),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen.withOpacity(0.05),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFormattedNotes(summary),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
    bool isLoading = false,
    bool isSecondary = false,
  }) {
    final bool isSmallScreen = MediaQuery.of(context).size.width < 600;
    
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading 
          ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: isSecondary ? color : Colors.white))
          : Icon(icon, size: 18),
      label: isSmallScreen ? const SizedBox.shrink() : Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSecondary ? color.withOpacity(0.1) : color,
        foregroundColor: isSecondary ? color : Colors.white,
        elevation: isSecondary ? 0 : 2,
        padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
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
        children.add(Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 8), 
          child: Text(
            trimmed.substring(3), 
            style: TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.w700, 
              color: AppTheme.getTextColor(context),
              letterSpacing: -0.2,
            ),
          ),
        ));
      } else if (trimmed.startsWith('# ')) {
        children.add(Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 12), 
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                trimmed.substring(2), 
                style: const TextStyle(
                  fontSize: 22, 
                  fontWeight: FontWeight.w800, 
                  color: AppTheme.primaryGreen,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 40,
                height: 3,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ));
      } else if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
        children.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 6), 
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start, 
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryGreen,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12), 
              Expanded(
                child: Text(
                  trimmed.substring(2), 
                  style: TextStyle(
                    fontSize: 16, 
                    height: 1.6, 
                    color: AppTheme.getTextColor(context).withOpacity(0.85),
                  ),
                ),
              ),
            ],
          ),
        ));
      } else if (trimmed.isNotEmpty) {
        children.add(Padding(
          padding: const EdgeInsets.only(bottom: 12), 
          child: Text(
            trimmed, 
            style: TextStyle(
              fontSize: 16, 
              height: 1.7, 
              color: AppTheme.getTextColor(context).withOpacity(0.85),
            ),
          ),
        ));
      } else {
        children.add(const SizedBox(height: 12));
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
