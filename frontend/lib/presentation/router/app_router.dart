import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/widgets/admin_layout_wrapper.dart';
import 'package:excellencecoachinghub/presentation/screens/splash/splash_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/auth/login_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/auth/register_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/auth/forgot_password_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/auth/reset_password_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/auth/auth_selection_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/auth/email_auth_option_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/auth/enter_reset_code_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/auth/phone_collection_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/courses/courses_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/courses/course_detail_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/profile/profile_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/settings/settings_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/certificates/certificates_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/certificates/certificate_verification_screen.dart';
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
import 'package:excellencecoachinghub/presentation/screens/admin/admin_settings_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/admin/payment_management_screen_riverpod.dart';
import 'package:excellencecoachinghub/presentation/screens/admin/admin_videos_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/admin/admin_analytics_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/admin/course_analytics_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/admin/admin_notifications_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/admin/admin_feedback_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/admin/admin_payment_settings_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/admin/admin_general_settings_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/admin/admin_user_mgmt_settings_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/admin/admin_content_moderation_settings_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/admin/admin_management_screen.dart';
import 'package:excellencecoachinghub/screens/admin/quiz_creation_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/learning/professional_learning_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/learning/professional_lesson_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/learning/enhanced_quiz_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/notifications/notifications_screen.dart';
import 'package:excellencecoachinghub/widgets/main_layout.dart';
import 'package:excellencecoachinghub/presentation/screens/downloads/downloads_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/landing/landing_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/payments/payment_history_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/library/library_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/library/book_reader_screen.dart';
import 'package:excellencecoachinghub/data/services/gutenberg_service.dart';

/// Custom page transition for smooth navigation
class _FadeTransitionPage extends CustomTransitionPage<void> {
  _FadeTransitionPage({
    required super.child,
    required super.name,
  }) : super(
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation.drive(Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeInOut))),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 200),
        );
}

/// Slide transition for modal-style navigation
class _SlideUpTransitionPage extends CustomTransitionPage<void> {
  _SlideUpTransitionPage({
    required super.child,
    required super.name,
  }) : super(
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 0.05);
            const end = Offset.zero;
            final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: Curves.easeOutCubic));
            final offsetAnimation = animation.drive(tween);
            return FadeTransition(
              opacity: animation.drive(Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut))),
              child: SlideTransition(
                position: offsetAnimation,
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 250),
        );
}

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

          // Phone Collection - Outside MainLayout to prevent layout duplication
          GoRoute(
            path: '/phone-collection',
            builder: (context, state) => const PhoneCollectionScreen(),
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
          GoRoute(
            path: '/verify-certificate/:serial',
            builder: (context, state) {
              final serial = state.pathParameters['serial'] ?? '';
              return CertificateVerificationScreen(serialNumber: serial);
            },
          ),

          // Admin Routes - Outside MainLayout because they have their own sidebar/layout
          GoRoute(
            path: '/admin',
            builder: (context, state) => const AdminLayoutWrapper(
              screenName: 'Admin Dashboard',
              child: AdminDashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/courses',
            builder: (context, state) => const AdminLayoutWrapper(
              screenName: 'Admin Courses',
              child: AdminCoursesScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/courses/create',
            builder: (context, state) => const AdminLayoutWrapper(
              screenName: 'Create Course',
              child: AdminCreateCourseScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/courses/:courseId/sections/:sectionId/lessons/:lessonId/edit',
            builder: (context, state) {
              final courseId = state.pathParameters['courseId'] ?? '';
              final sectionId = state.pathParameters['sectionId'] ?? '';
              final lessonId = state.pathParameters['lessonId'] ?? '';
              return AdminLayoutWrapper(
                screenName: 'Edit Lesson',
                child: AdminCreateLessonScreen(
                  courseId: courseId,
                  sectionId: sectionId,
                  lessonId: lessonId,
                ),
              );
            },
          ),
          GoRoute(
            path: '/admin/courses/:courseId',
            builder: (context, state) {
              final courseId = state.pathParameters['courseId'] ?? '';
              return AdminLayoutWrapper(
                screenName: 'Admin Course Content',
                child: AdminCourseContentScreen(courseId: courseId, courseTitle: 'Course Content'),
              );
            },
          ),
          GoRoute(
            path: '/admin/courses/:courseId/edit',
            builder: (context, state) {
              final courseId = state.pathParameters['courseId'] ?? '';
              return AdminLayoutWrapper(
                screenName: 'Edit Course',
                child: AdminCreateCourseScreen(courseId: courseId),
              );
            },
          ),
          GoRoute(
            path: '/admin/courses/:courseId/content',
            builder: (context, state) {
              final courseId = state.pathParameters['courseId'] ?? '';
              return AdminLayoutWrapper(
                screenName: 'Admin Course Content',
                child: AdminCourseContentScreen(courseId: courseId, courseTitle: 'Course Content'),
              );
            },
          ),
          GoRoute(
            path: '/admin/courses/:courseId/videos',
            builder: (context, state) {
              final courseId = state.pathParameters['courseId'] ?? '';
              return AdminLayoutWrapper(
                screenName: 'Course Videos',
                child: CourseVideosScreen(courseId: courseId),
              );
            },
          ),
          GoRoute(
            path: '/admin/courses/:courseId/materials',
            builder: (context, state) {
              final courseId = state.pathParameters['courseId'] ?? '';
              return AdminLayoutWrapper(
                screenName: 'Course Materials',
                child: CourseMaterialsScreen(courseId: courseId),
              );
            },
          ),
          GoRoute(
            path: '/admin/courses/:courseId/analytics',
            builder: (context, state) {
              final courseId = state.pathParameters['courseId'] ?? '';
              return AdminLayoutWrapper(
                screenName: 'Course Analytics',
                child: CourseAnalyticsScreen(courseId: courseId),
              );
            },
          ),
          GoRoute(
            path: '/admin/courses/:courseId/sections/:sectionId/lessons/create',
            builder: (context, state) {
              final courseId = state.pathParameters['courseId'] ?? '';
              final sectionId = state.pathParameters['sectionId'] ?? '';
              return AdminLayoutWrapper(
                screenName: 'Create Lesson',
                child: AdminCreateLessonScreen(
                  courseId: courseId,
                  sectionId: sectionId,
                ),
              );
            },
          ),
          GoRoute(
            path: '/admin/videos',
            builder: (context, state) => const AdminLayoutWrapper(
              screenName: 'Admin Videos',
              child: AdminVideosScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/students',
            builder: (context, state) => const AdminLayoutWrapper(
              screenName: 'Admin Students',
              child: AdminStudentsScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/admins',
            builder: (context, state) => const AdminLayoutWrapper(
              screenName: 'Admin Management',
              child: AdminManagementScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/students/:studentId',
            builder: (context, state) {
              final studentId = state.pathParameters['studentId'] ?? '';
              return AdminLayoutWrapper(
                screenName: 'Admin Student Details',
                child: AdminStudentsScreen(studentId: studentId),
              );
            },
          ),
          GoRoute(
            path: '/admin/payments',
            builder: (context, state) => const AdminLayoutWrapper(
              screenName: 'Admin Payments',
              child: PaymentManagementScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/settings',
            builder: (context, state) => const AdminLayoutWrapper(
              screenName: 'Admin Settings',
              child: AdminSettingsScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/settings/payments',
            builder: (context, state) => const AdminLayoutWrapper(
              screenName: 'Admin Payment Settings',
              child: AdminPaymentSettingsScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/settings/general',
            builder: (context, state) => const AdminLayoutWrapper(
              screenName: 'Admin General Settings',
              child: AdminGeneralSettingsScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/settings/users',
            builder: (context, state) => const AdminLayoutWrapper(
              screenName: 'Admin User Settings',
              child: AdminUserManagementSettingsScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/settings/moderation',
            builder: (context, state) => const AdminLayoutWrapper(
              screenName: 'Admin Moderation Settings',
              child: AdminContentModerationSettingsScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/analytics',
            builder: (context, state) => const AdminLayoutWrapper(
              screenName: 'Admin Analytics',
              child: AdminAnalyticsScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/user-feedback',
            builder: (context, state) => const AdminLayoutWrapper(
              screenName: 'Admin User Feedback',
              child: AdminFeedbackScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/notifications',
            builder: (context, state) => const AdminLayoutWrapper(
              screenName: 'Admin Notifications',
              child: AdminNotificationsScreen(),
            ),
          ),

          // Learning Routes - Outside MainLayout for full-screen focus
          GoRoute(
            path: '/learning/:courseId',
            builder: (context, state) {
              final courseId = state.pathParameters['courseId'] ?? '';
              return ProfessionalLearningScreen(courseId: courseId);
            },
          ),
                    GoRoute(
            path: '/lesson/:lessonId',
            builder: (context, state) {
              final lessonId = state.pathParameters['lessonId'] ?? '';
              final isAdminPreview = state.uri.queryParameters['admin'] == 'true';
              return ProfessionalLessonScreen(
                lessonId: lessonId,
                isAdminPreview: isAdminPreview,
              );
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
            path: '/learning/:courseId/section/:sectionId',
            builder: (context, state) {
              return Scaffold(
                appBar: AppBar(title: const Text('Section Learning')),
                body: const Center(child: Text('Section learning screen')),
              );
            },
          ),
          GoRoute(
            path: '/enhanced-quiz/:quizId',
            builder: (context, state) {
              final quizId = state.pathParameters['quizId'] ?? '';
              final lessonTitle = state.uri.queryParameters['lessonTitle'] ?? '';
              return EnhancedQuizScreen(
                quizId: quizId,
                lessonTitle: Uri.decodeComponent(lessonTitle),
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
                pageBuilder: (context, state) => _FadeTransitionPage(
                  name: state.matchedLocation,
                  child: const DashboardScreen(),
                ),
              ),
              GoRoute(
                path: '/courses',
                pageBuilder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>?;
                  return _SlideUpTransitionPage(
                    name: state.matchedLocation,
                    child: CoursesScreen(
                      categoryId: extra?['categoryId'] as String?,
                      categoryName: extra?['categoryName'] as String?,
                      searchQuery: extra?['searchQuery'] as String?,
                    ),
                  );
                },
              ),
              GoRoute(
                path: '/course/:id',
                pageBuilder: (context, state) {
                  final courseId = state.pathParameters['id'] ?? '';
                  return _SlideUpTransitionPage(
                    name: state.matchedLocation,
                    child: CourseDetailScreen(courseId: courseId),
                  );
                },
              ),
              GoRoute(
                path: '/downloads',
                builder: (context, state) => const DownloadsScreen(),
              ),
              GoRoute(
                path: '/my-courses',
                builder: (context, state) => const EnrolledCoursesScreen(),
              ),
              GoRoute(
                path: '/library',
                builder: (context, state) => const LibraryScreen(),
              ),
              GoRoute(
                path: '/books/:bookId',
                builder: (context, state) {
                  final bookId = state.pathParameters['bookId'] ?? '';
                  final book = state.extra as Book?;
                  
                  if (book != null) {
                    return BookReaderScreen(book: book);
                  } else {
                    return Scaffold(
                      appBar: AppBar(title: const Text('Book Not Found')),
                      body: const Center(
                        child: Text('Book not found or could not be loaded'),
                      ),
                    );
                  }
                },
              ),
              GoRoute(
                path: '/notifications',
                builder: (context, state) => const NotificationsScreen(),
              ),
              GoRoute(
                path: '/payments/history',
                builder: (context, state) => const PaymentHistoryScreen(),
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
