import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:excellence_coaching_hub/presentation/widgets/beautiful_widgets.dart';
import 'package:excellence_coaching_hub/config/app_theme.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        colors: AppTheme.primaryGradient,
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
                      // Help Overview
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
                                      Icons.help_outline,
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
                                          'Help Center',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 5),
                                        Text(
                                          'How can we help you today?',
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
                                'Find answers to common questions or get in touch with our support team.',
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
                      
                      // FAQ Categories
                      _buildFAQSection(
                        context,
                        'Getting Started',
                        [
                          {
                            'question': 'How do I create an account?',
                            'answer': 'Tap "Continue with Google" or "Continue with Email" on the welcome screen to create your account.'
                          },
                          {
                            'question': 'How do I enroll in a course?',
                            'answer': 'Browse courses from the dashboard or courses page, then tap "Enroll" on any course you\'re interested in.'
                          },
                          {
                            'question': 'Can I access courses offline?',
                            'answer': 'Yes, downloaded videos can be accessed offline. Look for the download icon on course content.'
                          },
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      _buildFAQSection(
                        context,
                        'Account Management',
                        [
                          {
                            'question': 'How do I change my password?',
                            'answer': 'Go to Settings > Password & Security to change your password.'
                          },
                          {
                            'question': 'How do I update my profile?',
                            'answer': 'Tap your profile picture on the dashboard and select "Edit Profile" to update your information.'
                          },
                          {
                            'question': 'How do I delete my account?',
                            'answer': 'Contact our support team at support@excellencecoachinghub.com to request account deletion.'
                          },
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      _buildFAQSection(
                        context,
                        'Technical Support',
                        [
                          {
                            'question': 'The app is crashing, what should I do?',
                            'answer': 'Try closing and reopening the app. If the problem persists, restart your device and reinstall the app.'
                          },
                          {
                            'question': 'Videos are not loading properly',
                            'answer': 'Check your internet connection. Try switching to a different network or clearing the app cache.'
                          },
                          {
                            'question': 'I\'m having payment issues',
                            'answer': 'Ensure your payment method is valid. If problems continue, contact our support team with details.'
                          },
                        ],
                      ),
                      
                      const SizedBox(height: 25),
                      
                      // Contact Support
                      GlassContainer(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Need More Help?',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 15),
                              const Text(
                                'Our support team is here to help you 24/7:',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 15,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 20),
                              _buildContactOption(
                                context,
                                icon: Icons.email_outlined,
                                title: 'Email Support',
                                subtitle: 'support@excellencecoachinghub.com',
                                onTap: () {
                                  // In a real app, this would open email client
                                },
                              ),
                              const SizedBox(height: 15),
                              _buildContactOption(
                                context,
                                icon: Icons.chat_outlined,
                                title: 'Live Chat',
                                subtitle: 'Chat with our support team now',
                                onTap: () {
                                  // In a real app, this would open chat
                                },
                              ),
                              const SizedBox(height: 15),
                              _buildContactOption(
                                context,
                                icon: Icons.phone_outlined,
                                title: 'Phone Support',
                                subtitle: '+1 (555) 123-4567',
                                onTap: () {
                                  // In a real app, this would initiate call
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 25),
                      
                      // Emergency Contact
                      GlassContainer(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Emergency Contact',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 15),
                              const Text(
                                'For urgent matters outside business hours:',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 15,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 15),
                              _buildContactInfo('24/7 Emergency Line:', '+1 (555) 999-0000'),
                              const SizedBox(height: 10),
                              _buildContactInfo('Critical Issues:', 'emergency@excellencecoachinghub.com'),
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
            'Help & Support',
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

  Widget _buildFAQSection(BuildContext context, String title, List<Map<String, String>> faqs) {
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
            ...faqs.map((faq) => _buildFAQItem(context, faq['question']!, faq['answer']!)),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(BuildContext context, String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      iconColor: Colors.white,
      collapsedIconColor: Colors.white70,
      textColor: Colors.white,
      collapsedTextColor: Colors.white,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            answer,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Function onTap,
  }) {
    return InkWell(
      onTap: () => onTap(),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white70, size: 24),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white54,
              size: 16,
            ),
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
          width: 150,
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