import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/services/api/section_service.dart';
import 'package:excellencecoachinghub/models/course.dart';
import 'package:excellencecoachinghub/models/section.dart';
import 'package:excellencecoachinghub/models/lesson.dart';
import 'package:excellencecoachinghub/models/enrollment.dart';
import 'package:excellencecoachinghub/widgets/ai_chat_dialog.dart';
import 'package:excellencecoachinghub/services/ai_chat_service.dart';
import 'package:excellencecoachinghub/presentation/providers/enrollment_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/course_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/payment_riverpod_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/auth_provider.dart';
import 'package:excellencecoachinghub/models/payment.dart';
import 'package:excellencecoachinghub/models/payment_status.dart';
import 'package:excellencecoachinghub/data/repositories/certificate_repository.dart';
import 'package:excellencecoachinghub/models/certificate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:excellencecoachinghub/widgets/student_guide_widget.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:excellencecoachinghub/services/book_service.dart';
import 'package:excellencecoachinghub/presentation/screens/library/book_reader_screen.dart';
import 'package:excellencecoachinghub/services/download_service.dart';
import 'package:excellencecoachinghub/models/download.dart';
import 'package:excellencecoachinghub/services/api/video_api_service.dart';
import 'package:excellencecoachinghub/presentation/providers/download_provider.dart';
import 'package:excellencecoachinghub/services/push_notification_service.dart';
import 'package:excellencecoachinghub/services/live_session_service.dart';
import 'package:excellencecoachinghub/models/live_session.dart';
import 'package:excellencecoachinghub/widgets/live_session_countdown.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:excellencecoachinghub/l10n/app_localizations.dart';

// ─────────────────────────────────────────────
//  Design Tokens
// ─────────────────────────────────────────────
class _DT {
  // Brand
  static const primary    = Color(0xFF00C853);
  static const primaryDim = Color(0xFF00A846);
  static const accent     = Color(0xFF7C4DFF);
  static const accentDim  = Color(0xFF6E35F5);

  // Gradients
  static const List<Color> heroGrad   = [Color(0xFF00C853), Color(0xFF00897B)];
  static const List<Color> darkGrad   = [Color(0xFF1A1F2E), Color(0xFF111522)];
  static const List<Color> purpleGrad = [Color(0xFF7C4DFF), Color(0xFF5C35E0)];

  // Surfaces
  static const bg        = Color(0xFFF7F8FC);
  static const bgDark    = Color(0xFF111522);
  static const card      = Colors.white;
  static const cardDark  = Color(0xFF1C2333);
  static const surface   = Color(0xFFF0F2F8);
  static const surfaceDk = Color(0xFF242C42);

  // Text
  static const textPrimary   = Color(0xFF0D1117);
  static const textSecondary = Color(0xFF6B7280);
  static const textHint      = Color(0xFFADB5BD);
  static const textLight     = Colors.white;

  // Borders
  static const border     = Color(0xFFE5E9F2);
  static const borderDark = Color(0xFF2D3748);

  // Shadows
  static List<BoxShadow> get cardShadow => [
    BoxShadow(color: const Color(0xFF00C853).withOpacity(0.08), blurRadius: 24, offset: const Offset(0, 8)),
    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
  ];
  static List<BoxShadow> get floatShadow => [
    BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 32, offset: const Offset(0, 12)),
  ];

  // Radius
  static const r4  = BorderRadius.all(Radius.circular(4));
  static const r8  = BorderRadius.all(Radius.circular(8));
  static const r12 = BorderRadius.all(Radius.circular(12));
  static const r16 = BorderRadius.all(Radius.circular(16));
  static const r20 = BorderRadius.all(Radius.circular(20));
  static const r24 = BorderRadius.all(Radius.circular(24));
  static const r32 = BorderRadius.all(Radius.circular(32));
}

// ─────────────────────────────────────────────
//  Main Screen
// ─────────────────────────────────────────────
class ProfessionalLearningScreen extends ConsumerStatefulWidget {
  final String courseId;
  const ProfessionalLearningScreen({super.key, required this.courseId});

  @override
  ConsumerState<ProfessionalLearningScreen> createState() =>
      _ProfessionalLearningScreenState();
}

class _ProfessionalLearningScreenState
    extends ConsumerState<ProfessionalLearningScreen>
    with TickerProviderStateMixin<ProfessionalLearningScreen> {

  Course? _course;
  List<Section>? _chapters;
  final Map<String, List<Lesson>> _chapterLessons = {};
  final Map<String, bool> _chapterCompletionStatus = {};
  final Map<String, bool> _chapterUnlockedStatus = {};
  final Map<String, bool> _lessonCompletionStatus = {};
  int _currentSectionIndex = 0;
  bool _isChatExpanded = false;
  bool _isLoading = false;
  final bool _isLoadingChapterDetails = false;
  final GlobalKey<StudentGuideWidgetState> _guideKey = GlobalKey<StudentGuideWidgetState>();
  List<Certificate>? _courseCertificates;
  Map<String, dynamic>? _courseAccessData;

  final TextEditingController _searchController = TextEditingController();
  List<Section>? _filteredChapters;
  bool _isSearchActive = false;
  final RealAIChatService _aiChatService = RealAIChatService();
  final String _conversationId =
      'conversation_${DateTime.now().millisecondsSinceEpoch}';

  int _totalLessons = 0;
  int _completedLessonsCount = 0;
  int _totalDurationMinutes = 0;
  int _completedDurationMinutes = 0;
  int _xpPoints = 0;
  int _completedChaptersCount = 0;
  final Set<String> _celebratedChapters = {};
  String? _markingCompleteChapterId;

  // Library tab state
  List<dynamic> _courseBooks = [];
  bool _isLoadingBooks = false;
  String? _booksError;
  final BookService _bookService = BookService();

  // Saved/Bookmarks tab state
  List<Lesson> _bookmarkedLessons = [];
  bool _bookmarksLoaded = false;

  // Course-wide download state
  bool _isCourseDownloading = false;
  int _courseDownloadTotal = 0;
  int _courseDownloadDone = 0;
  int _courseDownloadFailed = 0;

  late TabController _tabController;
  late AnimationController _heroAnimCtrl;
  late AnimationController _fabAnimCtrl;
  late AnimationController _fabPulseCtrl;
  late Animation<double> _heroFade;
  late Animation<Offset> _heroSlide;
  late Animation<double> _fabScale;
  Animation<double>? _fabPulse;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _liveSessionsTabController = TabController(length: 4, vsync: this);
    _liveSessionsTabController.addListener(() {
      if (mounted) setState(() {});
    });

    _heroAnimCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fabAnimCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fabPulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);

    _heroFade  = CurvedAnimation(parent: _heroAnimCtrl, curve: Curves.easeOut);
    _heroSlide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _heroAnimCtrl, curve: Curves.easeOut));
    _fabScale  = CurvedAnimation(parent: _fabAnimCtrl,  curve: Curves.elasticOut);
    _fabPulse = Tween<double>(begin: 1.0, end: 1.08)
        .animate(CurvedAnimation(parent: _fabPulseCtrl, curve: Curves.easeInOut));

    _searchController.addListener(_onSearchChanged);
    _checkPermissions();
    _loadCourseData();
    _loadCourseBooks();
    _tabController.addListener(() => setState(() {}));

    // Check for live sessions early to determine default tab
    _checkAndSwitchToLiveSessions();
  }

  void _checkPermissions() {
    final authState = ref.read(authProvider);
    final user = authState?.user;
    
    // For students, we'll filter content based on enrollment permissions
    // No need to block the entire screen - just show content from courses they have access to
  }
  
  /// Load live sessions and switch to the Live tab if any exist
  Future<void> _checkAndSwitchToLiveSessions() async {
    await _loadLiveSessions();
    if (mounted && _courseSessions.isNotEmpty) {
      _tabController.animateTo(1);
      // If there are live now sessions, switch to the Live Now sub-tab
      if (_liveNowSessions.isNotEmpty) {
        _liveSessionsTabController.animateTo(0);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _liveSessionsTabController.dispose();
    _heroAnimCtrl.dispose();
    _fabAnimCtrl.dispose();
    _fabPulseCtrl.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ── Data ──────────────────────────────────────
  Future<void> _loadCourseData() async {
    setState(() => _isLoading = true);
    try {
      _course = await ref.read(courseProvider(widget.courseId).future);
      _courseAccessData = await ref
          .read(enrollmentRepositoryProvider)
          .checkCourseAccess(widget.courseId);

      final sectionService = SectionService();
      final courseContent = await sectionService.getCourseContent(widget.courseId);

      try {
        _courseCertificates =
            await CertificateRepository().getCertificatesByCourse(widget.courseId);
      } catch (_) {
        _courseCertificates = [];
      }

      final courseSections =
          courseContent['sections'] ?? courseContent['chapters'];
      debugPrint('Course sections: $courseSections');
      debugPrint('Course sections type: ${courseSections.runtimeType}');
      debugPrint('Course sections is null: ${courseSections == null}');
      debugPrint('Course sections is List: ${courseSections is List}');
      if (courseSections is List) {
        debugPrint('Course sections length: ${(courseSections).length}');
      }

      if (courseSections != null && courseSections is List && courseSections.isNotEmpty) {
        final sectionsData = courseSections;
        _chapters =
            sectionsData.map((s) => Section.fromJson(s as Map<String, dynamic>)).toList();
        _chapters?.sort((a, b) => a.order.compareTo(b.order));

        _totalLessons = 0;
        _totalDurationMinutes = 0;
        _chapterLessons.clear();

        for (final chapterData in sectionsData) {
          final cData = chapterData as Map<String, dynamic>;
          final chapterId = (cData['_id'] ?? cData['id']).toString();
          final lessonsData = cData['lessons'] as List?;
          if (lessonsData != null) {
            // Only keep lessons that have real content (video / notes / quiz / materials)
            final lessons = lessonsData
                .map((l) => Lesson.fromJson(l as Map<String, dynamic>))
                .where((l) => l.hasVideo || l.hasNotes || l.hasQuiz || l.hasMaterials)
                .toList();
            _chapterLessons[chapterId] = lessons;
            _totalLessons += lessons.length;
            for (var l in lessons) {
              _totalDurationMinutes += l.duration;
            }
          }
        }

        // Remove chapters that have no content lessons at all
        // (e.g. sections created only to host live sessions)
        _chapters?.removeWhere((chapter) {
          final lessons = _chapterLessons[chapter.id] ?? [];
          return lessons.isEmpty;
        });
      } else {
        // Set chapters to empty list if sections data is missing or empty
        // This will show the empty state instead of continuous loading
        debugPrint('Setting chapters to empty list - no data available');
        _chapters = [];
      }

      _initializeCompletionStatus();
      _filteredChapters = _chapters;
      
      // Load user payments for this course
      try {
        await ref.read(paymentProvider.notifier).loadUserPayments();
      } catch (e) {
        debugPrint('Error loading user payments: $e');
      }
      
      _heroAnimCtrl.forward();
      _fabAnimCtrl.forward();
    } catch (e) {
      debugPrint('Error loading course data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCourseBooks() async {
    setState(() => _isLoadingBooks = true);
    try {
      _courseBooks = await _bookService.fetchBooksByCourse(widget.courseId);
      setState(() => _booksError = null);
    } catch (e) {
      debugPrint('Error loading course books: $e');
      setState(() => _booksError = e.toString());
    } finally {
      if (mounted) setState(() => _isLoadingBooks = false);
    }
  }

  // ── Mark chapter complete ─────────────────────
  Future<void> _markChapterComplete(Section chapter, int chapterIndex) async {
    if (_celebratedChapters.contains(chapter.id)) return;
    _celebratedChapters.add(chapter.id);
    final lessons = _chapterLessons[chapter.id] ?? [];
    final completedLessons = lessons.where((l) => _lessonCompletionStatus[l.id] == true).length;

    // Require at least one lesson to be completed
    if (completedLessons == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete at least one lesson before marking this chapter as complete.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark Chapter Complete'),
        content: Text(
          'You have completed $completedLessons of ${lessons.length} lessons. Mark this chapter as complete and proceed to the next one?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _DT.primary,
            ),
            child: const Text('Mark Complete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Get enrollmentId from course access data
    final enrollmentId = _courseAccessData?['enrollmentId']?.toString();
    if (enrollmentId == null) {
      debugPrint('Error: No enrollmentId found in course access data');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to mark chapter complete: Enrollment not found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Set loading state
    setState(() => _markingCompleteChapterId = chapter.id);

    // Call backend API to mark section as complete
    try {
      final enrollmentNotifier = ref.read(enrollmentNotifierProvider.notifier);
      await enrollmentNotifier.completeSection(enrollmentId, chapter.id, _course?.id ?? '');
      debugPrint('Successfully marked chapter ${chapter.id} as complete');
    } catch (e) {
      debugPrint('Error marking chapter complete: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark chapter complete: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _markingCompleteChapterId = null);
      return;
    }

    setState(() {
      // Mark all lessons in this chapter as complete
      final chapterLessons = _chapterLessons[chapter.id] ?? [];
      for (var lesson in chapterLessons) {
        _lessonCompletionStatus[lesson.id] = true;
      }
      _completedLessonsCount = _lessonCompletionStatus.values.where((v) => v).length;

      // Mark chapter as complete
      _chapterCompletionStatus[chapter.id] = true;
      _completedChaptersCount = _chapterCompletionStatus.values.where((v) => v).length;

      // Unlock next chapter
      if (_chapters != null && chapterIndex + 1 < _chapters!.length) {
        final nextChapter = _chapters![chapterIndex + 1];
        _chapterUnlockedStatus[nextChapter.id] = true;
        _currentSectionIndex = chapterIndex + 1;
      }

      // XP reward: 100 chapter bonus
      _xpPoints += 100;
      
      // Clear loading state
      _markingCompleteChapterId = null;
    });

    // Send congratulatory push notification
    try {
      await PushNotificationService.sendCongratulatoryNotification(
        'Chapter Complete! 🎉',
        'Congratulations! You completed "${chapter.displayName}"',
      );
      debugPrint('Chapter completion notification sent');
    } catch (e) {
      debugPrint('Error sending chapter completion notification: $e');
    }

    _showChapterCompletionCelebration(chapter, chapterIndex, lessons.length);
  }

  void _showChapterCompletionCelebration(Section chapter, int chapterIndex, int lessonCount) {
    final xpEarned = 100 + (lessonCount * 10);
    final totalChapters = _chapters?.length ?? 1;
    final isLastChapter = chapterIndex + 1 >= totalChapters;
    final nextChapterName = (!isLastChapter && _chapters != null)
        ? _chapters![chapterIndex + 1].displayName
        : null;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'dismiss',
      barrierColor: Colors.black.withOpacity(0.65),
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (ctx, anim, _, child) => ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
        child: FadeTransition(opacity: anim, child: child),
      ),
      pageBuilder: (ctx, _, __) => _ChapterCompletionDialog(
        chapterName: chapter.displayName,
        chapterNumber: chapterIndex + 1,
        xpEarned: xpEarned,
        totalXp: _xpPoints,
        lessonCount: lessonCount,
        isLastChapter: isLastChapter,
        nextChapterName: nextChapterName,
        overallProgress: _progress,
        isDark: _isDark,
        onContinue: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  void _initializeCompletionStatus() {
    if (_chapters == null) return;
    
    // Initialize all chapters as not completed
    for (int i = 0; i < _chapters!.length; i++) {
      _chapterCompletionStatus[_chapters![i].id] = false;
      _chapterUnlockedStatus[_chapters![i].id] = false;
    }
    
    // First chapter is always unlocked
    if (_chapters!.isNotEmpty) {
      _chapterUnlockedStatus[_chapters![0].id] = true;
    }
    
    if (_courseAccessData?['completedLessons'] != null) {
      final completedList = _courseAccessData!['completedLessons'] as List;
      _completedLessonsCount = completedList.length;
      for (var id in completedList) {
        _lessonCompletionStatus[id.toString()] = true;
      }
    }
    
    if (_courseAccessData?['completedSections'] != null) {
      final completedSectionsList =
          _courseAccessData!['completedSections'] as List;
      final completedSet =
          completedSectionsList.map((e) => e.toString()).toSet();
      
      // Mark completed chapters
      for (var id in completedSectionsList) {
        _chapterCompletionStatus[id.toString()] = true;
      }
      
      // Unlock chapters based on completion
      if (_chapters != null) {
        for (int i = 0; i < _chapters!.length; i++) {
          // First chapter is always unlocked
          if (i == 0) {
            _chapterUnlockedStatus[_chapters![i].id] = true;
          }
          // Unlock next chapter if current is completed
          if (completedSet.contains(_chapters![i].id) &&
              i + 1 < _chapters!.length) {
            _chapterUnlockedStatus[_chapters![i + 1].id] = true;
          }
        }
        
        // Find current section index (first incomplete chapter)
        _currentSectionIndex = _chapters!.length - 1;
        for (int i = 0; i < _chapters!.length; i++) {
          if (!completedSet.contains(_chapters![i].id)) {
            _currentSectionIndex = i;
            break;
          }
        }
      }
    }
    
    _completedChaptersCount = _chapterCompletionStatus.values.where((v) => v).length;
    _xpPoints = (_completedLessonsCount * 10) + (_completedChaptersCount * 100);
    // Pre-mark already-completed chapters so no stale celebration fires
    for (final entry in _chapterCompletionStatus.entries) {
      if (entry.value) _celebratedChapters.add(entry.key);
    }
  }

  // ── Search ────────────────────────────────────
  void _onSearchChanged() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      _filteredChapters = q.isEmpty
          ? _chapters
          : _chapters?.where((s) =>
              s.displayName.toLowerCase().contains(q) ||
              (s.description?.toLowerCase().contains(q) ?? false)).toList();
    });
  }

  // ── Helpers ───────────────────────────────────
  double get _progress =>
      _totalLessons > 0 ? _completedLessonsCount / _totalLessons : 0.0;

  bool get _isDark =>
      Theme.of(context).brightness == Brightness.dark;

  Color get _cardBg => _isDark ? _DT.cardDark : _DT.card;

  Color get _surfaceBg => _isDark ? _DT.surfaceDk : _DT.surface;

  Color get _borderColor => _isDark ? _DT.borderDark : _DT.border;

  Color get _textPrimary =>
      _isDark ? Colors.white : _DT.textPrimary;

  Color get _textSecondary => _DT.textSecondary;

  /// Get the user's payment for the current course (if any)
  Payment? _getUserPaymentForCurrentCourse() {
    final userPayments = ref.read(paymentProvider).userPayments;
    try {
      return userPayments.firstWhere(
        (payment) => payment.courseId == widget.courseId,
      );
    } catch (e) {
      return null; // No payment found for this course
    }
  }

  /// Check if user has a completed payment for this course
  bool get _hasPaidForCourse {
    final payment = _getUserPaymentForCurrentCourse();
    return payment != null && 
           (payment.status == PaymentStatus.completed || 
            payment.status == PaymentStatus.approved);
  }

  /// Download invoice for the current course
  Future<void> _downloadInvoice() async {
    final payment = _getUserPaymentForCurrentCourse();
    if (payment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No payment found for this course'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await ref.read(paymentProvider.notifier).downloadInvoice(payment.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invoice saved to Downloads folder'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download invoice: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ─────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isLoading && _course == null) return _buildSplash();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            _isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _isDark ? _DT.bgDark : _DT.bg,
        body: Stack(
          children: [
            _buildBody(),
            if (_isChatExpanded) _buildAIChatOverlay(),
          ],
        ),
        floatingActionButton: _isChatExpanded ? null : _buildAIChatFAB(),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  SPLASH / LOADING
  // ─────────────────────────────────────────────
  Widget _buildSplash() {
    return Scaffold(
      backgroundColor: _isDark ? _DT.bgDark : _DT.bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: _DT.heroGrad),
                borderRadius: _DT.r20,
              ),
              child: const Icon(Icons.school_rounded,
                  color: Colors.white, size: 36),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                color: _DT.primary,
                strokeWidth: 2.5,
              ),
            ),
            const SizedBox(height: 16),
            Text('Loading your course...',
                style: TextStyle(
                  color: _DT.textSecondary,
                  fontSize: 14,
                  letterSpacing: 0.3,
                )),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  CONTENT LOADING STATE (for lazy loading)
  // ─────────────────────────────────────────────
  Widget _buildContentLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              color: _DT.primary,
              strokeWidth: 2.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Please wait, loading content...',
            style: TextStyle(
              color: _DT.textSecondary,
              fontSize: 14,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  BODY (CustomScrollView with SliverAppBar)
  // ─────────────────────────────────────────────
  Widget _buildBody() {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        _buildSliverAppBar(innerBoxIsScrolled),
      ],
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildChaptersTab(),
          _buildLiveSessionsTab(),
          _buildProgressTab(),
          _buildBookmarksTab(),
          _buildMaterialsTab(),
          _buildLibraryTab(),
        ],
      ),
    );
  }

  // ── Sliver App Bar ────────────────────────────
  Widget _buildSliverAppBar(bool innerScrolled) {
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    return SliverAppBar(
      expandedHeight: isMobile ? 280 : 310,
      pinned: true,
      backgroundColor: _isDark ? _DT.bgDark : _DT.bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: _buildBackButton(),
      actions: _buildActions(),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: _buildHeroHeader(),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: _buildTabBar(),
      ),
    );
  }

  Widget _buildBackButton() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: GestureDetector(
        onTap: () => context.canPop() ? context.pop() : context.go('/dashboard'),
        child: Container(
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: _DT.r12,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: _textPrimary),
        ),
      ),
    );
  }

  List<Widget> _buildActions() {
    final actions = [
      // Search toggle
      _ActionChip(
        icon: _isSearchActive ? Icons.close_rounded : Icons.search_rounded,
        active: _isSearchActive,
        isDark: _isDark,
        cardBg: _cardBg,
        onTap: () => setState(() {
          _isSearchActive = !_isSearchActive;
          if (!_isSearchActive) {
            _searchController.clear();
            _filteredChapters = _chapters;
          }
        }),
      ),
      // Invoice download (only if user has paid)
      if (_hasPaidForCourse)
        _ActionChip(
          icon: Icons.download_rounded,
          isDark: _isDark,
          cardBg: _cardBg,
          onTap: _downloadInvoice,
        ),
      // Download whole course
      _ActionChip(
        icon: _isCourseDownloading
            ? Icons.downloading_rounded
            : Icons.download_for_offline_rounded,
        active: _isCourseDownloading,
        isDark: _isDark,
        cardBg: _cardBg,
        onTap: _isCourseDownloading ? null : _downloadWholeCourse,
      ),
      // Exam history
      _ActionChip(
        icon: Icons.history_edu_rounded,
        isDark: _isDark,
        cardBg: _cardBg,
        onTap: () => context.push('/exams/history'),
      ),
      // Refresh
      _ActionChip(
        icon: Icons.refresh_rounded,
        isDark: _isDark,
        cardBg: _cardBg,
        onTap: _refreshData,
      ),
      const SizedBox(width: 8),
    ];
    return actions;
  }

  Widget _buildHeroHeader() {
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    final completedChapters =
        _chapterCompletionStatus.values.where((v) => v).length;

    return SlideTransition(
      position: _heroSlide,
      child: FadeTransition(
        opacity: _heroFade,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Background: thumbnail or fallback gradient ──
            if (_course?.thumbnail != null && _course!.thumbnail!.isNotEmpty)
              Image.network(
                _course!.thumbnail!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF00C853), Color(0xFF00897B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              )
            else
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF00C853), Color(0xFF00897B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            // ── Dark gradient overlay so text is always readable ──
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.55),
                    Colors.black.withOpacity(0.25),
                    Colors.black.withOpacity(0.70),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            // ── Content ──
            SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    isMobile ? 16 : 24, 72, isMobile ? 16 : 24, 20),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Course badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: _DT.r32,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome_rounded,
                            color: Colors.white, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          _course?.level.toUpperCase() ?? 'BEGINNER',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Title
                  Text(
                    _course?.title ?? '',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isMobile ? 18 : 22,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Upcoming sessions warning
                  if (_upcomingSessions.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.schedule, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${_upcomingSessions.length} upcoming session${_upcomingSessions.length > 1 ? 's' : ''}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  // Stats row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _HeroStat(
                                  icon: Icons.library_books_rounded,
                                  value: '$completedChapters/${_chapters?.length ?? 0}',
                                  label: 'Chapters'),
                              const SizedBox(width: 14),
                              _HeroStat(
                                  icon: Icons.play_circle_rounded,
                                  value: '$_completedLessonsCount/$_totalLessons',
                                  label: 'Lessons'),
                              const SizedBox(width: 14),
                              _HeroStat(
                                  icon: Icons.trending_up_rounded,
                                  value: '${(_progress.isFinite ? (_progress * 100).clamp(0, 100) : 0).toInt()}%',
                                  label: 'Done'),
                              const SizedBox(width: 14),
                              _HeroStat(
                                  icon: Icons.bolt_rounded,
                                  value: '$_xpPoints',
                                  label: 'XP'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Mini circular progress
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: _progress,
                              backgroundColor: Colors.white.withOpacity(0.3),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                              strokeWidth: 3.5,
                            ),
                            Text(
                              '${(_progress.isFinite ? (_progress * 100).clamp(0, 100) : 0).toInt()}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: _isDark ? _DT.bgDark : Colors.white,
      child: Column(
        children: [
          // Search bar (expanded when active)
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _isSearchActive
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: _surfaceBg,
                        borderRadius: _DT.r12,
                        border: Border.all(
                            color: _DT.primary.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          Icon(Icons.search_rounded,
                              size: 18, color: _DT.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              autofocus: true,
                              style: TextStyle(
                                  fontSize: 14, color: _textPrimary),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Search chapters or lessons…',
                                hintStyle: TextStyle(
                                    fontSize: 14,
                                    color: _textSecondary),
                                isDense: true,
                              ),
                            ),
                          ),
                          if (_searchController.text.isNotEmpty)
                            IconButton(
                              onPressed: () =>
                                  setState(() => _searchController.clear()),
                              icon: Icon(Icons.close_rounded,
                                  size: 18, color: _textSecondary),
                              padding: EdgeInsets.zero,
                            ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: _DT.primary,
            unselectedLabelColor: _textSecondary,
            indicatorColor: _DT.primary,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.tab,
            labelStyle: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 11),
            unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500, fontSize: 11),
            dividerColor: _borderColor,
            dividerHeight: 0.5,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            tabs: const [
              Tab(icon: Icon(Icons.menu_book_rounded, size: 18), text: 'Chapters'),
              Tab(icon: Icon(Icons.live_tv_rounded, size: 18), text: 'Live'),
              Tab(icon: Icon(Icons.bar_chart_rounded, size: 18), text: 'Progress'),
              Tab(icon: Icon(Icons.bookmark_rounded, size: 18), text: 'Saved'),
              Tab(icon: Icon(Icons.folder_rounded, size: 18), text: 'Materials'),
              Tab(icon: Icon(Icons.local_library_rounded, size: 18), text: 'Library'),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  CHAPTERS TAB
  // ─────────────────────────────────────────────
  Widget _buildChaptersTab() {
    final authState = ref.read(authProvider);
    final user = authState?.user;
    
    // Check if student has chapter access for this course
    if (user != null && user.role == 'student') {
      final userEnrollmentsAsync = ref.read(userEnrollmentsProvider);
      final enrollments = userEnrollmentsAsync.when(
        data: (enrollments) => enrollments,
        loading: () => [],
        error: (_, __) => [],
      );

      final enrollment = enrollments.cast<Enrollment?>().firstWhere(
        (e) => e != null && e.courseId == widget.courseId,
        orElse: () => null,
      );

      // If enrollment exists and doesn't have chapter access, show permission denied
      if (enrollment != null && !enrollment.canAccessChapters) {
        return _buildEmptyState(
          icon: Icons.lock_rounded,
          title: AppLocalizations.of(context)!.noPermissionToAccessChapters,
          subtitle: 'Please contact your administrator for access to course materials',
        );
      }
    }

    final chapters = _filteredChapters ?? _chapters;
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final screenW = MediaQuery.of(context).size.width;

    // Show loading state if:
    // 1. Still loading initial data
    // 2. Chapters is null (lazy loading - data not ready yet)
    if (_isLoading || _chapters == null) {
      return _buildContentLoadingState();
    }

    // At this point, chapters is not null (it's either a list or empty list)
    if (chapters!.isEmpty) {
      return _buildEmptyState(
          icon: Icons.library_books_rounded,
          title: _isSearchActive
              ? 'No chapters match your search'
              : 'No recorded material yet',
          subtitle: _isSearchActive
              ? 'Try a different keyword'
              : 'Check back soon for content');
    }

    return isDesktop && screenW > 1100
        ? _buildChaptersGrid(chapters)
        : _buildChaptersList(chapters);
  }

  Widget _buildChaptersGrid(List<Section> chapters) {
    final screenW = MediaQuery.of(context).size.width;
    final crossCount = screenW > 1600 ? 3 : 2;
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossCount,
        childAspectRatio: 1.7,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),
      itemCount: chapters.length,
      itemBuilder: (ctx, i) {
        final s = chapters[i];
        return _ChapterCard(
          section: s,
          chapterIndex: i,
          lessons: _chapterLessons[s.id] ?? [],
          isUnlocked: _chapterUnlockedStatus[s.id] ?? false,
          isCurrent: i == _currentSectionIndex,
          isChapterCompleted: _chapterCompletionStatus[s.id] ?? false,
          lessonCompletionStatus: _lessonCompletionStatus,
          isDark: _isDark,
          isCompact: true,
          onLessonTap: _openLesson,
          onMoreTap: () => _openChapterDetails(s),
          onMarkComplete: () => _markChapterComplete(s, i),
          isLoading: _markingCompleteChapterId == s.id,
        );
      },
    );
  }

  Widget _buildChaptersList(List<Section> chapters) {
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        ResponsiveBreakpoints.isSmallMobile(context) ? 12 : 16,
        20,
        ResponsiveBreakpoints.isSmallMobile(context) ? 12 : 16,
        120,
      ),
      itemCount: chapters.length,
      separatorBuilder: (_, __) => const SizedBox(height: 20),
      itemBuilder: (ctx, i) {
        final s = chapters[i];
        return _ChapterCard(
          section: s,
          chapterIndex: i,
          lessons: _chapterLessons[s.id] ?? [],
          isUnlocked: _chapterUnlockedStatus[s.id] ?? false,
          isCurrent: i == _currentSectionIndex,
          isChapterCompleted: _chapterCompletionStatus[s.id] ?? false,
          lessonCompletionStatus: _lessonCompletionStatus,
          isDark: _isDark,
          isCompact: false,
          onLessonTap: _openLesson,
          onMoreTap: () => _openChapterDetails(s),
          onMarkComplete: () => _markChapterComplete(s, i),
          isLoading: _markingCompleteChapterId == s.id,
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  //  LIVE SESSIONS TAB
  // ─────────────────────────────────────────────
  List<LiveSession> _courseSessions = [];
  List<LiveSession> _liveNowSessions = [];
  List<LiveSession> _upcomingSessions = [];
  List<LiveSession> _pastSessions = [];
  List<LiveSession> _missedSessions = [];
  bool _isLoadingSessions = false;
  bool _sessionsLoaded = false;
  late TabController _liveSessionsTabController;

  Future<void> _loadLiveSessions() async {
    if (_isLoadingSessions) return;
    setState(() {
      _isLoadingSessions = true;
      _sessionsLoaded = false;
    });
    try {
      final service = LiveSessionService();
      // Load scheduled and live sessions
      final response = await service.getCourseSessions(
        widget.courseId,
        status: 'scheduled',
      );
      if (mounted) {
        final now = DateTime.now();
        final allSessions = response.sessions;

        // Filter into categories
        _liveNowSessions = allSessions.where((s) {
          // Live if status is 'live' OR if scheduled time has passed but session hasn't ended
          final isLive = s.status == 'live';
          final hasStartedAndNotEnded = !s.isEnded && !s.isCancelled &&
              (s.scheduledAt.isBefore(now) || s.scheduledAt.isAtSameMomentAs(now)) &&
              s.calculatedEndTime.isAfter(now);
          return isLive || hasStartedAndNotEnded;
        }).toList();

        _upcomingSessions = allSessions.where((s) {
          // Upcoming if scheduled time is in the future (or within 5 minutes) and not ended/cancelled
          return !s.isEnded && !s.isCancelled &&
              s.scheduledAt.isAfter(now.subtract(const Duration(minutes: 5)));
        }).toList();

        _pastSessions = allSessions.where((s) {
          // Past only if status is 'ended' or 'cancelled'
          return s.isEnded || s.isCancelled;
        }).toList();

        // Missed sessions: ended/cancelled that the user didn't attend
        final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
        final currentUserId = currentUser?.uid;
        
        _missedSessions = allSessions.where((s) {
          if (!(s.isEnded || s.isCancelled)) return false;
          
          // Check if user attended this session
          if (currentUserId != null) {
            final attendees = s.attendees ?? [];
            final attendedAt = s.attendedAt ?? [];
            
            // User attended if they're in attendees list or attendedAt list
            final didAttend = attendees.any((a) => 
              a is Map ? a['_id'] == currentUserId || a['id'] == currentUserId : a == currentUserId
            ) || attendedAt.any((a) => 
              a is Map ? a['userId'] == currentUserId : a == currentUserId
            );
            
            // Only show in missed if user did NOT attend
            return !didAttend;
          }
          
          // If no current user, show all ended/cancelled as potentially missed
          return true;
        }).toList();

        // Sort each list
        _liveNowSessions.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
        _upcomingSessions.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
        _pastSessions.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
        _missedSessions.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

        setState(() {
          _courseSessions = allSessions;
          _isLoadingSessions = false;
          _sessionsLoaded = true;
        });
        // Schedule push notifications for upcoming sessions
        PushNotificationService.scheduleLiveSessionNotifications(_upcomingSessions);
      }
    } catch (e) {
      debugPrint('Error loading live sessions: $e');
      if (mounted) setState(() => _isLoadingSessions = false);
    }
  }

  Future<void> _joinStudentSession(LiveSession session) async {
    try {
      final service = LiveSessionService();
      final response = await service.joinSession(session.id);
      if (!mounted) return;
      if (response.joinUrl.isNotEmpty) {
        final uri = Uri.parse(response.joinUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Cannot open: ${response.joinUrl}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error joining session: $e')),
        );
      }
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildLiveSessionsTab() {
    final authState = ref.read(authProvider);
    final user = authState?.user;
    
    // Check if student has live session access for this course
    if (user != null && user.role == 'student') {
      final userEnrollmentsAsync = ref.read(userEnrollmentsProvider);
      final enrollments = userEnrollmentsAsync.when(
        data: (enrollments) => enrollments,
        loading: () => [],
        error: (_, __) => [],
      );

      final enrollment = enrollments.cast<Enrollment?>().firstWhere(
        (e) => e != null && e.courseId == widget.courseId,
        orElse: () => null,
      );

      // If enrollment exists and doesn't have live session access, show permission denied
      if (enrollment != null && !enrollment.canAccessLiveSessions) {
        return _buildEmptyState(
          icon: Icons.lock_rounded,
          title: AppLocalizations.of(context)!.noPermissionToAccessLiveSessions,
          subtitle: 'Please contact your administrator for access to live sessions',
        );
      }
    }

    // Load sessions exactly once
    if (!_sessionsLoaded && !_isLoadingSessions) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_sessionsLoaded && !_isLoadingSessions) _loadLiveSessions();
      });
    }

    final isMobile = MediaQuery.of(context).size.width < 600;

    return Column(
      children: [
        // Header
        Container(
          margin: EdgeInsets.fromLTRB(isMobile ? 12 : 20, 16, isMobile ? 12 : 20, 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00C853), Color(0xFF00897B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.video_call, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Live Sessions',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    onPressed: _loadLiveSessions,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Join live classes and interact with your instructor in real time.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Tabs
        Container(
          margin: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _liveSessionsTabController,
            indicator: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            labelColor: const Color(0xFF00C853),
            unselectedLabelColor: Colors.grey[600],
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'Live Now'),
              Tab(text: 'Upcoming'),
              Tab(text: 'Past'),
              Tab(text: 'Missed'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _liveSessionsTabController,
            children: [
              _buildSessionsList(_liveNowSessions, 'liveNow', isMobile),
              _buildSessionsList(_upcomingSessions, 'upcoming', isMobile),
              _buildSessionsList(_pastSessions, 'past', isMobile),
              _buildSessionsList(_missedSessions, 'missed', isMobile),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSessionsList(List<LiveSession> sessions, String type, bool isMobile) {
    if (_isLoadingSessions) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (sessions.isEmpty) {
      String message;
      IconData icon;
      switch (type) {
        case 'liveNow':
          message = 'No live sessions right now';
          icon = Icons.live_tv;
          break;
        case 'upcoming':
          message = 'No upcoming live sessions';
          icon = Icons.schedule;
          break;
        case 'past':
          message = 'No past sessions yet';
          icon = Icons.history;
          break;
        case 'missed':
          message = 'No missed sessions';
          icon = Icons.event_busy;
          break;
        default:
          message = 'No sessions found';
          icon = Icons.video_call;
      }

      return Center(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Icon(
              icon,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              type == 'liveNow' ? 'Live sessions will appear here when they start' :
              type == 'upcoming' ? 'Check back later for scheduled sessions' : 'Sessions will appear here',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(isMobile ? 12 : 20, 0, isMobile ? 12 : 20, 100),
      children: sessions.map((session) => _buildSessionCard(session)).toList(),
    );
  }

  Widget _buildSessionCard(LiveSession session) {
    final now = DateTime.now();
    final isActuallyEnded = session.isEnded || session.calculatedEndTime.isBefore(now);
    final isLive = session.status == 'live' && !isActuallyEnded;
    final hasStarted = !isActuallyEnded &&
        (session.scheduledAt.isBefore(now) || session.scheduledAt.isAtSameMomentAs(now));
    // Joinable only if session is actually live
    final canJoin = isLive;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isLive ? Colors.red[50] : Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isLive)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      if (isLive) const SizedBox(width: 6),
                      Text(
                        isLive ? 'LIVE NOW' : 'UPCOMING',
                        style: TextStyle(
                          color: isLive ? Colors.red : Colors.orange[700],
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  session.timeProgressInfo,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              session.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (session.description != null && session.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                session.description!,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            LiveSessionCountdown(
              scheduledAt: session.scheduledAt,
              durationMinutes: session.duration,
              isLive: session.isLive,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${session.duration} min',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const Spacer(),
                if (canJoin)
                  ElevatedButton.icon(
                    onPressed: () => _joinStudentSession(session),
                    icon: const Icon(Icons.video_call, size: 18),
                    label: Text(isLive ? 'Join Live' : 'Join'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isLive ? Colors.red : const Color(0xFFFF8F00),
                      foregroundColor: Colors.white,
                    ),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.schedule),
                    label: const Text('Scheduled'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  PROGRESS TAB
  // ─────────────────────────────────────────────
  Widget _buildProgressTab() {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return ListView(
      padding: EdgeInsets.fromLTRB(isMobile ? 12 : 20, 16, isMobile ? 12 : 20, 100),
      children: [
        _buildXpLevelBanner(),
        const SizedBox(height: 16),
        _buildProgressHeroCard(),
        const SizedBox(height: 16),
        _buildChapterProgressList(),
        const SizedBox(height: 16),
        _buildAchievementsGrid(),
      ],
    );
  }

  Widget _buildXpLevelBanner() {
    final level = (_xpPoints ~/ 500) + 1;
    final xpInLevel = _xpPoints % 500;
    final xpToNextLevel = 500;
    final levelPct = xpInLevel / xpToNextLevel;
    final levelTitles = ['Beginner', 'Explorer', 'Learner', 'Achiever', 'Expert', 'Master'];
    final levelTitle = levelTitles[(level - 1).clamp(0, levelTitles.length - 1)];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C4DFF), Color(0xFF5C35E0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: _DT.r20,
        boxShadow: [
          BoxShadow(
              color: _DT.accent.withOpacity(0.35),
              blurRadius: 24,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    'Lv$level',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      levelTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$_xpPoints XP  •  ${xpToNextLevel - xpInLevel} to next',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: _DT.r32,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt_rounded,
                        color: Colors.white, size: 13),
                    const SizedBox(width: 3),
                    Text(
                      '$_xpPoints XP',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Level $level progress',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.8), fontSize: 11)),
                  Text('$xpInLevel / $xpToNextLevel XP',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: _DT.r32,
                child: LinearProgressIndicator(
                  value: levelPct,
                  minHeight: 8,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressHeroCard() {
    final completedChapters =
        _chapterCompletionStatus.values.where((v) => v).length;
    final totalChapters = _chapters?.length ?? 0;
    final screenW = MediaQuery.of(context).size.width;
    final isNarrow = screenW < 380;
    final ringSize = isNarrow ? 80.0 : 96.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: _DT.r20,
        boxShadow: _DT.cardShadow,
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Big ring
              SizedBox(
                width: ringSize,
                height: ringSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: ringSize,
                      height: ringSize,
                      child: CircularProgressIndicator(
                        value: _progress,
                        backgroundColor: _borderColor,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            _DT.primary),
                        strokeWidth: 7,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(_progress * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: isNarrow ? 18 : 20,
                            fontWeight: FontWeight.w800,
                            color: _DT.primary,
                          ),
                        ),
                        Text('Done',
                            style: TextStyle(
                                fontSize: 10,
                                color: _textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProgressStatRow(
                      label: 'Lessons done',
                      value: '$_completedLessonsCount / $_totalLessons',
                      color: _DT.primary,
                      isDark: _isDark,
                    ),
                    const SizedBox(height: 10),
                    _ProgressStatRow(
                      label: 'Chapters done',
                      value: '$completedChapters / $totalChapters',
                      color: _DT.accent,
                      isDark: _isDark,
                    ),
                    const SizedBox(height: 10),
                    _ProgressStatRow(
                      label: 'Time invested',
                      value: '${_completedDurationMinutes}m',
                      color: const Color(0xFF00ACC1),
                      isDark: _isDark,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Overall completion',
                      style: TextStyle(
                          fontSize: 12,
                          color: _textSecondary,
                          fontWeight: FontWeight.w500)),
                  Text('${(_progress * 100).toInt()}%',
                      style: TextStyle(
                          fontSize: 12,
                          color: _DT.primary,
                          fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: _DT.r8,
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 8,
                  backgroundColor: _borderColor,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(_DT.primary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChapterProgressList() {
    if (_chapters == null || _chapters!.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: _DT.r20,
        boxShadow: _DT.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Text('Chapter breakdown',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary)),
          ),
          ..._chapters!.asMap().entries.map((e) {
            final i = e.key;
            final s = e.value;
            final lessons = _chapterLessons[s.id] ?? [];
            final done =
                lessons.where((l) => _lessonCompletionStatus[l.id] == true).length;
            final pct = lessons.isEmpty ? 0.0 : done / lessons.length;
            final isCompleted = _chapterCompletionStatus[s.id] ?? false;

            return _ChapterProgressRow(
              index: i + 1,
              title: s.displayName,
              done: done,
              total: lessons.length,
              pct: pct,
              isCompleted: isCompleted,
              isDark: _isDark,
              isLast: i == _chapters!.length - 1,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAchievementsGrid() {
    final completedChaptersCount =
        _chapterCompletionStatus.values.where((v) => v).length;
    final achievements = [
      _Achievement(
        title: 'First Steps',
        desc: 'Complete your first lesson',
        icon: Icons.emoji_events_rounded,
        unlocked: _completedLessonsCount > 0,
        color: const Color(0xFFFFC107),
        xp: 10,
      ),
      _Achievement(
        title: 'Quick Learner',
        desc: 'Complete 5 lessons',
        icon: Icons.flash_on_rounded,
        unlocked: _completedLessonsCount >= 5,
        color: const Color(0xFFFF7043),
        xp: 50,
      ),
      _Achievement(
        title: 'Chapter Hero',
        desc: 'Complete your first chapter',
        icon: Icons.book_rounded,
        unlocked: completedChaptersCount >= 1,
        color: _DT.accent,
        xp: 100,
      ),
      _Achievement(
        title: 'Halfway There',
        desc: '50% course completion',
        icon: Icons.trending_up_rounded,
        unlocked: _progress >= 0.5,
        color: _DT.primary,
        xp: 200,
      ),
      _Achievement(
        title: 'Dedicated',
        desc: 'Complete 3 chapters',
        icon: Icons.workspace_premium_rounded,
        unlocked: completedChaptersCount >= 3,
        color: const Color(0xFF00ACC1),
        xp: 300,
      ),
      _Achievement(
        title: 'Graduate',
        desc: 'Finish the entire course',
        icon: Icons.military_tech_rounded,
        unlocked: _completedLessonsCount == _totalLessons && _totalLessons > 0,
        color: const Color(0xFFFFD700),
        xp: 500,
      ),
    ];

    final unlockedCount = achievements.where((a) => a.unlocked).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: _DT.r20,
        boxShadow: _DT.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Achievements',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _DT.accent.withOpacity(0.1),
                  borderRadius: _DT.r32,
                ),
                child: Text(
                  '$unlockedCount / ${achievements.length} unlocked',
                  style: const TextStyle(
                    color: _DT.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final crossCount = w < 300 ? 1 : (w < 500 ? 2 : 3);
              final aspectRatio = w < 300 ? 3.5 : (w < 500 ? 1.55 : 1.7);
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossCount,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: aspectRatio,
                ),
                itemCount: achievements.length,
                itemBuilder: (context, index) {
                  final a = achievements[index];
                  return _AchievementCard(a: a, isDark: _isDark);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  BOOKMARKS TAB
  // ─────────────────────────────────────────────
  Widget _buildBookmarksTab() {
    // Load bookmarks exactly once
    if (!_bookmarksLoaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_bookmarksLoaded) _loadBookmarks();
      });
      return const Center(child: CircularProgressIndicator());
    }

    if (_bookmarkedLessons.isEmpty) {
      return _buildEmptyState(
        icon: Icons.bookmark_border_rounded,
        title: 'No bookmarked lessons',
        subtitle: 'Bookmark lessons to find them here quickly',
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        ResponsiveBreakpoints.isSmallMobile(context) ? 12 : 16,
        20,
        ResponsiveBreakpoints.isSmallMobile(context) ? 12 : 16,
        100,
      ),
      itemCount: _bookmarkedLessons.length,
      itemBuilder: (context, index) {
        final lesson = _bookmarkedLessons[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _BookmarkedLessonCard(
            lesson: lesson,
            isDark: _isDark,
            onTap: () => _openLesson(lesson),
            onRemoveBookmark: () => _removeBookmark(lesson.id),
          ),
        );
      },
    );
  }

  Future<void> _loadBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final result = <Lesson>[];
      if (_chapterLessons.isNotEmpty) {
        for (final sectionId in _chapterLessons.keys) {
          for (final lesson in _chapterLessons[sectionId] ?? []) {
            if (prefs.getBool('bookmarked_lesson_${lesson.id}') == true) {
              result.add(lesson);
            }
          }
        }
      }
      if (mounted) {
        setState(() {
          _bookmarkedLessons = result;
          _bookmarksLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('Error loading bookmarks: $e');
      if (mounted) setState(() => _bookmarksLoaded = true);
    }
  }

  Future<void> _removeBookmark(String lessonId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('bookmarked_lesson_$lessonId', false);
      setState(() {
        _bookmarkedLessons.removeWhere((l) => l.id == lessonId);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bookmark removed'),
          backgroundColor: _DT.primary,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove bookmark: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ─────────────────────────────────────────────
  //  MATERIALS TAB
  // ─────────────────────────────────────────────
  Widget _buildMaterialsTab() {
    final authState = ref.read(authProvider);
    final user = authState?.user;
    
    // Check if student has chapter access for this course
    if (user != null && user.role == 'student') {
      final userEnrollmentsAsync = ref.read(userEnrollmentsProvider);
      final enrollments = userEnrollmentsAsync.when(
        data: (enrollments) => enrollments,
        loading: () => [],
        error: (_, __) => [],
      );

      final enrollment = enrollments.cast<Enrollment?>().firstWhere(
        (e) => e != null && e.courseId == widget.courseId,
        orElse: () => null,
      );

      // If enrollment exists and doesn't have chapter access, show permission denied
      if (enrollment != null && !enrollment.canAccessChapters) {
        return _buildEmptyState(
          icon: Icons.lock_rounded,
          title: AppLocalizations.of(context)!.noPermissionToAccessChapters,
          subtitle: 'Please contact your administrator for access to course materials',
        );
      }
    }

    if (_chapters == null || _chapters!.isEmpty) {
      return _buildEmptyState(
          icon: Icons.folder_open_rounded,
          title: 'No materials yet',
          subtitle: 'Materials appear as chapters are added');
    }

    // Pre-filter chapters with materials for efficient rendering
    final chaptersWithMaterials = _chapters!.asMap().entries.where((e) {
      final s = e.value;
      final lessons = _chapterLessons[s.id] ?? [];
      final materials = _extractChapterMaterials(s, lessons);
      return materials.isNotEmpty;
    }).toList();

    // Fixed header count: download banner always present + optional description + optional invoice
    final int descOffset = 1; // download banner is always index 0
    final int invoiceOffset = descOffset + (_course?.description != null ? 1 : 0);
    final int chaptersOffset = invoiceOffset + (_hasPaidForCourse ? 1 : 0);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: chaptersOffset + chaptersWithMaterials.length,
      itemBuilder: (context, index) {
        // ── Download whole course banner (always at top) ──
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildCourseDownloadBanner(),
          );
        }

        // Course description card
        if (_course?.description != null && index == descOffset) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildCourseSummaryCard(),
          );
        }

        // Invoice download card
        if (_hasPaidForCourse && index == invoiceOffset) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildInvoiceDownloadCard(),
          );
        }

        // Chapter materials cards
        final chapterIndex = index - chaptersOffset;
        if (chapterIndex >= 0 && chapterIndex < chaptersWithMaterials.length) {
          final e = chaptersWithMaterials[chapterIndex];
          final i = e.key;
          final s = e.value;
          final lessons = _chapterLessons[s.id] ?? [];
          final materials = _extractChapterMaterials(s, lessons);
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _ChapterMaterialsCard(
              section: s,
              materials: materials,
              chapterIndex: i,
              isDark: _isDark,
              onTap: _openMaterial,
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildCourseDownloadBanner() {
    final downloadService = ref.watch(downloadServiceProvider);
    final allLessons = <Lesson>[];
    for (final chapter in _chapters ?? []) {
      allLessons.addAll((_chapterLessons[chapter.id] ?? []).where((l) => l.hasVideo));
    }
    final totalVideos = allLessons.length;
    final downloadedCount = allLessons.where((l) {
      final s = downloadService.getDownloadStatus(l.id);
      return s?.status == DownloadStatus.completed;
    }).length;
    final allDone = totalVideos > 0 && downloadedCount == totalVideos;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: allDone
              ? [const Color(0xFF00C853).withOpacity(0.12), const Color(0xFF00897B).withOpacity(0.08)]
              : [const Color(0xFF1A1F2E), const Color(0xFF111522)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: _DT.r20,
        border: Border.all(
          color: allDone ? _DT.primary.withOpacity(0.3) : Colors.white.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: allDone
                      ? _DT.primary.withOpacity(0.15)
                      : Colors.white.withOpacity(0.1),
                  borderRadius: _DT.r12,
                ),
                child: Icon(
                  allDone ? Icons.offline_pin_rounded : Icons.download_for_offline_rounded,
                  color: allDone ? _DT.primary : Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      allDone ? 'Course Downloaded' : 'Download Whole Course',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: allDone ? _textPrimary : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      allDone
                          ? '$downloadedCount/$totalVideos lessons ready offline'
                          : 'Watch all $totalVideos video lesson${totalVideos != 1 ? "s" : ""} offline',
                      style: TextStyle(
                        fontSize: 12,
                        color: allDone ? _textSecondary : Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_isCourseDownloading) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: _DT.r8,
              child: LinearProgressIndicator(
                value: _courseDownloadTotal > 0
                    ? (_courseDownloadDone + _courseDownloadFailed) / _courseDownloadTotal
                    : null,
                backgroundColor: Colors.white.withOpacity(0.15),
                valueColor: const AlwaysStoppedAnimation<Color>(_DT.primary),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$_courseDownloadDone/$_courseDownloadTotal lessons downloaded'
              '${_courseDownloadFailed > 0 ? " · $_courseDownloadFailed failed" : ""}',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
          if (!_isCourseDownloading) ...[
            const SizedBox(height: 16),
            if (totalVideos > 0 && downloadedCount > 0 && !allDone)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: _DT.r8,
                        child: LinearProgressIndicator(
                          value: downloadedCount / totalVideos,
                          backgroundColor: Colors.white.withOpacity(0.15),
                          valueColor: const AlwaysStoppedAnimation<Color>(_DT.primary),
                          minHeight: 5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '$downloadedCount/$totalVideos',
                      style: const TextStyle(fontSize: 11, color: Colors.white60, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: totalVideos == 0 ? null : (allDone ? () => context.go('/downloads') : _downloadWholeCourse),
                    icon: Icon(
                      allDone ? Icons.folder_open_rounded : Icons.download_rounded,
                      size: 18,
                    ),
                    label: Text(allDone ? 'View Downloads' : (downloadedCount > 0 ? 'Resume Download' : 'Download All')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _DT.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: _DT.r12),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                ),
                if (!allDone && downloadedCount > 0) ...[
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: () => context.go('/downloads'),
                    icon: const Icon(Icons.offline_pin_rounded, size: 16),
                    label: const Text('My Downloads'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: BorderSide(color: Colors.white.withOpacity(0.2)),
                      shape: RoundedRectangleBorder(borderRadius: _DT.r12),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCourseSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_DT.primary.withOpacity(0.08), _DT.accent.withOpacity(0.06)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: _DT.r20,
        border: Border.all(color: _DT.primary.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _DT.primary.withOpacity(0.12),
              borderRadius: _DT.r12,
            ),
            child: const Icon(Icons.description_rounded,
                color: _DT.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Course Overview',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: _textPrimary)),
                const SizedBox(height: 4),
                Text(
                  _course!.description ?? '',
                  style: TextStyle(fontSize: 13, color: _textSecondary, height: 1.4),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceDownloadCard() {
    final payment = _getUserPaymentForCurrentCourse();
    final isDownloading = ref.watch(paymentProvider).isProcessing;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_DT.accent.withOpacity(0.08), _DT.primary.withOpacity(0.06)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: _DT.r20,
        border: Border.all(color: _DT.accent.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _DT.accent.withOpacity(0.12),
                  borderRadius: _DT.r12,
                ),
                child: Icon(Icons.receipt_long_rounded,
                    color: _DT.accent, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Payment Invoice',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: _textPrimary)),
                    const SizedBox(height: 4),
                    Text(
                      'Download your payment receipt for this course',
                      style: TextStyle(fontSize: 13, color: _textSecondary, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (payment != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _surfaceBg,
                borderRadius: _DT.r12,
                border: Border.all(color: _borderColor.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Payment Details',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: _textPrimary)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getPaymentStatusColor(payment.status).withOpacity(0.1),
                          borderRadius: _DT.r8,
                        ),
                        child: Text(
                          payment.status.displayName.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _getPaymentStatusColor(payment.status),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _PaymentDetailRow(
                    label: 'Amount',
                    value: '${payment.currency} ${payment.amount.toStringAsFixed(0)}',
                    isDark: _isDark,
                  ),
                  _PaymentDetailRow(
                    label: 'Payment ID',
                    value: '${payment.id.substring(0, 8)}...',
                    isDark: _isDark,
                  ),
                  _PaymentDetailRow(
                    label: 'Date',
                    value: payment.createdAt.toString().substring(0, 10),
                    isDark: _isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isDownloading ? null : _downloadInvoice,
              icon: isDownloading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.download_rounded, size: 18),
              label: Text(isDownloading ? 'Downloading...' : 'Download Invoice'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _DT.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: _DT.r12),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getPaymentStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.completed:
      case PaymentStatus.approved:
        return _DT.primary;
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.failed:
        return Colors.red;
      case PaymentStatus.cancelled:
        return _textSecondary;
      default:
        return _textSecondary;
    }
  }

  // ─────────────────────────────────────────────
  //  LIBRARY TAB
  // ─────────────────────────────────────────────
  Widget _buildLibraryTab() {
    final authState = ref.read(authProvider);
    final user = authState?.user;
    
    // Check if student has chapter access for this course
    if (user != null && user.role == 'student') {
      final userEnrollmentsAsync = ref.read(userEnrollmentsProvider);
      final enrollments = userEnrollmentsAsync.when(
        data: (enrollments) => enrollments,
        loading: () => [],
        error: (_, __) => [],
      );

      final enrollment = enrollments.cast<Enrollment?>().firstWhere(
        (e) => e != null && e.courseId == widget.courseId,
        orElse: () => null,
      );

      // If enrollment exists and doesn't have chapter access, show permission denied
      if (enrollment != null && !enrollment.canAccessChapters) {
        return _buildEmptyState(
          icon: Icons.lock_rounded,
          title: AppLocalizations.of(context)!.noPermissionToAccessChapters,
          subtitle: 'Please contact your administrator for access to course materials',
        );
      }
    }

    if (_isLoadingBooks) {
      return Center(
        child: CircularProgressIndicator(color: _DT.primary),
      );
    }

    if (_booksError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: _textSecondary),
              const SizedBox(height: 16),
              Text(
                'Failed to load books',
                style: TextStyle(fontSize: 16, color: _textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                _booksError!,
                style: TextStyle(fontSize: 12, color: _textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadCourseBooks,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _DT.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_courseBooks.isEmpty) {
      return _buildEmptyState(
        icon: Icons.menu_book_rounded,
        title: 'No books available',
        subtitle: 'No books have been linked to this course yet',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _courseBooks.length,
      itemBuilder: (context, index) {
        final book = _courseBooks[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildBookCard(book),
        );
      },
    );
  }

  Widget _buildBookCard(dynamic book) {
    final String coverUrl = book['coverUrl'] ?? '';
    final String title = book['title'] ?? 'Untitled';
    final String author = book['author'] ?? 'Unknown Author';
    final String? description = book['description'];
    final String pdfUrl = book['pdfUrl'] ?? '';
    final String subject = book['subject'] ?? 'General';
    final String language = book['language'] ?? 'en';

    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: _DT.r16,
        border: Border.all(color: _borderColor.withOpacity(0.5)),
        boxShadow: _DT.cardShadow,
      ),
      child: InkWell(
        borderRadius: _DT.r16,
        onTap: () {
          if (pdfUrl.isNotEmpty) {
            _openBookReader(book);
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image or placeholder
            if (coverUrl.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  coverUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 180,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_DT.primary.withOpacity(0.1), _DT.accent.withOpacity(0.1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Icon(Icons.menu_book_rounded, size: 64, color: _DT.primary.withOpacity(0.3)),
                    ),
                  ),
                ),
              )
            else
              Container(
                height: 180,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_DT.primary.withOpacity(0.1), _DT.accent.withOpacity(0.1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Center(
                  child: Icon(Icons.menu_book_rounded, size: 64, color: _DT.primary.withOpacity(0.3)),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Subject badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _DT.primary.withOpacity(0.1),
                      borderRadius: _DT.r8,
                    ),
                    child: Text(
                      subject,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _DT.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Title
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Author
                  Text(
                    'By $author',
                    style: TextStyle(
                      fontSize: 13,
                      color: _textSecondary,
                    ),
                  ),
                  if (description != null && description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: _textSecondary,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  // Language badge
                  Row(
                    children: [
                      Icon(Icons.language_rounded, size: 14, color: _textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        language.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          color: _textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.arrow_forward_rounded, size: 16, color: _DT.primary),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: pdfUrl.isNotEmpty ? () => _openBookReader(book) : null,
                          icon: const Icon(Icons.menu_book_rounded, size: 18),
                          label: const Text('Read'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _DT.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: _DT.r12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: pdfUrl.isNotEmpty ? () => _downloadBookToApp(book) : null,
                          icon: const Icon(Icons.download_rounded, size: 18),
                          label: const Text('Download'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _DT.primary,
                            side: BorderSide(color: _DT.primary),
                            shape: RoundedRectangleBorder(borderRadius: _DT.r12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openBookReader(dynamic book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookReaderScreen(book: book),
      ),
    );
  }

  Future<void> _downloadBookToApp(dynamic book) async {
    final String pdfUrl = book['pdfUrl'] ?? '';
    final String title = book['title'] ?? 'Untitled';

    if (pdfUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No PDF available for download'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading "$title"...'),
        backgroundColor: _DT.primary,
        duration: const Duration(seconds: 2),
      ),
    );

    try {
      final downloadService = DownloadService();
      final bookId = book['_id'] ?? book['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
      await downloadService.downloadNotesOrMaterial(
        url: pdfUrl,
        title: title,
        lessonId: 'book_$bookId',
        type: DownloadType.material,
        onProgress: (progress) {
          // Optional: Show progress updates
        },
        onSuccess: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"$title" downloaded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        },
        onError: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Download failed: $error'),
              backgroundColor: Colors.red,
            ),
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ─────────────────────────────────────────────
  //  AI CHAT FAB
  // ─────────────────────────────────────────────
  Widget _buildAIChatFAB() {
    return ScaleTransition(
      scale: _fabScale,
      child: AnimatedBuilder(
        animation: _fabPulse ?? const AlwaysStoppedAnimation(1.0),
        builder: (context, child) => Transform.scale(
          scale: _isChatExpanded ? 1.0 : (_fabPulse?.value ?? 1.0),
          child: child,
        ),
        child: GestureDetector(
          onTap: () => setState(() => _isChatExpanded = !_isChatExpanded),
          child: Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isChatExpanded
                    ? [const Color(0xFF6E35F5), const Color(0xFF4A1FCC)]
                    : [const Color(0xFF7C4DFF), const Color(0xFF5C35E0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: _DT.r20,
              boxShadow: [
                BoxShadow(
                    color: _DT.accent.withOpacity(0.5),
                    blurRadius: 24,
                    spreadRadius: 2,
                    offset: const Offset(0, 8)),
                BoxShadow(
                    color: _DT.accent.withOpacity(0.15),
                    blurRadius: 48,
                    spreadRadius: 8,
                    offset: const Offset(0, 16)),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Outer glow ring
                if (!_isChatExpanded)
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _fabPulse ?? const AlwaysStoppedAnimation(1.0),
                      builder: (_, __) => Container(
                        decoration: BoxDecoration(
                          borderRadius: _DT.r20,
                          border: Border.all(
                            color: Colors.white.withOpacity(
                                ((_fabPulse?.value ?? 1.0) - 1.0) * 3.5),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                // Brain icon
                const Icon(Icons.psychology_rounded,
                    color: Colors.white, size: 30),
                // Sparkle top-right
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: _DT.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                            color: _DT.primary.withOpacity(0.6),
                            blurRadius: 6),
                      ],
                    ),
                    child: const Icon(Icons.auto_awesome_rounded,
                        color: Colors.white, size: 10),
                  ),
                ),
                // "AI" label bottom
                Positioned(
                  bottom: -8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF00C853), Color(0xFF00897B)]),
                      borderRadius: _DT.r32,
                      boxShadow: [
                        BoxShadow(
                            color: _DT.primary.withOpacity(0.4),
                            blurRadius: 8),
                      ],
                    ),
                    child: const Text(
                      'AI Teacher',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  AI CHAT OVERLAY
  // ─────────────────────────────────────────────
  Widget _buildAIChatOverlay() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () => setState(() => _isChatExpanded = false),
        child: Container(
          color: Colors.black.withOpacity(0.55),
          child: Center(
            child: GestureDetector(
              onTap: () {},
              child: ModernAIChatDialog(
                currentCourse: _course,
                allSections: _chapters,
                sectionLessons: _chapterLessons,
                chatService: _aiChatService,
                conversationId: _conversationId,
                guideKey: _guideKey,
                onClose: () => setState(() => _isChatExpanded = false),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  CHAPTER DETAILS MODAL
  // ─────────────────────────────────────────────
  void _openChapterDetails(Section section) {
    final lessons = _chapterLessons[section.id] ?? [];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ChapterDetailsSheet(
        section: section,
        lessons: lessons,
        lessonCompletionStatus: _lessonCompletionStatus,
        isDark: _isDark,
        isLoading: _isLoadingChapterDetails,
        onLessonTap: (l) {
          Navigator.pop(ctx);
          _openLesson(l);
        },
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  HELPERS
  // ─────────────────────────────────────────────
  List<Map<String, dynamic>> _extractChapterMaterials(
      Section section, List<Lesson> lessons) {
    final materials = <Map<String, dynamic>>[];
    for (var lesson in lessons) {
      if (lesson.hasVideo) {
        materials.add({
          'title': lesson.title,
          'type': 'video',
          'icon': Icons.play_circle_rounded,
          'color': _DT.primary,
          'videoId': lesson.videoId,
          'duration': lesson.duration,
          'lessonId': lesson.id,
          'subtitle': '${lesson.duration} min video',
        });
      }
      if (lesson.hasNotes) {
        materials.add({
          'title': '${lesson.title} — Notes',
          'type': 'notes',
          'icon': Icons.description_rounded,
          'color': _DT.accent,
          'notes': lesson.notes,
          'notesPdfUrl': lesson.notesPdfUrl,
          'lessonId': lesson.id,
          'subtitle': 'Study notes',
        });
      }
      if (lesson.hasQuiz) {
        materials.add({
          'title': '${lesson.title} — Quiz',
          'type': 'quiz',
          'icon': Icons.quiz_rounded,
          'color': const Color(0xFFF59E0B),
          'quizId': lesson.quizId,
          'lessonId': lesson.id,
          'subtitle': 'Knowledge check',
        });
      }
      if (lesson.hasMaterials)
        for (var url in lesson.materials!) {
          materials.add({
            'title': url.split('/').last,
            'type': 'document',
            'icon': Icons.insert_drive_file_rounded,
            'color': const Color(0xFF8B5CF6),
            'url': url,
            'lessonId': lesson.id,
            'subtitle': 'Resource file',
          });
        }
    }
    return materials;
  }

  Future<void> _openLesson(Lesson lesson) async {
    // Snapshot completion before navigating
    final wasCompleted = _lessonCompletionStatus[lesson.id] == true;

    await context.push('/lesson/${lesson.id}');

    if (!mounted) return;

    // Find which chapter this lesson belongs to
    String? chapterId;
    int? chapterIndex;
    for (int i = 0; i < (_chapters?.length ?? 0); i++) {
      final ch = _chapters![i];
      final lessons = _chapterLessons[ch.id] ?? [];
      if (lessons.any((l) => l.id == lesson.id)) {
        chapterId = ch.id;
        chapterIndex = i;
        break;
      }
    }
    if (chapterId == null || chapterIndex == null) return;

    // Refresh completion status from server for this chapter's lessons
    try {
      final accessData = await ref
          .read(enrollmentRepositoryProvider)
          .checkCourseAccess(widget.courseId);
      if (!mounted) return;

      final completedList =
          (accessData?['completedLessons'] as List?)?.map((e) => e.toString()).toSet() ?? {};

      final chapterLessons = _chapterLessons[chapterId] ?? [];
      bool anyNewlyCompleted = false;

      setState(() {
        for (final l in chapterLessons) {
          final nowDone = completedList.contains(l.id);
          if (nowDone && _lessonCompletionStatus[l.id] != true) {
            _lessonCompletionStatus[l.id] = true;
            _completedLessonsCount++;
            _completedDurationMinutes += l.duration;
            anyNewlyCompleted = true;
          }
        }
        // Recompute XP
        _xpPoints = (_completedLessonsCount * 10) +
            (_chapterCompletionStatus.values.where((v) => v).length * 100);
      });

      // Check if this lesson being completed finishes the whole chapter
      final allDone = chapterLessons.isNotEmpty &&
          chapterLessons.every((l) => _lessonCompletionStatus[l.id] == true);

      if (anyNewlyCompleted && allDone) {
        await _markChapterComplete(_chapters![chapterIndex], chapterIndex);
      }
    } catch (e) {
      // Fallback: optimistically mark the lesson done if it wasn't before
      if (!wasCompleted && mounted) {
        setState(() {
          _lessonCompletionStatus[lesson.id] = true;
          _completedLessonsCount++;
          _xpPoints += 10;
        });

        final chapterLessons = _chapterLessons[chapterId] ?? [];
        final allDone = chapterLessons.isNotEmpty &&
            chapterLessons.every((l) => _lessonCompletionStatus[l.id] == true);
        if (allDone) {
          await _markChapterComplete(_chapters![chapterIndex], chapterIndex);
        }
      }
    }
  }

  void _openMaterial(Map<String, dynamic> m) {
    switch (m['type'] as String) {
      case 'video':
      case 'notes':
        context.push('/lesson/${m["lessonId"]}');
        break;
      case 'quiz':
        final qid = m['quizId'] as String;
        if (qid.isNotEmpty) {
          context.push(
              '/enhanced-quiz/$qid?lessonTitle=${Uri.encodeComponent(_course?.title ?? "Quiz")}');
        }
        break;
      case 'document':
        final url = m['url'] as String? ?? m['notesPdfUrl'] as String?;
        if (url != null && url.isNotEmpty && url.startsWith('http')) {
          launchUrl(Uri.parse(url));
        }
        break;
    }
  }

  // ─────────────────────────────────────────────
  //  COURSE-WIDE DOWNLOAD
  // ─────────────────────────────────────────────
  Future<void> _downloadWholeCourse() async {
    if (_isCourseDownloading) return;
    if (_chapters == null || _chapters!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No course content to download yet'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Collect all lessons with videos
    final videoLessons = <Lesson>[];
    for (final chapter in _chapters!) {
      final lessons = _chapterLessons[chapter.id] ?? [];
      for (final lesson in lessons) {
        if (lesson.hasVideo) videoLessons.add(lesson);
      }
    }

    if (videoLessons.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No video lessons found in this course'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final downloadService = ref.read(downloadServiceProvider);

    // Filter out already-downloaded lessons
    final toDownload = videoLessons.where((l) {
      final status = downloadService.getDownloadStatus(l.id);
      return status == null || status.status != DownloadStatus.completed;
    }).toList();

    if (toDownload.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('All lessons are already downloaded!'),
          backgroundColor: _DT.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );
      return;
    }

    setState(() {
      _isCourseDownloading = true;
      _courseDownloadTotal = toDownload.length;
      _courseDownloadDone = 0;
      _courseDownloadFailed = 0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Starting download of ${toDownload.length} lesson${toDownload.length > 1 ? "s" : ""}…'),
        backgroundColor: _DT.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 3),
      ),
    );

    final videoApiService = VideoApiService();

    for (final lesson in toDownload) {
      if (!mounted) break;
      try {
        final signedUrl = await videoApiService.getVideoStreamUrl(lesson.id);
        if (signedUrl.isEmpty) throw Exception('Empty URL');

        await downloadService.downloadVideo(
          url: signedUrl,
          fileName: lesson.id,
          originalTitle: lesson.title,
          lessonId: lesson.id,
          onSuccess: () {
            if (mounted) setState(() => _courseDownloadDone++);
          },
          onError: (_) {
            if (mounted) setState(() => _courseDownloadFailed++);
          },
        );
      } catch (e) {
        if (mounted) setState(() => _courseDownloadFailed++);
        debugPrint('Course download: failed for lesson ${lesson.id}: $e');
      }
    }

    if (mounted) {
      setState(() => _isCourseDownloading = false);
      final failed = _courseDownloadFailed;
      final done = _courseDownloadDone;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            failed == 0
                ? '$done lesson${done > 1 ? "s" : ""} downloaded successfully!'
                : '$done downloaded, $failed failed.',
          ),
          backgroundColor: failed == 0 ? _DT.primary : Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _refreshData() async {
    await _loadCourseData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Content refreshed'),
          backgroundColor: _DT.primary,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildEmptyState(
      {required IconData icon,
      required String title,
      required String subtitle}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _DT.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: _DT.primary),
            ),
            const SizedBox(height: 20),
            Text(title,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary)),
            const SizedBox(height: 8),
            Text(subtitle,
                style: TextStyle(fontSize: 14, color: _textSecondary),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════
//  CHAPTER CARD
// ═════════════════════════════════════════════
class _ChapterCard extends StatelessWidget {
  final Section section;
  final int chapterIndex;
  final List<Lesson> lessons;
  final bool isUnlocked;
  final bool isCurrent;
  final bool isChapterCompleted;
  final Map<String, bool> lessonCompletionStatus;
  final bool isDark;
  final bool isCompact;
  final void Function(Lesson) onLessonTap;
  final VoidCallback onMoreTap;
  final Future<void> Function() onMarkComplete;
  final bool isLoading;

  const _ChapterCard({
    required this.section,
    required this.chapterIndex,
    required this.lessons,
    required this.isUnlocked,
    required this.isCurrent,
    required this.isChapterCompleted,
    required this.lessonCompletionStatus,
    required this.isDark,
    required this.isCompact,
    required this.onLessonTap,
    required this.onMoreTap,
    required this.onMarkComplete,
    this.isLoading = false,
  });

  int get completedCount =>
      lessons.where((l) => lessonCompletionStatus[l.id] == true).length;

  double get chapterProgress =>
      lessons.isEmpty ? 0.0 : completedCount / lessons.length;

  bool get isFullyCompleted =>
      lessons.isNotEmpty && lessons.every((l) => lessonCompletionStatus[l.id] == true);

  Color get _cardBg => isDark ? _DT.cardDark : _DT.card;
  Color get _textPrimary => isDark ? Colors.white : _DT.textPrimary;
  Color get _borderColor => isDark ? _DT.borderDark : _DT.border;
  Color get _surfaceBg => isDark ? _DT.surfaceDk : _DT.surface;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: _DT.r20,
        border: isChapterCompleted
            ? Border.all(color: _DT.primary, width: 2)
            : isCurrent
                ? Border.all(color: _DT.primary.withOpacity(0.5), width: 1.5)
                : Border.all(color: _borderColor, width: 0.5),
        boxShadow: isChapterCompleted
            ? [
                BoxShadow(
                    color: _DT.primary.withOpacity(0.18),
                    blurRadius: 28,
                    offset: const Offset(0, 8)),
              ]
            : _DT.cardShadow,
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          if (isUnlocked && lessons.isNotEmpty) _buildLessonsSection(),
          if (isUnlocked) _buildMarkCompleteFooter(),
          if (!isUnlocked) _buildLockedFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(isCompact ? 14 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isUnlocked
              ? _DT.heroGrad
              : [Colors.grey.shade400, Colors.grey.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(isCompact ? 6 : 9),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: _DT.r8,
                ),
                child: Icon(
                  isUnlocked ? Icons.book_rounded : Icons.lock_rounded,
                  color: Colors.white,
                  size: isCompact ? 14 : 18,
                ),
              ),
              SizedBox(width: isCompact ? 8 : 12),
              Expanded(
                child: Text(
                  section.displayName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isCompact ? 13 : 17,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
              ),
              // Count badge
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 7 : 10,
                    vertical: isCompact ? 3 : 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: _DT.r32,
                ),
                child: Text(
                  '$completedCount/${lessons.length}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isCompact ? 10 : 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (section.description != null && section.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              section.description!,
              style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          // Progress bar inside header
          if (isUnlocked && lessons.isNotEmpty) ...[
            SizedBox(height: isCompact ? 8 : 12),
            ClipRRect(
              borderRadius: _DT.r32,
              child: LinearProgressIndicator(
                value: chapterProgress,
                minHeight: 3,
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLessonsSection() {
    final displayLessons = isCompact ? _getVisibleLessons() : lessons;
    return Padding(
      padding: EdgeInsets.fromLTRB(isCompact ? 12 : 16, 14, isCompact ? 12 : 16, isCompact ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isCompact) ...[
            Row(
              children: [
                Icon(Icons.list_rounded, size: 15, color: _DT.textSecondary),
                const SizedBox(width: 6),
                Text(
                  '${lessons.length} ${lessons.length == 1 ? "Lesson" : "Lessons"}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _DT.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          ...displayLessons.map((l) {
            final done = lessonCompletionStatus[l.id] == true;
            return _LessonRow(
              lesson: l,
              isCompleted: done,
              isCompact: isCompact,
              isDark: isDark,
              onTap: () => onLessonTap(l),
            );
          }),
          if (isCompact && _shouldShowMoreButton())
            GestureDetector(
              onTap: onMoreTap,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _DT.primary.withOpacity(0.06),
                  borderRadius: _DT.r12,
                  border:
                      Border.all(color: _DT.primary.withOpacity(0.2)),
                ),
                child: Text(
                  '+${_getHiddenLessonCount()} more lessons',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _DT.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Returns the lessons that should be visible based on completion status
  List<Lesson> _getVisibleLessons() {
    if (!isCompact || lessons.isEmpty) return lessons;
    
    List<Lesson> visibleLessons = [];
    
    for (int i = 0; i < lessons.length; i++) {
      final lesson = lessons[i];
      
      // Always show the first lesson
      if (i == 0) {
        visibleLessons.add(lesson);
        continue;
      }
      
      // Check if previous lesson is completed
      final previousLesson = lessons[i - 1];
      final isPreviousCompleted = lessonCompletionStatus[previousLesson.id] == true;
      
      if (isPreviousCompleted) {
        visibleLessons.add(lesson);
      } else {
        // Stop at the first incomplete lesson
        break;
      }
    }
    
    return visibleLessons;
  }

  // Determines if the "more lessons" button should be shown
  bool _shouldShowMoreButton() {
    if (!isCompact || lessons.length <= 2) return false;
    
    final visibleLessons = _getVisibleLessons();
    final hiddenCount = lessons.length - visibleLessons.length;
    
    return hiddenCount > 0;
  }

  // Returns the count of hidden lessons
  int _getHiddenLessonCount() {
    if (!isCompact) return 0;
    
    final visibleLessons = _getVisibleLessons();
    return lessons.length - visibleLessons.length;
  }

  Widget _buildLockedFooter() {
    return Container(
      margin: EdgeInsets.all(isCompact ? 10 : 14),
      padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 14 : 16, vertical: isCompact ? 10 : 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: _DT.r12,
        border: Border.all(color: Colors.grey.shade300, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.lock_outline_rounded,
                size: isCompact ? 14 : 16, color: Colors.grey.shade500),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chapter Locked',
                  style: TextStyle(
                      fontSize: isCompact ? 12 : 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(
                  'Complete the previous chapter to unlock this one',
                  style: TextStyle(
                      fontSize: isCompact ? 10 : 12,
                      color: Colors.grey.shade400),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarkCompleteFooter() {
    if (isChapterCompleted) {
      return Container(
        margin: EdgeInsets.fromLTRB(isCompact ? 10 : 14, 0, isCompact ? 10 : 14, isCompact ? 10 : 14),
        padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 12 : 16, vertical: isCompact ? 10 : 12),
        decoration: BoxDecoration(
          color: _DT.primary.withOpacity(0.08),
          borderRadius: _DT.r12,
          border: Border.all(color: _DT.primary.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                  color: _DT.primary, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 12),
            ),
            const SizedBox(width: 8),
            Text(
              'Chapter Completed!',
              style: TextStyle(
                fontSize: isCompact ? 11 : 13,
                fontWeight: FontWeight.w700,
                color: _DT.primary,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '🏆',
              style: TextStyle(fontSize: isCompact ? 13 : 16),
            ),
          ],
        ),
      );
    }
    // Show "Mark Complete" button when chapter is unlocked but not yet marked complete
    return Padding(
      padding: EdgeInsets.fromLTRB(isCompact ? 10 : 14, 0, isCompact ? 10 : 14, isCompact ? 10 : 14),
      child: GestureDetector(
        onTap: isLoading ? null : () => onMarkComplete(),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
              vertical: isCompact ? 10 : 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: _DT.heroGrad,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            borderRadius: _DT.r12,
            boxShadow: [
              BoxShadow(
                color: _DT.primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  width: isCompact ? 14 : 16,
                  height: isCompact ? 14 : 16,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else
                Icon(Icons.emoji_events_rounded,
                    color: Colors.white, size: isCompact ? 14 : 16),
              const SizedBox(width: 8),
              Text(
                isLoading ? 'Marking Complete...' : 'Mark Chapter Complete',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isCompact ? 11 : 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              if (!isLoading) ...[
                const SizedBox(width: 6),
                Text(
                  '+100 XP',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: isCompact ? 10 : 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════
//  LESSON ROW
// ═════════════════════════════════════════════
class _LessonRow extends StatelessWidget {
  final Lesson lesson;
  final bool isCompleted;
  final bool isCompact;
  final bool isDark;
  final VoidCallback onTap;

  const _LessonRow({
    required this.lesson,
    required this.isCompleted,
    required this.isCompact,
    required this.isDark,
    required this.onTap,
  });

  IconData get _typeIcon {
    switch (lesson.displayType.toLowerCase()) {
      case 'video': return Icons.play_circle_rounded;
      case 'notes': return Icons.description_rounded;
      case 'quiz':  return Icons.quiz_rounded;
      case 'mixed': return Icons.layers_rounded;
      default:      return Icons.article_rounded;
    }
  }

  Color get _typeColor {
    switch (lesson.displayType.toLowerCase()) {
      case 'video': return _DT.primary;
      case 'notes': return _DT.accent;
      case 'quiz':  return const Color(0xFFF59E0B);
      case 'mixed': return const Color(0xFF8B5CF6);
      default:      return _DT.textSecondary;
    }
  }

  Color get _surface => isDark ? _DT.surfaceDk : _DT.surface;
  Color get _border  => isDark ? _DT.borderDark : _DT.border;
  Color get _text    => isDark ? Colors.white : _DT.textPrimary;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: isCompact ? 6 : 12),
        padding: EdgeInsets.all(isCompact ? 10 : 14),
        decoration: BoxDecoration(
          color: isCompleted ? _DT.primary.withOpacity(0.06) : _surface,
          borderRadius: _DT.r12,
          border: Border.all(
            color: isCompleted
                ? _DT.primary.withOpacity(0.3)
                : _border,
            width: isCompleted ? 1.0 : 0.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(isCompact ? 5 : 8),
              decoration: BoxDecoration(
                color: _typeColor.withOpacity(0.12),
                borderRadius: _DT.r8,
              ),
              child: Icon(_typeIcon,
                  color: _typeColor, size: isCompact ? 13 : 17),
            ),
            SizedBox(width: isCompact ? 8 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.title,
                    style: TextStyle(
                      fontSize: isCompact ? 12 : 14,
                      fontWeight: FontWeight.w600,
                      color: _text,
                      height: 1.3,
                      decoration:
                          isCompleted ? TextDecoration.lineThrough : null,
                      decorationColor: _DT.textSecondary,
                    ),
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
                  const SizedBox(height: 4),
                  Text('${lesson.duration} min',
                      style: TextStyle(
                          fontSize: isCompact ? 10 : 12, color: _DT.textSecondary)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isCompleted)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                    color: _DT.primary, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 11),
              )
            else
              Icon(Icons.chevron_right_rounded,
                  size: 20, color: _DT.textSecondary),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════
//  CHAPTER DETAILS BOTTOM SHEET
// ═════════════════════════════════════════════
class _ChapterDetailsSheet extends StatelessWidget {
  final Section section;
  final List<Lesson> lessons;
  final Map<String, bool> lessonCompletionStatus;
  final bool isDark;
  final bool isLoading;
  final void Function(Lesson) onLessonTap;

  const _ChapterDetailsSheet({
    required this.section,
    required this.lessons,
    required this.lessonCompletionStatus,
    required this.isDark,
    required this.onLessonTap,
    this.isLoading = false,
  });

  // Returns the lessons that should be visible based on completion status
  List<Lesson> _getVisibleLessons() {
    if (lessons.isEmpty) return lessons;
    
    List<Lesson> visibleLessons = [];
    
    for (int i = 0; i < lessons.length; i++) {
      final lesson = lessons[i];
      
      // Always show the first lesson
      if (i == 0) {
        visibleLessons.add(lesson);
        continue;
      }
      
      // Check if previous lesson is completed
      final previousLesson = lessons[i - 1];
      final isPreviousCompleted = lessonCompletionStatus[previousLesson.id] == true;
      
      if (isPreviousCompleted) {
        visibleLessons.add(lesson);
      } else {
        // Stop at the first incomplete lesson
        break;
      }
    }
    
    return visibleLessons;
  }

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? _DT.cardDark : Colors.white;
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? _DT.borderDark : _DT.border,
              borderRadius: _DT.r32,
            ),
          ),
          // Header
          Container(
            margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: _DT.heroGrad,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: _DT.r16,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: _DT.r12),
                  child: const Icon(Icons.book_rounded,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(section.displayName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700)),
                      Text('${lessons.length} ${lessons.length == 1 ? "lesson" : "lessons"}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (isLoading)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: _DT.primary),
                    SizedBox(height: 16),
                    Text('Loading lessons...',
                        style: TextStyle(color: _DT.textSecondary, fontSize: 14)),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                itemCount: lessons.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) {
                  final l = lessons[i];
                  return _LessonRow(
                    lesson: l,
                    isCompleted: lessonCompletionStatus[l.id] == true,
                    isCompact: false,
                    isDark: isDark,
                    onTap: () => onLessonTap(l),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════
//  CHAPTER MATERIALS CARD
// ═════════════════════════════════════════════
class _ChapterMaterialsCard extends StatelessWidget {
  final Section section;
  final List<Map<String, dynamic>> materials;
  final int chapterIndex;
  final bool isDark;
  final void Function(Map<String, dynamic>) onTap;

  const _ChapterMaterialsCard({
    required this.section,
    required this.materials,
    required this.chapterIndex,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? _DT.cardDark : Colors.white;
    final textPrimary = isDark ? Colors.white : _DT.textPrimary;
    final border = isDark ? _DT.borderDark : _DT.border;
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: _DT.r20,
        border: Border.all(color: border, width: 0.5),
        boxShadow: _DT.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _DT.primary,
                    borderRadius: _DT.r32,
                  ),
                  child: Text(
                    'Ch. ${chapterIndex + 1}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(section.displayName,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                Text('${materials.length} items',
                    style: TextStyle(
                        fontSize: 12, color: _DT.textSecondary)),
              ],
            ),
          ),
          // Grid
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: GridView.count(
              crossAxisCount: isDesktop ? 4 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: isDesktop ? 1.8 : 1.5,
              children: materials
                  .map((m) => _MaterialTile(
                        material: m,
                        isDark: isDark,
                        onTap: () => onTap(m),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MaterialTile extends StatelessWidget {
  final Map<String, dynamic> material;
  final bool isDark;
  final VoidCallback onTap;

  const _MaterialTile(
      {required this.material,
      required this.isDark,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final Color c = material['color'] as Color;
    final bg = isDark ? _DT.surfaceDk : _DT.surface;
    final textPrimary = isDark ? Colors.white : _DT.textPrimary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: _DT.r12,
          border: Border.all(color: c.withOpacity(0.25), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                      color: c.withOpacity(0.12),
                      borderRadius: _DT.r8),
                  child:
                      Icon(material['icon'] as IconData, color: c, size: 14),
                ),
                const Spacer(),
                if (material['duration'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                        color: c.withOpacity(0.12),
                        borderRadius: _DT.r4),
                    child: Text('${material["duration"]}m',
                        style: TextStyle(
                            color: c,
                            fontSize: 9,
                            fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              material['title'] as String,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  color: textPrimary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              material['subtitle'] as String? ?? '',
              style:
                  const TextStyle(fontSize: 9, color: _DT.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════
//  SMALL REUSABLE WIDGETS
// ═════════════════════════════════════════════
class _ActionChip extends StatelessWidget {
  final IconData icon;
  final bool active;
  final bool isDark;
  final Color cardBg;
  final VoidCallback? onTap;

  const _ActionChip({
    required this.icon,
    this.active = false,
    required this.isDark,
    required this.cardBg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: active ? _DT.primary : cardBg,
          borderRadius: _DT.r12,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Icon(icon,
            size: 18,
            color: active
                ? Colors.white
                : (isDark ? Colors.white : _DT.textPrimary)),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _HeroStat(
      {required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 14),
        const SizedBox(width: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700)),
        const SizedBox(width: 3),
        Text(label,
            style: const TextStyle(color: Colors.white60, fontSize: 11)),
      ],
    );
  }
}

class _ProgressStatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;
  const _ProgressStatRow(
      {required this.label,
      required this.value,
      required this.color,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 8,
            height: 8,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: _DT.textSecondary)),
        ),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : _DT.textPrimary)),
      ],
    );
  }
}

class _ChapterProgressRow extends StatelessWidget {
  final int index;
  final String title;
  final int done;
  final int total;
  final double pct;
  final bool isCompleted;
  final bool isDark;
  final bool isLast;

  const _ChapterProgressRow({
    required this.index,
    required this.title,
    required this.done,
    required this.total,
    required this.pct,
    required this.isCompleted,
    required this.isDark,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? Colors.white : _DT.textPrimary;
    final border = isDark ? _DT.borderDark : _DT.border;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        border: !isLast
            ? Border(bottom: BorderSide(color: border, width: 0.5))
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isCompleted
                  ? _DT.primary
                  : _DT.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 14)
                  : Text('$index',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _DT.primary)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: _DT.r32,
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 4,
                          backgroundColor:
                              _DT.primary.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(
                              isCompleted
                                  ? _DT.primary
                                  : _DT.primary.withOpacity(0.6)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('$done/$total',
                        style: const TextStyle(
                            fontSize: 11,
                            color: _DT.textSecondary,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Achievement {
  final String title;
  final String desc;
  final IconData icon;
  final bool unlocked;
  final Color color;
  final int xp;
  const _Achievement(
      {required this.title,
      required this.desc,
      required this.icon,
      required this.unlocked,
      required this.color,
      this.xp = 0});
}

class _BookmarkedLessonCard extends StatelessWidget {
  final Lesson lesson;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onRemoveBookmark;

  const _BookmarkedLessonCard({
    required this.lesson,
    required this.isDark,
    required this.onTap,
    required this.onRemoveBookmark,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? _DT.cardDark : _DT.card;
    final textPrimary = isDark ? Colors.white : _DT.textPrimary;
    final textSecondary = isDark ? _DT.textLight : _DT.textSecondary;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: _DT.r16,
        border: Border.all(
          color: isDark ? _DT.borderDark : _DT.border,
          width: 0.5,
        ),
        boxShadow: _DT.cardShadow,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: _DT.r16,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Lesson icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _DT.primary.withOpacity(0.1),
                  borderRadius: _DT.r12,
                ),
                child: Icon(
                  lesson.hasVideo ? Icons.play_circle_rounded : Icons.article_rounded,
                  color: _DT.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              // Lesson info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (lesson.description != null && lesson.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        lesson.description!,
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (lesson.duration > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 14,
                            color: textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${lesson.duration} min',
                            style: TextStyle(
                              fontSize: 12,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Remove bookmark button
              IconButton(
                icon: const Icon(Icons.bookmark),
                color: _DT.primary,
                onPressed: onRemoveBookmark,
                tooltip: 'Remove bookmark',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final _Achievement a;
  final bool isDark;
  const _AchievementCard({required this.a, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? _DT.surfaceDk : _DT.surface;
    final textPrimary = isDark ? Colors.white : _DT.textPrimary;

    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: a.unlocked ? a.color.withOpacity(0.09) : bg,
            borderRadius: _DT.r16,
            border: Border.all(
              color: a.unlocked
                  ? a.color.withOpacity(0.35)
                  : (isDark ? _DT.borderDark : _DT.border),
              width: a.unlocked ? 1.5 : 0.5,
            ),
            boxShadow: a.unlocked
                ? [BoxShadow(color: a.color.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4))]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: a.unlocked ? a.color.withOpacity(0.15) : Colors.grey.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(a.icon,
                        color: a.unlocked ? a.color : _DT.textHint,
                        size: 20),
                  ),
                  if (!a.unlocked)
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                          color: _DT.textSecondary, shape: BoxShape.circle),
                      child: const Icon(Icons.lock_rounded,
                          color: Colors.white, size: 7),
                    ),
                ],
              ),
              const SizedBox(height: 5),
              Text(a.title,
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      color: a.unlocked ? a.color : _DT.textSecondary),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(a.desc,
                  style: TextStyle(
                      fontSize: 9,
                      color: a.unlocked
                          ? a.color.withOpacity(0.75)
                          : _DT.textHint),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        if (a.xp > 0)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: a.unlocked ? a.color : Colors.grey.shade300,
                borderRadius: _DT.r32,
              ),
              child: Text(
                '+${a.xp} XP',
                style: TextStyle(
                  color: a.unlocked ? Colors.white : Colors.grey.shade500,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ═════════════════════════════════════════════
//  CHAPTER COMPLETION DIALOG
// ═════════════════════════════════════════════
class _ChapterCompletionDialog extends StatefulWidget {
  final String chapterName;
  final int chapterNumber;
  final int xpEarned;
  final int totalXp;
  final int lessonCount;
  final bool isLastChapter;
  final String? nextChapterName;
  final double overallProgress;
  final bool isDark;
  final VoidCallback onContinue;

  const _ChapterCompletionDialog({
    required this.chapterName,
    required this.chapterNumber,
    required this.xpEarned,
    required this.totalXp,
    required this.lessonCount,
    required this.isLastChapter,
    required this.nextChapterName,
    required this.overallProgress,
    required this.isDark,
    required this.onContinue,
  });

  @override
  State<_ChapterCompletionDialog> createState() => _ChapterCompletionDialogState();
}

class _ChapterCompletionDialogState extends State<_ChapterCompletionDialog>
    with TickerProviderStateMixin {
  late AnimationController _progressCtrl;
  late Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();
    _progressCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _progressAnim = Tween<double>(begin: 0, end: widget.overallProgress)
        .animate(CurvedAnimation(parent: _progressCtrl, curve: Curves.easeOut));
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _progressCtrl.forward();
    });
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? _DT.cardDark : Colors.white;
    final textPrimary = widget.isDark ? Colors.white : _DT.textPrimary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: _DT.r24,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 40,
                    offset: const Offset(0, 16))
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Green gradient header ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: _DT.heroGrad,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      // Trophy icon
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text('🏆', style: TextStyle(fontSize: 36)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Chapter Complete!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.chapterName,
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            height: 1.3),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),

                // ── XP + stats ──
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // XP earned pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF7C4DFF), Color(0xFF5C35E0)],
                          ),
                          borderRadius: _DT.r32,
                          boxShadow: [
                            BoxShadow(
                                color: _DT.accent.withOpacity(0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 6))
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.bolt_rounded,
                                color: Colors.white, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              '+${widget.xpEarned} XP earned!',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Stats row
                      Row(
                        children: [
                          _DialogStat(
                            icon: Icons.play_lesson_rounded,
                            value: '${widget.lessonCount}',
                            label: 'Lessons done',
                            color: _DT.primary,
                          ),
                          const SizedBox(width: 12),
                          _DialogStat(
                            icon: Icons.bolt_rounded,
                            value: '${widget.totalXp}',
                            label: 'Total XP',
                            color: _DT.accent,
                          ),
                          const SizedBox(width: 12),
                          _DialogStat(
                            icon: Icons.percent_rounded,
                            value: '${(widget.overallProgress * 100).toInt()}%',
                            label: 'Course done',
                            color: const Color(0xFF00ACC1),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Overall progress bar
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Overall progress',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: _DT.textSecondary,
                                      fontWeight: FontWeight.w500)),
                              AnimatedBuilder(
                                animation: _progressAnim,
                                builder: (_, __) => Text(
                                  '${(_progressAnim.value * 100).toInt()}%',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: _DT.primary,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          AnimatedBuilder(
                            animation: _progressAnim,
                            builder: (_, __) => ClipRRect(
                              borderRadius: _DT.r32,
                              child: LinearProgressIndicator(
                                value: _progressAnim.value,
                                minHeight: 8,
                                backgroundColor: _DT.primary.withOpacity(0.12),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                    _DT.primary),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Next chapter info
                      if (!widget.isLastChapter &&
                          widget.nextChapterName != null) ...
                        [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: _DT.primary.withOpacity(0.07),
                              borderRadius: _DT.r12,
                              border: Border.all(
                                  color: _DT.primary.withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: _DT.primary.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                      Icons.lock_open_rounded,
                                      color: _DT.primary,
                                      size: 14),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Next chapter unlocked!',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: _DT.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        widget.nextChapterName!,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: textPrimary,
                                            fontWeight: FontWeight.w600),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ]
                      else if (widget.isLastChapter) ...
                        [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                  colors: [Color(0xFFFFD700), Color(0xFFFF8F00)]),
                              borderRadius: _DT.r12,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('🎓',
                                    style: TextStyle(fontSize: 20)),
                                SizedBox(width: 8),
                                Text(
                                  'Course Complete! Congratulations!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                      // Continue button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: widget.onContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _DT.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: Text(
                            widget.isLastChapter
                                ? 'View My Progress 🎉'
                                : 'Continue Learning →',
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _DialogStat(
      {required this.icon,
      required this.value,
      required this.label,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: _DT.r12,
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 9, color: _DT.textSecondary),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _PaymentDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _PaymentDetailRow({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? Colors.white : _DT.textPrimary;
    final textSecondary = _DT.textSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}