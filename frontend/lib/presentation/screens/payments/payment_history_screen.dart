import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/app_theme.dart';
import '../../../presentation/providers/payment_provider.dart';
import '../../../models/payment.dart';
import '../../../models/payment_status.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPayments();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _loadPayments() {
    final provider = Provider.of<PaymentProvider>(context, listen: false);
    provider.loadUserPayments();
  }

  void _onSearchChanged() {
    final provider = Provider.of<PaymentProvider>(context, listen: false);
    provider.setSearchQuery(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Payments'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPayments,
          ),
        ],
      ),
      body: Consumer<PaymentProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.userPayments.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.userPayments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading payments',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadPayments,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Filters and Search
              _buildFilters(provider),
              
              // Payments List
              Expanded(
                child: _buildPaymentsList(provider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilters(PaymentProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Search by transaction ID or course...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          
          // Status filter chips
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip('All', null, provider),
                _buildFilterChip('Pending', PaymentStatus.pending, provider),
                _buildFilterChip('Approved', PaymentStatus.approved, provider),
                _buildFilterChip('Completed', PaymentStatus.completed, provider),
                _buildFilterChip('Failed', PaymentStatus.failed, provider),
                _buildFilterChip('Cancelled', PaymentStatus.cancelled, provider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, PaymentStatus? status, PaymentProvider provider) {
    final isSelected = provider.filterStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          provider.setFilterStatus(selected ? status : null);
        },
        selectedColor: AppTheme.primary.withOpacity(0.2),
        backgroundColor: Colors.grey[200],
      ),
    );
  }

  Widget _buildPaymentsList(PaymentProvider provider) {
    final payments = provider.filteredUserPayments;
    
    if (payments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payment_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No payments found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              provider.searchQuery.isNotEmpty
                  ? 'Try adjusting your search criteria'
                  : 'You haven\'t made any payments yet',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (provider.searchQuery.isEmpty)
              ElevatedButton(
                onPressed: () {
                  // Navigate to course listing to make a payment
                },
                child: const Text('Browse Courses'),
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadPayments(),
      child: ListView.builder(
        itemCount: payments.length,
        itemBuilder: (context, index) {
          final payment = payments[index];
          return _buildPaymentCard(payment, provider);
        },
      ),
    );
  }

  Widget _buildPaymentCard(Payment payment, PaymentProvider provider) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payment.transactionId,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        payment.course?.title ?? 'Unknown Course',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(payment.status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    payment.statusDisplayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Amount and Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${payment.amount} ${payment.currency}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Text(
                  'Payment Method: ${payment.paymentMethod}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Contact Info
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Contact Info: ${payment.contactInfo}',
                style: TextStyle(color: Colors.grey[700], fontSize: 12),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (payment.canBeCancelled)
                  OutlinedButton(
                    onPressed: provider.isProcessing ? null : () => _showCancelDialog(payment, provider),
                    child: const Text('Cancel'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => _showPaymentDetails(payment),
                  child: const Text('View Details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.adminReview:
        return Colors.blue;
      case PaymentStatus.approved:
        return Colors.green;
      case PaymentStatus.completed:
        return Colors.green;
      case PaymentStatus.failed:
        return Colors.red;
      case PaymentStatus.cancelled:
        return Colors.grey;
    }
  }

  void _showCancelDialog(Payment payment, PaymentProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Payment'),
        content: Text('Are you sure you want to cancel payment ${payment.transactionId}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: provider.isProcessing
                ? null
                : () {
                    Navigator.pop(context);
                    provider.cancelPayment(payment.id);
                  },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: provider.isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Yes, Cancel', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showPaymentDetails(Payment payment) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Details',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Transaction ID', payment.transactionId),
            _buildDetailRow('Status', payment.statusDisplayName),
            _buildDetailRow('Amount', '${payment.amount} ${payment.currency}'),
            _buildDetailRow('Payment Method', payment.paymentMethod),
            _buildDetailRow('Contact Info', payment.contactInfo),
            _buildDetailRow('Course', payment.course?.title ?? 'Unknown Course'),
            if (payment.paymentDate != null)
              _buildDetailRow('Payment Date', payment.paymentDate.toString()),
            if (payment.adminApproval != null) ...[
              const SizedBox(height: 16),
              const Text(
                'Admin Approval',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              _buildDetailRow('Approved By', payment.adminApproval!.approvedBy),
              _buildDetailRow('Approved At', payment.adminApproval!.approvedAt.toString()),
              if (payment.adminApproval!.adminNotes != null)
                _buildDetailRow('Notes', payment.adminApproval!.adminNotes!),
            ],
          ],
        ),
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
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
