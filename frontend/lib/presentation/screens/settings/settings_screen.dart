import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';
import 'package:excellencecoachinghub/presentation/providers/auth_provider.dart';

// Providers for settings
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);
final notificationsProvider = StateProvider<bool>((ref) => true);
final darkModeProvider = StateProvider<bool>((ref) => false);

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

// Device binding policy widget for settings screen
class _SettingsDeviceBindingPolicy extends StatelessWidget {
  const _SettingsDeviceBindingPolicy();
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0), // Light orange background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFFB74D), // Orange border
          width: 1,
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.security,
            color: Color(0xFFF57C00), // Orange icon
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Device Security: Your account is permanently bound to your first login device. To use a different device, please contact our support team.',
              style: TextStyle(
                color: Color(0xFF333333), // Dark text for visibility
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(darkModeProvider);
    final notificationsEnabled = ref.watch(notificationsProvider);
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final padding = ResponsiveBreakpoints.getPadding(context);
    // Watch theme mode to trigger rebuilds
    ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: Colors.transparent, // Let MainLayout background show through
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = isDesktop ? 800.0 : double.infinity;
            final horizontalPadding = isDesktop ? (constraints.maxWidth - maxWidth) / 2 : 0.0;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                padding.left + horizontalPadding, 
                padding.top, 
                padding.right + horizontalPadding, 
                padding.bottom * 1.5
              ),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Device Security Policy
                  const _SettingsDeviceBindingPolicy(),
                  const SizedBox(height: 25),
                  
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
                        onTap: () => context.push('/terms'),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Danger Zone
                  _buildDangerZone(context),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
              ? Colors.black.withOpacity(0.2)
              : AppTheme.greyColor.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: isDarkMode
            ? AppTheme.greyColor.withOpacity(0.1)
            : AppTheme.greyColor.withOpacity(0.12),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
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
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 14),
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTap(),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryGreen.withOpacity(0.12),
                      AppTheme.primaryGreen.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    width: 0.5,
                  ),
                ),
                child: Icon(icon, 
                  color: AppTheme.primaryGreen,
                  size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isDarkMode 
                          ? AppTheme.whiteColor 
                          : AppTheme.blackColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppTheme.getSecondaryTextColor(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.primaryGreen.withOpacity(0.5),
                size: 14,
              ),
            ],
          ),
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryGreen.withOpacity(0.12),
                  AppTheme.primaryGreen.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                width: 0.5,
              ),
            ),
            child: Icon(icon, 
              color: AppTheme.primaryGreen,
              size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isDarkMode 
                      ? AppTheme.whiteColor 
                      : AppTheme.blackColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppTheme.getSecondaryTextColor(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryGreen,
            inactiveTrackColor: Colors.grey.withOpacity(0.3),
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryGreen.withOpacity(0.12),
                  AppTheme.primaryGreen.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                width: 0.5,
              ),
            ),
            child: Icon(icon, 
              color: AppTheme.primaryGreen,
              size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isDarkMode 
                      ? AppTheme.whiteColor 
                      : AppTheme.blackColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppTheme.getSecondaryTextColor(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryGreen,
            inactiveTrackColor: Colors.grey.withOpacity(0.3),
          ),
        ],
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
    bool isUpdating = false;
    String? localError;
    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
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
                height: localError != null ? 360 : 320,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (localError != null)
                        Container(
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            localError!,
                            style: const TextStyle(color: Colors.red, fontSize: 13),
                          ),
                        ),
                      TextField(
                        controller: oldPasswordController,
                        obscureText: obscureOld,
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
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureOld ? Icons.visibility_off : Icons.visibility,
                              color: AppTheme.primaryGreen,
                              size: 20,
                            ),
                            onPressed: () => setDialogState(() => obscureOld = !obscureOld),
                          ),
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
                        obscureText: obscureNew,
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
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureNew ? Icons.visibility_off : Icons.visibility,
                              color: AppTheme.primaryGreen,
                              size: 20,
                            ),
                            onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                          ),
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
                        obscureText: obscureConfirm,
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
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureConfirm ? Icons.visibility_off : Icons.visibility,
                              color: AppTheme.primaryGreen,
                              size: 20,
                            ),
                            onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                          ),
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
              ),
              actions: [
                TextButton(
                  onPressed: isUpdating ? null : () {
                    if (context.canPop()) context.pop();
                  },
                  child: Text('Cancel', 
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark 
                        ? AppTheme.white70 
                        : AppTheme.greyColor)),
                ),
                TextButton(
                  onPressed: isUpdating ? null : () async {
                    final current = oldPasswordController.text.trim();
                    final newPass = newPasswordController.text.trim();
                    final confirm = confirmController.text.trim();

                    if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
                      setDialogState(() => localError = 'Please fill in all fields');
                      return;
                    }

                    if (newPass.length < 6) {
                      setDialogState(() => localError = 'New password must be at least 6 characters');
                      return;
                    }

                    if (newPass != confirm) {
                      setDialogState(() => localError = 'Passwords do not match');
                      return;
                    }

                    setDialogState(() {
                      isUpdating = true;
                      localError = null;
                    });

                    try {
                      await ref.read(authProvider.notifier).updatePassword(current, newPass);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        _showSnackbar(context, 'Password changed successfully');
                      }
                    } catch (e) {
                      if (context.mounted) {
                        setDialogState(() {
                          isUpdating = false;
                          localError = e.toString().replaceFirst('Exception: ', '');
                        });
                      }
                    }
                  },
                  child: isUpdating 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Change', style: TextStyle(color: AppTheme.primaryGreen)),
                ),
              ],
            );
          },
        );
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
              onPressed: () {
                if (context.canPop()) context.pop();
              },
              child: Text('Cancel', 
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark 
                    ? AppTheme.white70 
                    : AppTheme.greyColor)),
            ),
            TextButton(
              onPressed: () {
                if (context.canPop()) context.pop();
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
          content: const SizedBox(
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
              onPressed: () {
                if (context.canPop()) context.pop();
              },
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
    final passwordController = TextEditingController();
    bool isDeleting = false;
    String? localError;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).brightness == Brightness.dark 
                ? const Color(0xFF1E1E1E) 
                : AppTheme.whiteColor,
              title: const Text('Delete Account', 
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Are you sure you want to permanently delete your account? '
                    'This action cannot be undone and all your data will be lost.',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark 
                        ? AppTheme.white70 
                        : AppTheme.greyColor),
                  ),
                  const SizedBox(height: 20),
                  if (localError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        localError!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  Text(
                    'Please enter your password to confirm:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).brightness == Brightness.dark 
                        ? AppTheme.whiteColor 
                        : AppTheme.blackColor),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark 
                        ? AppTheme.whiteColor 
                        : AppTheme.blackColor),
                    decoration: InputDecoration(
                      hintText: 'Current Password',
                      hintStyle: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark 
                          ? AppTheme.white60 
                          : AppTheme.greyColor),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Theme.of(context).brightness == Brightness.dark 
                            ? AppTheme.white60 
                            : AppTheme.greyColor.withOpacity(0.5)),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting ? null : () {
                    if (context.canPop()) context.pop();
                  },
                  child: Text('Cancel', 
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark 
                        ? AppTheme.white70 
                        : AppTheme.greyColor)),
                ),
                TextButton(
                  onPressed: isDeleting ? null : () async {
                    final password = passwordController.text.trim();
                    if (password.isEmpty) {
                      setDialogState(() => localError = 'Password is required');
                      return;
                    }

                    setDialogState(() {
                      isDeleting = true;
                      localError = null;
                    });

                    try {
                      await ref.read(authProvider.notifier).deleteAccount(password);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        context.go('/splash');
                        _showSnackbar(context, 'Account deleted successfully');
                      }
                    } catch (e) {
                      if (context.mounted) {
                        setDialogState(() {
                          isDeleting = false;
                          localError = e.toString().replaceFirst('Exception: ', '');
                        });
                      }
                    }
                  },
                  child: isDeleting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red))
                    : const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
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
              onPressed: () {
                if (context.canPop()) context.pop();
              },
              child: Text('Cancel', 
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark 
                    ? AppTheme.white70 
                    : AppTheme.greyColor)),
            ),
            TextButton(
              onPressed: () {
                if (context.canPop()) context.pop();
                ref.read(authProvider.notifier).logout();
                context.go('/login');
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
