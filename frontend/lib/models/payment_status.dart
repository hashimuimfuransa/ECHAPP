/// Payment status enumeration
enum PaymentStatus {
  pending('pending'),
  adminReview('admin_review'),
  approved('approved'),
  completed('completed'),
  failed('failed'),
  cancelled('cancelled');

  const PaymentStatus(this.value);
  final String value;

  /// Get display name for UI
  String get displayName {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.adminReview:
        return 'Admin Review';
      case PaymentStatus.approved:
        return 'Approved';
      case PaymentStatus.completed:
        return 'Completed';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Get color for UI display
  String get color {
    switch (this) {
      case PaymentStatus.pending:
        return 'orange';
      case PaymentStatus.adminReview:
        return 'blue';
      case PaymentStatus.approved:
        return 'green';
      case PaymentStatus.completed:
        return 'green';
      case PaymentStatus.failed:
        return 'red';
      case PaymentStatus.cancelled:
        return 'grey';
    }
  }

  /// Parse from string value
  static PaymentStatus fromString(String value) {
    return PaymentStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => PaymentStatus.pending,
    );
  }
}
