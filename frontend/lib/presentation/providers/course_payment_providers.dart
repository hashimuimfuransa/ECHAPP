import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/payment_status.dart';
import '../providers/payment_riverpod_provider.dart';
import '../../services/api/payment_api_service.dart';

// Provider to check if user has pending payment for a course
final hasPendingPaymentProvider = FutureProvider.family<bool, String>((ref, courseId) async {
  try {
    // Get fresh data by calling the API directly instead of relying on cached data
    final apiService = PaymentApiService();
    final userPayments = await apiService.getMyPayments();
    
    final pendingPayments = userPayments.where((p) => 
      p.courseId == courseId && 
      (p.status == PaymentStatus.pending || p.status == PaymentStatus.adminReview)
    ).toList();
    
    return pendingPayments.isNotEmpty;
  } catch (e) {
    // If there's an error fetching payments, assume no pending payment
    return false;
  }
});

// Provider for payment initiation state
final initiatePaymentProvider = StateProvider<PaymentInitiationState>((ref) {
  return PaymentInitiationState.initial();
});

// Payment initiation state
class PaymentInitiationState {
  final bool isLoading;
  final bool isSuccess;
  final String? error;
  final PaymentInitiationResponse? response;

  PaymentInitiationState({
    required this.isLoading,
    required this.isSuccess,
    this.error,
    this.response,
  });

  factory PaymentInitiationState.initial() {
    return PaymentInitiationState(
      isLoading: false,
      isSuccess: false,
    );
  }

  PaymentInitiationState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? error,
    PaymentInitiationResponse? response,
  }) {
    return PaymentInitiationState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      error: error,
      response: response,
    );
  }
}