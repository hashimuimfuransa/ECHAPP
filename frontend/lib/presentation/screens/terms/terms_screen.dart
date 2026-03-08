import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';

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
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFF041B2D),
      body: Stack(
        children: [
          // Background Gradient decoration
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF10B981).withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFBF00).withOpacity(0.03),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, isDesktop),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 40 : 20,
                          vertical: 20,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeroSection(isDesktop),
                            const SizedBox(height: 32),
                            _buildTermsSection(
                              '1. Acceptance of Terms',
                              'By accessing or using Excellence Coaching Hub, you agree to be bound by these Terms of Service. If you do not agree to these terms, you must not use our services. We may update these terms at any time, and your continued use constitutes acceptance of changes.',
                            ),
                            _buildTermsSection(
                              '2. User Eligibility',
                              '• You must be at least 13 years old to use this service.\n'
                              '• If you are under 18, you must have parental consent.\n'
                              '• You must provide accurate and complete information when creating an account.\n'
                              '• You are responsible for maintaining the security of your account credentials.\n'
                              '• One account per user - sharing accounts is prohibited.',
                            ),
                            _buildTermsSection(
                              '3. Service Usage',
                              '• All content is provided for educational purposes only.\n'
                              '• You may not copy, distribute, or modify course materials without permission.\n'
                              '• You agree to use the service only for lawful purposes.\n'
                              '• You must not attempt to interfere with the proper functioning of our platform.\n'
                              '• We reserve the right to suspend or terminate accounts for violations.',
                            ),
                            _buildTermsSection(
                              '4. Payments and Refunds',
                              '• All course payments are non-refundable after 7 days of purchase.\n'
                              '• Refunds may be considered within the first 7 days for technical issues.\n'
                              '• Subscription fees are billed in advance and non-refundable.\n'
                              '• We reserve the right to modify pricing with 30 days notice.\n'
                              '• Payment processing is handled securely through our payment partners.',
                            ),
                            _buildTermsSection(
                              '5. Intellectual Property',
                              'All course content, materials, and trademarks are owned by Excellence Coaching Hub. You are granted a limited license to access content for personal educational use. Unauthorized reproduction or distribution of content is prohibited.',
                            ),
                            _buildTermsSection(
                              '6. Limitation of Liability',
                              'Our service is provided "as is" without warranties of any kind. We are not liable for indirect, incidental, or consequential damages. We do not guarantee specific results from using our educational content.',
                            ),
                            const SizedBox(height: 20),
                            _buildContactSection(),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
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

  Widget _buildHeader(BuildContext context, bool isDesktop) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 40 : 10,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF041B2D),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.05),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 8),
          const Text(
            'Terms of Service',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF10B981).withOpacity(0.1),
            const Color(0xFF10B981).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF10B981).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.description_outlined,
              color: Color(0xFF10B981),
              size: 28,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Terms of Service',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Last updated: February 2026',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Please read these terms carefully before using the Excellence Coaching Hub platform. These terms govern your access to and use of our educational services.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 15,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Questions or Concerns?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'If you have any questions regarding these terms, please don\'t hesitate to contact our legal team.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          _buildContactItem(Icons.email_outlined, 'info@excellencecoachinghub.com', () => _launchEmail('info@excellencecoachinghub.com')),
          const SizedBox(height: 12),
          _buildContactItem(Icons.language_outlined, 'excellencecoachinghub.com', () => _launchUrl('excellencecoachinghub.com')),
          const SizedBox(height: 12),
          _buildContactItem(Icons.phone_outlined, '+250 788 535 156', () => _launchPhone('250788535156')),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF10B981), size: 18),
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(
                color: Color(0xFF10B981),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
