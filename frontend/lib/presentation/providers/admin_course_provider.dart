import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excellencecoachinghub/models/course.dart';
import 'package:excellencecoachinghub/services/api/course_service.dart';

// Admin course management state
class AdminCourseState {
  final List<Course> courses;
  final bool isLoading;
  final String? error;
  final Course? selectedCourse;
  final int totalCourses;

  AdminCourseState({
    required this.courses,
    required this.isLoading,
    this.error,
    this.selectedCourse,
    this.totalCourses = 0,
  });

  AdminCourseState copyWith({
    List<Course>? courses,
    bool? isLoading,
    String? error,
    Course? selectedCourse,
    int? totalCourses,
  }) {
    return AdminCourseState(
      courses: courses ?? this.courses,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedCourse: selectedCourse ?? this.selectedCourse,
      totalCourses: totalCourses ?? this.totalCourses,
    );
  }
}

// Admin course notifier
class AdminCourseNotifier extends StateNotifier<AdminCourseState> {
  final CourseService _courseService = CourseService();
  static const int _pageSize = 50;

  AdminCourseNotifier() : super(AdminCourseState(
    courses: [],
    isLoading: false,
  ));

  // Load all courses for admin by fetching all pages
  Future<void> loadCourses() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final allCourses = <Course>[];
      int page = 1;
      bool hasMore = true;

      while (hasMore) {
        final result = await _courseService.getCoursesPaged(
          page: page,
          limit: _pageSize,
          showUnpublished: true,
        );
        allCourses.addAll(result.courses);
        hasMore = result.hasNextPage;
        page++;
      }

      print('Loaded ${allCourses.length} courses for admin');
      state = state.copyWith(courses: allCourses, isLoading: false, totalCourses: allCourses.length);
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
      final allCourses = <Course>[];
      int page = 1;
      bool hasMore = true;

      while (hasMore) {
        final result = await _courseService.getCoursesPaged(
          page: page,
          limit: _pageSize,
          search: query,
          showUnpublished: true,
        );
        allCourses.addAll(result.courses);
        hasMore = result.hasNextPage;
        page++;
      }

      state = state.copyWith(courses: allCourses, isLoading: false);
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
