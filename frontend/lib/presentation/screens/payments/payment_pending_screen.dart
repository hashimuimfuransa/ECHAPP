import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/app_theme.dart';
import '../../../models/course.dart';
import '../../providers/payment_riverpod_provider.dart';

class PaymentPendingScreen extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    // Load user payments to check status
    final paymentState = ref.watch(paymentProvider);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (paymentState.userPayments.isEmpty) {
        ref.read(paymentProvider.notifier).loadUserPayments();
      }
    });

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
                
                // Description
                Text(
                  'Your payment for "${course.title}" is currently pending admin approval.',
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
                              Icon(Icons.warning_amber, color: Colors.amber, size: 16),
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
                            onPressed: () {
                              // Refresh payment status
                              ref.read(paymentProvider.notifier).loadUserPayments();
                            },
                            child: const Text('Check Status'),
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
                          onPressed: () {
                            // Refresh payment status
                            ref.read(paymentProvider.notifier).loadUserPayments();
                          },
                          child: const Text('Check Status'),
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
  
  Widget _buildContactInstruction(String instruction, String contact, IconData icon) {
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
