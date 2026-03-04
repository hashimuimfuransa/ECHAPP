import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/app_theme.dart';
import '../../../models/platform_settings.dart';
import '../../providers/platform_settings_provider.dart';

class AdminGeneralSettingsScreen extends ConsumerStatefulWidget {
  const AdminGeneralSettingsScreen({super.key});

  @override
  ConsumerState<AdminGeneralSettingsScreen> createState() => _AdminGeneralSettingsScreenState();
}

class _AdminGeneralSettingsScreenState extends ConsumerState<AdminGeneralSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _platformName;
  late TextEditingController _platformDescription;
  late TextEditingController _contactEmail;
  late TextEditingController _contactPhone;

  bool _initialized = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _platformName = TextEditingController();
    _platformDescription = TextEditingController();
    _contactEmail = TextEditingController();
    _contactPhone = TextEditingController();
  }

  @override
  void dispose() {
    _platformName.dispose();
    _platformDescription.dispose();
    _contactEmail.dispose();
    _contactPhone.dispose();
    super.dispose();
  }

  void _initializeControllers(PlatformSettings settings) {
    if (_initialized) return;
    
    final p = settings.platformInfo;
    
    _platformName.text = p.name;
    _platformDescription.text = p.description;
    _contactEmail.text = p.contactEmail;
    _contactPhone.text = p.contactPhone;

    _initialized = true;
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final platformInfo = PlatformInfo(
      name: _platformName.text,
      description: _platformDescription.text,
      contactEmail: _contactEmail.text,
      contactPhone: _contactPhone.text,
    );

    final success = await ref.read(platformSettingsProvider.notifier).updatePlatformInfo(platformInfo);

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Platform settings saved successfully' : 'Failed to save settings'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(platformSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('General Settings'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: settingsAsync.when(
        data: (settings) {
          _initializeControllers(settings);
          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader('Configure general platform information and contact details.'),
                  const SizedBox(height: 30),
                  
                  _buildSection(
                    title: 'Platform Information',
                    icon: Icons.info_outline,
                    children: [
                      _buildTextField(_platformName, 'Platform Name'),
                      _buildTextField(_platformDescription, 'Platform Description', maxLines: 3),
                    ],
                  ),
                  
                  const SizedBox(height: 25),
                  
                  _buildSection(
                    title: 'Contact Details',
                    icon: Icons.contact_mail_outlined,
                    children: [
                      _buildTextField(_contactEmail, 'Contact Email'),
                      _buildTextField(_contactPhone, 'Contact Phone'),
                    ],
                  ),
                  
                  const SizedBox(height: 40),
                  
                  Center(
                    child: SizedBox(
                      width: 200,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveSettings,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSaving 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildHeader(String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'General Platform Settings',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.blackColor),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 16, color: AppTheme.greyColor),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
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

  Widget _buildTextField(TextEditingController controller, String label, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }
}
