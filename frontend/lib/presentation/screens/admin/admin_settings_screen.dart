import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  // Settings state
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _pushNotifications = false;
  String _selectedTheme = 'Light';
  String _selectedLanguage = 'English';
  bool _autoSyncEnabled = true;
  int _autoSyncInterval = 30; // minutes

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Settings'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Platform Configuration',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.blackColor,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Manage your admin panel preferences and platform settings',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.greyColor,
              ),
            ),
            const SizedBox(height: 30),
            
            // Notifications Section
            _buildSection(
              title: 'Notifications',
              icon: Icons.notifications,
              children: [
                _buildToggleSetting(
                  title: 'Enable Notifications',
                  subtitle: 'Receive important platform updates',
                  value: _notificationsEnabled,
                  onChanged: (value) => setState(() => _notificationsEnabled = value),
                ),
                const SizedBox(height: 15),
                _buildToggleSetting(
                  title: 'Email Notifications',
                  subtitle: 'Send notifications via email',
                  value: _emailNotifications,
                  onChanged: (value) => setState(() => _emailNotifications = value),
                ),
                const SizedBox(height: 15),
                _buildToggleSetting(
                  title: 'Push Notifications',
                  subtitle: 'Show push notifications on device',
                  value: _pushNotifications,
                  onChanged: (value) => setState(() => _pushNotifications = value),
                ),
              ],
            ),
            
            const SizedBox(height: 30),
            
            // Appearance Section
            _buildSection(
              title: 'Appearance',
              icon: Icons.brush,
              children: [
                _buildDropdownSetting(
                  title: 'Theme',
                  subtitle: 'Choose your preferred theme',
                  value: _selectedTheme,
                  items: ['Light', 'Dark', 'System'],
                  onChanged: (value) => setState(() => _selectedTheme = value!),
                ),
                const SizedBox(height: 15),
                _buildDropdownSetting(
                  title: 'Language',
                  subtitle: 'Select display language',
                  value: _selectedLanguage,
                  items: ['English', 'Kinyarwanda', 'French'],
                  onChanged: (value) => setState(() => _selectedLanguage = value!),
                ),
              ],
            ),
            
            const SizedBox(height: 30),
            
            // Data Management Section
            _buildSection(
              title: 'Data Management',
              icon: Icons.data_usage,
              children: [
                _buildToggleSetting(
                  title: 'Auto Sync',
                  subtitle: 'Automatically sync data with backend',
                  value: _autoSyncEnabled,
                  onChanged: (value) => setState(() => _autoSyncEnabled = value),
                ),
                const SizedBox(height: 15),
                _buildSliderSetting(
                  title: 'Sync Interval',
                  subtitle: 'Minutes between auto-sync operations',
                  value: _autoSyncInterval.toDouble(),
                  min: 5,
                  max: 120,
                  divisions: 23,
                  onChanged: (value) => setState(() => _autoSyncInterval = value.toInt()),
                ),
              ],
            ),
            
            const SizedBox(height: 30),
            
            // Platform Settings Section
            _buildSection(
              title: 'Platform Settings',
              icon: Icons.settings_applications,
              children: [
                _buildSettingTile(
                  title: 'Payment Configuration',
                  subtitle: 'Configure payment gateways and methods',
                  icon: Icons.payment,
                  onTap: () {
                    // TODO: Navigate to payment settings
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Payment settings coming soon')),
                    );
                  },
                ),
                const SizedBox(height: 15),
                _buildSettingTile(
                  title: 'User Management',
                  subtitle: 'Configure user roles and permissions',
                  icon: Icons.people,
                  onTap: () {
                    // TODO: Navigate to user management settings
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User management settings coming soon')),
                    );
                  },
                ),
                const SizedBox(height: 15),
                _buildSettingTile(
                  title: 'Content Moderation',
                  subtitle: 'Set content review and approval policies',
                  icon: Icons.security,
                  onTap: () {
                    // TODO: Navigate to content moderation settings
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Content moderation settings coming soon')),
                    );
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 30),
            
            // Danger Zone Section
            _buildSection(
              title: 'Danger Zone',
              icon: Icons.warning_amber,
              backgroundColor: Colors.red[50],
              borderColor: Colors.red[200],
              children: [
                _buildDangerTile(
                  title: 'Reset All Data',
                  subtitle: 'Permanently delete all platform data',
                  icon: Icons.delete_forever,
                  onTap: _confirmDataReset,
                ),
                const SizedBox(height: 15),
                _buildDangerTile(
                  title: 'Restore Default Settings',
                  subtitle: 'Reset all settings to factory defaults',
                  icon: Icons.restore,
                  onTap: _confirmSettingsReset,
                ),
              ],
            ),
            
            const SizedBox(height: 30),
            
            // Save Button
            Center(
              child: ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save Settings',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
    Color? backgroundColor,
    Color? borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: borderColor ?? Colors.grey.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.primaryGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 15),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.blackColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildToggleSetting({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.blackColor,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.greyColor,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppTheme.primaryGreen,
        ),
      ],
    );
  }

  Widget _buildDropdownSetting({
    required String title,
    required String subtitle,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.blackColor,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.greyColor,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down),
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSliderSetting({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required Function(double) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.blackColor,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.greyColor,
          ),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: value,
                min: min,
                max: max,
                divisions: divisions,
                activeColor: AppTheme.primaryGreen,
                inactiveColor: Colors.grey.withOpacity(0.3),
                onChanged: onChanged,
              ),
            ),
            const SizedBox(width: 15),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${value.toInt()} min',
                style: TextStyle(
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Function() onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: AppTheme.accent,
                size: 24,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.blackColor,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.greyColor,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppTheme.greyColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Function() onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  void _saveSettings() {
    // TODO: Save settings to backend
    // final settings = {
    //   'notifications': {
    //     'enabled': _notificationsEnabled,
    //     'email': _emailNotifications,
    //     'push': _pushNotifications,
    //   },
    //   'appearance': {
    //     'theme': _selectedTheme,
    //     'language': _selectedLanguage,
    //   },
    //   'dataManagement': {
    //     'autoSync': _autoSyncEnabled,
    //     'syncInterval': _autoSyncInterval,
    //   }
    // };
    // 
    // // Save to backend API
    // // await apiService.saveAdminSettings(settings);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _confirmDataReset() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset All Data'),
          content: const Text(
            'Are you sure you want to reset all data? This action cannot be undone and will permanently delete all courses, students, payments, and platform data.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: Implement data reset
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Data reset functionality coming soon'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              child: const Text(
                'RESET DATA',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _confirmSettingsReset() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Restore Default Settings'),
          content: const Text(
            'Are you sure you want to restore all settings to their default values?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Reset all settings to defaults
                setState(() {
                  _notificationsEnabled = true;
                  _emailNotifications = true;
                  _pushNotifications = false;
                  _selectedTheme = 'Light';
                  _selectedLanguage = 'English';
                  _autoSyncEnabled = true;
                  _autoSyncInterval = 30;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Settings restored to defaults'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text(
                'RESTORE',
                style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}