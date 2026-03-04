import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/app_theme.dart';
import '../../../models/platform_settings.dart';
import '../../providers/platform_settings_provider.dart';

class AdminUserManagementSettingsScreen extends ConsumerStatefulWidget {
  const AdminUserManagementSettingsScreen({super.key});

  @override
  ConsumerState<AdminUserManagementSettingsScreen> createState() => _AdminUserManagementSettingsScreenState();
}

class _AdminUserManagementSettingsScreenState extends ConsumerState<AdminUserManagementSettingsScreen> {
  bool _allowRegistration = true;
  bool _requireEmailVerification = true;
  String _defaultUserRole = 'Student';
  bool _isInitialized = false;

  void _initialize(PlatformSettings settings) {
    if (_isInitialized) return;
    _allowRegistration = settings.userManagement.allowRegistration;
    _requireEmailVerification = settings.userManagement.requireEmailVerification;
    _defaultUserRole = settings.userManagement.defaultUserRole;
    _isInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(platformSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management Settings'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: settingsAsync.when(
        data: (settings) {
          _initialize(settings);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'User Access & Roles',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.blackColor),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Configure how users interact with the platform and their default permissions.',
                  style: TextStyle(fontSize: 16, color: AppTheme.greyColor),
                ),
                const SizedBox(height: 30),
                
                _buildSection(
                  title: 'Registration Settings',
                  icon: Icons.person_add_outlined,
                  children: [
                    _buildToggleSetting(
                      title: 'Allow New Registrations',
                      subtitle: 'Users can create new accounts',
                      value: _allowRegistration,
                      onChanged: (v) => setState(() => _allowRegistration = v),
                    ),
                    const SizedBox(height: 20),
                    _buildToggleSetting(
                      title: 'Require Email Verification',
                      subtitle: 'New users must verify their email',
                      value: _requireEmailVerification,
                      onChanged: (v) => setState(() => _requireEmailVerification = v),
                    ),
                  ],
                ),
                
                const SizedBox(height: 25),
                
                _buildSection(
                  title: 'Role Settings',
                  icon: Icons.admin_panel_settings_outlined,
                  children: [
                    _buildDropdownSetting(
                      title: 'Default User Role',
                      subtitle: 'Role assigned to new users',
                      value: _defaultUserRole,
                      items: ['Student', 'Instructor'],
                      onChanged: (v) => setState(() => _defaultUserRole = v!),
                    ),
                  ],
                ),
                
                const SizedBox(height: 40),
                Center(
                  child: ElevatedButton(
                    onPressed: _saveSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  void _saveSettings() async {
    final newUserManagement = UserManagementSettings(
      allowRegistration: _allowRegistration,
      requireEmailVerification: _requireEmailVerification,
      defaultUserRole: _defaultUserRole,
    );

    final success = await ref.read(platformSettingsProvider.notifier).updateUserManagementSettings(newUserManagement);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'User management settings saved' : 'Failed to save settings'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Widget _buildSection({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 5, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primaryGreen),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(height: 30),
          ...children,
        ],
      ),
    );
  }

  Widget _buildToggleSetting({required String title, required String subtitle, required bool value, required Function(bool) onChanged}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(subtitle, style: const TextStyle(color: AppTheme.greyColor, fontSize: 12)),
          ]),
        ),
        Switch(value: value, onChanged: onChanged, activeColor: AppTheme.primaryGreen),
      ],
    );
  }

  Widget _buildDropdownSetting({required String title, required String subtitle, required String value, required List<String> items, required Function(String?) onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(subtitle, style: const TextStyle(color: AppTheme.greyColor, fontSize: 12)),
        const SizedBox(height: 10),
        DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
