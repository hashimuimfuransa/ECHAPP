import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/models/course.dart';
import 'package:excellencecoachinghub/presentation/providers/course_payment_providers.dart';
import 'package:excellencecoachinghub/presentation/providers/enrollment_provider.dart';
import 'package:excellencecoachinghub/presentation/screens/payments/payment_pending_screen.dart';

/// Utility class for handling smart course navigation
/// Checks if user has pending payment and navigates accordingly
class CourseNavigationUtils {
  /// Navigates to the appropriate screen based on payment status
  /// Priority order: 1. Already enrolled -> Continue Learning, 2. Pending payment -> Payment screen, 3. New course -> Course detail
  /// After payment approval, automatically redirects to learning screen
  static Future<void> navigateToCourse(
    BuildContext context,
    WidgetRef ref,
    Course course,
  ) async {
    try {
      print('Smart navigation for course: ${course.id} - ${course.title}');
      
      // First check enrollment status (highest priority)
      final isEnrolled = await ref.read(isEnrolledInCourseProvider(course.id).future);
      print('Enrollment check result: $isEnrolled');
      
      if (isEnrolled) {
        // If already enrolled, go directly to learning screen
        print('User already enrolled - navigating to learning screen');
        if (context.mounted) {
          context.pushReplacement('/learning/${course.id}');
        }
        return;
      }
      
      // If not enrolled, check for pending payments
      try {
        print('🔍 Checking for pending payments for course ID: ${course.id}');
        final hasPendingPayment = await ref.read(hasPendingPaymentProvider(course.id).future);
        print('✅ Pending payment check result: $hasPendingPayment');
        
        if (hasPendingPayment) {
          // Navigate to payment pending screen and start listener
          print('User has pending payment - navigating to payment screen');
          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PaymentPendingScreen(
                  course: course,
                  transactionId: 'pending',
                  amount: course.price,
                ),
              ),
            ).then((_) {
              // After returning from payment screen, check if enrolled
              _checkPostPaymentStatus(context, ref, course);
            });
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
  
  /// Check enrollment status after returning from payment flow
  static Future<void> _checkPostPaymentStatus(
    BuildContext context,
    WidgetRef ref,
    Course course,
  ) async {
    try {
      print('Checking post-payment status for course: ${course.id}');
      final isEnrolled = await ref.read(isEnrolledInCourseProvider(course.id).future);
      
      if (isEnrolled && context.mounted) {
        print('User is now enrolled after payment - redirecting to learning screen');
        context.pushReplacement('/learning/${course.id}');
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 Payment approved! Welcome to "${course.title}"'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print('Error checking post-payment status: $e');
    }
  }
  
  /// Alternative method that works with BuildContext
  static Future<void> navigateToCourseWithContext(
    BuildContext context,
    WidgetRef ref,
    Course course,
  ) async {
    try {
      print('🔍 Checking for pending payments (context method) for course ID: ${course.id}');
      final hasPendingPayment = await ref.read(hasPendingPaymentProvider(course.id).future);
      
      if (hasPendingPayment) {
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentPendingScreen(
                course: course,
                transactionId: 'pending',
                amount: course.price,
              ),
            ),
          );
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
