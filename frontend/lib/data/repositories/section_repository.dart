import '../../services/api/section_service.dart';
import '../../models/section.dart';
import '../../models/lesson.dart';

class SectionRepository {
  final SectionService _sectionService;

  SectionRepository({SectionService? sectionService}) 
      : _sectionService = sectionService ?? SectionService();

  Future<List<Section>> getSectionsByCourse(String courseId) async {
    return await _sectionService.getSectionsByCourse(courseId);
  }

  Future<Section> createSection({
    required String courseId,
    required String title,
    required int order,
  }) async {
    return await _sectionService.createSection(
      courseId: courseId,
      title: title,
      order: order,
    );
  }

  Future<Section> updateSection({
    required String sectionId,
    String? title,
    int? order,
  }) async {
    return await _sectionService.updateSection(
      sectionId: sectionId,
      title: title,
      order: order,
    );
  }

  Future<void> deleteSection(String sectionId) async {
    await _sectionService.deleteSection(sectionId);
  }

  Future<void> reorderSections(String courseId, List<Map<String, dynamic>> newOrder) async {
    await _sectionService.reorderSections(courseId, newOrder);
  }

  Future<Map<String, dynamic>> getCourseContent(String courseId) async {
    return await _sectionService.getCourseContent(courseId);
  }
}

class LessonRepository {
  final SectionService _sectionService;

  LessonRepository({SectionService? sectionService}) 
      : _sectionService = sectionService ?? SectionService();

  Future<List<Lesson>> getLessonsBySection(String sectionId) async {
    return await _sectionService.getLessonsBySection(sectionId);
  }

  Future<Lesson> createLesson({
    required String courseId,
    required String sectionId,
    required String title,
    String? description,
    String? videoId,
    String? notes,
    required int order,
    required int duration,
  }) async {
    return await _sectionService.createLesson(
      courseId: courseId,
      sectionId: sectionId,
      title: title,
      description: description,
      videoId: videoId,
      notes: notes,
      order: order,
      duration: duration,
    );
  }

  Future<Lesson> updateLesson({
    required String lessonId,
    String? title,
    String? description,
    String? videoId,
    String? notes,
    int? order,
    int? duration,
  }) async {
    return await _sectionService.updateLesson(
      lessonId: lessonId,
      title: title,
      description: description,
      videoId: videoId,
      notes: notes,
      order: order,
      duration: duration,
    );
  }

  Future<void> deleteLesson(String lessonId) async {
    await _sectionService.deleteLesson(lessonId);
  }

  Future<void> reorderLessons(String sectionId, List<Map<String, dynamic>> newOrder) async {
    await _sectionService.reorderLessons(sectionId, newOrder);
  }
}