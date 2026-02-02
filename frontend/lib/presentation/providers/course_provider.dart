import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excellence_coaching_hub/data/repositories/course_repository.dart';
import 'package:excellence_coaching_hub/data/models/course.dart';
import 'package:excellence_coaching_hub/services/categories_service.dart';

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
  final repository = ref.read(courseRepositoryProvider);
  final allCourses = await repository.getCourses();
  // Sort by rating or popularity (assuming higher price/quality correlates with popularity)
  // In a real scenario, you'd probably have a popularity field from the backend
  final sortedCourses = List<Course>.from(allCourses)..sort((a, b) => b.price.compareTo(a.price));
  return sortedCourses.take(3).toList();
});

final enrolledCoursesProvider = FutureProvider<List<Course>>((ref) async {
  // This would typically fetch courses the user is enrolled in
  // For now, returning an empty list - this would be implemented based on the user's enrollment records
  final repository = ref.read(courseRepositoryProvider);
  final allCourses = await repository.getCourses();
  // Mock: return first 2 courses as enrolled (this would come from enrollment API in real implementation)
  return allCourses.take(2).toList();
});

// Category providers
final allCategoriesProvider = Provider<List<dynamic>>((ref) {
  // Note: This returns the mock categories for now, but could be updated to fetch from backend
  return CategoriesService.getAllCategories();
});

final popularCategoriesProvider = Provider<List<dynamic>>((ref) {
  final allCategories = ref.read(allCategoriesProvider);
  return CategoriesService.getPopularCategories(allCategories.cast());
});

final featuredCategoriesProvider = Provider<List<dynamic>>((ref) {
  final allCategories = ref.read(allCategoriesProvider);
  return CategoriesService.getFeaturedCategories(allCategories.cast());
});