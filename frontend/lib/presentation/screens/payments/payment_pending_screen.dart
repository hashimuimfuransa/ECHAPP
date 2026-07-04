import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/course.dart';
import '../../../models/payment_status.dart';
import '../../../models/platform_settings.dart';
import '../../providers/payment_riverpod_provider.dart';
import '../../providers/platform_settings_provider.dart';
import '../../providers/course_provider.dart';

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
  AppLocalizations? _l10n;

  @override
  void initState() {
    super.initState();

    // Start automatic checking of payment status
    _startAutoRefresh();

    // Initial load of user payments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(paymentProvider.notifier).loadUserPayments();
      
      // PRE-FETCH: Start pre-fetching course content while waiting for approval
      // This makes the transition instant once approved
      ref.read(courseContentProvider(widget.course.id).future);
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
          // Payment rejected/cancelled - stop polling and let the user know
          _timer?.cancel();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Payment ${coursePayment.status.displayName}. Please contact us for assistance.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking payment status: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  void _handlePaymentApproved() {
    // Stop the timer since payment is approved
    _timer?.cancel();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment approved! Redirecting to your course...'),
          backgroundColor: Colors.green,
        ),
      );
    }

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
    final l10n = AppLocalizations.of(context);
    _l10n ??= l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.paymentPendingApproval ?? 'Payment Pending Approval'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _buildSafeContent(context),
    );
  }

  Widget _buildSafeContent(BuildContext context) {
    final settingsAsync = ref.watch(platformSettingsProvider);

    return Container(
      color: AppTheme.getBackgroundColor(context),
      child: SafeArea(
        child: settingsAsync.when(
          data: (settings) => _buildContent(context, settings),
          loading: () => _buildContent(context, null), // Show content immediately with fallbacks while loading
          error: (err, stack) {
            debugPrint('PlatformSettings error: $err');
            return _buildContent(context, null); // Fallback to hardcoded on error
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, PlatformSettings? settings) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWideScreen = constraints.maxWidth > 600;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),

              // Icon
              Icon(
                Icons.hourglass_top_rounded,
                size: 64,
                color: AppTheme.primary,
              ),

              const SizedBox(height: 16),

              // Title
              Text(
                _l10n?.paymentPendingApproval ?? 'Payment Pending',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isWideScreen ? 28 : 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextColor(context),
                ),
              ),

              const SizedBox(height: 12),

              // Instructions
              Text(
                _l10n?.paymentPendingDescription(widget.course.title) ??
                    'To complete your enrollment in "${widget.course.title}", please contact us using the details below and share your payment confirmation.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isWideScreen ? 18 : 16,
                  color: AppTheme.getSecondaryTextColor(context),
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
                      Row(
                        children: [
                          Icon(Icons.contact_phone, color: AppTheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            _l10n?.needHelp ?? 'Contact Us to Pay',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _l10n?.toCompletePayment ?? 'To complete your payment, reach us via:',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: AppTheme.getTextColor(context),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Payment and Contact Instructions from Backend or Fallback
                      _buildPaymentAndContactInstructions(settings),
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
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go('/courses');
                              }
                            },
                            child: Text(_l10n?.backToCourse ?? 'Back to Course'),
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
                                : Text(_l10n?.checkStatus ?? 'Check Status'),
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
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go('/courses');
                              }
                            },
                            child: Text(_l10n?.backToCourse ?? 'Back to Course'),
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
                              : Text(_l10n?.checkStatus ?? 'Check Status'),
                        ),
                      ],
                    ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPaymentAndContactInstructions(PlatformSettings? settings) {
    final List<Widget> instructions = [];

    if (settings != null) {
      // Use Backend settings
      if (settings.paymentInfo.mtnMomo.enabled && 
          (settings.paymentInfo.mtnMomo.accountName.isNotEmpty || 
           settings.paymentInfo.mtnMomo.accountNumber.isNotEmpty)) {
        instructions.add(_buildContactInstruction(
          _l10n?.paymentViaMtnMomo ?? 'Payment via MTN MoMo:',
          '${settings.paymentInfo.mtnMomo.accountName} - ${settings.paymentInfo.mtnMomo.accountNumber}',
          Icons.phone_android,
        ));
        instructions.add(const SizedBox(height: 8));
      }

      if (settings.paymentInfo.airtelMoney.enabled &&
          (settings.paymentInfo.airtelMoney.accountName.isNotEmpty ||
           settings.paymentInfo.airtelMoney.accountNumber.isNotEmpty)) {
        instructions.add(_buildContactInstruction(
          _l10n?.paymentViaAirtelMoney ?? 'Payment via Airtel Money:',
          '${settings.paymentInfo.airtelMoney.accountName} - ${settings.paymentInfo.airtelMoney.accountNumber}',
          Icons.phone_android,
        ));
        instructions.add(const SizedBox(height: 8));
      }

      if (settings.paymentInfo.bankTransfer.enabled &&
          (settings.paymentInfo.bankTransfer.accountName.isNotEmpty ||
           settings.paymentInfo.bankTransfer.accountNumber.isNotEmpty)) {
        instructions.add(_buildContactInstruction(
          _l10n?.paymentViaBankTransfer(settings.paymentInfo.bankTransfer.bankName) ??
              'Payment via Bank Transfer (${settings.paymentInfo.bankTransfer.bankName}):',
          '${settings.paymentInfo.bankTransfer.accountName} - ${settings.paymentInfo.bankTransfer.accountNumber}',
          Icons.account_balance,
        ));
        instructions.add(const SizedBox(height: 8));
      }

      // Contact Info
      final support = settings.paymentInfo.contactSupport;
      if (support.phone.isNotEmpty) {
        instructions.add(_buildContactInstruction(
          _l10n?.contactSupportPhone ?? 'Contact Support Phone:',
          support.phone,
          Icons.phone,
        ));
        instructions.add(const SizedBox(height: 8));
      }

      if (support.email.isNotEmpty) {
        instructions.add(_buildContactInstruction(
          _l10n?.contactSupportEmail ?? 'Contact Support Email:',
          support.email,
          Icons.email,
        ));
        instructions.add(const SizedBox(height: 8));
      }

      if (support.whatsapp.isNotEmpty) {
        instructions.add(_buildContactInstruction(
          _l10n?.contactOnWhatsapp ?? 'Contact on WhatsApp:',
          support.whatsapp,
          Icons.chat,
        ));
        instructions.add(const SizedBox(height: 8));
      }
    }

    // If no instructions from backend (or settings is null), show fallbacks
    if (instructions.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildContactInstruction(
            _l10n?.contactForPayment ?? '1. Contact for payment via:',
            'MTN: +250 793 828 834',
            Icons.phone,
          ),
          const SizedBox(height: 8),
          _buildContactInstruction(
            _l10n?.alsoAvailableVia ?? '2. Also available via:',
            'MTN: +250 788 535 156',
            Icons.phone,
          ),
          const SizedBox(height: 8),
          _buildContactInstruction(
            _l10n?.additionalContact ?? '3. Additional contact:',
            'MTN: +250 781 671 517',
            Icons.phone,
          ),
          const SizedBox(height: 8),
          _buildContactInstruction(
            _l10n?.contactViaEmail ?? '4. Contact via email:',
            'info@excellencecoachinghub.com',
            Icons.email,
          ),
          const SizedBox(height: 8),
          _buildContactInstruction(
            _l10n?.contactOnWhatsappNumber ?? '5. Or contact us on WhatsApp:',
            '+250 793 828 834 / +250 788 535 156 / +250 781 671 517',
            Icons.chat,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: instructions,
    );
  }

  Widget _buildContactInstruction(
      String instruction, String contact, IconData icon) {
    return Builder(
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 16, color: AppTheme.getSecondaryTextColor(context)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      instruction,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.getTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.getSurfaceColor(context),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        contact,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.getTextColor(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
