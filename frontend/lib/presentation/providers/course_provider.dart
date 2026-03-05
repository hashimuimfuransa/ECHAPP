import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excellencecoachinghub/data/repositories/course_repository.dart';
import 'package:excellencecoachinghub/models/course.dart';
import 'package:excellencecoachinghub/services/categories_service.dart';
import 'package:excellencecoachinghub/data/repositories/enrollment_repository.dart';
import 'package:excellencecoachinghub/data/repositories/category_repository.dart';
import 'package:excellencecoachinghub/models/category.dart';
import 'package:excellencecoachinghub/models/enrollment.dart';

final courseRepositoryProvider = Provider<CourseRepository>((ref) {
  return CourseRepository();
});

final enrollmentRepositoryProvider = Provider<EnrollmentRepository>((ref) {
  return EnrollmentRepository();
});

final categoriesServiceProvider = Provider<CategoriesService>((ref) {
  return CategoriesService();
});

// Course providers
final coursesProvider = FutureProvider<List<Course>>((ref) async {
  final repository = ref.read(courseRepositoryProvider);
  return await repository.getCourses();
});

final popularCoursesProvider = FutureProvider<List<Course>>((ref) async {
  print('PopularCoursesProvider: Starting to fetch courses');
  final repository = ref.read(courseRepositoryProvider);
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
  return result;
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

// Category providers
final allCategoriesProvider = Provider<List<dynamic>>((ref) {
  // Note: This returns the mock categories for now, but could be updated to fetch from backend
  return CategoriesService.getAllCategories();
});

// Backend category providers
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository();
});

final backendCategoriesProvider = FutureProvider<List<Category>>((ref) async {
  final repository = ref.read(categoryRepositoryProvider);
  return await repository.getAllCategories();
});

final popularCategoriesProvider = Provider<List<dynamic>>((ref) {
  final allCategories = ref.read(allCategoriesProvider);
  return CategoriesService.getPopularCategories(allCategories.cast());
});

final featuredCategoriesProvider = Provider<List<dynamic>>((ref) {
  final allCategories = ref.read(allCategoriesProvider);
  return CategoriesService.getFeaturedCategories(allCategories.cast());
});
