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
    // Handle courseId which might be a string ID or a populated object
    String courseIdValue;
    if (json['courseId'] is String) {
      courseIdValue = json['courseId'];
    } else if (json['courseId'] is Map<String, dynamic>) {
      courseIdValue = json['courseId']['id'] ?? json['courseId']['_id'] ?? '';
    } else {
      courseIdValue = json['courseId']?.toString() ?? '';
    }

    // Handle userId which might be a string ID or a populated object
    String userIdValue;
    if (json['userId'] is String) {
      userIdValue = json['userId'];
    } else if (json['userId'] is Map<String, dynamic>) {
      userIdValue = json['userId']['id'] ?? json['userId']['_id'] ?? '';
    } else {
      userIdValue = json['userId']?.toString() ?? '';
    }

    return Payment(
      id: (json['id'] as String?) ?? (json['_id'] as String?) ?? '',
      userId: userIdValue,
      courseId: courseIdValue,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? '',
      paymentMethod: json['paymentMethod'] as String? ?? '',
      transactionId: json['transactionId'] as String? ?? '',
      status: json['status'] as String? ?? '',
      contactInfo: json['contactInfo'] as String? ?? '',
      paymentDate: json['paymentDate'] != null 
          ? DateTime.parse(json['paymentDate'].toString()) 
          : null,
      adminApproval: json['adminApproval'] != null
          ? PaymentAdminApproval.fromJson(json['adminApproval'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.parse(json['createdAt']?.toString() ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt']?.toString() ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'courseId': courseId,
      'amount': amount,
      'currency': currency,
      'paymentMethod': paymentMethod,
      'transactionId': transactionId,
      'status': status,
      'contactInfo': contactInfo,
      'paymentDate': paymentDate?.toIso8601String(),
      'adminApproval': adminApproval?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
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
    // Handle approvedBy which might be a string ID or a populated object
    String approvedByValue;
    if (json['approvedBy'] is String) {
      approvedByValue = json['approvedBy'];
    } else if (json['approvedBy'] is Map<String, dynamic>) {
      approvedByValue = json['approvedBy']['id'] ?? json['approvedBy']['_id'] ?? '';
    } else {
      approvedByValue = json['approvedBy']?.toString() ?? '';
    }

    return PaymentAdminApproval(
      approvedBy: approvedByValue,
      approvedAt: json['approvedAt'] != null ? DateTime.parse(json['approvedAt'].toString()) : DateTime.now(),
      adminNotes: json['adminNotes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'approvedBy': approvedBy,
      'approvedAt': approvedAt.toIso8601String(),
      'adminNotes': adminNotes,
    };
  }
}