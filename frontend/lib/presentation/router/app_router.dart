import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/presentation/screens/splash/splash_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/auth/login_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/auth/register_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/auth/forgot_password_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/auth/reset_password_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/auth/auth_selection_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/auth/email_auth_option_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/auth/enter_reset_code_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/courses/courses_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/courses/course_detail_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/profile/profile_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/settings/settings_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/certificates/certificates_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/privacy/privacy_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/terms/terms_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/categories/categories_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/enrolled/enrolled_courses_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/help/help_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/admin/admin_dashboard_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/admin/admin_courses_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/admin/create_course_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/admin/admin_course_content_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/admin/admin_create_lesson_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/admin/admin_students_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/admin/course_videos_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/admin/course_materials_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/admin/course_exams_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/admin/admin_settings_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/admin/payment_management_screen_riverpod.dart';
import 'package:excellencecoachinghub/presentation/screens/admin/admin_videos_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/admin/admin_analytics_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/exams/create_exam_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/exams/exam_taking_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/learning/modern_student_learning_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/notifications/notifications_screen.dart';
import 'package:excellencecoachinghub/widgets/main_layout.dart';
import 'package:excellencecoachinghub/models/exam.dart' as exam_model;
import 'package:excellencecoachinghub/presentation/screens/downloads/downloads_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/landing/landing_screen.dart';

class AppRouter {
  // Static instance for singleton
  static final AppRouter _instance = AppRouter._internal();
  
  // Factory constructor
  factory AppRouter() => _instance;
  
  // Private internal constructor
  AppRouter._internal();

  // Lazy-loaded GoRouter
  late final GoRouter _router = _buildRouter();

  GoRouter get router => _router;

  GoRouter _buildRouter() => GoRouter(
        initialLocation: '/',
        routes: [
          // Authentication Routes
          ShellRoute(
            builder: (context, state, child) => MainLayout(
              key: const ValueKey('auth_shell'),
              child: child,
            ),
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const SplashScreen(),
              ),
              GoRoute(
                path: '/landing',
                builder: (context, state) => const LandingScreen(),
              ),
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
              GoRoute(
                path: '/enter-reset-code',
                builder: (context, state) => const EnterResetCodeScreen(),
              ),
              // Reset Password Route
              GoRoute(
                path: '/reset-password',
                builder: (context, state) {
                  final mode = state.uri.queryParameters['mode'];
                  final oobCode = state.uri.queryParameters['oobCode'];
                  
                  // Only return oobCode if mode is resetPassword
                  final resetCode = (mode == 'resetPassword' || mode == 'verifyEmail') ? oobCode : oobCode;
                  return ResetPasswordScreen(oobCode: resetCode);
                },
              ),
            ],
          ),

          // Privacy, Terms, Help - Outside MainLayout to prevent layout duplication
          GoRoute(
            path: '/privacy',
            builder: (context, state) => const PrivacyScreen(),
          ),
          GoRoute(
            path: '/terms',
            builder: (context, state) => const TermsScreen(),
          ),
          GoRoute(
            path: '/help',
            builder: (context, state) => const HelpScreen(),
          ),

          // Admin Routes - Outside MainLayout because they have their own sidebar/layout
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

          // Learning Routes - Outside MainLayout for full-screen focus
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
              return Scaffold(
                appBar: AppBar(title: const Text('Video Learning')),
                body: const Center(child: Text('Video learning screen')),
              );
            },
          ),
          GoRoute(
            path: '/learning/:courseId/notes',
            builder: (context, state) {
              return Scaffold(
                appBar: AppBar(title: const Text('Notes Learning')),
                body: const Center(child: Text('Notes learning screen')),
              );
            },
          ),
          GoRoute(
            path: '/learning/:courseId/exam/:examId',
            builder: (context, state) {
              final examId = state.pathParameters['examId'] ?? '';
              final courseId = state.pathParameters['courseId'] ?? '';
              final exam = state.extra as exam_model.Exam?;
              
              if (exam != null) {
                return ExamTakingScreen(exam: exam);
              } else {
                return Scaffold(
                  appBar: AppBar(title: const Text('Exam')),  
                  body: const Center(child: Text('Exam not found')),
                );
              }
            },
          ),
          GoRoute(
            path: '/learning/:courseId/section/:sectionId',
            builder: (context, state) {
              return Scaffold(
                appBar: AppBar(title: const Text('Section Learning')),
                body: const Center(child: Text('Section learning screen')),
              );
            },
          ),

          // Shell Route for Student Dashboard and Main App Pages
          ShellRoute(
            builder: (context, state, child) => MainLayout(
              key: const ValueKey('main_shell'),
              child: child,
            ),
            routes: [
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
              GoRoute(
                path: '/downloads',
                builder: (context, state) => const DownloadsScreen(),
              ),
              GoRoute(
                path: '/notifications',
                builder: (context, state) => const NotificationsScreen(),
              ),
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
              GoRoute(
                path: '/categories',
                builder: (context, state) => const CategoriesScreen(),
              ),
              GoRoute(
                path: '/my-courses',
                builder: (context, state) => const EnrolledCoursesScreen(),
              ),
              GoRoute(
                path: '/certificates',
                builder: (context, state) => const CertificatesScreen(),
              ),
            ],
          ),
        ],
        redirect: (context, state) {
          return null;
        },
      );
}
