import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excellence_coaching_hub/models/course.dart';
import 'package:excellence_coaching_hub/services/api/course_service.dart';

// Admin course management state
class AdminCourseState {
  final List<Course> courses;
  final bool isLoading;
  final String? error;
  final Course? selectedCourse;

  AdminCourseState({
    required this.courses,
    required this.isLoading,
    this.error,
    this.selectedCourse,
  });

  AdminCourseState copyWith({
    List<Course>? courses,
    bool? isLoading,
    String? error,
    Course? selectedCourse,
  }) {
    return AdminCourseState(
      courses: courses ?? this.courses,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedCourse: selectedCourse ?? this.selectedCourse,
    );
  }
}

// Admin course notifier
class AdminCourseNotifier extends StateNotifier<AdminCourseState> {
  final CourseService _courseService = CourseService();

  AdminCourseNotifier() : super(AdminCourseState(
    courses: [],
    isLoading: false,
  ));

  // Load all courses for admin
  Future<void> loadCourses() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Fetch real courses from backend, including unpublished ones for admin
      final courses = await _courseService.getAllCourses(showUnpublished: true);
      print('Loaded ${courses.length} courses for admin'); // Debug log
      for (var course in courses) {
        print('Course ID: ${course.id}, Title: ${course.title ?? "Untitled Course"}'); // Debug log
      }
      state = state.copyWith(courses: courses, isLoading: false);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString(),
      );
    }
  }

  // Search courses
  Future<void> searchCourses(String query) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Fetch courses with search query
      final courses = await _courseService.searchCourses(query, showUnpublished: true);
      state = state.copyWith(courses: courses, isLoading: false);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString(),
      );
    }
  }

  // Filter courses by status
  void filterCoursesByStatus(String status) {
    // This would be implemented with proper filtering logic
    // For now, we'll just reload with the appropriate filter
    loadCourses();
  }

  // Create new course
  Future<void> createCourse(Map<String, dynamic> courseData) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final newCourse = await _courseService.createCourse(
        title: courseData['title'],
        description: courseData['description'],
        price: courseData['price'],
        duration: courseData['duration'],
        level: courseData['level'],
        thumbnail: courseData['thumbnail'],
        categoryId: courseData['categoryId'],
        learningObjectives: courseData['learningObjectives'],
        requirements: courseData['requirements'],
      );
      
      state = state.copyWith(
        courses: [...state.courses, newCourse],
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString(),
      );
    }
  }

  // Update course
  Future<void> updateCourse(String courseId, Map<String, dynamic> updateData) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final updatedCourse = await _courseService.updateCourse(
        id: courseId,
        title: updateData['title'],
        description: updateData['description'],
        price: updateData['price'],
        duration: updateData['duration'],
        level: updateData['level'],
        thumbnail: updateData['thumbnail'],
        categoryId: updateData['categoryId'],
        isPublished: updateData['isPublished'],
        learningObjectives: updateData['learningObjectives'],
        requirements: updateData['requirements'],
      );
      
      final updatedCourses = state.courses.map((course) {
        return course.id == courseId ? updatedCourse : course;
      }).toList();
      
      state = state.copyWith(courses: updatedCourses, isLoading: false);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString(),
      );
    }
  }

  // Delete course
  Future<void> deleteCourse(String courseId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _courseService.deleteCourse(courseId);
      final updatedCourses = state.courses.where((course) => course.id != courseId).toList();
      state = state.copyWith(courses: updatedCourses, isLoading: false);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString(),
      );
    }
  }

  // Select course for editing
  void selectCourse(Course course) {
    state = state.copyWith(selectedCourse: course);
  }

  // Toggle course publish status
  Future<void> toggleCoursePublish(String courseId, bool currentStatus) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final updatedCourse = await _courseService.updateCourse(
        id: courseId,
        isPublished: !currentStatus,
      );
      
      final updatedCourses = state.courses.map((course) {
        return course.id == courseId ? updatedCourse : course;
      }).toList();
      
      state = state.copyWith(courses: updatedCourses, isLoading: false);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString(),
      );
    }
  }

  @override
  void dispose() {
    _courseService.dispose();
    super.dispose();
  }
}

// Provider for admin course management
final adminCourseProvider = StateNotifierProvider<AdminCourseNotifier, AdminCourseState>((ref) {
  return AdminCourseNotifier();
});