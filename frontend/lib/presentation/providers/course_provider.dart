import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excellencecoachinghub/data/repositories/course_repository.dart';
import 'package:excellencecoachinghub/models/course.dart';
import 'package:excellencecoachinghub/services/categories_service.dart';
import 'package:excellencecoachinghub/data/repositories/enrollment_repository.dart';
import 'package:excellencecoachinghub/data/repositories/category_repository.dart';
import 'package:excellencecoachinghub/models/category.dart';

final courseRepositoryProvider = Provider<CourseRepository>((ref) {
  return CourseRepository();
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
  // Sort by rating or popularity (assuming higher price/quality correlates with popularity)
  // In a real scenario, you'd probably have a popularity field from the backend
  final sortedCourses = List<Course>.from(allCourses)..sort((a, b) => b.price.compareTo(a.price));
  final result = sortedCourses.take(3).toList();
  print('PopularCoursesProvider: Returning ${result.length} popular courses');
  if (result.isNotEmpty) {
    print('PopularCoursesProvider: First popular course thumbnail: ${result[0].thumbnail ?? "null"}');
  }
  return result;
});

final enrolledCoursesProvider = FutureProvider<List<Course>>((ref) async {
  // Fetch courses the user is enrolled in using the enrollment repository
  final enrollmentRepository = EnrollmentRepository();
  return await enrollmentRepository.getEnrolledCourses();
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
