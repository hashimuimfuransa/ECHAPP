import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/models/course.dart';
import 'package:excellencecoachinghub/presentation/providers/course_payment_providers.dart';
import 'package:excellencecoachinghub/presentation/providers/enrollment_provider.dart';
import 'package:excellencecoachinghub/presentation/screens/payments/payment_pending_screen.dart';
import 'package:excellencecoachinghub/presentation/providers/course_provider.dart';
import 'package:excellencecoachinghub/utils/navigation_optimizer.dart';
import 'package:excellencecoachinghub/utils/navigation_performance_monitor.dart';
import 'package:excellencecoachinghub/utils/learning_content_optimizer.dart';

/// Utility class for handling smart course navigation
/// 
/// This utility automatically determines the correct destination when a user
/// clicks on a course based on their enrollment status:
/// 
/// - If user IS enrolled: Navigate directly to Professional Learning Screen (/learning/:id)
/// - If user has PENDING payment: Navigate to Payment Screen
/// - If user is NOT enrolled: Navigate to Course Detail Screen (/course/:id)
/// 
/// After successful payment, users are automatically redirected to the learning screen.
/// 
/// Usage: CourseNavigationUtils.navigateToCourse(context, ref, course)
class CourseNavigationUtils {
  // Cache for enrollment status to avoid repeated checks
  static final Map<String, bool> _enrollmentCache = {};
  static final Map<String, bool> _paymentCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);
  
  /// Fast navigation with immediate feedback and caching
  static Future<void> navigateToCourse(
    BuildContext context,
    WidgetRef ref,
    Course course, {
    bool showLoading = true,
  }) async {
    if (!context.mounted) return;
    
    try {
      print('🚀 Fast navigation for course: ${course.id} - ${course.title}');
      
      // Start performance monitoring
      NavigationPerformanceMonitor.startNavigation('course_${course.id}');
      
      // Check cache first for instant response
      final cachedEnrollment = _getCachedEnrollmentStatus(course.id);
      
      if (cachedEnrollment != null) {
        print('⚡ Using cached enrollment status: $cachedEnrollment');
        if (cachedEnrollment) {
          // User is enrolled - immediate navigation
          if (context.mounted) {
            await NavigationOptimizer.navigateToRoute(
              context,
              '/learning/${course.id}',
            );
          }
          NavigationPerformanceMonitor.endNavigation('course_${course.id}');
          return;
        }
      }
      
      // If not cached or not enrolled, do full check
      await _performFullNavigationCheck(context, ref, course);
      
    } catch (e) {
      print('❌ Navigation error: $e');
      if (context.mounted) {
        await NavigationOptimizer.navigateToRoute(
          context,
          '/course/${course.id}',
        );
      }
    } finally {
      NavigationPerformanceMonitor.endNavigation('course_${course.id}');
    }
  }
  
  /// Perform full navigation check with parallel requests
  static Future<void> _performFullNavigationCheck(
    BuildContext context,
    WidgetRef ref,
    Course course,
  ) async {
    if (!context.mounted) return;
    
    // Run enrollment and payment checks in parallel for speed
    final futures = <Future<bool>>[];
    
    // Check enrollment status
    futures.add(ref.read(isEnrolledInCourseProvider(course.id).future));
    
    // Check payment status in parallel
    futures.add(ref.read(hasPendingPaymentProvider(course.id).future).catchError((_) => false));
    
    final results = await Future.wait(futures);
    final isEnrolled = results[0];
    final hasPendingPayment = results[1];
    
    // Cache the results
    _cacheEnrollmentStatus(course.id, isEnrolled);
    _cachePaymentStatus(course.id, hasPendingPayment);
    
    print('📊 Navigation results - Enrolled: $isEnrolled, Pending: $hasPendingPayment');
    
    if (!context.mounted) return;
    
    if (isEnrolled) {
      // Navigate to learning screen with optimization
      if (context.mounted) {
        // Preload course content for instant loading
        LearningContentOptimizer().preloadFullCourseContent(course.id);
        
        await NavigationOptimizer.navigateToRoute(
          context,
          '/learning/${course.id}',
        );
      }
    } else if (hasPendingPayment) {
      // Navigate to payment screen
      if (context.mounted) {
        Navigator.push(
          context,
          OptimizedPageRoute(
            child: PaymentPendingScreen(
              course: course,
              transactionId: 'pending',
              amount: course.price ?? 0.0,
            ),
          ),
        ).then((_) => _checkPostPaymentStatus(context, ref, course));
      }
    } else {
      // Navigate to course detail
      if (context.mounted) {
        await NavigationOptimizer.navigateToRoute(
          context,
          '/course/${course.id}',
        );
      }
    }
  }
  
  /// Cache enrollment status for faster subsequent navigation
  static void _cacheEnrollmentStatus(String courseId, bool isEnrolled) {
    _enrollmentCache[courseId] = isEnrolled;
    _cacheTimestamps[courseId] = DateTime.now();
  }
  
  /// Cache payment status for faster subsequent navigation
  static void _cachePaymentStatus(String courseId, bool hasPendingPayment) {
    _paymentCache[courseId] = hasPendingPayment;
    _cacheTimestamps['payment_$courseId'] = DateTime.now();
  }
  
  /// Get cached enrollment status if not expired
  static bool? _getCachedEnrollmentStatus(String courseId) {
    final timestamp = _cacheTimestamps[courseId];
    if (timestamp == null || DateTime.now().difference(timestamp) > _cacheExpiry) {
      _enrollmentCache.remove(courseId);
      _cacheTimestamps.remove(courseId);
      return null;
    }
    return _enrollmentCache[courseId];
  }
  
  /// Get cached payment status if not expired
  static bool? _getCachedPaymentStatus(String courseId) {
    final timestamp = _cacheTimestamps['payment_$courseId'];
    if (timestamp == null || DateTime.now().difference(timestamp) > _cacheExpiry) {
      _paymentCache.remove(courseId);
      _cacheTimestamps.remove('payment_$courseId');
      return null;
    }
    return _paymentCache[courseId];
  }
  
  /// Clear all caches (useful after logout)
  static void clearAllCaches() {
    _enrollmentCache.clear();
    _paymentCache.clear();
    _cacheTimestamps.clear();
    print('🧹 Navigation caches cleared');
  }
  
  /// Preload course navigation data for multiple courses
  static Future<void> preloadCourseData(
    WidgetRef ref,
    List<String> courseIds,
  ) async {
    print('📦 Preloading navigation data for ${courseIds.length} courses');
    
    final futures = courseIds.map((courseId) async {
      try {
        final isEnrolled = await ref.read(isEnrolledInCourseProvider(courseId).future);
        final hasPendingPayment = await ref.read(hasPendingPaymentProvider(courseId).future).catchError((_) => false);
        
        _cacheEnrollmentStatus(courseId, isEnrolled);
        _cachePaymentStatus(courseId, hasPendingPayment);
      } catch (e) {
        print('⚠️ Failed to preload data for course $courseId: $e');
      }
    });
    
    await Future.wait(futures);
    print('✅ Preloading completed');
  }
  
  /// Check enrollment status after returning from payment flow
  static Future<void> _checkPostPaymentStatus(
    BuildContext context,
    WidgetRef ref,
    Course course,
  ) async {
    try {
      print('🔄 Checking post-payment enrollment status for course: ${course.id}');
      final isEnrolled = await ref.read(isEnrolledInCourseProvider(course.id).future);
      
      // Update cache
      _cacheEnrollmentStatus(course.id, isEnrolled);
      
      if (isEnrolled && context.mounted) {
        print('🎉 User is now enrolled after payment - redirecting to professional learning screen');
        await NavigationOptimizer.navigateToRoute(
          context,
          '/learning/${course.id}',
          replace: true,
        );
        
        // Show success message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎉 Payment approved! Welcome to "${course.title}"'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else if (context.mounted) {
        print('⚠️ User is still not enrolled after payment - staying on course detail');
        // Stay on current screen or navigate to course detail
        await NavigationOptimizer.navigateToRoute(
          context,
          '/course/${course.id}',
        );
      }
    } catch (e) {
      print('❌ Error checking post-payment status: $e');
      if (context.mounted) {
        await NavigationOptimizer.navigateToRoute(
          context,
          '/course/${course.id}',
        );
      }
    }
  }
  
  /// Alternative method that works with BuildContext
  static Future<void> navigateToCourseWithContext(
    BuildContext context,
    WidgetRef ref,
    Course course,
  ) async {
    try {
      print('Smart navigation for course (context method): ${course.id}');
      
      // First check enrollment status
      final isEnrolled = await ref.read(isEnrolledInCourseProvider(course.id).future);
      print('Enrollment check result (context method): $isEnrolled');
      
      if (isEnrolled) {
        // If already enrolled, go directly to professional learning screen
        print('✅ User already enrolled - navigating to professional learning screen');
        
        // PRE-FETCH: Start pre-fetching course content for instant loading
        ref.read(courseContentProvider(course.id).future);
        
        if (context.mounted) {
          context.push('/learning/${course.id}');
        }
        return;
      }

      print('🔍 Checking for pending payments (context method) for course ID: ${course.id}');
      final hasPendingPayment = await ref.read(hasPendingPaymentProvider(course.id).future);
      
      if (hasPendingPayment) {
        if (context.mounted) {
          Navigator.push(
            context,
            OptimizedPageRoute(
              child: PaymentPendingScreen(
                course: course,
                transactionId: 'pending',
                amount: course.price ?? 0.0,
              ),
            ),
          );
        }
      } else {
        if (context.mounted) {
          await NavigationOptimizer.navigateToRoute(
            context,
            '/course/${course.id}',
          );
        }
      }
    } catch (e) {
      print('Error in context-based navigation: $e');
      if (context.mounted) {
        await NavigationOptimizer.navigateToRoute(
          context,
          '/course/${course.id}',
        );
      }
    }
  }
}
