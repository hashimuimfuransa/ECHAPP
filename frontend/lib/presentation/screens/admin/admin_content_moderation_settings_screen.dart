import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/app_theme.dart';
import '../../../models/platform_settings.dart';
import '../../providers/platform_settings_provider.dart';

class AdminContentModerationSettingsScreen extends ConsumerStatefulWidget {
  const AdminContentModerationSettingsScreen({super.key});

  @override
  ConsumerState<AdminContentModerationSettingsScreen> createState() => _AdminContentModerationSettingsScreenState();
}

class _AdminContentModerationSettingsScreenState extends ConsumerState<AdminContentModerationSettingsScreen> {
  bool _requireManualCourseApproval = true;
  bool _autoFilterSpam = true;
  bool _allowCommentsOnCourses = true;
  bool _isInitialized = false;

  void _initialize(PlatformSettings settings) {
    if (_isInitialized) return;
    _requireManualCourseApproval = settings.contentModeration.requireManualCourseApproval;
    _autoFilterSpam = settings.contentModeration.autoFilterSpam;
    _allowCommentsOnCourses = settings.contentModeration.allowCommentsOnCourses;
    _isInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(platformSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Content Moderation'),
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
                  'Content Policies',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.blackColor),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Manage content quality and moderation across the platform.',
                  style: TextStyle(fontSize: 16, color: AppTheme.greyColor),
                ),
                const SizedBox(height: 30),
                
                _buildSection(
                  title: 'Course Moderation',
                  icon: Icons.book_outlined,
                  children: [
                    _buildToggleSetting(
                      title: 'Manual Course Approval',
                      subtitle: 'Newly created courses must be approved before publishing',
                      value: _requireManualCourseApproval,
                      onChanged: (v) => setState(() => _requireManualCourseApproval = v),
                    ),
                    const SizedBox(height: 20),
                    _buildToggleSetting(
                      title: 'Auto-filter Spam Content',
                      subtitle: 'Use AI to detect and filter low-quality content',
                      value: _autoFilterSpam,
                      onChanged: (v) => setState(() => _autoFilterSpam = v),
                    ),
                  ],
                ),
                
                const SizedBox(height: 25),
                
                _buildSection(
                  title: 'Interaction Policies',
                  icon: Icons.forum_outlined,
                  children: [
                    _buildToggleSetting(
                      title: 'Enable Course Comments',
                      subtitle: 'Students can comment on courses and lessons',
                      value: _allowCommentsOnCourses,
                      onChanged: (v) => setState(() => _allowCommentsOnCourses = v),
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
    final newContentModeration = ContentModerationSettings(
      requireManualCourseApproval: _requireManualCourseApproval,
      autoFilterSpam: _autoFilterSpam,
      allowCommentsOnCourses: _allowCommentsOnCourses,
    );

    final success = await ref.read(platformSettingsProvider.notifier).updateContentModerationSettings(newContentModeration);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Content moderation settings saved' : 'Failed to save settings'),
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
}
