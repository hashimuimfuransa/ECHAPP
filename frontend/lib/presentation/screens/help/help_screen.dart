import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

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

  Future<void> _launchWhatsApp(String phone) async {
    final String url = "https://wa.me/$phone";
    final Uri whatsappUri = Uri.parse(url);
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppTheme.getTextColor(context);
    final textSecondary = AppTheme.getSecondaryTextColor(context);
    final cardColor = AppTheme.getCardColor(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Help Overview
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.help_outline, color: Colors.white, size: 26),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Help Center',
                                      style: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 4),
                                  Text('Find answers or contact our support team.',
                                      style: TextStyle(color: textSecondary, fontSize: 13, height: 1.4)),
                                ],
                              ),
                            ),
                          ],
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
                            'answer': 'Contact our support team at info@excellencecoachinghub.com to request account deletion.'
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
                      Card(
                        margin: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Need More Help?',
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Our support team is here to help you 24/7:',
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 20),
                              _buildContactOption(
                                context,
                                icon: Icons.email_outlined,
                                title: 'Email Support',
                                subtitle: 'info@excellencecoachinghub.com',
                                onTap: () => _launchEmail('info@excellencecoachinghub.com'),
                              ),
                              const SizedBox(height: 15),
                              _buildContactOption(
                                context,
                                icon: Icons.chat_outlined,
                                title: 'WhatsApp Chat',
                                subtitle: 'Chat with our support team now',
                                onTap: () => _launchWhatsApp('250788535156'),
                              ),
                              const SizedBox(height: 15),
                              _buildContactOption(
                                context,
                                icon: Icons.phone_outlined,
                                title: 'Phone Support',
                                subtitle: '+250 788 535 156',
                                onTap: () => _launchPhone('250788535156'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 25),
                      
                      // Alternative Contact
                      Card(
                        margin: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Alternative Contact',
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'You can also reach us through our secondary line:',
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 15),
                              _buildContactInfo(context, 'Secondary Line:', '+250 793 828 834'),
                              const SizedBox(height: 10),
                              _buildContactInfo(context, 'Website:', 'excellencecoachinghub.com'),
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
    );
  }

  Widget _buildHeader(BuildContext context) {
    final textPrimary = AppTheme.getTextColor(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 20, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: Icon(Icons.arrow_back_ios_rounded, color: textPrimary, size: 20),
          ),
          Text(
            'Help & Support',
            style: TextStyle(
              color: textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQSection(BuildContext context, String title, List<Map<String, String>> faqs) {
    final textPrimary = AppTheme.getTextColor(context);
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            ...faqs.map((faq) => _buildFAQItem(context, faq['question']!, faq['answer']!)),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(BuildContext context, String question, String answer) {
    final textPrimary = AppTheme.getTextColor(context);
    final textSecondary = AppTheme.getSecondaryTextColor(context);
    return ExpansionTile(
      title: Text(
        question,
        style: TextStyle(
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      iconColor: const Color(0xFF10B981),
      collapsedIconColor: textSecondary,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            answer,
            style: TextStyle(
              color: textSecondary,
              fontSize: 13,
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
    final textPrimary = AppTheme.getTextColor(context);
    final textSecondary = AppTheme.getSecondaryTextColor(context);
    return InkWell(
      onTap: () => onTap(),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF10B981), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(color: textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(color: textSecondary, fontSize: 13)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: textSecondary, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfo(BuildContext context, String label, String value) {
    final textPrimary = AppTheme.getTextColor(context);
    final textSecondary = AppTheme.getSecondaryTextColor(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(label,
              style: TextStyle(color: textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: Text(value,
              style: TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}
