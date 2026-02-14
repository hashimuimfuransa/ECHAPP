
// Mock classes to test the fix
enum PaymentStatus { pending, adminReview, approved, completed, failed, cancelled }

class PaymentStatusHelper {
  static PaymentStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
        return PaymentStatus.pending;
      case 'admin_review':
        return PaymentStatus.adminReview;
      case 'approved':
        return PaymentStatus.approved;
      case 'completed':
        return PaymentStatus.completed;
      case 'failed':
        return PaymentStatus.failed;
      case 'cancelled':
        return PaymentStatus.cancelled;
      default:
        return PaymentStatus.pending;
    }
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
  final PaymentStatus status;
  final String contactInfo;
  final DateTime? paymentDate;
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
    required this.createdAt,
    required this.updatedAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: (json['id'] as String?) ?? (json['_id'] as String?) ?? '',
      userId: json['userId']?.toString() ?? '',
      courseId: json['courseId']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'RWF',
      paymentMethod: json['paymentMethod'] as String? ?? '',
      transactionId: json['transactionId'] as String? ?? '',
      status: PaymentStatusHelper.fromString(json['status'] as String? ?? 'pending'),
      contactInfo: json['contactInfo'] as String? ?? '',
      paymentDate: json['paymentDate'] != null 
          ? DateTime.parse(json['paymentDate'].toString()) 
          : null,
      createdAt: DateTime.parse(json['createdAt']?.toString() ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt']?.toString() ?? DateTime.now().toIso8601String()),
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
    if (value is num) return value.toInt();
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

void main() {
  print('=== Testing PaymentListResponse Fix ===\n');

  // Test Case 1: The problematic case - payments as integer
  print('Test 1: payments = 0 (integer)');
  final testData1 = {
    'payments': 0,
    'totalPages': 1,
    'currentPage': 1,
    'total': 0
  };
  
  try {
    final result1 = PaymentListResponse.fromJson(testData1);
    print('✓ Success: payments length = ${result1.payments.length}');
    print('✓ Success: totalPages = ${result1.totalPages}');
    print('✓ Success: currentPage = ${result1.currentPage}');
    print('✓ Success: total = ${result1.total}\n');
  } catch (e) {
    print('✗ Failed: $e\n');
  }

  // Test Case 2: payments as null
  print('Test 2: payments = null');
  final testData2 = {
    'payments': null,
    'totalPages': 1,
    'currentPage': 1,
    'total': 0
  };
  
  try {
    final result2 = PaymentListResponse.fromJson(testData2);
    print('✓ Success: payments length = ${result2.payments.length}\n');
  } catch (e) {
    print('✗ Failed: $e\n');
  }

  // Test Case 3: Valid payments list
  print('Test 3: Valid payments list');
  final testData3 = {
    'payments': [
      {
        '_id': 'test_id_1',
        'userId': 'user123',
        'courseId': 'course123',
        'amount': 1000,
        'currency': 'RWF',
        'paymentMethod': 'mtn',
        'transactionId': 'TXN123',
        'status': 'pending',
        'contactInfo': '0788888888',
        'createdAt': '2024-01-01T00:00:00.000Z',
        'updatedAt': '2024-01-01T00:00:00.000Z'
      }
    ],
    'totalPages': 1,
    'currentPage': 1,
    'total': 1
  };
  
  try {
    final result3 = PaymentListResponse.fromJson(testData3);
    print('✓ Success: payments length = ${result3.payments.length}');
    print('✓ Success: first payment id = ${result3.payments[0].id}');
    print('✓ Success: total = ${result3.total}\n');
  } catch (e) {
    print('✗ Failed: $e\n');
  }

  // Test Case 4: Malformed data
  print('Test 4: Malformed payments data');
  final testData4 = {
    'payments': 'invalid_string_data',
    'totalPages': 'invalid',
    'currentPage': null,
    'total': {}
  };
  
  try {
    final result4 = PaymentListResponse.fromJson(testData4);
    print('✓ Success: payments length = ${result4.payments.length}');
    print('✓ Success: totalPages = ${result4.totalPages}');
    print('✓ Success: currentPage = ${result4.currentPage}');
    print('✓ Success: total = ${result4.total}\n');
  } catch (e) {
    print('✗ Failed: $e\n');
  }

  print('=== All tests completed ===');
}