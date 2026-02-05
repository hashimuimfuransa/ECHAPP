import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/section_repository.dart';
import '../../models/section.dart';
import '../../models/lesson.dart';

// Content management state
class ContentManagementState {
  final List<Section> sections;
  final bool isLoading;
  final String? error;
  final bool isReordering;

  ContentManagementState({
    required this.sections,
    required this.isLoading,
    this.error,
    required this.isReordering,
  });

  ContentManagementState copyWith({
    List<Section>? sections,
    bool? isLoading,
    String? error,
    bool? isReordering,
  }) {
    return ContentManagementState(
      sections: sections ?? this.sections,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isReordering: isReordering ?? this.isReordering,
    );
  }
}

// Content management notifier
class ContentManagementNotifier extends StateNotifier<ContentManagementState> {
  final SectionRepository _sectionRepository;
  final LessonRepository _lessonRepository;

  ContentManagementNotifier({SectionRepository? sectionRepository, LessonRepository? lessonRepository}) 
      : _sectionRepository = sectionRepository ?? SectionRepository(),
        _lessonRepository = lessonRepository ?? LessonRepository(),
        super(ContentManagementState(
          sections: [],
          isLoading: false,
          isReordering: false,
        ));

  // Load sections for a course
  Future<void> loadSections(String courseId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final sections = await _sectionRepository.getSectionsByCourse(courseId);
      
      state = state.copyWith(sections: sections ?? [], isLoading: false);
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
      
      state = state.copyWith(
        sections: [...state.sections, newSection]..sort((a, b) => a.order.compareTo(b.order)),
        isLoading: false,
      );
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
      final updatedSection = await _sectionRepository.updateSection(
        sectionId: sectionId,
        title: updateData['title'] as String?,
        order: updateData['order'] as int?,
      );
      
      final updatedSections = state.sections.map((section) {
        if (section.id == sectionId) {
          return updatedSection;
        }
        return section;
      }).toList();
      
      state = state.copyWith(sections: updatedSections, isLoading: false);
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
      
      final updatedSections = state.sections.where((section) => section.id != sectionId).toList();
      state = state.copyWith(sections: updatedSections, isLoading: false);
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
      
      // Refresh sections after reordering
      final sections = await _sectionRepository.getSectionsByCourse(courseId);
      
      state = state.copyWith(sections: sections ?? [], isLoading: false);
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