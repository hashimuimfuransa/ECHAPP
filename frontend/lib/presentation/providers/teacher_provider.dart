import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:excellencecoachinghub/services/teacher_service.dart';
import 'package:excellencecoachinghub/models/teacher_course.dart';
import 'package:excellencecoachinghub/models/student_performance.dart';

/// Teacher Provider for managing teacher-related state
final teacherProvider = StateNotifierProvider<TeacherNotifier, TeacherState>((ref) {
  return TeacherNotifier();
});

/// Teacher State
class TeacherState {
  final bool isLoading;
  final String? error;
  final TeacherDashboardStats? dashboardStats;
  final List<TeacherCourse> courses;
  final CourseContent? selectedCourseContent;
  final List<StudentPerformance> students;
  final int currentPage;
  final int totalPages;

  TeacherState({
    this.isLoading = false,
    this.error,
    this.dashboardStats,
    this.courses = const [],
    this.selectedCourseContent,
    this.students = const [],
    this.currentPage = 1,
    this.totalPages = 1,
  });

  TeacherState copyWith({
    bool? isLoading,
    String? error,
    TeacherDashboardStats? dashboardStats,
    List<TeacherCourse>? courses,
    CourseContent? selectedCourseContent,
    List<StudentPerformance>? students,
    int? currentPage,
    int? totalPages,
  }) {
    return TeacherState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      dashboardStats: dashboardStats ?? this.dashboardStats,
      courses: courses ?? this.courses,
      selectedCourseContent: selectedCourseContent ?? this.selectedCourseContent,
      students: students ?? this.students,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
    );
  }
}

/// Teacher Notifier
class TeacherNotifier extends StateNotifier<TeacherState> {
  final TeacherService _teacherService = TeacherService();

  TeacherNotifier() : super(TeacherState());

  /// Load dashboard statistics
  Future<void> loadDashboardStats() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final stats = await _teacherService.getDashboardStats();
      state = state.copyWith(
        isLoading: false,
        dashboardStats: stats,
      );
    } catch (e) {
      debugPrint('Load Dashboard Stats Error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load dashboard stats: $e',
      );
    }
  }

  /// Load assigned courses
  Future<void> loadCourses({int page = 1}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final response = await _teacherService.getAssignedCourses(page: page);
      state = state.copyWith(
        isLoading: false,
        courses: response.courses,
        currentPage: response.currentPage,
        totalPages: response.totalPages,
      );
    } catch (e) {
      debugPrint('Load Courses Error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load courses: $e',
      );
    }
  }

  /// Load course content (sections and lessons)
  Future<void> loadCourseContent(String courseId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final content = await _teacherService.getCourseContent(courseId);
      state = state.copyWith(
        isLoading: false,
        selectedCourseContent: content,
      );
    } catch (e) {
      debugPrint('Load Course Content Error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load course content: $e',
      );
    }
  }

  /// Load students for a course
  Future<void> loadStudents(
    String courseId, {
    int page = 1,
    String? search,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final response = await _teacherService.getCourseStudents(
        courseId,
        page: page,
        search: search,
      );
      state = state.copyWith(
        isLoading: false,
        students: response.students,
        currentPage: response.currentPage,
        totalPages: response.totalPages,
      );
    } catch (e) {
      debugPrint('Load Students Error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load students: $e',
      );
    }
  }

  /// Clear any error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Refresh all data
  Future<void> refresh() async {
    await Future.wait([
      loadDashboardStats(),
      loadCourses(),
    ]);
  }
}
