import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excellence_coaching_hub/data/models/course.dart';
import 'package:excellence_coaching_hub/data/models/user.dart';

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
  AdminCourseNotifier() : super(AdminCourseState(
    courses: [],
    isLoading: false,
  ));

  // Load all courses for admin
  Future<void> loadCourses() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // In real implementation, this would call the API
      // final courses = await courseRepository.getAdminCourses();
      
      // Mock data for now
      final mockCourses = [
        Course(
          id: '1',
          title: 'Mathematics Advanced',
          description: 'Advanced mathematics concepts for high school students',
          price: 150000,
          duration: 120,
          level: 'advanced',
          thumbnail: '',
          isPublished: true,
          createdBy: User(
            id: 'admin1',
            fullName: 'Admin User',
            email: 'admin@example.com',
            role: 'admin',
            createdAt: DateTime.now(),
          ),
          createdAt: DateTime.now(),
        ),
        Course(
          id: '2',
          title: 'Physics Fundamentals',
          description: 'Basic physics concepts for beginners',
          price: 120000,
          duration: 90,
          level: 'beginner',
          thumbnail: '',
          isPublished: false,
          createdBy: User(
            id: 'admin1',
            fullName: 'Admin User',
            email: 'admin@example.com',
            role: 'admin',
            createdAt: DateTime.now(),
          ),
          createdAt: DateTime.now(),
        ),
      ];
      
      state = state.copyWith(courses: mockCourses, isLoading: false);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString(),
      );
    }
  }

  // Create new course
  Future<void> createCourse(Map<String, dynamic> courseData) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // In real implementation: await courseRepository.createCourse(courseData)
      
      // Mock implementation
      final newCourse = Course(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: courseData['title'],
        description: courseData['description'],
        price: courseData['price'],
        duration: courseData['duration'],
        level: courseData['level'],
        thumbnail: courseData['thumbnail'] ?? '',
        isPublished: courseData['isPublished'] ?? false,
        createdBy: User(
          id: 'admin1',
          fullName: 'Admin User',
          email: 'admin@example.com',
          role: 'admin',
          createdAt: DateTime.now(),
        ),
        createdAt: DateTime.now(),
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
      // In real implementation: await courseRepository.updateCourse(courseId, updateData)
      
      // Mock implementation
      final updatedCourses = state.courses.map((course) {
        if (course.id == courseId) {
          return Course(
            id: course.id,
            title: updateData['title'] ?? course.title,
            description: updateData['description'] ?? course.description,
            price: updateData['price'] ?? course.price,
            duration: updateData['duration'] ?? course.duration,
            level: updateData['level'] ?? course.level,
            thumbnail: updateData['thumbnail'] ?? course.thumbnail,
            isPublished: updateData['isPublished'] ?? course.isPublished,
            createdBy: course.createdBy,
            createdAt: course.createdAt,
          );
        }
        return course;
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
      // In real implementation: await courseRepository.deleteCourse(courseId)
      
      // Mock implementation
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

  // Clear selection
  void clearSelection() {
    state = state.copyWith(selectedCourse: null);
  }
}

// Provider for admin course management
final adminCourseProvider = StateNotifierProvider<AdminCourseNotifier, AdminCourseState>((ref) {
  return AdminCourseNotifier();
});