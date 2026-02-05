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
    required String level,
    String? thumbnail,
    String? categoryId,
    bool? isPublished,
    List<String>? learningObjectives,
    List<String>? requirements,
  }) async {
    return await _courseService.createCourse(
      title: title,
      description: description,
      price: price,
      duration: duration,
      level: level,
      thumbnail: thumbnail,
      categoryId: categoryId,
      isPublished: isPublished,
      learningObjectives: learningObjectives,
      requirements: requirements,
    );
  }

  Future<Course> updateCourse({
    required String id,
    String? title,
    String? description,
    double? price,
    int? duration,
    String? level,
    String? thumbnail,
    String? categoryId,
    bool? isPublished,
    List<String>? learningObjectives,
    List<String>? requirements,
  }) async {
    return await _courseService.updateCourse(
      id: id,
      title: title,
      description: description,
      price: price,
      duration: duration,
      level: level,
      thumbnail: thumbnail,
      categoryId: categoryId,
      isPublished: isPublished,
      learningObjectives: learningObjectives,
      requirements: requirements,
    );
  }

  Future<void> deleteCourse(String id) async {
    await _courseService.deleteCourse(id);
  }
}