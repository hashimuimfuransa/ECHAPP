import '../../services/api/course_service.dart';
import '../../models/course.dart';

class CourseRepository {
  final CourseService _courseService;

  CourseRepository({CourseService? courseService}) 
      : _courseService = courseService ?? CourseService();

  Future<List<Course>> getCourses({String? categoryId}) async {
    return await _courseService.getAllCourses(categoryId: categoryId);
  }

  Future<Course> getCourseById(String id) async {
    print('Getting course by ID: $id'); // Debug log
    return await _courseService.getCourseById(id);
  }

  Future<Course> createCourse({
    required String title,
    required String description,
    required double price,
    required int duration,
    String? durationUnit,
    required String level,
    String? thumbnail,
    String? instructorName,
    String? categoryId,
    bool? isPublished,
    List<String>? learningObjectives,
    List<String>? requirements,
    int? accessDuration,
    String? accessDurationUnit,
    int? accessDurationDays,
  }) async {
    return await _courseService.createCourse(
      title: title,
      description: description,
      price: price,
      duration: duration,
      durationUnit: durationUnit,
      level: level,
      thumbnail: thumbnail,
      instructorName: instructorName,
      categoryId: categoryId,
      isPublished: isPublished,
      learningObjectives: learningObjectives,
      requirements: requirements,
      accessDuration: accessDuration,
      accessDurationUnit: accessDurationUnit,
      accessDurationDays: accessDurationDays,
    );
  }

  Future<Course> updateCourse({
    required String id,
    String? title,
    String? description,
    double? price,
    int? duration,
    String? durationUnit,
    String? level,
    String? thumbnail,
    String? instructorName,
    String? categoryId,
    bool? isPublished,
    List<String>? learningObjectives,
    List<String>? requirements,
    int? accessDuration,
    String? accessDurationUnit,
    int? accessDurationDays,
  }) async {
    return await _courseService.updateCourse(
      id: id,
      title: title,
      description: description,
      price: price,
      duration: duration,
      durationUnit: durationUnit,
      level: level,
      thumbnail: thumbnail,
      instructorName: instructorName,
      categoryId: categoryId,
      isPublished: isPublished,
      learningObjectives: learningObjectives,
      requirements: requirements,
      accessDuration: accessDuration,
      accessDurationUnit: accessDurationUnit,
      accessDurationDays: accessDurationDays,
    );
  }

  Future<void> deleteCourse(String id) async {
    await _courseService.deleteCourse(id);
  }

  Future<List<Course>> getRecommendedCourses({int limit = 8}) async {
    return await _courseService.getRecommendedCourses(limit: limit);
  }
}
