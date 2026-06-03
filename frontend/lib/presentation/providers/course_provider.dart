import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excellencecoachinghub/data/repositories/course_repository.dart';
import 'package:excellencecoachinghub/data/repositories/section_repository.dart';
import 'package:excellencecoachinghub/models/course.dart';
import 'package:excellencecoachinghub/services/categories_service.dart';
import 'package:excellencecoachinghub/data/repositories/category_repository.dart';
import 'package:excellencecoachinghub/models/category.dart';
import 'package:excellencecoachinghub/models/enrollment.dart';
import 'package:excellencecoachinghub/presentation/providers/enrollment_provider.dart';
import 'package:excellencecoachinghub/services/api/video_api_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

final courseRepositoryProvider = Provider<CourseRepository>((ref) {
  return CourseRepository();
});

final sectionRepositoryProvider = Provider<SectionRepository>((ref) {
  return SectionRepository();
});

final categoriesServiceProvider = Provider<CategoriesService>((ref) {
  return CategoriesService();
});

// Course providers
final coursesProvider = FutureProvider<List<Course>>((ref) async {
  final repository = ref.read(courseRepositoryProvider);
  return await repository.getCourses();
});

final courseProvider = FutureProvider.family<Course, String>((ref, courseId) async {
  final repository = ref.read(courseRepositoryProvider);
  return await repository.getCourseById(courseId);
});

final videoApiServiceProvider = Provider<VideoApiService>((ref) {
  return VideoApiService();
});

final lessonContentProvider = FutureProvider.family<LessonContent, String>((ref, lessonId) async {
  final service = ref.read(videoApiServiceProvider);
  return await service.getLessonContent(lessonId);
});

final courseContentProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, courseId) async {
  final repository = ref.read(sectionRepositoryProvider);
  return await repository.getCourseContent(courseId);
});

final popularCoursesProvider = FutureProvider<List<Course>>((ref) async {
  print('PopularCoursesProvider: Starting to fetch courses');
  
  // Check connectivity
  final connectivityResult = await Connectivity().checkConnectivity();
  final isOffline = connectivityResult.isEmpty || 
                   connectivityResult.every((result) => result == ConnectivityResult.none);
  
  if (isOffline) {
    print('Device is offline, loading popular courses from cache');
    return await _loadCachedPopularCourses();
  }
  
  final repository = ref.read(courseRepositoryProvider);
  try {
    final allCourses = await repository.getCourses();
    print('PopularCoursesProvider: Got ${allCourses.length} courses');
    if (allCourses.isNotEmpty) {
      print('PopularCoursesProvider: First course thumbnail: ${allCourses[0].thumbnail ?? "null"}');
    }
    // Sort by popularity: highest enrollment count first, then highest rating
    final sortedByPopularity = List<Course>.from(allCourses)..sort((a, b) {
      final enrollmentDiff = (b.enrollmentCount ?? 0).compareTo(a.enrollmentCount ?? 0);
      if (enrollmentDiff != 0) return enrollmentDiff;
      // Tie-breaker: use average rating
      return (b.averageRating ?? 0.0).compareTo(a.averageRating ?? 0.0);
    });
    
    final result = sortedByPopularity.take(8).toList();
    print('PopularCoursesProvider: Returning ${result.length} popular courses');
    if (result.isNotEmpty) {
      print('PopularCoursesProvider: First popular course thumbnail: ${result[0].thumbnail ?? "null"}');
    }
    // Cache the popular courses for offline use
    await _cachePopularCourses(result);
    return result;
  } catch (e) {
    print('Error fetching popular courses: $e, trying cache');
    return await _loadCachedPopularCourses();
  }
});

final recommendedCoursesProvider = FutureProvider<List<Course>>((ref) async {
  final repository = ref.read(courseRepositoryProvider);
  
  try {
    final backendRecommendations = await repository.getRecommendedCourses();
    if (backendRecommendations.isNotEmpty) {
      return backendRecommendations;
    }
  } catch (e) {
    print('Error fetching recommended courses from backend: $e');
  }

  // Fallback to frontend-only logic if backend fails, returns empty, or for unauthenticated users
  final allCoursesAsync = ref.watch(coursesProvider);
  // Using enrollment_provider.dart's enrolledCoursesProvider
  final enrolledCoursesAsync = ref.watch(enrolledCoursesProvider);

  return allCoursesAsync.when(
    data: (allCourses) => enrolledCoursesAsync.when(
      data: (enrolledCourses) {
        final enrolledIds = enrolledCourses.map((e) => e.id).toSet();
        
        // 1. Filter out courses user is already enrolled in
        final availableCourses = allCourses.where((c) => !enrolledIds.contains(c.id)).toList();
        
        if (availableCourses.isEmpty) return [];

        // 2. Identify categories user is interested in from their current enrollments
        final interestedCategories = enrolledCourses
            .map((e) => e.categoryId)
            .where((id) => id != null)
            .toSet();

        // 3. Score and sort courses
        final scoredCourses = List<Course>.from(availableCourses)..sort((a, b) {
          // Check for category match (highest priority)
          final aMatches = a.categoryId != null && interestedCategories.contains(a.categoryId);
          final bMatches = b.categoryId != null && interestedCategories.contains(b.categoryId);
          
          if (aMatches && !bMatches) return -1;
          if (!aMatches && bMatches) return 1;
          
          // Secondary sort: enrollmentCount (popularity)
          final enrollmentDiff = (b.enrollmentCount ?? 0).compareTo(a.enrollmentCount ?? 0);
          if (enrollmentDiff != 0) return enrollmentDiff;
          
          // Tertiary sort: average rating
          return (b.averageRating ?? 0.0).compareTo(a.averageRating ?? 0.0);
        });

        return scoredCourses.take(8).toList();
      },
      loading: () => [],
      error: (_, __) => [],
    ),
    loading: () => [],
    error: (_, __) => [],
  );
});

final userEnrollmentsProvider = FutureProvider<List<Enrollment>>((ref) async {
  final enrollmentRepository = ref.read(enrollmentRepositoryProvider);
  return await enrollmentRepository.getEnrollments();
});

// Category providers with optimized loading
final allCategoriesProvider = Provider<List<dynamic>>((ref) {
  // Use backend categories only - no fallback to mock data
  final backendCategories = ref.watch(backendCategoriesProvider);
  return backendCategories.when(
    data: (categories) => categories.cast<dynamic>(),
    loading: () => [], // Return empty list while loading
    error: (_, __) => [], // Return empty list on error
  );
});

// Preload categories provider for faster initial load
final categoryPreloadProvider = Provider<void>((ref) {
  // Start preloading when provider is first accessed
  Future.microtask(() {
    final repository = ref.read(categoryRepositoryProvider);
    BackendCategoriesCache.preloadCategories(repository);
  });
});

// Backend category providers with caching
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository();
});

class BackendCategoriesCache {
  static List<Category>? _cachedCategories;
  static DateTime? _lastFetch;
  static const Duration _cacheTimeout = Duration(minutes: 30); // Extended cache for 30 minutes
  static const int _maxCacheSize = 100; // Increased cache size
  static bool _isPreloading = false;
  
  static bool get isCacheValid {
    if (_cachedCategories == null || _lastFetch == null) return false;
    return DateTime.now().difference(_lastFetch!) < _cacheTimeout;
  }
  
  static List<Category>? get cachedCategories => _cachedCategories;
  
  static void cacheCategories(List<Category> categories) {
    // Limit cache size to prevent memory issues
    if (categories.length <= _maxCacheSize) {
      _cachedCategories = categories;
      _lastFetch = DateTime.now();
    } else {
      _cachedCategories = categories.take(_maxCacheSize).toList();
      _lastFetch = DateTime.now();
    }
  }
  
  static void invalidateCache() {
    _cachedCategories = null;
    _lastFetch = null;
  }
  
  static bool get isPreloading => _isPreloading;
  
  static void setPreloading(bool value) {
    _isPreloading = value;
  }
  
  // Preload categories in background
  static Future<void> preloadCategories(CategoryRepository repository) async {
    if (_isPreloading || isCacheValid) return;
    
    _isPreloading = true;
    try {
      final categories = await repository.getAllCategories();
      cacheCategories(categories);
    } catch (e) {
      // Silent fail for preloading
      print('Background category preload failed: $e');
    } finally {
      _isPreloading = false;
    }
  }
}

// Optimized provider with immediate cache access and background refresh
final backendCategoriesProvider = FutureProvider<List<Category>>((ref) async {
  // 1) Fast path: in-memory cache
  if (BackendCategoriesCache.isCacheValid && BackendCategoriesCache.cachedCategories != null) {
    return BackendCategoriesCache.cachedCategories!;
  }

  // 2) Fetch from backend - no fallback to mock data
  final repository = ref.read(categoryRepositoryProvider);
  final categories = await repository.getAllCategories();
  BackendCategoriesCache.cacheCategories(categories);
  return categories;
});


final popularCategoriesProvider = Provider<List<dynamic>>((ref) {
  final allCategories = ref.read(allCategoriesProvider);
  return CategoriesService.getPopularCategories(allCategories.cast());
});

final featuredCategoriesProvider = Provider<List<dynamic>>((ref) {
  final allCategories = ref.read(allCategoriesProvider);
  return CategoriesService.getFeaturedCategories(allCategories.cast());
});

// Cache popular courses to SharedPreferences
Future<void> _cachePopularCourses(List<Course> courses) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final coursesJson = courses.map((c) => c.toJson()).toList();
    await prefs.setString('cached_popular_courses', json.encode(coursesJson));
    print('Cached ${courses.length} popular courses');
  } catch (e) {
    print('Error caching popular courses: $e');
  }
}

// Load cached popular courses from SharedPreferences
Future<List<Course>> _loadCachedPopularCourses() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final coursesJson = prefs.getString('cached_popular_courses');
    if (coursesJson != null) {
      final List<dynamic> decoded = json.decode(coursesJson);
      final courses = decoded.map((json) => Course.fromJson(json)).toList();
      print('Loaded ${courses.length} cached popular courses');
      return courses;
    }
  } catch (e) {
    print('Error loading cached popular courses: $e');
  }
  return [];
}
