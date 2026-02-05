import '../../services/api/payment_service.dart';
import '../../models/payment.dart' as model;

class PaymentRepository {
  final PaymentService _paymentService;

  PaymentRepository({PaymentService? paymentService}) 
      : _paymentService = paymentService ?? PaymentService();

  /// Initiate payment for a course
  Future<PaymentInitiationResponse> initiatePayment({
    required String courseId,
    required String paymentMethod,
    required String contactInfo,
  }) async {
    print('PaymentRepository: Initiating payment for course: $courseId');
    print('PaymentRepository: Payment method: $paymentMethod');
    print('PaymentRepository: Contact info: $contactInfo');
    
    // Validate payment method
    final validMethods = ['mtn_momo', 'airtel_money'];
    if (!validMethods.contains(paymentMethod)) {
      throw Exception('Invalid payment method. Valid methods are: ${validMethods.join(', ')}');
    }
    
    final response = await _paymentService.initiatePayment(
      courseId: courseId,
      paymentMethod: paymentMethod,
      contactInfo: contactInfo,
    );
    print('PaymentRepository: Payment service response received');
    print('PaymentRepository: Transaction ID: ${response.transactionId}');
    return response;
  }

  /// Get user's payments
  Future<List<model.Payment>> getMyPayments({String? status}) async {
    final payments = await _paymentService.getMyPayments(status: status);
    return payments.map((p) => model.Payment(
      id: p.id,
      userId: p.userId,
      courseId: p.courseId,
      amount: p.amount,
      currency: p.currency,
      paymentMethod: p.paymentMethod,
      transactionId: p.transactionId,
      status: p.status,
      contactInfo: p.contactInfo,
      paymentDate: p.paymentDate,
      adminApproval: p.adminApproval != null ? model.PaymentAdminApproval(
        approvedBy: p.adminApproval!.approvedBy,
        approvedAt: p.adminApproval!.approvedAt,
        adminNotes: p.adminApproval!.adminNotes,
      ) : null,
      createdAt: p.createdAt,
      updatedAt: p.updatedAt,
    )).toList();
  }

  /// Check if user has pending payment for a specific course
  Future<bool> hasPendingPaymentForCourse(String courseId) async {
    try {
      print('Checking pending payments for course: $courseId');
      final pendingPayments = await getMyPayments(status: 'pending');
      print('Found ${pendingPayments.length} pending payments');
      
      final hasPending = pendingPayments.any((payment) {
        // Safely compare courseId, handling potential null or different types
        String paymentCourseId = payment.courseId.toString() ?? '';
        return paymentCourseId == courseId.toString();
      });
      print('Course $courseId has pending payment: $hasPending');
      
      // Also check if any payment exists for this course (regardless of status)
      final allPayments = await getMyPayments();
      final hasAnyPayment = allPayments.any((payment) {
        // Safely compare courseId, handling potential null or different types
        String paymentCourseId = payment.courseId.toString() ?? '';
        return paymentCourseId == courseId.toString();
      });
      print('Course $courseId has any payment: $hasAnyPayment');
      
      return hasPending;
    } catch (e) {
      print('Error checking pending payments for course $courseId: $e');
      return false;
    }
  }

  /// Get payment by ID
  Future<model.Payment> getPaymentById(String id) async {
    final payment = await _paymentService.getPaymentById(id);
    return model.Payment(
      id: payment.id,
      userId: payment.userId,
      courseId: payment.courseId,
      amount: payment.amount,
      currency: payment.currency,
      paymentMethod: payment.paymentMethod,
      transactionId: payment.transactionId,
      status: payment.status,
      contactInfo: payment.contactInfo,
      paymentDate: payment.paymentDate,
      adminApproval: payment.adminApproval != null ? model.PaymentAdminApproval(
        approvedBy: payment.adminApproval!.approvedBy,
        approvedAt: payment.adminApproval!.approvedAt,
        adminNotes: payment.adminApproval!.adminNotes,
      ) : null,
      createdAt: payment.createdAt,
      updatedAt: payment.updatedAt,
    );
  }

  /// Cancel payment
  Future<void> cancelPayment(String paymentId) async {
    return await _paymentService.cancelPayment(paymentId);
  }
}