import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:excellence_coaching_hub/presentation/screens/splash/splash_screen.dart';
import 'package:excellence_coaching_hub/presentation/screens/auth/login_screen.dart';
import 'package:excellence_coaching_hub/presentation/screens/auth/register_screen.dart';
import 'package:excellence_coaching_hub/presentation/screens/auth/forgot_password_screen.dart';
import 'package:excellence_coaching_hub/presentation/screens/auth/auth_selection_screen.dart';
import 'package:excellence_coaching_hub/presentation/screens/auth/email_auth_option_screen.dart';
import 'package:excellence_coaching_hub/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:excellence_coaching_hub/presentation/screens/courses/courses_screen.dart';
import 'package:excellence_coaching_hub/presentation/screens/courses/course_detail_screen.dart';
import 'package:excellence_coaching_hub/presentation/screens/profile/profile_screen.dart';
import 'package:excellence_coaching_hub/presentation/screens/settings/settings_screen.dart';
import 'package:excellence_coaching_hub/presentation/screens/certificates/certificates_screen.dart';
import 'package:excellence_coaching_hub/presentation/screens/privacy/privacy_screen.dart';
import 'package:excellence_coaching_hub/presentation/screens/categories/categories_screen.dart';
import 'package:excellence_coaching_hub/presentation/screens/learning/learning_path_screen.dart';
import 'package:excellence_coaching_hub/presentation/screens/enrolled/enrolled_courses_screen.dart';
import 'package:excellence_coaching_hub/presentation/screens/help/help_screen.dart';
import 'package:excellence_coaching_hub/presentation/screens/admin/admin_dashboard_screen.dart';
import 'package:excellence_coaching_hub/presentation/screens/admin/admin_courses_screen.dart';
import 'package:excellence_coaching_hub/presentation/screens/admin/create_course_screen.dart';
import 'package:excellence_coaching_hub/presentation/screens/admin/admin_course_content_screen.dart';
import 'package:excellence_coaching_hub/presentation/screens/admin/admin_create_lesson_screen.dart';
import 'package:excellence_coaching_hub/presentation/screens/admin/admin_students_screen.dart';
import 'package:excellence_coaching_hub/presentation/screens/admin/course_videos_screen.dart';
import 'package:excellence_coaching_hub/presentation/screens/admin/course_materials_screen.dart';
import 'package:excellence_coaching_hub/presentation/screens/admin/course_exams_screen.dart';
import 'package:excellence_coaching_hub/presentation/screens/admin/admin_settings_screen.dart';
import 'package:excellence_coaching_hub/presentation/screens/admin/payment_management_screen_riverpod.dart';
import 'package:excellence_coaching_hub/presentation/screens/admin/admin_videos_screen.dart';
import 'package:excellence_coaching_hub/presentation/screens/admin/admin_analytics_screen.dart';
import 'package:excellence_coaching_hub/presentation/screens/exams/create_exam_screen.dart';
import 'package:excellence_coaching_hub/presentation/screens/learning/modern_student_learning_screen.dart';

class AppRouter {
  GoRouter get router => GoRouter(
        initialLocation: '/',
        routes: [
          // Splash Screen
          GoRoute(
            path: '/',
            builder: (context, state) => const SplashScreen(),
          ),
          
          // Authentication Routes
          GoRoute(
            path: '/auth-selection',
            builder: (context, state) => const AuthSelectionScreen(),
          ),
          GoRoute(
            path: '/email-auth-option',
            builder: (context, state) => const EmailAuthOptionScreen(),
          ),
          GoRoute(
            path: '/login',
            builder: (context, state) => const LoginScreen(),
          ),
          GoRoute(
            path: '/register',
            builder: (context, state) => const RegisterScreen(),
          ),
          GoRoute(
            path: '/forgot-password',
            builder: (context, state) => const ForgotPasswordScreen(),
          ),
          
          // Main App Routes
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/courses',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return CoursesScreen(
                categoryId: extra?['categoryId'] as String?,
                categoryName: extra?['categoryName'] as String?,
              );
            },
          ),
          GoRoute(
            path: '/course/:id',
            builder: (context, state) {
              final courseId = state.pathParameters['id'] ?? '';
              return CourseDetailScreen(courseId: courseId);
            },
          ),
          
          // Admin Routes
          GoRoute(
            path: '/admin',
            builder: (context, state) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/admin/courses',
            builder: (context, state) => const AdminCoursesScreen(),
          ),
          GoRoute(
            path: '/admin/courses/create',
            builder: (context, state) => const AdminCreateCourseScreen(),
          ),
          GoRoute(
            path: '/admin/courses/:courseId/edit',
            builder: (context, state) {
              final courseId = state.pathParameters['courseId'] ?? '';
              return AdminCreateCourseScreen(courseId: courseId);
            },
          ),
          GoRoute(
            path: '/admin/courses/:courseId/content',
            builder: (context, state) {
              final courseId = state.pathParameters['courseId'] ?? '';
              return AdminCourseContentScreen(courseId: courseId);
            },
          ),
          GoRoute(
            path: '/admin/courses/:courseId/videos',
            builder: (context, state) {
              final courseId = state.pathParameters['courseId'] ?? '';
              return CourseVideosScreen(courseId: courseId);
            },
          ),
          GoRoute(
            path: '/admin/courses/:courseId/materials',
            builder: (context, state) {
              final courseId = state.pathParameters['courseId'] ?? '';
              return CourseMaterialsScreen(courseId: courseId);
            },
          ),
          GoRoute(
            path: '/admin/courses/:courseId/exams',
            builder: (context, state) {
              final courseId = state.pathParameters['courseId'] ?? '';
              return CourseExamsScreen(courseId: courseId);
            },
          ),
          GoRoute(
            path: '/admin/courses/:courseId/sections/:sectionId/lessons/create',
            builder: (context, state) {
              final courseId = state.pathParameters['courseId'] ?? '';
              final sectionId = state.pathParameters['sectionId'] ?? '';
              return AdminCreateLessonScreen(
                courseId: courseId,
                sectionId: sectionId,
              );
            },
          ),
          GoRoute(
            path: '/admin/videos',
            builder: (context, state) => const AdminVideosScreen(),
          ),
          GoRoute(
            path: '/admin/exams',
            builder: (context, state) => const CourseExamsScreen(courseId: 'all'),
          ),
          GoRoute(
            path: '/admin/courses/:courseId/sections/:sectionId/exams/create',
            builder: (context, state) {
              final courseId = state.pathParameters['courseId'] ?? '';
              final sectionId = state.pathParameters['sectionId'] ?? '';
              return CreateExamScreen(courseId: courseId, sectionId: sectionId);
            },
          ),
          GoRoute(
            path: '/admin/students',
            builder: (context, state) => const AdminStudentsScreen(),
          ),
          GoRoute(
            path: '/admin/payments',
            builder: (context, state) => const PaymentManagementScreen(),
          ),
          GoRoute(
            path: '/admin/settings',
            builder: (context, state) => const AdminSettingsScreen(),
          ),
          GoRoute(
            path: '/admin/analytics',
            builder: (context, state) => const AdminAnalyticsScreen(),
          ),
          
          // Learning Routes
          GoRoute(
            path: '/learning/:courseId',
            builder: (context, state) {
              final courseId = state.pathParameters['courseId'] ?? '';
              return ModernStudentLearningScreen(courseId: courseId);
            },
          ),
          GoRoute(
            path: '/learning/:courseId/video',
            builder: (context, state) {
              // Would implement video learning screen
              return Scaffold(
                appBar: AppBar(title: const Text('Video Learning')),
                body: const Center(child: Text('Video learning screen')),
              );
            },
          ),
          GoRoute(
            path: '/learning/:courseId/notes',
            builder: (context, state) {
              // Would implement notes learning screen
              return Scaffold(
                appBar: AppBar(title: const Text('Notes Learning')),
                body: const Center(child: Text('Notes learning screen')),
              );
            },
          ),
          GoRoute(
            path: '/learning/:courseId/exam',
            builder: (context, state) {
              // Would implement exam screen
              return Scaffold(
                appBar: AppBar(title: const Text('Practice Exam')),
                body: const Center(child: Text('Exam screen')),
              );
            },
          ),
          GoRoute(
            path: '/learning/:courseId/section/:sectionId',
            builder: (context, state) {
              // Would implement section learning screen
              return Scaffold(
                appBar: AppBar(title: const Text('Section Learning')),
                body: const Center(child: Text('Section learning screen')),
              );
            },
          ),
          
          // Profile Routes
          GoRoute(
            path: '/profile',
            builder: (context, state) => _buildProfileScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => _buildSettingsScreen(),
          ),
          GoRoute(
            path: '/categories',
            builder: (context, state) => _buildCategoriesScreen(),
          ),
          GoRoute(
            path: '/privacy',
            builder: (context, state) => _buildPrivacyScreen(),
          ),
          GoRoute(
            path: '/help',
            builder: (context, state) => _buildHelpScreen(),
          ),
          
          // Additional Routes
          GoRoute(
            path: '/my-courses',
            builder: (context, state) => _buildMyCoursesScreen(),
          ),
          GoRoute(
            path: '/certificates',
            builder: (context, state) => _buildCertificatesScreen(),
          ),
          GoRoute(
            path: '/learning-path',
            builder: (context, state) => _buildLearningPathScreen(),
          ),
        ],
        redirect: (context, state) {
          // Handle authentication redirects
          // We'll handle auth redirects in the widgets themselves rather than here
          // because accessing Riverpod providers in the router redirect is complex
          return null;
        },
      );

  // Placeholder screens - would be implemented in next phases

  Widget _buildProfileScreen() {
    return const ProfileScreen();
  }

  Widget _buildMyCoursesScreen() {
    return const EnrolledCoursesScreen();
  }

  Widget _buildCertificatesScreen() {
    return const CertificatesScreen();
  }

  Widget _buildLearningPathScreen() {
    return const LearningPathScreen();
  }

  Widget _buildSettingsScreen() {
    return const SettingsScreen();
  }

  Widget _buildPrivacyScreen() {
    return const PrivacyScreen();
  }

  Widget _buildCategoriesScreen() {
    return const CategoriesScreen();
  }

  Widget _buildHelpScreen() {
    return const HelpScreen();
  }
}