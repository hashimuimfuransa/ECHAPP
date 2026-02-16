import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_theme.dart';
import '../../../models/course.dart';
import '../../../models/payment_status.dart';
import '../../providers/payment_riverpod_provider.dart';
import '../../providers/course_payment_providers.dart'; // Import the hasPendingPaymentProvider

class PaymentPendingScreen extends ConsumerStatefulWidget {
  final Course course;
  final String transactionId;
  final double amount;

  const PaymentPendingScreen({
    super.key,
    required this.course,
    required this.transactionId,
    required this.amount,
  });

  @override
  ConsumerState<PaymentPendingScreen> createState() =>
      _PaymentPendingScreenState();
}

class _PaymentPendingScreenState extends ConsumerState<PaymentPendingScreen> {
  Timer? _timer;
  bool _isChecking = false;
  String _statusMessage = 'Waiting for admin approval...';
  Color _statusColor = Colors.orange;

  @override
  void initState() {
    super.initState();

    // Start automatic checking of payment status
    _startAutoRefresh();

    // Initial load of user payments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(paymentProvider.notifier).loadUserPayments();
    });
  }

  void _startAutoRefresh() {
    // Check payment status every 5 seconds
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkPaymentStatus();
    });
  }

  void _checkPaymentStatus() async {
    if (_isChecking) return; // Prevent overlapping checks

    setState(() {
      _isChecking = true;
    });

    try {
      // Refresh user payments to get latest status
      await ref.read(paymentProvider.notifier).loadUserPayments();

      // Check if there's a payment for this course with approved status
      final paymentState = ref.read(paymentProvider);
      final coursePayments = paymentState.userPayments
          .where((payment) => payment.courseId == widget.course.id)
          .toList();

      if (coursePayments.isNotEmpty) {
        final coursePayment = coursePayments.first;
        if (coursePayment.status == PaymentStatus.approved ||
            coursePayment.status == PaymentStatus.completed) {
          // Payment approved, navigate to learning page
          _handlePaymentApproved();
        } else if (coursePayment.status == PaymentStatus.failed ||
            coursePayment.status == PaymentStatus.cancelled) {
          // Payment rejected/cancelled
          setState(() {
            _statusMessage = 'Payment ${coursePayment.status.displayName}';
            _statusColor = Colors.red;
          });
        } else {
          // Still pending
          setState(() {
            _statusMessage = 'Still waiting for admin approval...';
            _statusColor = Colors.orange;
          });
        }
      } else {
        // No payment found for this course
        setState(() {
          _statusMessage = 'No payment found for this course';
          _statusColor = Colors.red;
        });
      }
    } catch (e) {
      print('Error checking payment status: $e');
    } finally {
      setState(() {
        _isChecking = false;
      });
    }
  }

  void _handlePaymentApproved() {
    // Stop the timer since payment is approved
    _timer?.cancel();

    setState(() {
      _statusMessage = 'Payment Approved! Redirecting to course...';
      _statusColor = Colors.green;
    });

    // Navigate to the course learning page after a brief delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        // Navigate to course learning page using GoRouter
        context.go('/learning/${widget.course.id}');
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(paymentProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Pending Approval'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWideScreen = constraints.maxWidth > 600;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),

                // Title
                Text(
                  'Payment Pending Approval',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isWideScreen ? 28 : 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                // Status indicator
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.1),
                    border: Border.all(color: _statusColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isChecking
                            ? Icons.autorenew
                            : (_statusColor == Colors.green
                                ? Icons.check_circle
                                : (_statusColor == Colors.red
                                    ? Icons.error
                                    : Icons.hourglass_empty)),
                        color: _statusColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _statusMessage,
                        style: TextStyle(
                          color: _statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Description
                Text(
                  'Your payment for "${widget.course.title}" is currently pending admin approval.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isWideScreen ? 18 : 16,
                    color: Colors.grey[600],
                  ),
                ),

                const SizedBox(height: 24),

                // Contact Information Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.contact_phone, color: Colors.orange),
                            SizedBox(width: 8),
                            Text(
                              'Need Help?',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'To complete your payment:',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildContactInstruction(
                          '1. contact for payment via:',
                          'MTN: 0793828834',
                          Icons.phone,
                        ),
                        const SizedBox(height: 8),
                        _buildContactInstruction(
                          '2. Also available via:',
                          ' 0788535156',
                          Icons.phone,
                        ),
                        const SizedBox(height: 8),
                        _buildContactInstruction(
                          '3. Contact via email:',
                          'info@excellencecoachinghub.com',
                          Icons.email,
                        ),
                        const SizedBox(height: 8),
                        _buildContactInstruction(
                          '4. Or contact us on WhatsApp:',
                          '0793828834',
                          Icons.chat,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.amber[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber,
                                  color: Colors.amber, size: 16),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Important: Keep your transaction ID for reference and send proof of payment to admin.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.amber[800]!,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Auto-refresh info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    border: Border.all(color: Colors.blue[200]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.sync, color: Colors.blue[700], size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Automatically checking payment status every 5 seconds...',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Action Buttons
                isWideScreen
                    ? Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text('Back to Course'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isChecking
                                  ? null
                                  : () {
                                      // Manual refresh
                                      ref
                                          .read(paymentProvider.notifier)
                                          .loadUserPayments();
                                      _checkPaymentStatus();
                                    },
                              child: _isChecking
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Text('Check Status'),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text('Back to Course'),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _isChecking
                                ? null
                                : () {
                                    // Manual refresh
                                    ref
                                        .read(paymentProvider.notifier)
                                        .loadUserPayments();
                                    _checkPaymentStatus();
                                  },
                            child: _isChecking
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Text('Check Status'),
                          ),
                        ],
                      ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInstruction(
      String instruction, String contact, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  instruction,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    contact,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
