import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/utils/learning_content_optimizer.dart';
import 'package:excellencecoachinghub/models/lesson.dart';
import 'package:excellencecoachinghub/models/course.dart';
import 'package:excellencecoachinghub/models/section.dart';
import 'package:excellencecoachinghub/services/api/section_service.dart';
import 'package:excellencecoachinghub/presentation/providers/enrollment_provider.dart';
import 'package:excellencecoachinghub/widgets/video_player_widget.dart';
import 'package:excellencecoachinghub/widgets/ai_chat_dialog.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';

/// Optimized Lesson Screen with instant loading
class OptimizedLessonScreen extends ConsumerStatefulWidget {
  final String lessonId;
  
  const OptimizedLessonScreen({
    super.key,
    required this.lessonId,
  });

  @override
  ConsumerState<OptimizedLessonScreen> createState() => _OptimizedLessonScreenState();
}

class _OptimizedLessonScreenState extends ConsumerState<OptimizedLessonScreen>
    with TickerProviderStateMixin {
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  final LearningContentOptimizer _optimizer = LearningContentOptimizer();
  final ScrollController _scrollController = ScrollController();
  
  Lesson? _lesson;
  Course? _course;
  Section? _section;
  Lesson? _nextLesson;
  Lesson? _previousLesson;
  bool _isLoading = false;
  bool _isCompleted = false;
  bool _isVideoLoading = false;
  String? _videoError;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations for smooth transitions
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    // Start animations immediately
    _fadeController.forward();
    _slideController.forward();
    
    // Load lesson data instantly
    _loadLessonData();
  }

  Future<void> _loadLessonData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get lesson from route parameters or fetch
      final args = GoRouterState.of(context).extra as Map<String, dynamic>?;
      _lesson = args?['lesson'] as Lesson?;
      _course = args?['course'] as Course?;
      
      // If lesson not provided, fetch it
      if (_lesson == null) {
        _lesson = await _fetchLessonById(widget.lessonId);
      }
      
      if (_lesson != null) {
        // Load related data
        await _loadRelatedData();
        
        // Check completion status
        await _checkCompletionStatus();
        
        // Preload next and previous lessons
        _preloadAdjacentLessons();
      }
    } catch (e) {
      debugPrint('Error loading lesson: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<Lesson?> _fetchLessonById(String lessonId) async {
    try {
      // Try to find in cached sections first
      // This would require extending the optimizer to cache lessons by ID
      final sectionService = SectionService();
      final sectionsData = await sectionService.getAllSections();
      
      for (final sectionData in sectionsData) {
        final lessonsData = await sectionService.getSectionLessons(sectionData['id']);
        if (lessonsData != null) {
          final lessons = lessonsData
              .map((l) => Lesson.fromJson(l as Map<String, dynamic>))
              .toList();
          
          final lesson = lessons.firstWhere(
            (l) => l.id == lessonId,
            orElse: () => lessons.first,
          );
          
          if (lesson.id == lessonId) {
            return lesson;
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching lesson by ID: $e');
    }
    
    return null;
  }

  Future<void> _loadRelatedData() async {
    if (_lesson == null) return;
    
    try {
      // Load course if not provided
      if (_course == null) {
        // Find course containing this lesson
        final sections = _optimizer.getSectionsInstant(_lesson!.courseId);
        if (sections != null) {
          for (final section in sections) {
            final lessons = _optimizer.getLessonsInstant(section.id);
            if (lessons != null && lessons.any((l) => l.id == _lesson!.id)) {
              _section = section;
              _course = _optimizer.getCourseInstant(_lesson!.courseId);
              break;
            }
          }
        }
      }
      
      // Find next and previous lessons
      await _findAdjacentLessons();
    } catch (e) {
      debugPrint('Error loading related data: $e');
    }
  }

  Future<void> _findAdjacentLessons() async {
    if (_section == null || _lesson == null) return;
    
    try {
      final lessons = _optimizer.getLessonsInstant(_section!.id);
      if (lessons != null) {
        final currentIndex = lessons.indexWhere((l) => l.id == _lesson!.id);
        
        if (currentIndex > 0) {
          _previousLesson = lessons[currentIndex - 1];
        }
        
        if (currentIndex < lessons.length - 1) {
          _nextLesson = lessons[currentIndex + 1];
        }
      }
    } catch (e) {
      debugPrint('Error finding adjacent lessons: $e');
    }
  }

  Future<void> _checkCompletionStatus() async {
    if (_lesson == null) return;
    
    try {
      // Check if lesson is completed
      final isCompleted = await ref.read(
        lessonCompletionProvider(_lesson!.id).future,
      );
      
      if (mounted) {
        setState(() {
          _isCompleted = isCompleted;
        });
      }
    } catch (e) {
      debugPrint('Error checking completion status: $e');
    }
  }

  Future<void> _preloadAdjacentLessons() async {
    // Preload next lesson for instant navigation
    if (_nextLesson != null) {
      // Preload video content for next lesson
      debugPrint('Preloading next lesson: ${_nextLesson!.title}');
    }
    
    // Preload previous lesson
    if (_previousLesson != null) {
      debugPrint('Preloading previous lesson: ${_previousLesson!.title}');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }
    
    if (_lesson == null) {
      return _buildErrorScreen();
    }
    
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
          ? const Color(0xFF0F1419) 
          : const Color(0xFFF7F8FC),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: _buildLessonContent(),
              ),
            ),
          ),
          _buildNavigationSliver(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
          ? const Color(0xFF0F1419) 
          : const Color(0xFFF7F8FC),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: Theme.of(context).brightness == Brightness.dark 
                ? const Color(0xFF0F1419) 
                : const Color(0xFFF7F8FC),
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: Theme.of(context).brightness == Brightness.dark
                      ? [const Color(0xFF1A1F2E), const Color(0xFF111522)]
                      : [const Color(0xFF00C853), const Color(0xFF00897B)],
                ),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _buildLessonSkeleton(),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Video skeleton
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 16),
          // Title skeleton
          Container(
            height: 24,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          // Description skeleton
          Container(
            height: 16,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 16,
            width: 300,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
          ? const Color(0xFF0F1419) 
          : const Color(0xFFF7F8FC),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.grey[600] 
                    : Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Lesson not found',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'The lesson you\'re looking for doesn\'t exist or has been removed.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.grey[400] 
                      : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C853),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
          ? const Color(0xFF0F1419) 
          : const Color(0xFFF7F8FC),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: Theme.of(context).brightness == Brightness.dark
                  ? [const Color(0xFF1A1F2E), const Color(0xFF111522)]
                  : [const Color(0xFF00C853), const Color(0xFF00897B)],
            ),
          ),
          child: Stack(
            children: [
              if (_lesson?.videoUrl != null)
                _buildVideoThumbnail()
              else
                _buildDefaultThumbnail(),
              if (_isCompleted)
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Completed',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _isCompleted ? Icons.check_circle : Icons.check_circle_outline,
            color: _isCompleted ? Colors.green : null,
          ),
          onPressed: _toggleCompletion,
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'ai_chat':
                _openAIChat();
                break;
              case 'report':
                _reportIssue();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'ai_chat',
              child: Row(
                children: [
                  Icon(Icons.chat),
                  SizedBox(width: 8),
                  Text('AI Assistant'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'report',
              child: Row(
                children: [
                  Icon(Icons.report),
                  SizedBox(width: 8),
                  Text('Report Issue'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVideoThumbnail() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        children: [
          if (_lesson!.thumbnail != null)
            Image.network(
              _lesson!.thumbnail!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildDefaultThumbnail();
              },
            )
          else
            _buildDefaultThumbnail(),
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 48,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultThumbnail() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF00C853).withOpacity(0.8),
            const Color(0xFF00897B).withOpacity(0.8),
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.play_circle_outline,
          color: Colors.white,
          size: 64,
        ),
      ),
    );
  }

  Widget _buildLessonContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLessonHeader(),
          const SizedBox(height: 24),
          _buildVideoPlayer(),
          const SizedBox(height: 24),
          _buildLessonDescription(),
          const SizedBox(height: 24),
          _buildLessonMaterials(),
        ],
      ),
    );
  }

  Widget _buildLessonHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _lesson!.title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.schedule,
              size: 16,
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.grey[400] 
                  : Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              _lesson!.duration ?? 'No duration',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.grey[400] 
                    : Colors.grey[600],
              ),
            ),
            if (_section != null) ...[
              const SizedBox(width: 16),
              Icon(
                Icons.folder,
                size: 16,
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.grey[400] 
                    : Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                _section!.title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.grey[400] 
                      : Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildVideoPlayer() {
    if (_lesson!.videoUrl == null) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.grey[800]! 
                : Colors.grey[200]!,
          ),
        ),
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.grey[800] 
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.video_library_outlined,
                  size: 48,
                  color: Colors.grey,
                ),
                SizedBox(height: 8),
                Text(
                  'No video available',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: VideoPlayerWidget(
            videoUrl: _lesson!.videoUrl!,
            autoPlay: false,
            showControls: true,
            onLoadingStateChanged: (isLoading) {
              if (mounted) {
                setState(() {
                  _isVideoLoading = isLoading;
                });
              }
            },
            onError: (error) {
              if (mounted) {
                setState(() {
                  _videoError = error;
                });
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLessonDescription() {
    if (_lesson!.description == null || _lesson!.description!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).brightness == Brightness.dark 
              ? Colors.grey[800]! 
              : Colors.grey[200]!,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lesson Overview',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _lesson!.description!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonMaterials() {
    // TODO: Implement lesson materials section
    return const SizedBox.shrink();
  }

  Widget _buildNavigationSliver() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (_previousLesson != null)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _navigateToLesson(_previousLesson!),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Previous'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black,
                  ),
                ),
              ),
            if (_previousLesson != null && _nextLesson != null)
              const SizedBox(width: 16),
            if (_nextLesson != null)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _navigateToLesson(_nextLesson!),
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Next'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C853),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _toggleCompletion,
      backgroundColor: _isCompleted ? Colors.green : const Color(0xFF00C853),
      foregroundColor: Colors.white,
      icon: Icon(_isCompleted ? Icons.check : Icons.check_circle_outline),
      label: Text(_isCompleted ? 'Completed' : 'Mark Complete'),
    );
  }

  void _navigateToLesson(Lesson lesson) {
    context.push('/lesson/${lesson.id}', extra: {
      'lesson': lesson,
      'course': _course,
    });
  }

  void _toggleCompletion() {
    setState(() {
      _isCompleted = !_isCompleted;
    });
    
    // Update completion status in backend
    ref.read(lessonCompletionProvider(_lesson!.id).notifier).toggle();
  }

  void _openAIChat() {
    showDialog(
      context: context,
      builder: (context) => AIChatDialog(
        context: _lesson?.description ?? '',
      ),
    );
  }

  void _reportIssue() {
    // TODO: Implement issue reporting
  }
}

// Provider for lesson completion status
final lessonCompletionProvider = StateNotifierProvider.family<LessonCompletionNotifier, bool, String>(
  (ref, lessonId) => LessonCompletionNotifier(ref, lessonId),
);

class LessonCompletionNotifier extends StateNotifier<bool> {
  final Ref ref;
  final String lessonId;
  
  LessonCompletionNotifier(this.ref, this.lessonId) : super(false);
  
  Future<void> toggle() async {
    state = !state;
    // TODO: Update backend
  }
}
