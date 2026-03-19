import '../../models/lesson.dart';
import '../../services/api/section_service.dart';

class LessonRepository {
  final SectionService _sectionService;

  LessonRepository({SectionService? sectionService}) 
      : _sectionService = sectionService ?? SectionService();

  /// Create a new lesson
  Future<Lesson> createLesson({
    required String courseId,
    required String sectionId,
    required String title,
    String? description,
    String? videoId,
    String? notes,
    String? notesPdfUrl,
    bool processNotes = false,
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
      notesPdfUrl: notesPdfUrl,
      processNotes: processNotes,
      order: order,
      duration: duration,
    );
  }

  /// Create a lesson with document upload
  Future<Lesson> createLessonWithDocument({
    required String courseId,
    required String sectionId,
    required String title,
    String? description,
    String? documentPath,
    String? notesPdfUrl,
    bool processNotes = false,
    required int order,
    required int duration,
  }) async {
    return await _sectionService.createLessonWithDocument(
      courseId: courseId,
      sectionId: sectionId,
      title: title,
      description: description,
      documentPath: documentPath,
      notesPdfUrl: notesPdfUrl,
      processNotes: processNotes,
      order: order,
      duration: duration,
    );
  }

  /// Update an existing lesson
  Future<Lesson> updateLesson({
    required String lessonId,
    String? title,
    String? description,
    String? videoId,
    String? notes,
    String? notesPdfUrl,
    int? order,
    int? duration,
  }) async {
    return await _sectionService.updateLesson(
      lessonId: lessonId,
      title: title,
      description: description,
      videoId: videoId,
      notes: notes,
      notesPdfUrl: notesPdfUrl,
      order: order,
      duration: duration,
    );
  }

  /// Delete a lesson
  Future<void> deleteLesson(String lessonId) async {
    return await _sectionService.deleteLesson(lessonId);
  }

  /// Get lessons by section
  Future<List<Lesson>> getLessonsBySection(String sectionId) async {
    return await _sectionService.getLessonsBySection(sectionId);
  }
}
