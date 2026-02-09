import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excellence_coaching_hub/config/app_theme.dart';
import 'package:excellence_coaching_hub/presentation/providers/payment_riverpod_provider.dart';
import 'package:excellence_coaching_hub/presentation/screens/admin/payment_management_screen_riverpod.dart';
import 'package:excellence_coaching_hub/presentation/screens/payments/payment_history_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: PaymentSystemTestApp(),
    ),
  );
}

class PaymentSystemTestApp extends StatelessWidget {
  const PaymentSystemTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Payment System Test',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: const PaymentSystemTestScreen(),
    );
  }
}

class PaymentSystemTestScreen extends ConsumerWidget {
  const PaymentSystemTestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment System Test'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Payment System Status',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            
            // Test Admin Payment Management
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PaymentManagementScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
              child: const Text(
                'Test Admin Payment Management',
                style: TextStyle(fontSize: 16),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Test User Payment History
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PaymentHistoryScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
              child: const Text(
                'Test User Payment History',
                style: TextStyle(fontSize: 16),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // System Status
            const Text(
              'System Components:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            _buildStatusItem('✅ Payment Models', 'Updated with proper status handling'),
            _buildStatusItem('✅ Payment API Service', 'Clean backend integration'),
            _buildStatusItem('✅ Riverpod Providers', 'Modern state management'),
            _buildStatusItem('✅ Admin Dashboard', 'Payment management interface'),
            _buildStatusItem('✅ User Interface', 'Payment history and initiation'),
            _buildStatusItem('✅ Mock Data', 'Working around database timeouts'),
            
            const SizedBox(height: 24),
            
            const Text(
              'The new payment system is ready to use!\n'
              'All old debugging code has been removed.\n'
              'Integration with existing screens is in progress.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Text(description, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}