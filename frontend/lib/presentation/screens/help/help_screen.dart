import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/l10n/app_localizations.dart';

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

  /// Slightly stronger brand tints in dark mode - the same alpha that reads as a
  /// soft wash on a white surface all but disappears on a near-black one.
  static double _tintOpacity(BuildContext context, double light, double dark) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppTheme.getTextColor(context);
    final textSecondary = AppTheme.getSecondaryTextColor(context);

    return Scaffold(
      // Was transparent, which let the black void behind the route show through
      // and left light-mode content sitting on a dark backdrop.
      backgroundColor: AppTheme.getBackgroundColor(context),
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
                          color: AppTheme.primary.withOpacity(_tintOpacity(context, 0.08, 0.14)),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.primary.withOpacity(_tintOpacity(context, 0.2, 0.32)),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.help_outline, color: Colors.white, size: 26),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(AppLocalizations.of(context)!.helpCenter,
                                      style: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 4),
                                  Text(AppLocalizations.of(context)!.helpCenterSubtitle,
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
                        AppLocalizations.of(context)!.gettingStarted,
                        [
                          {
                            'question': AppLocalizations.of(context)!.howToCreateAccount,
                            'answer': AppLocalizations.of(context)!.createAccountAnswer
                          },
                          {
                            'question': AppLocalizations.of(context)!.howToEnroll,
                            'answer': AppLocalizations.of(context)!.enrollAnswer
                          },
                          {
                            'question': AppLocalizations.of(context)!.howToAccessOffline,
                            'answer': AppLocalizations.of(context)!.offlineAnswer
                          },
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      _buildFAQSection(
                        context,
                        AppLocalizations.of(context)!.accountManagement,
                        [
                          {
                            'question': AppLocalizations.of(context)!.howToChangePassword,
                            'answer': AppLocalizations.of(context)!.changePasswordAnswer
                          },
                          {
                            'question': AppLocalizations.of(context)!.howToUpdateProfile,
                            'answer': AppLocalizations.of(context)!.updateProfileAnswer
                          },
                          {
                            'question': AppLocalizations.of(context)!.howToDeleteAccount,
                            'answer': AppLocalizations.of(context)!.deleteAccountAnswer
                          },
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      _buildFAQSection(
                        context,
                        AppLocalizations.of(context)!.technicalSupport,
                        [
                          {
                            'question': AppLocalizations.of(context)!.appCrashing,
                            'answer': AppLocalizations.of(context)!.crashingAnswer
                          },
                          {
                            'question': AppLocalizations.of(context)!.videosNotLoading,
                            'answer': AppLocalizations.of(context)!.videosAnswer
                          },
                          {
                            'question': AppLocalizations.of(context)!.paymentIssues,
                            'answer': AppLocalizations.of(context)!.paymentAnswer
                          },
                        ],
                      ),
                      
                      const SizedBox(height: 25),
                      
                      // Contact Support
                      _buildCard(
                        context,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.needMoreHelp,
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                AppLocalizations.of(context)!.support24_7,
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
                                title: AppLocalizations.of(context)!.emailSupport,
                                subtitle: 'info@excellencecoachinghub.com',
                                onTap: () => _launchEmail('info@excellencecoachinghub.com'),
                              ),
                              const SizedBox(height: 15),
                              _buildContactOption(
                                context,
                                icon: Icons.chat_outlined,
                                title: 'WhatsApp',
                                subtitle: AppLocalizations.of(context)!.chatWithUs,
                                onTap: () => _launchWhatsApp('250788535156'),
                              ),
                              const SizedBox(height: 15),
                              _buildContactOption(
                                context,
                                icon: Icons.phone_outlined,
                                title: AppLocalizations.of(context)!.phoneSupport,
                                subtitle: '+250 788 535 156',
                                onTap: () => _launchPhone('250788535156'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 25),
                      
                      // Alternative Contact
                      _buildCard(
                        context,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.alternativeContact,
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                AppLocalizations.of(context)!.support24_7,
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 15),
                              _buildContactInfo(context, AppLocalizations.of(context)!.secondaryLine, '+250 793 828 834'),
                              const SizedBox(height: 10),
                              _buildContactInfo(context, AppLocalizations.of(context)!.website, 'excellencecoachinghub.com'),
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
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.helpAndSupport,
              style: TextStyle(
                color: textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// One card treatment for the whole page. Dark mode leans on an outline
  /// instead of a shadow, which is invisible against a near-black background.
  Widget _buildCard(BuildContext context, {required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: EdgeInsets.zero,
      color: AppTheme.getCardColor(context),
      elevation: isDark ? 0 : 3,
      shadowColor: Colors.black.withOpacity(0.08),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppTheme.getBorderColor(context).withOpacity(isDark ? 0.6 : 0.7),
        ),
      ),
      child: child,
    );
  }

  Widget _buildFAQSection(BuildContext context, String title, List<Map<String, String>> faqs) {
    final textPrimary = AppTheme.getTextColor(context);
    return _buildCard(
      context,
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
            const SizedBox(height: 4),
            ...faqs.asMap().entries.map((entry) {
              final faq = entry.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (entry.key > 0)
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: AppTheme.getBorderColor(context).withOpacity(0.4),
                    ),
                  _buildFAQItem(context, faq['question']!, faq['answer']!),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(BuildContext context, String question, String answer) {
    final textPrimary = AppTheme.getTextColor(context);
    final textSecondary = AppTheme.getSecondaryTextColor(context);
    return ExpansionTile(
      // The card already draws the outline; the tile's own default borders would
      // double it up once expanded.
      shape: const Border(),
      collapsedShape: const Border(),
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      expansionAnimationStyle: AnimationStyle(curve: Curves.easeOutCubic),
      backgroundColor: Colors.transparent,
      collapsedBackgroundColor: Colors.transparent,
      title: Text(
        question,
        style: TextStyle(
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      iconColor: AppTheme.primary,
      collapsedIconColor: textSecondary,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
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
                color: AppTheme.primary.withOpacity(_tintOpacity(context, 0.1, 0.18)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTheme.primary, size: 22),
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
