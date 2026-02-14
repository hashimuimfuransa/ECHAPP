import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/app_theme.dart';
import '../../../presentation/providers/payment_riverpod_provider.dart';
import '../../../models/payment.dart';
import '../../../models/payment_status.dart';
import '../../../services/api/payment_api_service.dart';

class PaymentManagementScreen extends ConsumerStatefulWidget {
  const PaymentManagementScreen({super.key});

  @override
  ConsumerState<PaymentManagementScreen> createState() => _PaymentManagementScreenState();
}

class _PaymentManagementScreenState extends ConsumerState<PaymentManagementScreen> {
  bool _hasLoaded = false;

  @override
  void initState() {
    super.initState();
    // Load data once when widget is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final paymentState = ref.read(paymentProvider);
      if (!_hasLoaded && !paymentState.isLoading) {
        _hasLoaded = true;
        final paymentNotifier = ref.read(paymentProvider.notifier);
        print('PaymentManagementScreen: Initial loading of payments and stats');
        paymentNotifier.loadPayments();
        paymentNotifier.loadPaymentStats();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(paymentProvider);
    final paymentNotifier = ref.read(paymentProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Management'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              print('PaymentManagementScreen: Refresh button pressed');
              paymentNotifier.loadPayments();
              paymentNotifier.loadPaymentStats();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8.0), // Prevent bottom overflow
          child: Column(
            children: [
              // Filters and Search
              _buildFilters(ref, paymentState, paymentNotifier),
              
              // Statistics
              if (paymentState.stats != null) _buildStats(paymentState.stats!),
              
              // Payments List
              Expanded(
                child: _buildPaymentsList(ref, paymentState, paymentNotifier),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilters(WidgetRef ref, PaymentState state, PaymentStateNotifier notifier) {
    final searchController = TextEditingController(text: state.searchQuery);
    
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
            controller: searchController,
            decoration: const InputDecoration(
              hintText: 'Search by transaction ID, user, or course...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) => notifier.setSearchQuery(value),
          ),
          const SizedBox(height: 12),
          
          // Status filter chips
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip('All', null, state, notifier),
                _buildFilterChip('Pending', PaymentStatus.pending, state, notifier),
                _buildFilterChip('Admin Review', PaymentStatus.adminReview, state, notifier),
                _buildFilterChip('Approved', PaymentStatus.approved, state, notifier),
                _buildFilterChip('Completed', PaymentStatus.completed, state, notifier),
                _buildFilterChip('Failed', PaymentStatus.failed, state, notifier),
                _buildFilterChip('Cancelled', PaymentStatus.cancelled, state, notifier),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, PaymentStatus? status, PaymentState state, PaymentStateNotifier notifier) {
    final isSelected = state.filterStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          notifier.setFilterStatus(selected ? status : null);
        },
        selectedColor: AppTheme.primary.withOpacity(0.2),
        backgroundColor: Colors.grey[200],
      ),
    );
  }

  Widget _buildStats(PaymentStatsResponse stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Statistics',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatCard('Total', stats.totalPayments.toString(), Colors.blue),
              _buildStatCard('Pending', stats.pendingPayments.toString(), Colors.orange),
              _buildStatCard('Approved', stats.approvedPayments.toString(), Colors.green),
              _buildStatCard('Completed', stats.completedPayments.toString(), Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Card(
        color: color.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentsList(WidgetRef ref, PaymentState state, PaymentStateNotifier notifier) {
    if (state.isLoading && state.payments.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.payments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            const Text(
              'Error loading payments',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              state.error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                print('PaymentManagementScreen: Retry button pressed');
                notifier.loadPayments();
                notifier.loadPaymentStats();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final payments = state.filteredPayments;
    
    if (payments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payment_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No payments found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              state.searchQuery.isNotEmpty
                  ? 'Try adjusting your search criteria'
                  : 'No payments match the current filters',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        print('PaymentManagementScreen: Pull to refresh triggered');
        await notifier.loadPayments();
        await notifier.loadPaymentStats();
      },
      child: ListView.builder(
        itemCount: payments.length,
        itemBuilder: (context, index) {
          final payment = payments[index];
          return _buildPaymentCard(context, payment, state, notifier);
        },
      ),
    );
  }

  Widget _buildPaymentCard(BuildContext context, Payment payment, PaymentState state, PaymentStateNotifier notifier) {
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
                        payment.user?.fullName ?? 'Unknown User',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      Text(
                        payment.user?.email ?? '',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
            
            // Course and Amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payment.course?.title ?? 'Unknown Course',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${payment.amount} ${payment.currency}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
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
                'Contact: ${payment.contactInfo}',
                style: TextStyle(color: Colors.grey[700], fontSize: 12),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (payment.canBeApproved) ...[
                  OutlinedButton(
                    onPressed: state.isProcessing ? null : () => _showApproveDialog(context, payment, notifier, state.isProcessing),
                    child: const Text('Approve'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: state.isProcessing ? null : () => _showRejectDialog(context, payment, notifier, state.isProcessing),
                    child: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => _showPaymentDetails(context, payment),
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

  void _showApproveDialog(BuildContext context, Payment payment, PaymentStateNotifier notifier, bool isProcessing) {
    final notesController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to approve payment ${payment.transactionId}?'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Admin Notes (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: isProcessing
                ? null
                : () {
                    Navigator.pop(context);
                    notifier.verifyPayment(
                      paymentId: payment.id,
                      status: PaymentStatus.approved,
                      adminNotes: notesController.text,
                    );
                  },
            child: isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, Payment payment, PaymentStateNotifier notifier, bool isProcessing) {
    final notesController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to reject payment ${payment.transactionId}?'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Reason for Rejection',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: isProcessing
                ? null
                : () {
                    Navigator.pop(context);
                    notifier.verifyPayment(
                      paymentId: payment.id,
                      status: PaymentStatus.failed,
                      adminNotes: notesController.text,
                    );
                  },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showPaymentDetails(BuildContext context, Payment payment) {
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
