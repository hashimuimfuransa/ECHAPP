import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/presentation/widgets/beautiful_widgets.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        colors: AppTheme.sunsetGradient,
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
                      // Privacy Overview
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
                                      color: Color(0xFF4facfe),
                                      borderRadius: BorderRadius.all(Radius.circular(12)),
                                    ),
                                    child: const Icon(
                                      Icons.privacy_tip_outlined,
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
                                          'Privacy Policy',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 5),
                                        Text(
                                          'Last updated: February 1, 2026',
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
                                'We are committed to protecting your privacy and ensuring your personal information is handled in a safe and responsible manner.',
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
                      
                      // Privacy Sections
                      _buildPrivacySection(
                        context,
                        'Information We Collect',
                        [
                          '• Personal information you provide during registration',
                          '• Email address and basic profile information',
                          '• Course enrollment and progress data',
                          '• Device information and usage analytics',
                          '• Payment information (processed securely by third parties)',
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      _buildPrivacySection(
                        context,
                        'How We Use Your Information',
                        [
                          '• Provide and improve our educational services',
                          '• Process your course enrollments and payments',
                          '• Send you important updates and notifications',
                          '• Analyze usage patterns to enhance user experience',
                          '• Comply with legal requirements and regulations',
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      _buildPrivacySection(
                        context,
                        'Data Protection',
                        [
                          '• All data is encrypted both in transit and at rest',
                          '• We use industry-standard security measures',
                          '• Regular security audits and updates',
                          '• Limited access to personal information',
                          '• Data retention only for as long as necessary',
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      _buildPrivacySection(
                        context,
                        'Your Rights',
                        [
                          '• Access your personal data at any time',
                          '• Request correction of inaccurate information',
                          '• Request deletion of your data',
                          '• Export your data in portable format',
                          '• Opt-out of marketing communications',
                        ],
                      ),
                      
                      const SizedBox(height: 25),
                      
                      // Contact
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
                                'If you have any questions about this Privacy Policy, please contact us:',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 15,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 15),
                              _buildContactInfo('Email:', 'privacy@excellencecoachinghub.com'),
                              const SizedBox(height: 10),
                              _buildContactInfo('Phone:', '+1 (555) 123-4567'),
                              const SizedBox(height: 10),
                              _buildContactInfo('Address:', '123 Education Street, Learning City'),
                            ],
                          ),
                        ),
                      ),
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
          ),
          const Text(
            'Privacy Policy',
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

  Widget _buildPrivacySection(BuildContext context, String title, List<String> items) {
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
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfo(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
