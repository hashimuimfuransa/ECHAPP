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
  // Sort by popularity (more enrolled)
  final sortedByEnrolled = List<Course>.from(allCourses)..sort((a, b) => (b.enrollmentCount ?? 0).compareTo(a.enrollmentCount ?? 0));
  final result = sortedByEnrolled.take(6).toList();
  print('PopularCoursesProvider: Returning ${result.length} popular courses');
  if (result.isNotEmpty) {
    print('PopularCoursesProvider: First popular course thumbnail: ${result[0].thumbnail ?? "null"}');
  }
  return result;
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
