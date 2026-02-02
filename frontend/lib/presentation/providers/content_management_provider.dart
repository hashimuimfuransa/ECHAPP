import 'package:flutter_riverpod/flutter_riverpod.dart';

// Section model
class Section {
  final String id;
  final String courseId;
  final String title;
  final int order;

  Section({
    required this.id,
    required this.courseId,
    required this.title,
    required this.order,
  });

  Section.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        courseId = json['courseId'],
        title = json['title'],
        order = json['order'];

  Map<String, dynamic> toJson() => {
        'id': id,
        'courseId': courseId,
        'title': title,
        'order': order,
      };
}

// Lesson model
class Lesson {
  final String id;
  final String sectionId;
  final String courseId;
  final String title;
  final String? description;
  final String? videoId;
  final String? notes;
  final int order;
  final int duration;

  Lesson({
    required this.id,
    required this.sectionId,
    required this.courseId,
    required this.title,
    this.description,
    this.videoId,
    this.notes,
    required this.order,
    required this.duration,
  });

  Lesson.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        sectionId = json['sectionId'],
        courseId = json['courseId'],
        title = json['title'],
        description = json['description'],
        videoId = json['videoId'],
        notes = json['notes'],
        order = json['order'],
        duration = json['duration'];

  Map<String, dynamic> toJson() => {
        'id': id,
        'sectionId': sectionId,
        'courseId': courseId,
        'title': title,
        'description': description,
        'videoId': videoId,
        'notes': notes,
        'order': order,
        'duration': duration,
      };
}

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
  ContentManagementNotifier() : super(ContentManagementState(
    sections: [],
    isLoading: false,
    isReordering: false,
  ));

  // Load sections for a course
  Future<void> loadSections(String courseId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // In real implementation: final sections = await sectionRepository.getSectionsByCourse(courseId)
      
      // Mock data
      final mockSections = [
        Section(id: '1', courseId: courseId, title: 'Introduction', order: 1),
        Section(id: '2', courseId: courseId, title: 'Core Concepts', order: 2),
        Section(id: '3', courseId: courseId, title: 'Advanced Topics', order: 3),
      ];
      
      state = state.copyWith(sections: mockSections, isLoading: false);
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
      // In real implementation: await sectionRepository.createSection(courseId, title, order)
      
      // Mock implementation
      final newSection = Section(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
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
      // In real implementation: await sectionRepository.updateSection(sectionId, updateData)
      
      // Mock implementation
      final updatedSections = state.sections.map((section) {
        if (section.id == sectionId) {
          return Section(
            id: section.id,
            courseId: section.courseId,
            title: updateData['title'] ?? section.title,
            order: updateData['order'] ?? section.order,
          );
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
      // In real implementation: await sectionRepository.deleteSection(sectionId)
      
      // Mock implementation
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
      // In real implementation: await sectionRepository.reorderSections(courseId, newOrder)
      
      // Mock implementation
      final updatedSections = state.sections.map((section) {
        final newOrderItem = newOrder.firstWhere(
          (item) => item['sectionId'] == section.id,
          orElse: () => {'order': section.order},
        );
        return Section(
          id: section.id,
          courseId: section.courseId,
          title: section.title,
          order: newOrderItem['order'] as int,
        );
      }).toList();
      
      state = state.copyWith(
        sections: updatedSections..sort((a, b) => a.order.compareTo(b.order)),
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