import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/utils/learning_content_optimizer.dart';
import 'package:excellencecoachinghub/widgets/instant_learning_loader.dart';
import 'package:excellencecoachinghub/data/repositories/course_repository.dart';
import 'package:excellencecoachinghub/services/api/section_service.dart';
import 'package:excellencecoachinghub/models/course.dart';
import 'package:excellencecoachinghub/models/section.dart';
import 'package:excellencecoachinghub/models/lesson.dart';
import 'package:excellencecoachinghub/widgets/ai_chat_dialog.dart';
import 'package:excellencecoachinghub/services/ai_chat_service.dart';
import 'package:excellencecoachinghub/presentation/providers/enrollment_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/course_provider.dart';
import 'package:excellencecoachinghub/presentation/screens/exams/exam_taking_screen.dart';
import 'package:excellencecoachinghub/data/repositories/certificate_repository.dart';
import 'package:excellencecoachinghub/models/certificate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:excellencecoachinghub/widgets/student_guide_widget.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';

/// Optimized Professional Learning Screen with instant loading
class OptimizedProfessionalLearningScreen extends ConsumerStatefulWidget {
  final String courseId;
  
  const OptimizedProfessionalLearningScreen({
    super.key, 
    required this.courseId,
  });

  @override
  ConsumerState<OptimizedProfessionalLearningScreen> createState() =>
      _OptimizedProfessionalLearningScreenState();
}

class _OptimizedProfessionalLearningScreenState 
    extends ConsumerState<OptimizedProfessionalLearningScreen>
    with TickerProviderStateMixin {

  late TabController _tabController;
  late AnimationController _heroAnimCtrl;
  late AnimationController _fabAnimCtrl;
  late Animation<double> _heroFade;
  late Animation<Offset> _heroSlide;
  late Animation<double> _fabScale;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final LearningContentOptimizer _optimizer = LearningContentOptimizer();

  Course? _course;
  List<Section>? _sections;
  Map<String, List<Lesson>> _sectionLessons = {};
  Map<String, bool> _lessonCompletionStatus = {};
  List<Certificate> _courseCertificates = [];
  bool _isChatExpanded = false;
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _tabController = TabController(length: 3, vsync: this);
    _heroAnimCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fabAnimCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));

    _heroFade = CurvedAnimation(parent: _heroAnimCtrl, curve: Curves.easeOut);
    _heroSlide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _heroAnimCtrl, curve: Curves.easeOut));
    _fabScale = CurvedAnimation(parent: _fabAnimCtrl, curve: Curves.elasticOut);

    _searchController.addListener(_onSearchChanged);
    
    // Start animations immediately for instant feedback
    _heroAnimCtrl.forward();
    _fabAnimCtrl.forward();
    
    // Preload content in background
    _preloadContent();
  }

  Future<void> _preloadContent() async {
    // Preload full course content for instant navigation
    await _optimizer.preloadFullCourseContent(widget.courseId);
    
    // Also preload related courses if available
    _preloadRelatedCourses();
  }

  Future<void> _preloadRelatedCourses() async {
    try {
      final courseRepository = CourseRepository();
      final relatedCourses = await courseRepository.getRecommendedCourses();
      
      // Preload first 3 related courses
      final courseIds = relatedCourses.take(3).map((c) => c.id).toList();
      await _optimizer.preloadMultipleCourses(courseIds);
    } catch (e) {
      debugPrint('Error preloading related courses: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _heroAnimCtrl.dispose();
    _fabAnimCtrl.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query != _searchQuery) {
      setState(() {
        _searchQuery = query;
        _isSearching = query.isNotEmpty;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return InstantLearningLoader(
      courseId: widget.courseId,
      loadingWidget: _buildInstantLoadingScreen(),
      errorWidget: _buildErrorScreen(),
      builder: (course, sections) {
        _course = course;
        _sections = sections;
        
        return Scaffold(
          backgroundColor: Theme.of(context).brightness == Brightness.dark 
              ? const Color(0xFF0F1419) 
              : const Color(0xFFF7F8FC),
          body: NestedScrollView(
            controller: _scrollController,
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                _buildSliverAppBar(innerBoxIsScrolled),
                _buildSliverTabBar(),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildContentTab(),
                _buildResourcesTab(),
              ],
            ),
          ),
          floatingActionButton: _buildFloatingActionButton(),
          floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
        );
      },
    );
  }

  Widget _buildInstantLoadingScreen() {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
          ? const Color(0xFF0F1419) 
          : const Color(0xFFF7F8FC),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
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
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _buildSkeletonContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Skeleton title
          Container(
            height: 24,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          // Skeleton subtitle
          Container(
            height: 16,
            width: 200,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 24),
          // Skeleton cards
          ...List.generate(3, (index) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          )),
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
                'Failed to load course',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Please check your connection and try again',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.grey[400] 
                      : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => setState(() {}),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C853),
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

  Widget _buildSliverAppBar(bool innerBoxIsScrolled) {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
          ? const Color(0xFF0F1419) 
          : const Color(0xFFF7F8FC),
      flexibleSpace: FlexibleSpaceBar(
        background: AnimatedBuilder(
          animation: _heroAnimCtrl,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: Theme.of(context).brightness == Brightness.dark
                      ? [const Color(0xFF1A1F2E), const Color(0xFF111522)]
                      : [const Color(0xFF00C853), const Color(0xFF00897B)],
                ),
              ),
              child: FadeTransition(
                opacity: _heroFade,
                child: SlideTransition(
                  position: _heroSlide,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_course?.thumbnail != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              _course!.thumbnail!,
                              height: 80,
                              width: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 80,
                                  width: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.play_circle_outline,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 12),
                        Text(
                          _course?.title ?? 'Loading...',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_course?.description != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _course!.description!,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            setState(() {
              _isSearching = !_isSearching;
            });
          },
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'refresh':
                setState(() {});
                break;
              case 'certificate':
                _showCertificates();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'refresh',
              child: Row(
                children: [
                  Icon(Icons.refresh),
                  SizedBox(width: 8),
                  Text('Refresh'),
                ],
              ),
            ),
            if (_courseCertificates.isNotEmpty)
              const PopupMenuItem(
                value: 'certificate',
                child: Row(
                  children: [
                    Icon(Icons.card_membership),
                    SizedBox(width: 8),
                    Text('Certificates'),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSliverTabBar() {
    return SliverPersistentHeader(
      delegate: _SliverTabBarDelegate(
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Content'),
            Tab(text: 'Resources'),
          ],
          labelColor: const Color(0xFF00C853),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF00C853),
        ),
      ),
      pinned: true,
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCourseInfo(),
          const SizedBox(height: 24),
          _buildProgressSection(),
          const SizedBox(height: 24),
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildCourseInfo() {
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
              'Course Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Duration', _course?.duration ?? 'N/A'),
            _buildInfoRow('Level', _course?.level ?? 'N/A'),
            _buildInfoRow('Price', '\$${_course?.price ?? 0}'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
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
              'Your Progress',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: 0.3, // TODO: Calculate actual progress
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00C853)),
            ),
            const SizedBox(height: 8),
            Text(
              '30% Complete',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
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
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _startLearning(),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Continue Learning'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C853),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _tabController.animateTo(1),
                    icon: const Icon(Icons.list),
                    label: const Text('View Content'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentTab() {
    if (_sections == null || _sections!.isEmpty) {
      return const Center(
        child: Text('No content available'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _sections!.length,
      itemBuilder: (context, index) {
        final section = _sections![index];
        return _buildSectionCard(section, index);
      },
    );
  }

  Widget _buildSectionCard(Section section, int index) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).brightness == Brightness.dark 
              ? Colors.grey[800]! 
              : Colors.grey[200]!,
        ),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF00C853).withOpacity(0.1),
          child: Text(
            '${index + 1}',
            style: const TextStyle(
              color: Color(0xFF00C853),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          section.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${section.lessons?.length ?? 0} lessons',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        children: _buildLessonList(section),
      ),
    );
  }

  List<Widget> _buildLessonList(Section section) {
    final lessons = _sectionLessons[section.id] ?? [];
    
    if (lessons.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No lessons available',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ];
    }

    return lessons.map((lesson) {
      return ListTile(
        leading: Icon(
          _lessonCompletionStatus[lesson.id] == true 
              ? Icons.check_circle 
              : Icons.radio_button_unchecked,
          color: _lessonCompletionStatus[lesson.id] == true 
              ? const Color(0xFF00C853) 
              : Colors.grey,
        ),
        title: Text(lesson.title),
        subtitle: Text(
          lesson.duration ?? 'No duration',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: const Icon(Icons.play_arrow),
        onTap: () => _openLesson(lesson),
      );
    }).toList();
  }

  Widget _buildResourcesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCertificatesSection(),
          const SizedBox(height: 24),
          _buildAdditionalResources(),
        ],
      ),
    );
  }

  Widget _buildCertificatesSection() {
    if (_courseCertificates.isEmpty) {
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
              'Your Certificates',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ..._courseCertificates.map((certificate) {
              return ListTile(
                leading: const Icon(Icons.card_membership, color: Color(0xFF00C853)),
                title: Text(certificate.title ?? 'Certificate'),
                subtitle: Text('Issued: ${certificate.issuedAt ?? 'N/A'}'),
                trailing: const Icon(Icons.download),
                onTap: () => _downloadCertificate(certificate),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalResources() {
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
              'Additional Resources',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.help_outline, color: Color(0xFF00C853)),
              title: const Text('Student Guide'),
              subtitle: const Text('Get help with navigation and features'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showStudentGuide(),
            ),
            ListTile(
              leading: const Icon(Icons.chat, color: Color(0xFF00C853)),
              title: const Text('AI Assistant'),
              subtitle: const Text('Get help with course content'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _openAIChat(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return ScaleTransition(
      scale: _fabScale,
      child: FloatingActionButton.extended(
        onPressed: () => _startLearning(),
        backgroundColor: const Color(0xFF00C853),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.play_arrow),
        label: const Text('Continue'),
      ),
    );
  }

  void _startLearning() {
    if (_sections != null && _sections!.isNotEmpty) {
      // Navigate to first available lesson
      final firstSection = _sections!.first;
      _loadSectionLessons(firstSection.id).then((lessons) {
        if (lessons.isNotEmpty) {
          _openLesson(lessons.first);
        }
      });
    }
  }

  Future<List<Lesson>> _loadSectionLessons(String sectionId) async {
    // Try to get from cache first
    var lessons = _optimizer.getLessonsInstant(sectionId);
    
    if (lessons != null) {
      _sectionLessons[sectionId] = lessons;
      return lessons;
    }

    // Load from network
    try {
      final sectionService = SectionService();
      final lessonsData = await sectionService.getSectionLessons(sectionId);
      
      if (lessonsData != null) {
        lessons = lessonsData
            .map((l) => Lesson.fromJson(l as Map<String, dynamic>))
            .toList();
        lessons.sort((a, b) => a.order.compareTo(b.order));
        
        _sectionLessons[sectionId] = lessons;
        return lessons;
      }
    } catch (e) {
      debugPrint('Error loading lessons: $e');
    }
    
    return [];
  }

  void _openLesson(Lesson lesson) {
    // Navigate to lesson screen with instant loading
    context.push('/lesson/${lesson.id}', extra: {
      'lesson': lesson,
      'course': _course,
    });
  }

  void _showCertificates() {
    _tabController.animateTo(2);
  }

  void _downloadCertificate(Certificate certificate) {
    // Implement certificate download
  }

  void _showStudentGuide() {
    showDialog(
      context: context,
      builder: (context) => const StudentGuideWidget(),
    );
  }

  void _openAIChat() {
    showDialog(
      context: context,
      builder: (context) => const AIChatDialog(),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverTabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).brightness == Brightness.dark 
          ? const Color(0xFF0F1419) 
          : const Color(0xFFF7F8FC),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
