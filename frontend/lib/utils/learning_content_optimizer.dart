import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:excellencecoachinghub/models/course.dart';
import 'package:excellencecoachinghub/models/section.dart';
import 'package:excellencecoachinghub/models/lesson.dart';
import 'package:excellencecoachinghub/data/repositories/course_repository.dart';
import 'package:excellencecoachinghub/services/api/section_service.dart';

/// Optimized learning content manager for instant loading with lazy loading
class LearningContentOptimizer {
  static final LearningContentOptimizer _instance = LearningContentOptimizer._internal();
  factory LearningContentOptimizer() => _instance;
  LearningContentOptimizer._internal();

  // Cache for instant loading
  final Map<String, Course> _courseCache = {};
  final Map<String, List<Section>> _sectionsCache = {};
  final Map<String, List<Lesson>> _lessonsCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 10);
  
  // Lazy loading queues
  final Set<String> _preloadingCourses = {};
  final Set<String> _preloadingSections = {};
  final Set<String> _preloadingLessons = {};
  
  // Lazy loading priority queue
  final List<_LazyLoadTask> _loadQueue = [];
  bool _isProcessingQueue = false;
  
  // Memory management
  static const int _maxCachedCourses = 20;
  static const int _maxCachedSections = 50;
  static const int _maxCachedLessons = 200;
  
  // Progressive loading
  final Map<String, _LoadProgress> _loadProgress = {};

  /// Get course instantly from cache or trigger lazy preload
  Course? getCourseInstant(String courseId) {
    final cached = _courseCache[courseId];
    if (cached != null && !_isCacheExpired(courseId)) {
      debugPrint('⚡ Course loaded instantly from cache: $courseId');
      return cached;
    }
    
    // Add to lazy load queue with high priority
    _addToLoadQueue(_LazyLoadTask(
      type: _LoadType.course,
      id: courseId,
      priority: _LoadPriority.high,
    ));
    
    return null;
  }

  /// Get sections instantly from cache or trigger lazy preload
  List<Section>? getSectionsInstant(String courseId) {
    final cached = _sectionsCache[courseId];
    if (cached != null && !_isCacheExpired('sections_$courseId')) {
      debugPrint('⚡ Sections loaded instantly from cache: $courseId');
      return cached;
    }
    
    // Add to lazy load queue with medium priority
    _addToLoadQueue(_LazyLoadTask(
      type: _LoadType.sections,
      id: courseId,
      priority: _LoadPriority.medium,
    ));
    
    return null;
  }

  /// Get lessons instantly from cache for a section
  List<Lesson>? getLessonsInstant(String sectionId) {
    final cached = _lessonsCache[sectionId];
    if (cached != null && !_isCacheExpired('lessons_$sectionId')) {
      debugPrint('⚡ Lessons loaded instantly from cache: $sectionId');
      return cached;
    }
    
    // Add to lazy load queue with low priority
    _addToLoadQueue(_LazyLoadTask(
      type: _LoadType.lessons,
      id: sectionId,
      priority: _LoadPriority.low,
    ));
    
    return null;
  }

  /// Add task to lazy load queue
  void _addToLoadQueue(_LazyLoadTask task) {
    // Remove existing task if present
    _loadQueue.removeWhere((t) => t.type == task.type && t.id == task.id);
    
    // Add new task
    _loadQueue.add(task);
    
    // Sort by priority
    _loadQueue.sort((a, b) {
      final priorityComparison = a.priority.index.compareTo(b.priority.index);
      if (priorityComparison != 0) return priorityComparison;
      return a.timestamp.compareTo(b.timestamp);
    });
    
    // Start processing queue if not already processing
    _processLoadQueue();
  }
  
  /// Process lazy load queue
  Future<void> _processLoadQueue() async {
    if (_isProcessingQueue || _loadQueue.isEmpty) return;
    
    _isProcessingQueue = true;
    debugPrint('🔄 Processing lazy load queue (${_loadQueue.length} tasks)');
    
    while (_loadQueue.isNotEmpty) {
      final task = _loadQueue.removeAt(0);
      
      try {
        await _executeLoadTask(task);
      } catch (e) {
        debugPrint('❌ Failed to load task ${task.type}:${task.id} - $e');
      }
      
      // Add small delay to prevent overwhelming the system
      await Future.delayed(const Duration(milliseconds: 10));
    }
    
    _isProcessingQueue = false;
    debugPrint('✅ Lazy load queue processing completed');
  }
  
  /// Execute individual load task
  Future<void> _executeLoadTask(_LazyLoadTask task) async {
    switch (task.type) {
      case _LoadType.course:
        await _preloadCourseData(task.id);
        break;
      case _LoadType.sections:
        await _preloadSectionsData(task.id);
        break;
      case _LoadType.lessons:
        await _preloadLessonsData(task.id);
        break;
    }
  }
  
  /// Manage memory by cleaning old cache entries
  void _manageMemory() {
    // Clean expired cache entries
    final now = DateTime.now();
    _cacheTimestamps.removeWhere((key, timestamp) {
      if (now.difference(timestamp) > _cacheExpiry) {
        // Remove corresponding cache entry
        if (key.startsWith('sections_')) {
          _sectionsCache.remove(key.substring(9));
        } else if (key.startsWith('lessons_')) {
          _lessonsCache.remove(key.substring(8));
        } else {
          _courseCache.remove(key);
        }
        return true;
      }
      return false;
    });
    
    // Limit cache sizes
    if (_courseCache.length > _maxCachedCourses) {
      _courseCache.removeWhere((key, value) => !_isCacheExpired(key));
    }
    
    if (_sectionsCache.length > _maxCachedSections) {
      _sectionsCache.removeWhere((key, value) => !_isCacheExpired('sections_$key'));
    }
    
    if (_lessonsCache.length > _maxCachedLessons) {
      _lessonsCache.removeWhere((key, value) => !_isCacheExpired('lessons_$key'));
    }
  }
  /// Preload course data in background
  Future<void> _preloadCourseData(String courseId) async {
    if (_preloadingCourses.contains(courseId)) return;
    
    _preloadingCourses.add(courseId);
    _loadProgress[courseId] = _LoadProgress(progress: 0.0, status: 'Starting');
    debugPrint('🔄 Preloading course data: $courseId');
    
    try {
      _loadProgress[courseId] = _LoadProgress(progress: 0.3, status: 'Fetching course');
      
      final courseRepository = CourseRepository();
      final course = await courseRepository.getCourseById(courseId);
      
      if (course != null) {
        _loadProgress[courseId] = _LoadProgress(progress: 0.7, status: 'Caching course');
        
        _courseCache[courseId] = course;
        _cacheTimestamps[courseId] = DateTime.now();
        
        _loadProgress[courseId] = _LoadProgress(progress: 1.0, status: 'Completed');
        debugPrint('✅ Course preloaded: $courseId');
        
        // Trigger memory management
        _manageMemory();
      }
    } catch (e) {
      debugPrint('❌ Failed to preload course $courseId: $e');
      _loadProgress[courseId] = _LoadProgress(progress: 0.0, status: 'Failed');
    } finally {
      _preloadingCourses.remove(courseId);
    }
  }

  /// Preload sections data in background
  Future<void> _preloadSectionsData(String courseId) async {
    if (_preloadingSections.contains(courseId)) return;
    
    _preloadingSections.add(courseId);
    _loadProgress['sections_$courseId'] = _LoadProgress(progress: 0.0, status: 'Starting');
    debugPrint('🔄 Preloading sections data: $courseId');
    
    try {
      _loadProgress['sections_$courseId'] = _LoadProgress(progress: 0.3, status: 'Fetching sections');
      
      final sectionService = SectionService();
      final courseContent = await sectionService.getCourseContent(courseId);
      
      final courseSections = courseContent['sections'] ?? courseContent['chapters'];
      if (courseSections != null) {
        _loadProgress['sections_$courseId'] = _LoadProgress(progress: 0.6, status: 'Processing sections');
        
        final sectionsData = courseSections as List;
        final sections = sectionsData
            .map((s) => Section.fromJson(s as Map<String, dynamic>))
            .toList();
        sections.sort((a, b) => a.order.compareTo(b.order));
        
        _loadProgress['sections_$courseId'] = _LoadProgress(progress: 0.8, status: 'Caching sections');
        
        _sectionsCache[courseId] = sections;
        _cacheTimestamps['sections_$courseId'] = DateTime.now();
        
        // Lazy load lessons for each section (low priority)
        for (final section in sections) {
          _addToLoadQueue(_LazyLoadTask(
            type: _LoadType.lessons,
            id: section.id,
            priority: _LoadPriority.low,
          ));
        }
        
        _loadProgress['sections_$courseId'] = _LoadProgress(progress: 1.0, status: 'Completed');
        debugPrint('✅ Sections preloaded: $courseId (${sections.length} sections)');
        
        // Trigger memory management
        _manageMemory();
      }
    } catch (e) {
      debugPrint('❌ Failed to preload sections $courseId: $e');
      _loadProgress['sections_$courseId'] = _LoadProgress(progress: 0.0, status: 'Failed');
    } finally {
      _preloadingSections.remove(courseId);
    }
  }

  /// Preload lessons data in background
  Future<void> _preloadLessonsData(String sectionId) async {
    if (_preloadingLessons.contains(sectionId)) return;
    
    _preloadingLessons.add(sectionId);
    _loadProgress['lessons_$sectionId'] = _LoadProgress(progress: 0.0, status: 'Starting');
    debugPrint('🔄 Preloading lessons data: $sectionId');
    
    try {
      _loadProgress['lessons_$sectionId'] = _LoadProgress(progress: 0.3, status: 'Fetching lessons');
      
      final sectionService = SectionService();
      final lessonsData = await sectionService.getLessonsBySection(sectionId);
      
      if (lessonsData != null) {
        _loadProgress['lessons_$sectionId'] = _LoadProgress(progress: 0.6, status: 'Processing lessons');
        
        final lessons = lessonsData
            .map((l) => Lesson.fromJson(l as Map<String, dynamic>))
            .toList();
        lessons.sort((a, b) => a.order.compareTo(b.order));
        
        _loadProgress['lessons_$sectionId'] = _LoadProgress(progress: 0.8, status: 'Caching lessons');
        
        _lessonsCache[sectionId] = lessons;
        _cacheTimestamps['lessons_$sectionId'] = DateTime.now();
        
        _loadProgress['lessons_$sectionId'] = _LoadProgress(progress: 1.0, status: 'Completed');
        debugPrint('✅ Lessons preloaded: $sectionId (${lessons.length} lessons)');
        
        // Trigger memory management
        _manageMemory();
      }
    } catch (e) {
      debugPrint('❌ Failed to preload lessons $sectionId: $e');
      _loadProgress['lessons_$sectionId'] = _LoadProgress(progress: 0.0, status: 'Failed');
    } finally {
      _preloadingLessons.remove(sectionId);
    }
  }

  /// Preload entire course content (course + sections + lessons)
  Future<void> preloadFullCourseContent(String courseId) async {
    debugPrint('🚀 Starting full course preload: $courseId');
    
    // Add all tasks to lazy load queue with appropriate priorities
    _addToLoadQueue(_LazyLoadTask(
      type: _LoadType.course,
      id: courseId,
      priority: _LoadPriority.high,
    ));
    
    _addToLoadQueue(_LazyLoadTask(
      type: _LoadType.sections,
      id: courseId,
      priority: _LoadPriority.medium,
    ));
    
    debugPrint('🎉 Full course preload queued: $courseId');
  }

  /// Preload multiple courses for better UX
  Future<void> preloadMultipleCourses(List<String> courseIds) async {
    debugPrint('📦 Preloading ${courseIds.length} courses');
    
    // Add all courses to lazy load queue
    for (final courseId in courseIds) {
      _addToLoadQueue(_LazyLoadTask(
        type: _LoadType.course,
        id: courseId,
        priority: _LoadPriority.medium,
      ));
      
      _addToLoadQueue(_LazyLoadTask(
        type: _LoadType.sections,
        id: courseId,
        priority: _LoadPriority.low,
      ));
    }
    
    debugPrint('🎉 All courses queued for preloading');
  }

  /// Check if cache is expired
  bool _isCacheExpired(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return true;
    
    return DateTime.now().difference(timestamp) > _cacheExpiry;
  }

  /// Clear all caches (useful for logout)
  void clearAllCaches() {
    _courseCache.clear();
    _sectionsCache.clear();
    _lessonsCache.clear();
    _cacheTimestamps.clear();
    _preloadingCourses.clear();
    _preloadingSections.clear();
    debugPrint('🧹 All learning content caches cleared');
  }

  /// Clear specific course cache
  void clearCourseCache(String courseId) {
    _courseCache.remove(courseId);
    _sectionsCache.remove(courseId);
    _cacheTimestamps.remove(courseId);
    _cacheTimestamps.remove('sections_$courseId');
    debugPrint('🧹 Course cache cleared: $courseId');
  }

  /// Get cache statistics for debugging
  Map<String, int> getCacheStats() {
    return {
      'courses': _courseCache.length,
      'sections': _sectionsCache.length,
      'lessons': _lessonsCache.length,
      'preloading_courses': _preloadingCourses.length,
      'preloading_sections': _preloadingSections.length,
    };
  }

  /// Check if content is available instantly
  bool isContentAvailableInstant(String courseId) {
    return _courseCache.containsKey(courseId) && 
           _sectionsCache.containsKey(courseId) &&
           !_isCacheExpired(courseId) &&
           !_isCacheExpired('sections_$courseId');
  }
  
  /// Get loading progress for a specific item
  _LoadProgress? getLoadProgress(String key) {
    return _loadProgress[key];
  }
  
  /// Get queue status for debugging
  Map<String, dynamic> getQueueStatus() {
    return {
      'queue_length': _loadQueue.length,
      'is_processing': _isProcessingQueue,
      'preloading_courses': _preloadingCourses.length,
      'preloading_sections': _preloadingSections.length,
      'preloading_lessons': _preloadingLessons.length,
      'load_progress_items': _loadProgress.length,
    };
  }
  
  /// Clear lazy load queue
  void clearLoadQueue() {
    _loadQueue.clear();
    debugPrint('🧹 Lazy load queue cleared');
  }
  
  /// Pause queue processing
  void pauseQueueProcessing() {
    _isProcessingQueue = false;
    debugPrint('⏸️ Queue processing paused');
  }
  
  /// Resume queue processing
  void resumeQueueProcessing() {
    if (!_isProcessingQueue && _loadQueue.isNotEmpty) {
      _processLoadQueue();
    }
    debugPrint('▶️ Queue processing resumed');
  }
}

// Lazy loading task classes
class _LazyLoadTask {
  final _LoadType type;
  final String id;
  final _LoadPriority priority;
  final DateTime timestamp;
  
  _LazyLoadTask({
    required this.type,
    required this.id,
    required this.priority,
  }) : timestamp = DateTime.now();
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _LazyLoadTask &&
        other.type == type &&
        other.id == id;
  }
  
  @override
  int get hashCode => type.hashCode ^ id.hashCode;
}

enum _LoadType { course, sections, lessons }
enum _LoadPriority { high, medium, low }

class _LoadProgress {
  final double progress;
  final String status;
  final DateTime startTime;
  
  _LoadProgress({
    required this.progress,
    required this.status,
  }) : startTime = DateTime.now();
  
  Duration get elapsed => DateTime.now().difference(startTime);
}
