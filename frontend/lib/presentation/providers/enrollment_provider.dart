import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excellencecoachinghub/data/repositories/enrollment_repository.dart';
import 'package:excellencecoachinghub/models/course.dart';

final enrollmentRepositoryProvider = Provider<EnrollmentRepository>((ref) {
  return EnrollmentRepository();
});

// Provider to check if user is enrolled in a specific course
final isEnrolledInCourseProvider = FutureProvider.family<bool, String>((ref, courseId) async {
  final repository = ref.read(enrollmentRepositoryProvider);
  print('Checking enrollment status for course: $courseId');
  try {
    final result = await repository.isEnrolledInCourse(courseId);
    print('Enrollment check result for course $courseId: $result');
    return result;
  } catch (e) {
    print('Error checking enrollment for course $courseId: $e');
    return false;
  }
});

// Provider for enrolled courses
final enrolledCoursesProvider = FutureProvider<List<Course>>((ref) async {
  final repository = ref.read(enrollmentRepositoryProvider);
  return await repository.getEnrolledCourses();
});

// Async notifier for enrollment actions
final enrollmentNotifierProvider = AsyncNotifierProvider<EnrollmentNotifier, void>(
  () => EnrollmentNotifier(),
);

class EnrollmentNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> enrollInCourse(String courseId) async {
    final repository = ref.read(enrollmentRepositoryProvider);
    state = const AsyncValue.loading();
    
    try {
      await repository.enrollInCourse(courseId);
      state = const AsyncValue.data(null);
      
      // Refresh enrolled courses
      ref.invalidate(enrolledCoursesProvider);
      ref.invalidate(isEnrolledInCourseProvider(courseId));
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}
