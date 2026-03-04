import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_theme.dart';
import '../../../models/platform_settings.dart';
import '../../providers/platform_settings_provider.dart';

class AdminPaymentSettingsScreen extends ConsumerStatefulWidget {
  const AdminPaymentSettingsScreen({super.key});

  @override
  ConsumerState<AdminPaymentSettingsScreen> createState() => _AdminPaymentSettingsScreenState();
}

class _AdminPaymentSettingsScreenState extends ConsumerState<AdminPaymentSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // MTN Momo
  late TextEditingController _mtnAccountName;
  late TextEditingController _mtnAccountNumber;
  late TextEditingController _mtnMerchantCode;
  bool _mtnEnabled = true;

  // Airtel Money
  late TextEditingController _airtelAccountName;
  late TextEditingController _airtelAccountNumber;
  late TextEditingController _airtelMerchantCode;
  bool _airtelEnabled = true;

  // Bank Transfer
  late TextEditingController _bankName;
  late TextEditingController _bankAccountName;
  late TextEditingController _bankAccountNumber;
  late TextEditingController _bankSwiftCode;
  bool _bankEnabled = true;

  // Contact Support
  late TextEditingController _supportPhone;
  late TextEditingController _supportEmail;
  late TextEditingController _supportWhatsapp;

  bool _initialized = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _mtnAccountName = TextEditingController();
    _mtnAccountNumber = TextEditingController();
    _mtnMerchantCode = TextEditingController();
    _airtelAccountName = TextEditingController();
    _airtelAccountNumber = TextEditingController();
    _airtelMerchantCode = TextEditingController();
    _bankName = TextEditingController();
    _bankAccountName = TextEditingController();
    _bankAccountNumber = TextEditingController();
    _bankSwiftCode = TextEditingController();
    _supportPhone = TextEditingController();
    _supportEmail = TextEditingController();
    _supportWhatsapp = TextEditingController();
  }

  @override
  void dispose() {
    _mtnAccountName.dispose();
    _mtnAccountNumber.dispose();
    _mtnMerchantCode.dispose();
    _airtelAccountName.dispose();
    _airtelAccountNumber.dispose();
    _airtelMerchantCode.dispose();
    _bankName.dispose();
    _bankAccountName.dispose();
    _bankAccountNumber.dispose();
    _bankSwiftCode.dispose();
    _supportPhone.dispose();
    _supportEmail.dispose();
    _supportWhatsapp.dispose();
    super.dispose();
  }

  void _initializeControllers(PlatformSettings settings) {
    if (_initialized) return;
    
    final p = settings.paymentInfo;
    
    _mtnAccountName.text = p.mtnMomo.accountName;
    _mtnAccountNumber.text = p.mtnMomo.accountNumber;
    _mtnMerchantCode.text = p.mtnMomo.merchantCode;
    _mtnEnabled = p.mtnMomo.enabled;

    _airtelAccountName.text = p.airtelMoney.accountName;
    _airtelAccountNumber.text = p.airtelMoney.accountNumber;
    _airtelMerchantCode.text = p.airtelMoney.merchantCode;
    _airtelEnabled = p.airtelMoney.enabled;

    _bankName.text = p.bankTransfer.bankName;
    _bankAccountName.text = p.bankTransfer.accountName;
    _bankAccountNumber.text = p.bankTransfer.accountNumber;
    _bankSwiftCode.text = p.bankTransfer.swiftCode;
    _bankEnabled = p.bankTransfer.enabled;

    _supportPhone.text = p.contactSupport.phone;
    _supportEmail.text = p.contactSupport.email;
    _supportWhatsapp.text = p.contactSupport.whatsapp;

    _initialized = true;
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final paymentInfo = PaymentInfo(
      mtnMomo: MobilePaymentInfo(
        accountName: _mtnAccountName.text,
        accountNumber: _mtnAccountNumber.text,
        merchantCode: _mtnMerchantCode.text,
        enabled: _mtnEnabled,
      ),
      airtelMoney: MobilePaymentInfo(
        accountName: _airtelAccountName.text,
        accountNumber: _airtelAccountNumber.text,
        merchantCode: _airtelMerchantCode.text,
        enabled: _airtelEnabled,
      ),
      bankTransfer: BankTransferInfo(
        bankName: _bankName.text,
        accountName: _bankAccountName.text,
        accountNumber: _bankAccountNumber.text,
        swiftCode: _bankSwiftCode.text,
        enabled: _bankEnabled,
      ),
      contactSupport: ContactSupport(
        phone: _supportPhone.text,
        email: _supportEmail.text,
        whatsapp: _supportWhatsapp.text,
      ),
    );

    final success = await ref.read(platformSettingsProvider.notifier).updatePaymentInfo(paymentInfo);

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Payment settings saved successfully' : 'Failed to save settings'),
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
        title: const Text('Payment Configuration'),
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
                  _buildHeader('Configure payment methods and support details for students.'),
                  const SizedBox(height: 30),
                  
                  _buildPaymentSection(
                    title: 'MTN MoMo',
                    icon: Icons.account_balance_wallet,
                    enabled: _mtnEnabled,
                    onEnabledChanged: (v) => setState(() => _mtnEnabled = v),
                    children: [
                      _buildTextField(_mtnAccountName, 'Account Name'),
                      _buildTextField(_mtnAccountNumber, 'Account Number'),
                      _buildTextField(_mtnMerchantCode, 'Merchant Code (Optional)'),
                    ],
                  ),
                  
                  const SizedBox(height: 25),
                  
                  _buildPaymentSection(
                    title: 'Airtel Money',
                    icon: Icons.account_balance_wallet,
                    enabled: _airtelEnabled,
                    onEnabledChanged: (v) => setState(() => _airtelEnabled = v),
                    children: [
                      _buildTextField(_airtelAccountName, 'Account Name'),
                      _buildTextField(_airtelAccountNumber, 'Account Number'),
                      _buildTextField(_airtelMerchantCode, 'Merchant Code (Optional)'),
                    ],
                  ),
                  
                  const SizedBox(height: 25),
                  
                  _buildPaymentSection(
                    title: 'Bank Transfer',
                    icon: Icons.account_balance,
                    enabled: _bankEnabled,
                    onEnabledChanged: (v) => setState(() => _bankEnabled = v),
                    children: [
                      _buildTextField(_bankName, 'Bank Name'),
                      _buildTextField(_bankAccountName, 'Account Name'),
                      _buildTextField(_bankAccountNumber, 'Account Number'),
                      _buildTextField(_bankSwiftCode, 'SWIFT/IFSC Code'),
                    ],
                  ),
                  
                  const SizedBox(height: 25),
                  
                  _buildSimpleSection(
                    title: 'Contact Support',
                    icon: Icons.support_agent,
                    children: [
                      _buildTextField(_supportPhone, 'Support Phone'),
                      _buildTextField(_supportEmail, 'Support Email'),
                      _buildTextField(_supportWhatsapp, 'WhatsApp Number'),
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
          'Payment Settings',
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

  Widget _buildPaymentSection({
    required String title,
    required IconData icon,
    required bool enabled,
    required Function(bool) onEnabledChanged,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: AppTheme.primaryGreen),
                  const SizedBox(width: 10),
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              Switch(
                value: enabled,
                onChanged: onEnabledChanged,
                activeColor: AppTheme.primaryGreen,
              ),
            ],
          ),
          if (enabled) ...[
            const Divider(height: 30),
            ...children,
          ],
        ],
      ),
    );
  }

  Widget _buildSimpleSection({
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

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            if (label.contains('Optional')) return null;
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }
}
