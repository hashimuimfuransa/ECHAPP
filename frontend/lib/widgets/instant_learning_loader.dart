import 'package:flutter/material.dart';
import 'package:excellencecoachinghub/utils/learning_content_optimizer.dart';
import 'package:excellencecoachinghub/models/course.dart';
import 'package:excellencecoachinghub/models/section.dart';
import 'package:excellencecoachinghub/data/repositories/course_repository.dart';
import 'package:excellencecoachinghub/services/api/section_service.dart';

/// Instant loading widget for learning content
class InstantLearningLoader extends StatefulWidget {
  final String courseId;
  final Widget Function(Course course, List<Section> sections) builder;
  final Widget? loadingWidget;
  final Widget? errorWidget;

  const InstantLearningLoader({
    super.key,
    required this.courseId,
    required this.builder,
    this.loadingWidget,
    this.errorWidget,
  });

  @override
  State<InstantLearningLoader> createState() => _InstantLearningLoaderState();
}

class _InstantLearningLoaderState extends State<InstantLearningLoader> {
  final LearningContentOptimizer _optimizer = LearningContentOptimizer();
  Course? _course;
  List<Section>? _sections;
  bool _isLoading = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    // Try to get content instantly from cache
    _course = _optimizer.getCourseInstant(widget.courseId);
    _sections = _optimizer.getSectionsInstant(widget.courseId);

    if (_course != null && _sections != null) {
      // Content available instantly
      if (mounted) {
        setState(() {});
      }
      return;
    }

    // Show loading state while fetching from network
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // Fetch from network
      final courseRepository = CourseRepository();
      final sectionService = SectionService();

      _course = await courseRepository.getCourseById(widget.courseId);
      final courseContent = await sectionService.getCourseContent(widget.courseId);

      if (_course != null && courseContent != null) {
        final courseSections = courseContent['sections'] ?? courseContent['chapters'];
        if (courseSections != null) {
          final sectionsData = courseSections as List;
          _sections = sectionsData
              .map((s) => Section.fromJson(s as Map<String, dynamic>))
              .toList();
          _sections!.sort((a, b) => a.order.compareTo(b.order));
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading learning content: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError && widget.errorWidget != null) {
      return widget.errorWidget!;
    }

    if (_isLoading && widget.loadingWidget != null) {
      return widget.loadingWidget!;
    }

    if (_course != null && _sections != null) {
      return widget.builder(_course!, _sections!);
    }

    // Default loading state
    if (_isLoading) {
      return widget.loadingWidget ?? _buildDefaultLoading();
    }

    // Default error state
    if (_hasError) {
      return widget.errorWidget ?? _buildDefaultError();
    }

    // Should not reach here, but just in case
    return widget.loadingWidget ?? _buildDefaultLoading();
  }

  Widget _buildDefaultLoading() {
    return Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildDefaultError() {
    return Center(
      child: Text('Failed to load content'),
    );
  }
}
