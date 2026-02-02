import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'package:excellence_coaching_hub/presentation/screens/privacy/privacy_screen.dart';
import 'package:excellence_coaching_hub/presentation/screens/categories/categories_screen.dart';
import 'package:excellence_coaching_hub/presentation/screens/help/help_screen.dart';
import 'package:excellence_coaching_hub/presentation/screens/admin/admin_dashboard_screen.dart';
import 'package:excellence_coaching_hub/presentation/screens/admin/admin_courses_screen.dart';
import 'package:excellence_coaching_hub/presentation/screens/admin/create_course_screen.dart';
import 'package:excellence_coaching_hub/presentation/screens/admin/admin_course_content_screen.dart';
import 'package:excellence_coaching_hub/presentation/screens/learning/student_learning_screen.dart';

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
              return const AdminCreateCourseScreen(); // Would pass courseId for editing
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
            path: '/admin/courses/:courseId/sections/:sectionId/lessons/create',
            builder: (context, state) {
              // Would implement lesson creation screen
              return Scaffold(
                appBar: AppBar(title: const Text('Create Lesson')),
                body: const Center(child: Text('Lesson creation screen')),
              );
            },
          ),
          GoRoute(
            path: '/admin/videos',
            builder: (context, state) => Scaffold(
              appBar: AppBar(title: const Text('Video Management')),
              body: const Center(child: Text('Video management screen')),
            ),
          ),
          GoRoute(
            path: '/admin/exams',
            builder: (context, state) => Scaffold(
              appBar: AppBar(title: const Text('Exam Management')),
              body: const Center(child: Text('Exam management screen')),
            ),
          ),
          GoRoute(
            path: '/admin/students',
            builder: (context, state) => Scaffold(
              appBar: AppBar(title: const Text('Student Management')),
              body: const Center(child: Text('Student management screen')),
            ),
          ),
          GoRoute(
            path: '/admin/payments',
            builder: (context, state) => Scaffold(
              appBar: AppBar(title: const Text('Payment Management')),
              body: const Center(child: Text('Payment management screen')),
            ),
          ),
          GoRoute(
            path: '/admin/settings',
            builder: (context, state) => Scaffold(
              appBar: AppBar(title: const Text('Admin Settings')),
              body: const Center(child: Text('Admin settings screen')),
            ),
          ),
          
          // Learning Routes
          GoRoute(
            path: '/learning/:courseId',
            builder: (context, state) {
              final courseId = state.pathParameters['courseId'] ?? '';
              return StudentLearningScreen(courseId: courseId);
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
  Widget _buildLearningScreen(String courseId) {
    return Scaffold(
      appBar: AppBar(title: const Text('Learning')),
      body: Center(
        child: Text('Learning screen for course: $courseId'),
      ),
    );
  }

  Widget _buildProfileScreen() {
    return const ProfileScreen();
  }

  Widget _buildMyCoursesScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('My Courses')),
      body: const Center(
        child: Text('My enrolled courses'),
      ),
    );
  }

  Widget _buildCertificatesScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('Certificates')),
      body: const Center(
        child: Text('Your certificates'),
      ),
    );
  }

  Widget _buildLearningPathScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('Learning Path')),
      body: const Center(
        child: Text('Your learning path'),
      ),
    );
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