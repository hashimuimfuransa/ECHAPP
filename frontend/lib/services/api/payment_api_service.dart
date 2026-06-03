import 'dart:convert';
import 'dart:io' show Platform, File, Directory;
import '../infrastructure/api_client.dart';
import '../../config/api_config.dart';
import '../../models/payment.dart';
import '../../models/payment_status.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Helper to safely parse payment status from various types
PaymentStatus _parsePaymentStatus(dynamic statusValue) {
  if (statusValue == null) return PaymentStatus.pending;
  if (statusValue is String) {
    return PaymentStatus.fromString(statusValue);
  }
  if (statusValue is int) {
    // Handle numeric enum index
    if (statusValue >= 0 && statusValue < PaymentStatus.values.length) {
      return PaymentStatus.values[statusValue];
    }
    return PaymentStatus.pending;
  }
  // Fallback: convert to string
  return PaymentStatus.fromString(statusValue.toString());
}

/// Clean Payment API Service that integrates with backend endpoints
class PaymentApiService {
  final ApiClient _apiClient;

  PaymentApiService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Admin-initiated payment for a student
  Future<PaymentInitiationResponse> adminInitiatePayment({
    required String userId,
    required String courseId,
    required String paymentMethod,
    required String contactInfo,
  }) async {
    try {
      final requestBody = {
        'userId': userId,
        'courseId': courseId,
        'paymentMethod': paymentMethod,
        'contactInfo': contactInfo,
      };

      final response = await _apiClient.post(
        '${ApiConfig.payments}/admin-initiate',
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
    PaymentStatus? status,
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
      
      if (status != null) queryParams['status'] = status.value;
      if (courseId != null) queryParams['courseId'] = courseId;
      if (userId != null) queryParams['userId'] = userId;

      print('PaymentApiService: Fetching payments with params: $queryParams');
      
      final response = await _apiClient.get(
        ApiConfig.payments,
        queryParams: queryParams,
      );
      
      print('PaymentApiService: Response status: ${response.statusCode}');
      print('PaymentApiService: Response headers: ${response.headers}');
      print('PaymentApiService: FULL RESPONSE BODY: ${response.body}');
      
      response.validateStatus();
      
      // Parse JSON with extensive error handling
      Map<String, dynamic> jsonBody;
      try {
        jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
        print('PaymentApiService: Successfully parsed JSON response');
        print('PaymentApiService: Response keys: ${jsonBody.keys.toList()}');
      } catch (parseError) {
        print('PaymentApiService: JSON parsing failed: $parseError');
        print('PaymentApiService: Raw response body: ${response.body}');
        throw ApiException('Invalid JSON response from server');
      }
      
      // Check success field
      if (jsonBody['success'] != true) {
        final errorMessage = jsonBody['message'] as String? ?? 'Failed to fetch payments';
        print('PaymentApiService: API returned failure: $errorMessage');
        throw ApiException(errorMessage);
      }
      
      // Extract data field with safety checks
      final dataField = jsonBody['data'];
      if (dataField == null) {
        print('PaymentApiService: Data field is null');
        // Return empty response instead of throwing
        return PaymentListResponse(
          payments: [],
          totalPages: 0,
          currentPage: 1,
          total: 0,
        );
      }
      
      if (dataField is! Map<String, dynamic>) {
        print('PaymentApiService: Data field is not a map. Type: ${dataField.runtimeType}, Value: $dataField');
        // Return empty response instead of throwing
        return PaymentListResponse(
          payments: [],
          totalPages: 0,
          currentPage: 1,
          total: 0,
        );
      }
      
      final data = dataField;
      print('PaymentApiService: Data field keys: ${data.keys.toList()}');
      
      // Check payments field specifically before passing to fromJson
      final paymentsField = data['payments'];
      print('PaymentApiService: Payments field type: ${paymentsField?.runtimeType}');
      print('PaymentApiService: Payments field value: $paymentsField');
      
      // Pre-validate payments field to prevent type errors
      if (paymentsField != null && paymentsField is! List) {
        print('PaymentApiService: Payments field is not a list, returning empty response');
        return PaymentListResponse(
          payments: [],
          totalPages: 0,
          currentPage: 1,
          total: 0,
        );
      }
      
      return PaymentListResponse.fromJson(data);
    } catch (e, stackTrace) {
      print('PaymentApiService: Error fetching payments: $e');
      print('PaymentApiService: Error type: ${e.runtimeType}');
      print('PaymentApiService: Stack trace: $stackTrace');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch payments: $e');
    }
  }

  /// Get user's payments
  Future<List<Payment>> getMyPayments({PaymentStatus? status}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status.value;

      final response = await _apiClient.get(
        '${ApiConfig.payments}/my',
        queryParams: queryParams,
      );

      response.validateStatus();
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      
      if (jsonBody['success'] == true) {
        final data = jsonBody['data'];
        if (data is List) {
          final payments = <Payment>[];
          for (final item in data) {
            if (item is Map<String, dynamic>) {
              try {
                payments.add(Payment.fromJson(item));
              } catch (e) {
                print('PaymentApiService: Error parsing payment item: $e');
              }
            } else {
              print('PaymentApiService: Skipping non-map item: ${item.runtimeType}');
            }
          }
          return payments;
        }
        return [];
      } else {
        throw ApiException(jsonBody['message'] as String? ?? 'Failed to fetch payments');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch payments: $e');
    }
  }

  /// Verify/approve payment (admin only)
  Future<PaymentVerificationResponse> verifyPayment({
    required String paymentId,
    required PaymentStatus status,
    String? adminNotes,
  }) async {
    try {
      final requestBody = {
        'paymentId': paymentId,
        'status': status.value,
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

  /// Delete payment (admin only)
  Future<void> deletePayment(String paymentId) async {
    try {
      final response = await _apiClient.delete('${ApiConfig.payments}/$paymentId');
      response.validateStatus();
      
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      if (jsonBody['success'] != true) {
        throw ApiException(jsonBody['message'] as String? ?? 'Failed to delete payment');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to delete payment: $e');
    }
  }

  /// Get payment statistics (admin only)
  Future<PaymentStatsResponse> getPaymentStats() async {
    try {
      print('PaymentApiService: Fetching payment stats');
      final response = await _apiClient.get('${ApiConfig.payments}/stats');
      print('PaymentApiService: Stats response status: ${response.statusCode}');
      print('PaymentApiService: Stats response body: ${response.body}');
      
      response.validateStatus();
      
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      if (jsonBody['success'] == true) {
        final data = jsonBody['data'] as Map<String, dynamic>;
        return PaymentStatsResponse.fromJson(data);
      } else {
        throw ApiException(jsonBody['message'] as String? ?? 'Failed to fetch payment statistics');
      }
    } catch (e) {
      print('PaymentApiService: Error fetching payment stats: $e');
      print('PaymentApiService: Error type: ${e.runtimeType}');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch payment statistics: $e');
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

  /// Download payment invoice (admin only)
  Future<void> downloadInvoice(String paymentId) async {
    try {
      print('PaymentApiService: Downloading invoice for payment: $paymentId');
      
      final response = await _apiClient.get('${ApiConfig.payments}/$paymentId/invoice');
      
      print('PaymentApiService: Invoice response status: ${response.statusCode}');
      print('PaymentApiService: Invoice response content type: ${response.headers['content-type']}');
      
      if (response.statusCode != 200) {
        throw ApiException('Failed to download invoice: Server returned ${response.statusCode}');
      }
      
      // Check if response is PDF
      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.contains('application/pdf')) {
        throw ApiException('Invalid response format: Expected PDF, got $contentType');
      }
      
      // Get filename from content-disposition header or generate one
      String filename = 'invoice.pdf';
      final contentDisposition = response.headers['content-disposition'];
      if (contentDisposition != null && contentDisposition.contains('filename=')) {
        final filenameMatch = RegExp(r'filename="?([^"]+)"?').firstMatch(contentDisposition);
        if (filenameMatch != null) {
          filename = filenameMatch.group(1) ?? 'invoice.pdf';
        }
      }
      
      // For web, we'll create a download link
      if (kIsWeb) {
        print('PaymentApiService: Creating blob for web download');
        print('Response body type: ${response.bodyBytes.runtimeType}');
        print('Response body length: ${response.bodyBytes.length}');
        
        // Convert response body bytes to Uint8List for blob
        final bytes = response.bodyBytes;
        final blob = html.Blob([bytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        
        print('PaymentApiService: Blob created, URL: $url');
        
        // Create anchor element and trigger download
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', filename)
          ..click();
        
        // Clean up the object URL after a small delay
        Future.delayed(const Duration(milliseconds: 100), () {
          html.Url.revokeObjectUrl(url);
          print('PaymentApiService: Object URL revoked');
        });
        
        print('PaymentApiService: Invoice downloaded successfully for web');
      } else {
        // For mobile/desktop platforms
        print('PaymentApiService: Saving invoice for mobile/desktop platform');
        
        // Get the appropriate directory for saving files
        Directory directory;
        if (Platform.isAndroid || Platform.isIOS) {
          directory = await getApplicationDocumentsDirectory();
        } else {
          directory = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
        }
        
        // Create the file path
        final filePath = '${directory.path}/$filename';
        final file = File(filePath);
        
        // Write the PDF bytes to the file
        await file.writeAsBytes(response.bodyBytes);
        print('PaymentApiService: Invoice saved to: $filePath');
        
        // Try to open the file with the default application
        final uri = Uri.file(filePath);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
          print('PaymentApiService: Invoice opened with default application');
        } else {
          print('PaymentApiService: Could not open invoice, but file was saved successfully');
          throw ApiException('Invoice saved to $filePath but could not open automatically. Please open the file manually.');
        }
      }
      
    } catch (e) {
      print('PaymentApiService: Error downloading invoice: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to download invoice: $e');
    }
  }

  /// Dispose of resources
  void dispose() {
    _apiClient.dispose();
  }
}

// Response Data Models

class PaymentInitiationResponse {
  final String paymentId;
  final String transactionId;
  final double amount;
  final String currency;
  final PaymentStatus status;
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
      paymentId: json['paymentId'] as String? ?? '',
      transactionId: json['transactionId'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'RWF',
      status: _parsePaymentStatus(json['status']),
      contactInfo: json['contactInfo'] as String? ?? '',
      adminContact: json['adminContact'] as String? ?? '',
      instructions: json['instructions'] as String? ?? '',
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
    // Handle case where payments might be an integer (error case), null, or invalid data
    List<dynamic> paymentsData = [];
    
    try {
      final paymentsValue = json['payments'];
      
      if (paymentsValue == null) {
        print('INFO: payments field is null, returning empty list');
        paymentsData = [];
      } else if (paymentsValue is List) {
        paymentsData = paymentsValue;
        print('INFO: Found ${paymentsData.length} payments in list');
      } else {
        // Handle non-list values (int, string, etc.)
        print('WARNING: payments is not a list. Type: ${paymentsValue.runtimeType}, Value: $paymentsValue');
        paymentsData = [];
      }
    } catch (e) {
      print('ERROR: Exception while processing payments data: $e');
      paymentsData = [];
    }
    
    // Convert valid payment objects to Payment instances
    final List<Payment> paymentsList = [];
    
    for (var item in paymentsData) {
      try {
        if (item is Map<String, dynamic>) {
          paymentsList.add(Payment.fromJson(item));
        } else {
          print('WARNING: Skipping invalid payment item. Type: ${item.runtimeType}, Value: $item');
        }
      } catch (e) {
        print('ERROR: Failed to parse payment item: $e');
        print('Item data: $item');
      }
    }
    
    print('Final parsed payments count: ${paymentsList.length}');
    
    return PaymentListResponse(
      payments: paymentsList,
      totalPages: _safeIntParse(json['totalPages'], 0),
      currentPage: _safeIntParse(json['currentPage'], 1),
      total: _safeIntParse(json['total'], 0),
    );
  }
  
  // Helper method to safely parse integers
  static int _safeIntParse(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is num) {
      final d = value.toDouble();
      if (d.isNaN || d.isInfinite) return defaultValue;
      return d.toInt();
    }
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        print('WARNING: Failed to parse int from string "$value": $e');
        return defaultValue;
      }
    }
    print('WARNING: Unexpected type for integer parsing: ${value.runtimeType}');
    return defaultValue;
  }
}

class PaymentVerificationResponse {
  final String paymentId;
  final String transactionId;
  final PaymentStatus status;
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
      paymentId: json['paymentId'] as String? ?? '',
      transactionId: json['transactionId'] as String? ?? '',
      status: _parsePaymentStatus(json['status']),
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      userEmail: json['userEmail'] as String? ?? '',
      courseId: json['courseId'] as String? ?? '',
      courseTitle: json['courseTitle'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      approvedBy: json['approvedBy'] as String? ?? '',
      approvedAt: json['approvedAt'] != null
          ? DateTime.tryParse(json['approvedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
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
    // Safely parse recentPayments
    List<Payment> recentPaymentsList = [];
    final recentPaymentsData = json['recentPayments'];
    if (recentPaymentsData is List) {
      for (final item in recentPaymentsData) {
        if (item is Map<String, dynamic>) {
          try {
            recentPaymentsList.add(Payment.fromJson(item));
          } catch (e) {
            print('PaymentStatsResponse: Error parsing payment: $e');
          }
        }
      }
    }

    return PaymentStatsResponse(
      totalPayments: _safeIntParse(json['totalPayments'], 0),
      pendingPayments: _safeIntParse(json['pendingPayments'], 0),
      adminReviewPayments: _safeIntParse(json['adminReviewPayments'], 0),
      approvedPayments: _safeIntParse(json['approvedPayments'], 0),
      completedPayments: _safeIntParse(json['completedPayments'], 0),
      failedPayments: _safeIntParse(json['failedPayments'], 0),
      cancelledPayments: _safeIntParse(json['cancelledPayments'], 0),
      totalRevenue: _safeDoubleParse(json['totalRevenue'], 0.0),
      recentPayments: recentPaymentsList,
    );
  }
}

// Helper to safely parse integers from various types
int _safeIntParse(dynamic value, int defaultValue) {
  if (value == null) return defaultValue;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    return int.tryParse(value) ?? defaultValue;
  }
  return defaultValue;
}

// Helper to safely parse doubles from various types
double _safeDoubleParse(dynamic value, double defaultValue) {
  if (value == null) return defaultValue;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) {
    return double.tryParse(value) ?? defaultValue;
  }
  return defaultValue;
}
