import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/section_repository.dart';
import '../../models/section.dart';
import '../../models/lesson.dart';

// Content management state
class ContentManagementState {
  final List<Section> sections;
  final Map<String, List<Lesson>> _lessonsBySection; // sectionId -> lessons
  final bool isLoading;
  final String? error;
  final bool isReordering;

  // Getter - _lessonsBySection is always non-null due to constructor requirements
  Map<String, List<Lesson>> get lessonsBySection => _lessonsBySection;

  ContentManagementState({
    required this.sections,
    required Map<String, List<Lesson>> lessonsBySection,
    required this.isLoading,
    this.error,
    required this.isReordering,
  }) : _lessonsBySection = lessonsBySection;

  ContentManagementState copyWith({
    List<Section>? sections,
    Map<String, List<Lesson>>? lessonsBySection,
    bool? isLoading,
    String? error,
    bool? isReordering,
  }) {
    return ContentManagementState(
      sections: sections ?? this.sections,
      lessonsBySection: lessonsBySection ?? this._lessonsBySection,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isReordering: isReordering ?? this.isReordering,
    );
  }
}

// Content management notifier
class ContentManagementNotifier extends StateNotifier<ContentManagementState> {
  final SectionRepository _sectionRepository;

  ContentManagementNotifier({SectionRepository? sectionRepository}) 
      : _sectionRepository = sectionRepository ?? SectionRepository(),
        super(ContentManagementState(
          sections: [],
          lessonsBySection: <String, List<Lesson>>{}, // Explicitly typed empty map
          isLoading: false,
          isReordering: false,
        ));

  // Load sections and lessons for a course
  Future<void> loadSections(String courseId) async {
    print('Loading sections for course: $courseId');
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Get course content which includes both sections and lessons
      final courseContent = await _sectionRepository.getCourseContent(courseId);
      print('Course content received: $courseContent');
      final sectionsData = courseContent['sections'] as List? ?? [];
      print('Sections data: $sectionsData (length: ${sectionsData.length})');
      
      // Parse sections and create lessons mapping
      final sections = <Section>[];
      final lessonsBySection = <String, List<Lesson>>{};
      
      // Ensure we always have a valid map even if parsing fails
      if (sectionsData.isEmpty) {
        state = state.copyWith(
          sections: [],
          lessonsBySection: <String, List<Lesson>>{},
          isLoading: false,
        );
        return;
      }
      
      for (var sectionData in sectionsData) {
        if (sectionData is Map<String, dynamic>) {
          try {
          print('Parsing section data: $sectionData');
          // Create section object
          final section = Section(
            id: sectionData['_id']?.toString() ?? sectionData['id']?.toString() ?? '',
            courseId: sectionData['courseId']?.toString() ?? '',
            title: sectionData['title']?.toString() ?? '',
            order: sectionData['order'] as int? ?? 0,
          );
          sections.add(section);
          print('Created section: ${section.title} (id: ${section.id})');
          
          // Extract lessons for this section
          final lessonsData = sectionData['lessons'] as List? ?? [];
          print('Lessons data for section ${section.id}: $lessonsData (length: ${lessonsData.length})');
          final sectionLessons = <Lesson>[];
          
          for (var lessonData in lessonsData) {
            if (lessonData is Map<String, dynamic>) {
              try {
                print('Parsing lesson data: $lessonData');
                final lesson = Lesson(
                  id: lessonData['_id']?.toString() ?? lessonData['id']?.toString() ?? '',
                  sectionId: lessonData['sectionId']?.toString() ?? '',
                  courseId: lessonData['courseId']?.toString() ?? '',
                  title: lessonData['title']?.toString() ?? '',
                  description: lessonData['description']?.toString(),
                  videoId: lessonData['videoId']?.toString(),
                  notes: lessonData['notes'] as String?,
                  order: lessonData['order'] as int? ?? 0,
                  duration: lessonData['duration'] as int? ?? 0,
                );
                sectionLessons.add(lesson);
                print('Created lesson: ${lesson.title} (id: ${lesson.id})');
              } catch (e) {
                // Log the error but continue processing other lessons
                print('Error parsing lesson data: $e');
              }
            }
          }
          
          lessonsBySection[section.id] = sectionLessons;
          } catch (e) {
            // Log the error but continue processing other sections
            print('Error parsing section data: $e');
          }
        }
      }
      
      print('Final parsing results - Sections: ${sections.length}, Lessons mapping: ${lessonsBySection.length}');
      // Final safety check to ensure we have valid data
      final safeLessonsBySection = lessonsBySection.isNotEmpty ? lessonsBySection : <String, List<Lesson>>{};
      print('Using lessonsBySection with ${safeLessonsBySection.length} entries');
      state = state.copyWith(
        sections: sections,
        lessonsBySection: safeLessonsBySection,
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString(),
      );
    }
  }

  // Create section
  Future<void> createSection(String courseId, String title, int order) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final newSection = await _sectionRepository.createSection(
        courseId: courseId,
        title: title,
        order: order,
      );
      
      // Refresh all data to get updated sections and lessons
      await loadSections(courseId);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString(),
      );
    }
  }

  // Update section
  Future<void> updateSection(String sectionId, Map<String, dynamic> updateData) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _sectionRepository.updateSection(
        sectionId: sectionId,
        title: updateData['title'] as String?,
        order: updateData['order'] as int?,
      );
      
      // Refresh all data to get updated sections and lessons
      final courseId = state.sections.firstWhere((s) => s.id == sectionId).courseId;
      await loadSections(courseId);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString(),
      );
    }
  }

  // Delete section
  Future<void> deleteSection(String sectionId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _sectionRepository.deleteSection(sectionId);
      
      // Refresh all data to get updated sections and lessons
      final courseId = state.sections.firstWhere((s) => s.id == sectionId).courseId;
      await loadSections(courseId);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString(),
      );
    }
  }

  // Reorder sections
  Future<void> reorderSections(String courseId, List<Map<String, dynamic>> newOrder) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _sectionRepository.reorderSections(courseId, newOrder);
      
      // Refresh all data to get updated sections and lessons
      await loadSections(courseId);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString(),
      );
    }
  }

  // Update lesson - optimized to only update specific lesson without full refresh
  Future<void> updateLesson(String lessonId, Map<String, dynamic> updateData) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final lessonRepo = LessonRepository();
      final updatedLesson = await lessonRepo.updateLesson(
        lessonId: lessonId,
        title: updateData['title'],
        description: updateData['description'],
        videoId: updateData['videoId'],
        notes: updateData['notes'],
        duration: updateData['duration'],
      );
      
      // Update the lesson in our local state without full refresh
      final updatedLessonsBySection = Map<String, List<Lesson>>.from(state.lessonsBySection);
      final sectionId = updateData['sectionId'];
      
      if (sectionId != null && updatedLessonsBySection.containsKey(sectionId)) {
        final lessonsInSection = List<Lesson>.from(updatedLessonsBySection[sectionId]!);
        final lessonIndex = lessonsInSection.indexWhere((lesson) => lesson.id == lessonId);
        
        if (lessonIndex != -1) {
          lessonsInSection[lessonIndex] = updatedLesson;
          updatedLessonsBySection[sectionId] = lessonsInSection;
        }
      }
      
      state = state.copyWith(
        lessonsBySection: updatedLessonsBySection,
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString(),
      );
    }
  }

  // Toggle reordering mode
  void toggleReordering() {
    state = state.copyWith(isReordering: !state.isReordering);
  }
}

// Provider for content management
final contentManagementProvider = StateNotifierProvider<ContentManagementNotifier, ContentManagementState>((ref) {
  return ContentManagementNotifier();
});
