import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excellence_coaching_hub/data/repositories/payment_repository.dart';
import 'package:excellence_coaching_hub/models/payment.dart' as model;
import 'package:excellence_coaching_hub/services/api/payment_service.dart' show PaymentInitiationResponse;

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository();
});

// Provider for initiating payment
final initiatePaymentProvider = AsyncNotifierProvider<PaymentInitiationNotifier, PaymentInitiationResponse?>(
  () => PaymentInitiationNotifier(),
);

class PaymentInitiationNotifier extends AsyncNotifier<PaymentInitiationResponse?> {
  @override
  FutureOr<PaymentInitiationResponse?> build() => null;

  Future<void> initiatePayment({
    required String courseId,
    required String paymentMethod,
    required String contactInfo,
  }) async {
    print('PaymentInitiationNotifier: Initiating payment for course: $courseId');
    print('PaymentInitiationNotifier: Payment method: $paymentMethod');
    print('PaymentInitiationNotifier: Contact info: $contactInfo');
    
    final repository = ref.read(paymentRepositoryProvider);
    state = const AsyncValue.loading();
    print('PaymentInitiationNotifier: Set state to loading');
    
    try {
      final response = await repository.initiatePayment(
        courseId: courseId,
        paymentMethod: paymentMethod,
        contactInfo: contactInfo,
      );
      print('PaymentInitiationNotifier: Payment initiated successfully');
      print('PaymentInitiationNotifier: Transaction ID: ${response.transactionId}');
      state = AsyncValue.data(response);
    } catch (e) {
      print('PaymentInitiationNotifier: Payment initiation failed: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

// Provider for user's payments
final userPaymentsProvider = FutureProvider<List<model.Payment>>((ref) async {
  final repository = ref.read(paymentRepositoryProvider);
  return await repository.getMyPayments();
});

// Provider for specific payment
final paymentByIdProvider = FutureProvider.family<model.Payment, String>((ref, paymentId) async {
  final repository = ref.read(paymentRepositoryProvider);
  return await repository.getPaymentById(paymentId);
});

// Async notifier for payment actions
final paymentActionNotifierProvider = AsyncNotifierProvider<PaymentActionNotifier, void>(
  () => PaymentActionNotifier(),
);

class PaymentActionNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> cancelPayment(String paymentId) async {
    final repository = ref.read(paymentRepositoryProvider);
    state = const AsyncValue.loading();
    
    try {
      await repository.cancelPayment(paymentId);
      state = const AsyncValue.data(null);
      // Refresh payments list
      ref.invalidate(userPaymentsProvider);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

// Provider for checking if user has pending payment for a course
final hasPendingPaymentProvider = FutureProvider.family<bool, String>((ref, courseId) async {
  final repository = ref.read(paymentRepositoryProvider);
  return await repository.hasPendingPaymentForCourse(courseId);
});