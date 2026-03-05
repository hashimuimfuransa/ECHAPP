import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excellencecoachinghub/services/api/course_service.dart';

/// Provider for course statistics including enrollment count
final courseStatsProvider = FutureProvider.family<int, String>((ref, courseId) async {
  final courseService = CourseService();
  try {
    print('Fetching real enrollment count for course: $courseId');
    
    // Fetch the actual course data which now includes the up-to-date enrollmentCount
    final course = await courseService.getCourseById(courseId);
    
    final count = course.enrollmentCount ?? 0;
    print('Course $courseId has $count enrolled students');
    return count;
  } catch (e) {
    print('Error fetching enrollment count for course $courseId: $e');
    return 0;
  }
});