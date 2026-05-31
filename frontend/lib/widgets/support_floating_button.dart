import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/l10n/app_localizations.dart';
import 'package:excellencecoachinghub/services/ai_chat_service.dart';
import 'package:excellencecoachinghub/widgets/ai_chat_dialog.dart';
import 'package:excellencecoachinghub/presentation/providers/platform_settings_provider.dart';

/// Floating Support Button for dashboard that provides platform guidance
class SupportFloatingButton extends ConsumerStatefulWidget {
  const SupportFloatingButton({super.key});

  @override
  ConsumerState<SupportFloatingButton> createState() => _SupportFloatingButtonState();
}

class _SupportFloatingButtonState extends ConsumerState<SupportFloatingButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _bubbleController;
  late Animation<double> _bubbleScaleAnimation;
  bool _showBubble = false;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOutSine,
    ));

    _bubbleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _bubbleScaleAnimation = CurvedAnimation(
      parent: _bubbleController,
      curve: Curves.easeOutBack,
    );

    // Show bubble after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showBubble = true;
        });
        _bubbleController.forward();
        
        // Hide bubble after 8 seconds
        Future.delayed(const Duration(seconds: 8), () {
          if (mounted && _showBubble) {
            _bubbleController.reverse().then((_) {
              if (mounted) {
                setState(() {
                  _showBubble = false;
                });
              }
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _bubbleController.dispose();
    super.dispose();
  }

  void _toggleSupport() {
    print('SupportFloatingButton: _toggleSupport called');
    
    // Show dialog using showDialog for better reliability
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => _SupportDialog(
        onClose: () {
          Navigator.pop(context);
          _pulseController.repeat(reverse: true);
        },
      ),
    );
    _pulseController.stop();
    if (_showBubble) {
      setState(() {
        _showBubble = false;
      });
      _bubbleController.reverse();
    }
    
    print('SupportFloatingButton: _toggleSupport completed');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Support label
        Positioned(
          right: 60,
          bottom: 20,
          child: AnimatedOpacity(
            opacity: _showBubble ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    AppTheme.primary.withOpacity(0.95),
                    AppTheme.accent.withOpacity(0.95),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.support_agent,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l10n?.support ?? 'Support',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Support bubble
        if (_showBubble)
          Positioned(
            right: 0,
            bottom: 75,
            child: ScaleTransition(
              scale: _bubbleScaleAnimation,
              child: Container(
                width: 200,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: AppTheme.primary.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.support_agent,
                            color: AppTheme.primary,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n?.support ?? 'Support',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppTheme.primary,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            _bubbleController.reverse().then((_) {
                              if (mounted) {
                                setState(() {
                                  _showBubble = false;
                                });
                              }
                            });
                          },
                          child: Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n?.needHelp ?? 'Need help using the platform? I\'m here to guide you!',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        
        // Floating support button
        ScaleTransition(
          scale: _pulseAnimation,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primary,
                  AppTheme.primaryDark,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: FloatingActionButton(
              onPressed: _toggleSupport,
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              elevation: 0,
              mini: false,
              child: const Icon(Icons.support_agent, size: 24),
            ),
          ),
        ),
      ],
    );
  }
}

class _SupportDialog extends ConsumerWidget {
  final VoidCallback onClose;

  const _SupportDialog({required this.onClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 700),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.support_agent,
                        color: AppTheme.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n?.support ?? 'Support',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n?.helpCenterSubtitle ?? 'Get help with using the app',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: onClose,
                      icon: const Icon(Icons.close),
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSupportItem(
                  context,
                  icon: Icons.school,
                  title: l10n?.continueLearning ?? 'How to start learning',
                  description: 'Learn how to enroll in courses and start your learning journey',
                  onTap: () {
                    onClose();
                    _showGuide(context, 'courses');
                  },
                ),
                const SizedBox(height: 12),
                _buildSupportItem(
                  context,
                  icon: Icons.payment,
                  title: 'Payment Guide',
                  description: 'Understand how to make payments and manage subscriptions',
                  onTap: () {
                    onClose();
                    _showGuide(context, 'payments');
                  },
                ),
                const SizedBox(height: 12),
                _buildSupportItem(
                  context,
                  icon: Icons.video_library,
                  title: 'Video Lessons',
                  description: 'Learn how to access and download video lessons',
                  onTap: () {
                    onClose();
                    _showGuide(context, 'videos');
                  },
                ),
                const SizedBox(height: 12),
                _buildSupportItem(
                  context,
                  icon: Icons.quiz,
                  title: 'Taking Exams',
                  description: 'Guide on how to take exams and track your progress',
                  onTap: () {
                    onClose();
                    _showGuide(context, 'exams');
                  },
                ),
                const SizedBox(height: 12),
                _buildSupportItem(
                  context,
                  icon: Icons.auto_awesome,
                  title: 'Chat with AI Assistant',
                  description: 'Get instant help from our AI support assistant',
                  onTap: () {
                    onClose();
                    _showAIChat(context);
                  },
                ),
                const SizedBox(height: 12),
                _buildSupportItem(
                  context,
                  icon: Icons.contact_support,
                  title: l10n?.contactSupport ?? 'Contact Support',
                  description: 'Get direct help from our support team',
                  onTap: () {
                    onClose();
                    _showContactSupport(context, ref);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSupportItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark 
              ? AppTheme.primary.withOpacity(0.08)
              : AppTheme.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primary.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: AppTheme.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDark ? Colors.grey[500] : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  void _showGuide(BuildContext context, String topic) {
    showDialog(
      context: context,
      builder: (context) => _GuideDialog(topic: topic),
    );
  }

  void _showContactSupport(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settingsAsync = ref.read(platformSettingsProvider);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n?.contactSupport ?? 'Contact Support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n?.support24_7 ?? 'Our support team is here to help you 24/7:'),
            const SizedBox(height: 16),
            settingsAsync.when(
              data: (settings) {
                final contact = settings.paymentInfo.contactSupport;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (contact.email.isNotEmpty) ...[
                      _buildContactItem(
                        Icons.email,
                        'Email: ${contact.email}',
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (contact.phone.isNotEmpty) ...[
                      _buildContactItem(
                        Icons.phone,
                        'Phone: ${contact.phone}',
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (contact.whatsapp.isNotEmpty)
                      _buildContactItem(
                        Icons.message,
                        'WhatsApp: ${contact.whatsapp}',
                      ),
                  ],
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildContactItem(
                    Icons.email,
                    l10n?.contactSupportEmail ?? 'Email: info@excellencecoachinghub.com',
                  ),
                  const SizedBox(height: 12),
                  _buildContactItem(
                    Icons.phone,
                    l10n?.contactSupportPhone ?? 'Phone: +250 788 123 456',
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n?.close ?? 'Close'),
          ),
        ],
      ),
    );
  }

  void _showAIChat(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withOpacity(0.5),
        pageBuilder: (context, animation, secondaryAnimation) => Scaffold(
          backgroundColor: Colors.transparent,
          body: SizedBox.expand(
            child: ModernAIChatDialog(
              chatService: RealAIChatService(),
              conversationId: 'support_chat',
              onClose: () => Navigator.pop(context),
              // Pass platform support context so AI knows to provide general platform help
              context: const AIChatContext(
                isPlatformSupport: true,
                studentName: 'Student',
                studentLevel: 'Platform User',
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class _GuideDialog extends StatelessWidget {
  final String topic;

  const _GuideDialog({required this.topic});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    String title;
    String content;

    switch (topic) {
      case 'courses':
        title = l10n?.continueLearning ?? 'How to Start Learning';
        content = '''
1. Browse available courses from the dashboard
2. Click on a course to view details
3. Tap "Enroll" to join the course
4. Go to "My Learning" to access enrolled courses
5. Start with the first lesson and progress at your own pace
        ''';
        break;
      case 'payments':
        title = 'Payment Guide';
        content = '''
1. Select a course and click "Enroll"
2. Choose your preferred payment method
3. Complete the payment process
4. You'll receive a confirmation with your invoice
5. Access your course immediately after payment
        ''';
        break;
      case 'videos':
        title = 'Video Lessons';
        content = '''
1. Navigate to your enrolled course
2. Select a lesson from the list
3. Click play to watch the video
4. Use the download button to save for offline viewing
5. Track your progress as you complete lessons
        ''';
        break;
      case 'exams':
        title = 'Taking Exams';
        content = '''
1. Complete all lessons in a section
2. Take the section quiz to test your knowledge
3. Answer all questions carefully
4. Submit your exam when ready
5. View your results and track your overall progress
        ''';
        break;
      default:
        title = 'Guide';
        content = 'Guide content not available.';
    }

    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Text(
          content,
          style: TextStyle(
            fontSize: 14,
            height: 1.6,
            color: isDark ? Colors.grey[300] : Colors.black87,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n?.close ?? 'Close'),
        ),
      ],
    );
  }
}
