import '../../models/lesson.dart';
import '../../services/api/section_service.dart';
import '../../services/infrastructure/api_client.dart';
import '../../config/api_config.dart';

class LessonRepository {
  final SectionService _sectionService;
  final ApiClient _apiClient;

  LessonRepository({SectionService? sectionService, ApiClient? apiClient}) 
      : _sectionService = sectionService ?? SectionService(),
        _apiClient = apiClient ?? ApiClient();

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
    String? quizId, // New field for quiz association
    List<String>? materials, // New field for additional materials
    String? lessonType, // New field for lesson type
    bool? isPublished, // New field for publish status
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
      quizId: quizId, // Pass quiz ID
      materials: materials, // Pass materials
      lessonType: lessonType, // Pass lesson type
      isPublished: isPublished, // Pass publish status
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
    String? quizId, // New field for quiz association
    List<String>? materials, // New field for additional materials
    String? lessonType, // New field for lesson type
    bool? isPublished, // New field for publish status
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
      quizId: quizId, // Pass quiz ID
      materials: materials, // Pass materials
      lessonType: lessonType, // Pass lesson type
      isPublished: isPublished, // Pass publish status
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

  /// Get lesson by ID
  Future<Lesson?> getLessonById(String lessonId) async {
    try {
      final response = await _apiClient.get('${ApiConfig.lessons}/$lessonId');
      response.validateStatus();

      final apiResponse = response.toApiResponse((json) => Lesson.fromJson(json));
      
      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      } else {
        return null;
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch lesson: $e');
    }
  }
}
