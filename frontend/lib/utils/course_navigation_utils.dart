import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellence_coaching_hub/models/course.dart';
import 'package:excellence_coaching_hub/presentation/providers/payment_provider.dart';
import 'package:excellence_coaching_hub/presentation/providers/enrollment_provider.dart';

/// Utility class for handling smart course navigation
/// Checks if user has pending payment and navigates accordingly
class CourseNavigationUtils {
  /// Navigates to the appropriate screen based on payment status
  /// Priority order: 1. Already enrolled -> Continue Learning, 2. Pending payment -> Payment screen, 3. New course -> Course detail
  static Future<void> navigateToCourse(
    BuildContext context,
    WidgetRef ref,
    Course course,
  ) async {
    try {
      print('Smart navigation for course: ${course.id} - ${course.title ?? "Untitled Course"}');
      
      // First check enrollment status (highest priority)
      final isEnrolled = await ref.read(isEnrolledInCourseProvider(course.id).future);
      print('Enrollment check result: $isEnrolled');
      
      if (isEnrolled) {
        // If already enrolled, go directly to learning screen
        print('User already enrolled - navigating to learning screen');
        if (context.mounted) {
          context.push('/learning/${course.id}');
        }
        return;
      }
      
      // If not enrolled, check for pending payments
      try {
        final hasPendingPayment = await ref.read(hasPendingPaymentProvider(course.id).future);
        print('Pending payment check result: $hasPendingPayment');
        
        if (hasPendingPayment) {
          // Navigate to payment pending screen
          print('User has pending payment - navigating to payment screen');
          if (context.mounted) {
            context.push('/payments/pending?courseId=${course.id}');
          }
        } else {
          // Navigate to course detail screen
          print('No pending payment - navigating to course detail');
          if (context.mounted) {
            context.push('/course/${course.id}');
          }
        }
      } catch (paymentError) {
        // If payment check fails, fall back to course detail
        print('Payment check failed ($paymentError) - falling back to course detail');
        if (context.mounted) {
          context.push('/course/${course.id}');
        }
      }
      
    } catch (e) {
      // If there's any other error, log it and navigate to course detail as ultimate fallback
      print('Error in smart navigation for course ${course.id}: $e');
      if (context.mounted) {
        context.push('/course/${course.id}');
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
      final hasPendingPayment = await ref.read(hasPendingPaymentProvider(course.id).future);
      
      if (hasPendingPayment) {
        if (context.mounted) {
          context.push('/payments/pending?courseId=${course.id}');
        }
      } else {
        if (context.mounted) {
          context.push('/course/${course.id}');
        }
      }
    } catch (e) {
      if (context.mounted) {
        context.push('/course/${course.id}');
      }
    }
  }
}