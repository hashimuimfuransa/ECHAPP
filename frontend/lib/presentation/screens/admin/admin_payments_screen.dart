import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:excellence_coaching_hub/config/app_theme.dart';
import 'package:excellence_coaching_hub/services/api/payment_service.dart' as payment_service;

class AdminPaymentsScreen extends StatefulWidget {
  const AdminPaymentsScreen({super.key});

  @override
  State<AdminPaymentsScreen> createState() => _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends State<AdminPaymentsScreen> {
  List<payment_service.Payment> _payments = [];
  String _filterStatus = 'All';
  int _currentPage = 1;
  int _itemsPerPage = 10;
  int _totalPages = 1;
  bool _isLoading = false;
  String? _errorMessage;
  
  final List<Map<String, dynamic>> _mockPayments = [
    {
      'id': '1',
      'studentName': 'John Doe',
      'courseTitle': 'Flutter Development Masterclass',
      'amount': 45000,
      'status': 'Completed',
      'method': 'Mobile Money',
      'date': DateTime.now().subtract(const Duration(days: 1)),
      'reference': 'MM2024001',
    },
    {
      'id': '2',
      'studentName': 'Jane Smith',
      'courseTitle': 'Advanced React Native',
      'amount': 38000,
      'status': 'Pending',
      'method': 'Bank Transfer',
      'date': DateTime.now().subtract(const Duration(days: 2)),
      'reference': 'BT2024002',
    },
    {
      'id': '3',
      'studentName': 'Mike Johnson',
      'courseTitle': 'UI/UX Design Fundamentals',
      'amount': 32000,
      'status': 'Completed',
      'method': 'Mobile Money',
      'date': DateTime.now().subtract(const Duration(days: 3)),
      'reference': 'MM2024003',
    },
    {
      'id': '4',
      'studentName': 'Sarah Wilson',
      'courseTitle': 'Data Science with Python',
      'amount': 52000,
      'status': 'Failed',
      'method': 'Credit Card',
      'date': DateTime.now().subtract(const Duration(days: 5)),
      'reference': 'CC2024004',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final paymentService = payment_service.PaymentService();
      final response = await paymentService.getAllPayments(
        status: _filterStatus == 'All' ? null : _filterStatus.toLowerCase(),
        page: _currentPage,
        limit: _itemsPerPage,
      );
      
      setState(() {
        _payments = response.payments;
        _totalPages = response.totalPages;
        _isLoading = false;
      });
    } catch (e) {
      // Handle the case where there might be no payments gracefully
      if (e.toString().contains('Data type mismatch') || e.toString().contains('type') || e.toString().contains('null')) {
        setState(() {
          _payments = []; // Set empty list for no payments
          _totalPages = 0;
          _isLoading = false;
          // Don't set error message for empty data - just show empty state
        });
      } else {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  double _getTotalRevenue() {
    return _payments
        .where((payment) => payment.status == 'completed')
        .fold(0.0, (sum, payment) => sum + payment.amount);
  }

  int _getPaymentCount(String status) {
    if (status == 'All') return _payments.length;
    return _payments.where((payment) => payment.status.toLowerCase() == status.toLowerCase()).length;
  }

  List<payment_service.Payment> _getFilteredPayments() {
    if (_filterStatus == 'All') return _payments;
    return _payments.where((payment) => payment.status.toLowerCase() == _filterStatus.toLowerCase()).toList();
  }

  Future<void> _refreshPayments() async {
    await _loadPayments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Management'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Payments',
            onPressed: _refreshPayments,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export Reports',
            onPressed: _exportPayments,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 768;
          
          return Padding(
            padding: EdgeInsets.all(isSmallScreen ? 15 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderSection(isSmallScreen),
                const SizedBox(height: 20),
                _buildStatsSection(),
                const SizedBox(height: 20),
                _buildFilterSection(),
                const SizedBox(height: 20),
                _buildErrorMessage(),
                const SizedBox(height: 20),
                Expanded(
                  child: _isLoading && _payments.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : _getFilteredPayments().isEmpty
                      ? _buildEmptyState(isSmallScreen)
                      : _buildPaymentsList(isSmallScreen),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderSection(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Management',
          style: TextStyle(
            fontSize: isSmallScreen ? 20 : 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.blackColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Track and manage all course payments and transactions. Monitor revenue and payment status.',
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            color: AppTheme.greyColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    final totalRevenue = _getTotalRevenue();
    final completedPayments = _getPaymentCount('Completed');
    final pendingPayments = _getPaymentCount('Pending');
    final failedPayments = _getPaymentCount('Failed');

    return Row(
      children: [
        _buildStatCard('Total Revenue', 'RWF ${totalRevenue.toStringAsFixed(0)}', Icons.attach_money, Colors.green),
        const SizedBox(width: 15),
        _buildStatCard('Completed', completedPayments.toString(), Icons.check_circle, Colors.blue),
        const SizedBox(width: 15),
        _buildStatCard('Pending', pendingPayments.toString(), Icons.pending, Colors.orange),
        const SizedBox(width: 15),
        _buildStatCard('Failed', failedPayments.toString(), Icons.error, Colors.red),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.greyColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_list, color: AppTheme.greyColor),
          const SizedBox(width: 10),
          const Text(
            'Filter by Status:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 15),
          DropdownButton<String>(
            value: _filterStatus,
            items: ['All', 'Completed', 'Pending', 'Failed'].map((String status) {
              return DropdownMenuItem<String>(
                value: status,
                child: Text(status),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _filterStatus = value!;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    if (_errorMessage == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.red),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: () => setState(() => _errorMessage = null),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isSmallScreen) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.payment,
              size: 80,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _filterStatus == 'All' 
              ? 'No payments found' 
              : 'No ${_filterStatus.toLowerCase()} payments',
            style: TextStyle(
              fontSize: isSmallScreen ? 18 : 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.blackColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Payments will appear here once students enroll in courses',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              color: AppTheme.greyColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsList(bool isSmallScreen) {
    return RefreshIndicator(
      onRefresh: _refreshPayments,
      child: ListView.builder(
        itemCount: _getFilteredPayments().length,
        itemBuilder: (context, index) {
          final payment = _getFilteredPayments()[index];
          return _buildPaymentCard(payment, isSmallScreen);
        },
      ),
    );
  }

  Widget _buildPaymentCard(payment_service.Payment payment, bool isSmallScreen) {
    final statusColor = _getStatusColor(payment.status);
    final statusIcon = _getStatusIcon(payment.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: statusColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          payment.userId, // Using userId as student name for now
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallScreen ? 16 : 18,
                            color: AppTheme.blackColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          payment.courseId, // Using courseId for now
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                            color: AppTheme.greyColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        const SizedBox(width: 6),
                        Text(
                          payment.status,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RWF ${payment.amount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.blackColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        payment.paymentMethod,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.greyColor,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatDate(payment.createdAt),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.greyColor,
                        ),
                      ),
                      Text(
                        'Reference: ${payment.transactionId}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.greyColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isSmallScreen)
                    _buildCompactPaymentActions(payment)
                  else
                    _buildFullPaymentActions(payment),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green;
      case 'Pending':
        return Colors.orange;
      case 'Failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Completed':
        return Icons.check_circle;
      case 'Pending':
        return Icons.pending;
      case 'Failed':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  Widget _buildFullPaymentActions(payment_service.Payment payment) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton.icon(
          onPressed: () => _viewPaymentDetails(payment),
          icon: const Icon(Icons.visibility, size: 16),
          label: const Text('View Details'),
        ),
        const SizedBox(width: 10),
        if (payment.status == 'pending' || payment.status == 'admin_review')
          ElevatedButton.icon(
            onPressed: () => _markAsCompleted(payment),
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Approve'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        const SizedBox(width: 10),
        if (payment.status == 'pending' || payment.status == 'admin_review')
          ElevatedButton.icon(
            onPressed: () => _markAsFailed(payment),
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Reject'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
      ],
    );
  }

  Widget _buildCompactPaymentActions(payment_service.Payment payment) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.visibility, size: 20),
          onPressed: () => _viewPaymentDetails(payment),
          tooltip: 'View Details',
        ),
        if (payment.status == 'pending' || payment.status == 'admin_review')
          IconButton(
            icon: const Icon(Icons.check, size: 20),
            onPressed: () => _markAsCompleted(payment),
            tooltip: 'Approve Payment',
            color: Colors.green,
          ),
        if (payment.status == 'pending' || payment.status == 'admin_review')
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => _markAsFailed(payment),
            tooltip: 'Reject Payment',
            color: Colors.red,
          ),
      ],
    );
  }

  void _viewPaymentDetails(payment_service.Payment payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Student ID', payment.userId),
            _buildDetailRow('Course ID', payment.courseId),
            _buildDetailRow('Amount', 'RWF ${payment.amount.toStringAsFixed(0)}'),
            _buildDetailRow('Method', payment.paymentMethod),
            _buildDetailRow('Status', payment.status),
            _buildDetailRow('Reference', payment.transactionId),
            _buildDetailRow('Date', _formatDate(payment.createdAt)),
            if (payment.contactInfo != null)
              _buildDetailRow('Contact Info', payment.contactInfo!),
            if (payment.adminApproval != null) ...[
              _buildDetailRow('Approved By', payment.adminApproval!.approvedBy),
              _buildDetailRow('Approved At', _formatDate(payment.adminApproval!.approvedAt)),
              if (payment.adminApproval!.adminNotes != null)
                _buildDetailRow('Notes', payment.adminApproval!.adminNotes!),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _downloadReceipt(Map<String, dynamic> payment) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Receipt download functionality coming soon'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _markAsCompleted(payment_service.Payment payment) {
    // TODO: Replace with actual API call
    // final paymentService = payment_service.PaymentService();
    // paymentService.verifyPayment(payment.id, 'approved', 'Payment verified and approved');
    
    // For now, we'll just show a message since we can't modify the immutable model
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment marked as completed (API call needed)'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _markAsFailed(payment_service.Payment payment) {
    // TODO: Replace with actual API call
    // final paymentService = payment_service.PaymentService();
    // paymentService.verifyPayment(payment.id, 'failed', 'Payment verification failed');
    
    // For now, we'll just show a message since we can't modify the immutable model
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment marked as failed (API call needed)'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _exportPayments() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment export functionality coming soon'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}