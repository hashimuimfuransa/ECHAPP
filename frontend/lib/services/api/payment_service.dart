import 'dart:convert';
import '../../models/api_response.dart';
import '../infrastructure/api_client.dart';
import '../../config/api_config.dart';

/// Service for payment-related API operations
class PaymentService {
  final ApiClient _apiClient;

  PaymentService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Initiate payment for a course
  Future<PaymentInitiationResponse> initiatePayment({
    required String courseId,
    required String paymentMethod,
    required String contactInfo,
  }) async {
    try {
      final requestBody = {
        'courseId': courseId,
        'paymentMethod': paymentMethod,
        'contactInfo': contactInfo,
      };

      final response = await _apiClient.post(
        '${ApiConfig.payments}/initiate',
        body: requestBody,
      );

      response.validateStatus();
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      
      if (jsonBody['success'] == true) {
        final data = jsonBody['data'] as Map<String, dynamic>;
        return PaymentInitiationResponse.fromJson(data);
      } else {
        throw ApiException(jsonBody['message'] as String? ?? 'Payment initiation failed');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to initiate payment: $e');
    }
  }

  /// Get all payments (admin only)
  Future<PaymentListResponse> getAllPayments({
    String? status,
    String? courseId,
    String? userId,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      
      if (status != null) queryParams['status'] = status;
      if (courseId != null) queryParams['courseId'] = courseId;
      if (userId != null) queryParams['userId'] = userId;

      final response = await _apiClient.get(
        ApiConfig.payments,
        queryParams: queryParams,
      );

      response.validateStatus();
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      
      // Debug logging
      print('Payment API Response: $jsonBody');
      
      if (jsonBody['success'] == true) {
        final data = jsonBody['data'];
        print('Payment Data: $data');
        print('Payment Data Type: ${data.runtimeType}');
        
        // Handle case where data might be null or not a Map
        if (data == null) {
          print('Warning: Payment data is null, returning empty response');
          return PaymentListResponse(
            payments: [],
            totalPages: 0,
            currentPage: page,
            total: 0
          );
        }
        
        if (data is! Map<String, dynamic>) {
          print('Warning: Payment data is not a Map, got: ${data.runtimeType}');
          return PaymentListResponse(
            payments: [],
            totalPages: 0,
            currentPage: page,
            total: 0
          );
        }
        
        return PaymentListResponse.fromJson(data);
      } else {
        throw ApiException(jsonBody['message'] as String? ?? 'Failed to fetch payments');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      // Provide more detailed error information
      if (e.toString().contains('type')) {
        throw ApiException('Data type mismatch in payment response. This might indicate no payments exist yet or backend data structure issue.');
      }
      throw ApiException('Failed to fetch payments: $e');
    }
  }

  /// Verify/approve payment (admin only)
  Future<PaymentVerificationResponse> verifyPayment({
    required String paymentId,
    required String status,
    String? adminNotes,
  }) async {
    try {
      final requestBody = {
        'paymentId': paymentId,
        'status': status,
        if (adminNotes != null) 'adminNotes': adminNotes,
      };

      final response = await _apiClient.put(
        '${ApiConfig.payments}/verify',
        body: requestBody,
      );

      response.validateStatus();
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      
      if (jsonBody['success'] == true) {
        final data = jsonBody['data'] as Map<String, dynamic>;
        return PaymentVerificationResponse.fromJson(data);
      } else {
        throw ApiException(jsonBody['message'] as String? ?? 'Payment verification failed');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to verify payment: $e');
    }
  }

  /// Cancel payment
  Future<void> cancelPayment(String paymentId) async {
    try {
      final response = await _apiClient.delete('${ApiConfig.payments}/cancel/$paymentId');
      response.validateStatus();
      
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      if (jsonBody['success'] != true) {
        throw ApiException(jsonBody['message'] as String? ?? 'Failed to cancel payment');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to cancel payment: $e');
    }
  }

  /// Get payment statistics (admin only)
  Future<PaymentStatsResponse> getPaymentStats() async {
    try {
      final response = await _apiClient.get('${ApiConfig.payments}/stats');
      response.validateStatus();
      
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      if (jsonBody['success'] == true) {
        final data = jsonBody['data'] as Map<String, dynamic>;
        return PaymentStatsResponse.fromJson(data);
      } else {
        throw ApiException(jsonBody['message'] as String? ?? 'Failed to fetch payment statistics');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch payment statistics: $e');
    }
  }

  /// Get user's payments
  Future<List<Payment>> getMyPayments({String? status}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;

      final response = await _apiClient.get(
        '${ApiConfig.payments}/my',
        queryParams: queryParams,
      );

      response.validateStatus();
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      
      if (jsonBody['success'] == true) {
        final data = jsonBody['data'] as List<dynamic>;
        return data.map((item) => Payment.fromJson(item as Map<String, dynamic>)).toList();
      } else {
        throw ApiException(jsonBody['message'] as String? ?? 'Failed to fetch payments');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch payments: $e');
    }
  }

  /// Get payment by ID
  Future<Payment> getPaymentById(String id) async {
    try {
      final response = await _apiClient.get('${ApiConfig.payments}/$id');
      response.validateStatus();
      
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      if (jsonBody['success'] == true) {
        final data = jsonBody['data'] as Map<String, dynamic>;
        return Payment.fromJson(data);
      } else {
        throw ApiException(jsonBody['message'] as String? ?? 'Failed to fetch payment');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch payment: $e');
    }
  }

  /// Dispose of resources
  void dispose() {
    _apiClient.dispose();
  }
}

// Data models for payment responses
class PaymentInitiationResponse {
  final String paymentId;
  final String transactionId;
  final double amount;
  final String currency;
  final String status;
  final String contactInfo;
  final String adminContact;
  final String instructions;

  PaymentInitiationResponse({
    required this.paymentId,
    required this.transactionId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.contactInfo,
    required this.adminContact,
    required this.instructions,
  });

  factory PaymentInitiationResponse.fromJson(Map<String, dynamic> json) {
    return PaymentInitiationResponse(
      paymentId: json['paymentId'] as String,
      transactionId: json['transactionId'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      status: json['status'] as String,
      contactInfo: json['contactInfo'] as String,
      adminContact: json['adminContact'] as String,
      instructions: json['instructions'] as String,
    );
  }
}

class PaymentListResponse {
  final List<Payment> payments;
  final int totalPages;
  final int currentPage;
  final int total;

  PaymentListResponse({
    required this.payments,
    required this.totalPages,
    required this.currentPage,
    required this.total,
  });

  factory PaymentListResponse.fromJson(Map<String, dynamic> json) {
    // Handle empty or null payments gracefully
    final paymentsData = json['payments'];
    final List<Payment> paymentsList = [];
    
    if (paymentsData != null) {
      if (paymentsData is List) {
        paymentsList.addAll(
          paymentsData.map((item) => Payment.fromJson(item as Map<String, dynamic>)).toList()
        );
      } else if (paymentsData is Map<String, dynamic>) {
        // Handle single payment object (edge case)
        paymentsList.add(Payment.fromJson(paymentsData));
      }
      // If paymentsData is neither List nor Map, we keep paymentsList empty
    }
    // If paymentsData is null, we keep paymentsList empty (no payments = empty list)
    
    return PaymentListResponse(
      payments: paymentsList,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
      currentPage: (json['currentPage'] as num?)?.toInt() ?? 1,
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }
}

class PaymentVerificationResponse {
  final String paymentId;
  final String transactionId;
  final String status;
  final String userId;
  final String userName;
  final String userEmail;
  final String courseId;
  final String courseTitle;
  final double amount;
  final String approvedBy;
  final DateTime approvedAt;
  final String? adminNotes;

  PaymentVerificationResponse({
    required this.paymentId,
    required this.transactionId,
    required this.status,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.courseId,
    required this.courseTitle,
    required this.amount,
    required this.approvedBy,
    required this.approvedAt,
    this.adminNotes,
  });

  factory PaymentVerificationResponse.fromJson(Map<String, dynamic> json) {
    return PaymentVerificationResponse(
      paymentId: json['paymentId'] as String,
      transactionId: json['transactionId'] as String,
      status: json['status'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userEmail: json['userEmail'] as String,
      courseId: json['courseId'] as String,
      courseTitle: json['courseTitle'] as String,
      amount: (json['amount'] as num).toDouble(),
      approvedBy: json['approvedBy'] as String,
      approvedAt: DateTime.parse(json['approvedAt'] as String),
      adminNotes: json['adminNotes'] as String?,
    );
  }
}

class PaymentStatsResponse {
  final int totalPayments;
  final int pendingPayments;
  final int adminReviewPayments;
  final int approvedPayments;
  final int completedPayments;
  final int failedPayments;
  final int cancelledPayments;
  final double totalRevenue;
  final List<Payment> recentPayments;

  PaymentStatsResponse({
    required this.totalPayments,
    required this.pendingPayments,
    required this.adminReviewPayments,
    required this.approvedPayments,
    required this.completedPayments,
    required this.failedPayments,
    required this.cancelledPayments,
    required this.totalRevenue,
    required this.recentPayments,
  });

  factory PaymentStatsResponse.fromJson(Map<String, dynamic> json) {
    return PaymentStatsResponse(
      totalPayments: json['totalPayments'] as int,
      pendingPayments: json['pendingPayments'] as int,
      adminReviewPayments: json['adminReviewPayments'] as int,
      approvedPayments: json['approvedPayments'] as int,
      completedPayments: json['completedPayments'] as int,
      failedPayments: json['failedPayments'] as int,
      cancelledPayments: json['cancelledPayments'] as int,
      totalRevenue: (json['totalRevenue'] as num).toDouble(),
      recentPayments: (json['recentPayments'] as List)
          .map((item) => Payment.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Payment {
  final String id;
  final String userId;
  final String courseId;
  final double amount;
  final String currency;
  final String paymentMethod;
  final String transactionId;
  final String status;
  final String contactInfo;
  final DateTime? paymentDate;
  final PaymentAdminApproval? adminApproval;
  final DateTime createdAt;
  final DateTime updatedAt;

  Payment({
    required this.id,
    required this.userId,
    required this.courseId,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    required this.transactionId,
    required this.status,
    required this.contactInfo,
    this.paymentDate,
    this.adminApproval,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['_id'] as String,
      userId: json['userId'] as String,
      courseId: json['courseId'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      paymentMethod: json['paymentMethod'] as String,
      transactionId: json['transactionId'] as String,
      status: json['status'] as String,
      contactInfo: json['contactInfo'] as String,
      paymentDate: json['paymentDate'] != null 
          ? DateTime.parse(json['paymentDate'] as String) 
          : null,
      adminApproval: json['adminApproval'] != null
          ? PaymentAdminApproval.fromJson(json['adminApproval'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

class PaymentAdminApproval {
  final String approvedBy;
  final DateTime approvedAt;
  final String? adminNotes;

  PaymentAdminApproval({
    required this.approvedBy,
    required this.approvedAt,
    this.adminNotes,
  });

  factory PaymentAdminApproval.fromJson(Map<String, dynamic> json) {
    return PaymentAdminApproval(
      approvedBy: json['approvedBy'] as String,
      approvedAt: DateTime.parse(json['approvedAt'] as String),
      adminNotes: json['adminNotes'] as String?,
    );
  }
}