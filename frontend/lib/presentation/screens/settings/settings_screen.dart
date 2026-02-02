import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellence_coaching_hub/config/app_theme.dart';

// Providers for settings
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);
final notificationsProvider = StateProvider<bool>((ref) => true);
final darkModeProvider = StateProvider<bool>((ref) => false);

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(darkModeProvider);
    final notificationsEnabled = ref.watch(notificationsProvider);
    // Watch theme mode to trigger rebuilds
    ref.watch(themeModeProvider);

    return Scaffold(
      body: Container(
        color: isDarkMode ? const Color(0xFF121212) : AppTheme.whiteColor,
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(context),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  physics: const BouncingScrollPhysics(), // Better scroll physics
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Account Settings
                      _buildSection(
                        context,
                        'Account Settings',
                        [
                          _buildSettingTile(
                            context,
                            icon: Icons.person_outline,
                            title: 'Profile Information',
                            subtitle: 'Update your personal details',
                            onTap: () => context.push('/profile'),
                          ),
                          _buildSettingTile(
                            context,
                            icon: Icons.lock_outline,
                            title: 'Password & Security',
                            subtitle: 'Change password and security settings',
                            onTap: () => _showPasswordChangeDialog(context),
                          ),
                          _buildNotificationTile(
                            context,
                            icon: Icons.notifications_outlined,
                            title: 'Push Notifications',
                            subtitle: 'Receive important updates and reminders',
                            value: notificationsEnabled,
                            onChanged: (value) {
                              ref.read(notificationsProvider.notifier).state = value;
                              _showSnackbar(context, 
                                value ? 'Notifications enabled' : 'Notifications disabled');
                            },
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 25),
                      
                      // Preferences
                      _buildSection(
                        context,
                        'Preferences',
                        [
                          _buildLanguageTile(context),
                          _buildThemeTile(
                            context,
                            icon: Icons.dark_mode_outlined,
                            title: 'Dark Mode',
                            subtitle: isDarkMode ? 'Dark theme enabled' : 'Light theme enabled',
                            value: isDarkMode,
                            onChanged: (value) {
                              ref.read(darkModeProvider.notifier).state = value;
                              ref.read(themeModeProvider.notifier).state = 
                                value ? ThemeMode.dark : ThemeMode.light;
                              _showSnackbar(context, 
                                value ? 'Dark mode enabled' : 'Light mode enabled');
                            },
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 25),
                      
                      // Support
                      _buildSection(
                        context,
                        'Support',
                        [
                          _buildSettingTile(
                            context,
                            icon: Icons.help_outline,
                            title: 'Help Center',
                            subtitle: 'Get help with using the app',
                            onTap: () => context.push('/help'),
                          ),
                          _buildSettingTile(
                            context,
                            icon: Icons.feedback_outlined,
                            title: 'Send Feedback',
                            subtitle: 'Share your thoughts with us',
                            onTap: () => _showFeedbackDialog(context),
                          ),
                          _buildSettingTile(
                            context,
                            icon: Icons.info_outline,
                            title: 'About',
                            subtitle: 'App version and information',
                            onTap: () => _showAboutDialog(context),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 25),
                      
                      // Legal
                      _buildSection(
                        context,
                        'Legal',
                        [
                          _buildSettingTile(
                            context,
                            icon: Icons.privacy_tip_outlined,
                            title: 'Privacy Policy',
                            subtitle: 'Read our privacy policy',
                            onTap: () => context.push('/privacy'),
                          ),
                          _buildSettingTile(
                            context,
                            icon: Icons.description_outlined,
                            title: 'Terms of Service',
                            subtitle: 'Read our terms and conditions',
                            onTap: () => _showTermsDialog(context),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Danger Zone
                      _buildDangerZone(context),
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
            icon: Icon(Icons.arrow_back, 
              color: Theme.of(context).brightness == Brightness.dark 
                ? AppTheme.whiteColor 
                : AppTheme.blackColor, 
              size: 28),
          ),
          Text(
            'Settings',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark 
                ? AppTheme.whiteColor 
                : AppTheme.blackColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
          ? const Color(0xFF1E1E1E) 
          : AppTheme.whiteColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.greyColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: AppTheme.greyColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark 
                  ? AppTheme.whiteColor 
                  : AppTheme.blackColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            Column(
              children: children,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile(
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
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.greyColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, 
                color: Theme.of(context).brightness == Brightness.dark 
                  ? AppTheme.whiteColor 
                  : AppTheme.greyColor, 
                size: 24),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark 
                        ? AppTheme.whiteColor 
                        : AppTheme.blackColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppTheme.greyColor,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppTheme.greyColor,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.greyColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, 
              color: Theme.of(context).brightness == Brightness.dark 
                ? AppTheme.whiteColor 
                : AppTheme.greyColor, 
              size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark 
                      ? AppTheme.whiteColor 
                      : AppTheme.blackColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTheme.greyColor,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryGreen,
            inactiveThumbColor: Colors.grey[400],
            inactiveTrackColor: Colors.grey[600],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.greyColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, 
              color: Theme.of(context).brightness == Brightness.dark 
                ? AppTheme.whiteColor 
                : AppTheme.greyColor, 
              size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark 
                      ? AppTheme.whiteColor 
                      : AppTheme.blackColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTheme.greyColor,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryGreen,
            inactiveThumbColor: Colors.grey[400],
            inactiveTrackColor: Colors.grey[600],
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageTile(BuildContext context) {
    return InkWell(
      onTap: () => _showLanguagePicker(context),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.greyColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.language_outlined, 
                color: AppTheme.greyColor, 
                size: 24),
            ),
            const SizedBox(width: 15),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Language',
                    style: TextStyle(
                      color: AppTheme.blackColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'English (US)',
                    style: TextStyle(
                      color: AppTheme.greyColor,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppTheme.greyColor,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerZone(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
          ? const Color(0xFF1E1E1E) 
          : AppTheme.whiteColor,
        border: Border.all(color: Colors.red.withOpacity(0.3), width: 1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Danger Zone',
              style: TextStyle(
                color: Colors.red,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            _buildDangerButton(
              context,
              icon: Icons.delete_outline,
              title: 'Delete Account',
              subtitle: 'Permanently delete your account and all data',
              color: Colors.red,
              onTap: () => _showDeleteAccountDialog(context),
            ),
            const SizedBox(height: 10),
            _buildDangerButton(
              context,
              icon: Icons.logout,
              title: 'Sign Out',
              subtitle: 'Sign out from all devices',
              color: Colors.orange,
              onTap: () => _showSignOutDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
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
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: color.withOpacity(0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color.withOpacity(0.7),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // Dialog methods
  void _showPasswordChangeDialog(BuildContext context) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF1E1E1E) 
            : AppTheme.whiteColor,
          title: Text(
            'Change Password',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark 
                ? AppTheme.whiteColor 
                : AppTheme.blackColor),
          ),
          content: SizedBox(
            height: 300, // Fixed height to prevent overflow
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: oldPasswordController,
                  obscureText: true,
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark 
                      ? AppTheme.whiteColor 
                      : AppTheme.blackColor),
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    labelStyle: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark 
                        ? AppTheme.white70 
                        : AppTheme.greyColor),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).brightness == Brightness.dark 
                          ? AppTheme.white60 
                          : AppTheme.greyColor.withOpacity(0.5)),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.primaryGreen),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark 
                      ? AppTheme.whiteColor 
                      : AppTheme.blackColor),
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    labelStyle: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark 
                        ? AppTheme.white70 
                        : AppTheme.greyColor),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).brightness == Brightness.dark 
                          ? AppTheme.white60 
                          : AppTheme.greyColor.withOpacity(0.5)),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.primaryGreen),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: confirmController,
                  obscureText: true,
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark 
                      ? AppTheme.whiteColor 
                      : AppTheme.blackColor),
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    labelStyle: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark 
                        ? AppTheme.white70 
                        : AppTheme.greyColor),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).brightness == Brightness.dark 
                          ? AppTheme.white60 
                          : AppTheme.greyColor.withOpacity(0.5)),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.primaryGreen),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', 
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark 
                    ? AppTheme.white70 
                    : AppTheme.greyColor)),
            ),
            TextButton(
              onPressed: () {
                if (newPasswordController.text == confirmController.text && 
                    newPasswordController.text.length >= 6) {
                  Navigator.of(context).pop();
                  _showSnackbar(context, 'Password changed successfully');
                } else {
                  _showSnackbar(context, 'Passwords do not match or too short');
                }
              },
              child: const Text('Change', 
                style: TextStyle(color: AppTheme.primaryGreen)),
            ),
          ],
        );
      },
    );
  }

  void _showLanguagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
        ? const Color(0xFF1E1E1E) 
        : AppTheme.whiteColor,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Language',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark 
                    ? AppTheme.whiteColor 
                    : AppTheme.blackColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Flexible( // Wrap the content in Flexible to prevent overflow
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    _buildLanguageOption(context, 'English (US)', true),
                    _buildLanguageOption(context, 'Spanish', false),
                    _buildLanguageOption(context, 'French', false),
                    _buildLanguageOption(context, 'German', false),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(BuildContext context, String language, bool isSelected) {
    return ListTile(
      title: Text(
        language,
        style: TextStyle(
          color: isSelected 
            ? AppTheme.primaryGreen 
            : (Theme.of(context).brightness == Brightness.dark 
                ? AppTheme.whiteColor 
                : AppTheme.blackColor),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected 
          ? const Icon(Icons.check, color: AppTheme.primaryGreen)
          : null,
      onTap: () {
        if (!isSelected) {
          Navigator.of(context).pop();
          _showSnackbar(context, 'Language changed to $language');
        }
      },
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    final feedbackController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF1E1E1E) 
            : AppTheme.whiteColor,
          title: Text('Send Feedback', 
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark 
                ? AppTheme.whiteColor 
                : AppTheme.blackColor)),
          content: SizedBox(
            height: 150, // Set a fixed height to prevent overflow
            child: TextField(
              controller: feedbackController,
              maxLines: 4,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark 
                  ? AppTheme.whiteColor 
                  : AppTheme.blackColor),
              decoration: InputDecoration(
                hintText: 'Tell us how we can improve...',
                hintStyle: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark 
                    ? AppTheme.white60 
                    : AppTheme.greyColor),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', 
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark 
                    ? AppTheme.white70 
                    : AppTheme.greyColor)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showSnackbar(context, 'Thank you for your feedback!');
              },
              child: const Text('Send', 
                style: TextStyle(color: AppTheme.primaryGreen)),
            ),
          ],
        );
      },
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Excellence Coaching Hub',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2026 Excellence Coaching Hub',
      children: [
        Flexible(
          child: Text(
            'A premium learning platform for continuous education and skill development.',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark 
                ? AppTheme.white70 
                : AppTheme.greyColor),
          ),
        ),
      ],
    );
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF1E1E1E) 
            : AppTheme.whiteColor,
          title: Text('Terms of Service', 
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark 
                ? AppTheme.whiteColor 
                : AppTheme.blackColor)),
          content: SizedBox(
            height: 200, // Set fixed height to prevent overflow
            child: SingleChildScrollView(
              child: Text(
                'By using this application, you agree to our terms of service...\n\n'
                '• You must be at least 13 years old\n'
                '• Content is for educational purposes only\n'
                '• Payments are non-refundable after 7 days\n'
                '• We reserve the right to terminate accounts\n\n'
                'Last updated: February 1, 2026',
                style: TextStyle(color: AppTheme.greyColor),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close', 
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark 
                    ? AppTheme.white70 
                    : AppTheme.greyColor)),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF1E1E1E) 
            : AppTheme.whiteColor,
          title: const Text('Delete Account', 
            style: TextStyle(color: Colors.red)),
          content: Text(
            'Are you sure you want to permanently delete your account? '
            'This action cannot be undone and all your data will be lost.',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark 
                ? AppTheme.white70 
                : AppTheme.greyColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', 
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark 
                    ? AppTheme.white70 
                    : AppTheme.greyColor)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showSnackbar(context, 'Account scheduled for deletion');
              },
              child: const Text('Delete', 
                style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF1E1E1E) 
            : AppTheme.whiteColor,
          title: Text('Sign Out', 
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark 
                ? AppTheme.whiteColor 
                : AppTheme.blackColor)),
          content: Text(
            'Are you sure you want to sign out?',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark 
                ? AppTheme.white70 
                : AppTheme.greyColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', 
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark 
                    ? AppTheme.white70 
                    : AppTheme.greyColor)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/auth-selection');
                _showSnackbar(context, 'Signed out successfully');
              },
              child: const Text('Sign Out', 
                style: TextStyle(color: Colors.orange)),
            ),
          ],
        );
      },
    );
  }

  void _showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.primaryGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}