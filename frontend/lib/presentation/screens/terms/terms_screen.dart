import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:excellencecoachinghub/presentation/widgets/beautiful_widgets.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  Future<void> _launchPhone(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF3B82F6), // Blue
              Color(0xFF8B5CF6), // Purple
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(context),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section
                      GlassContainer(
                        child: Padding(
                          padding: const EdgeInsets.all(25),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF8B5CF6),
                                      borderRadius: BorderRadius.all(Radius.circular(12)),
                                    ),
                                    child: const Icon(
                                      Icons.description_outlined,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Terms of Service',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 5),
                                        Text(
                                          'Last updated: February 2026',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'By using Excellence Coaching Hub, you agree to these terms and conditions that govern your access to and use of our educational platform.',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 15,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 25),
                      
                      // Acceptance of Terms
                      _buildTermsSection(
                        context,
                        'Acceptance of Terms',
                        [
                          '• By accessing or using Excellence Coaching Hub, you agree to be bound by these Terms of Service',
                          '• If you do not agree to these terms, you must not use our services',
                          '• We may update these terms at any time, and your continued use constitutes acceptance of changes',
                          '• You are responsible for reviewing these terms periodically for updates',
                        ],
                      ),
                      
                      const SizedBox(height: 25),
                      
                      // User Eligibility
                      _buildTermsSection(
                        context,
                        'User Eligibility',
                        [
                          '• You must be at least 13 years old to use this service',
                          '• If you are under 18, you must have parental consent',
                          '• You must provide accurate and complete information when creating an account',
                          '• You are responsible for maintaining the security of your account credentials',
                          '• One account per user - sharing accounts is prohibited',
                        ],
                      ),
                      
                      const SizedBox(height: 25),
                      
                      // Service Usage
                      _buildTermsSection(
                        context,
                        'Service Usage',
                        [
                          '• All content is provided for educational purposes only',
                          '• You may not copy, distribute, or modify course materials without permission',
                          '• You agree to use the service only for lawful purposes',
                          '• You must not attempt to interfere with the proper functioning of our platform',
                          '• We reserve the right to suspend or terminate accounts for violations',
                        ],
                      ),
                      
                      const SizedBox(height: 25),
                      
                      // Payments and Refunds
                      _buildTermsSection(
                        context,
                        'Payments and Refunds',
                        [
                          '• All course payments are non-refundable after 7 days of purchase',
                          '• Refunds may be considered within the first 7 days for technical issues',
                          '• Subscription fees are billed in advance and non-refundable',
                          '• We reserve the right to modify pricing with 30 days notice',
                          '• Payment processing is handled securely through our payment partners',
                        ],
                      ),
                      
                      const SizedBox(height: 25),
                      
                      // Intellectual Property
                      _buildTermsSection(
                        context,
                        'Intellectual Property',
                        [
                          '• All course content, materials, and trademarks are owned by Excellence Coaching Hub',
                          '• You are granted a limited license to access content for personal educational use',
                          '• Unauthorized reproduction or distribution of content is prohibited',
                          '• You retain ownership of content you create and submit to the platform',
                          '• By submitting content, you grant us a license to display and distribute it',
                        ],
                      ),
                      
                      const SizedBox(height: 25),
                      
                      // Limitation of Liability
                      _buildTermsSection(
                        context,
                        'Limitation of Liability',
                        [
                          '• Our service is provided "as is" without warranties of any kind',
                          '• We are not liable for indirect, incidental, or consequential damages',
                          '• We do not guarantee specific results from using our educational content',
                          '• Your use of the service is at your own risk',
                          '• We are not responsible for content provided by third-party instructors',
                        ],
                      ),
                      
                      const SizedBox(height: 25),
                      
                      // Termination
                      _buildTermsSection(
                        context,
                        'Termination',
                        [
                          '• We may terminate or suspend your account at any time for violations',
                          '• You may terminate your account by contacting support',
                          '• Upon termination, you lose access to paid content',
                          '• We reserve the right to refuse service to anyone for any reason',
                          '• Termination does not affect our rights to content you have submitted',
                        ],
                      ),
                      
                      const SizedBox(height: 25),
                      
                      // Contact Information
                      GlassContainer(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Contact Us',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 15),
                              const Text(
                                'If you have questions about these Terms of Service, please contact us:',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 15,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 15),
                              _buildContactLink('📧 info@excellencecoachinghub.com', () => _launchEmail('info@excellencecoachinghub.com')),
                              _buildContactLink('🌐 excellencecoachinghub.com', () => _launchUrl('excellencecoachinghub.com')),
                              _buildContactLink('📱 +250 788 535 156', () => _launchPhone('250788535156')),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildContactLink(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            height: 1.6,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 24),
          ),
          const Text(
            'Terms of Service',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
  
  Widget _buildTermsSection(BuildContext context, String title, List<String> items) {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                item,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }
}