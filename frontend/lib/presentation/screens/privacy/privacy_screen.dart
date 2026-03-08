import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

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
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF3B82F6).withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF10B981).withOpacity(0.03),
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
                            _buildPrivacySection(
                              '1. Information We Collect',
                              'We collect information that you provide directly to us when you create an account, enroll in a course, or communicate with us. This includes:\n\n'
                              '• Personal information (name, email address, phone number)\n'
                              '• Account credentials\n'
                              '• Course progress and enrollment data\n'
                              '• Payment information (processed securely by third-party providers)',
                            ),
                            _buildPrivacySection(
                              '2. How We Use Your Information',
                              'We use the information we collect to:\n\n'
                              '• Provide, maintain, and improve our educational services\n'
                              '• Process transactions and send related information\n'
                              '• Send you technical notices, updates, and support messages\n'
                              '• Respond to your comments and questions\n'
                              '• Monitor and analyze trends, usage, and activities',
                            ),
                            _buildPrivacySection(
                              '3. Data Protection and Security',
                              'We take reasonable measures to help protect information about you from loss, theft, misuse, and unauthorized access, disclosure, alteration, and destruction. All data is encrypted both in transit and at rest using industry-standard protocols.',
                            ),
                            _buildPrivacySection(
                              '4. Your Data Rights',
                              'You have the right to:\n\n'
                              '• Access the personal information we hold about you\n'
                              '• Request that we correct or delete your personal information\n'
                              '• Object to or restrict certain processing of your data\n'
                              '• Request a copy of your data in a portable format',
                            ),
                            _buildPrivacySection(
                              '5. Cookies and Tracking',
                              'We use cookies and similar tracking technologies to track activity on our platform and hold certain information to enhance your user experience and analyze how our services are used.',
                            ),
                            _buildPrivacySection(
                              '6. Third-Party Services',
                              'Our platform may contain links to third-party websites or services. We are not responsible for the privacy practices or the content of these third-party sites.',
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
            'Privacy Policy',
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
            const Color(0xFF3B82F6).withOpacity(0.1),
            const Color(0xFF3B82F6).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF3B82F6).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.privacy_tip_outlined,
              color: Color(0xFF3B82F6),
              size: 28,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Privacy Policy',
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
            'At Excellence Coaching Hub, your privacy is our priority. We are committed to protecting your personal information and being transparent about how we collect, use, and share it.',
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

  Widget _buildPrivacySection(String title, String content) {
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
            'Contact Our Privacy Team',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'If you have any questions or concerns about our privacy practices, please reach out to us:',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          _buildContactItem(Icons.email_outlined, 'privacy@excellencecoachinghub.com', () => _launchEmail('privacy@excellencecoachinghub.com')),
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
            Icon(icon, color: const Color(0xFF3B82F6), size: 18),
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(
                color: Color(0xFF3B82F6),
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
