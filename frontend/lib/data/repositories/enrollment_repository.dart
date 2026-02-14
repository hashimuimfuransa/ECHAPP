import '../../services/api/enrollment_service.dart';
import '../../models/course.dart';

class EnrollmentRepository {
  final EnrollmentService _enrollmentService;

  EnrollmentRepository({EnrollmentService? enrollmentService}) 
      : _enrollmentService = enrollmentService ?? EnrollmentService();

  /// Enroll in a course
  Future<void> enrollInCourse(String courseId) async {
    return await _enrollmentService.enrollInCourse(courseId);
  }

  /// Get user's enrolled courses
  Future<List<Course>> getEnrolledCourses() async {
    return await _enrollmentService.getEnrolledCourses();
  }

  /// Check if user is enrolled in a specific course
  Future<bool> isEnrolledInCourse(String courseId) async {
    return await _enrollmentService.isEnrolledInCourse(courseId);
  }
}
