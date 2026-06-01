import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:excellencecoachinghub/widgets/network_image_widget.dart';
import 'package:excellencecoachinghub/presentation/providers/auth_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/user_profile_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/localization_provider.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/config/storage_manager.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';
import 'package:excellencecoachinghub/l10n/app_localizations.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isEditing = false;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  File? _imageFile;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final user = ref.read(authProvider.select((state) => state.user));
    if (user != null) {
      _nameController.text = user.fullName;
      _emailController.text = user.email;
      _phoneController.text = user.phone ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        _loadUserData();
        _imageFile = null;
      }
    });
  }

  Future<void> _pickImage() async {
    if (!_isEditing) return;
    
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n?.errorPickingImage ?? 'Error picking image'}: $e')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    try {
      await ref.read(authProvider.notifier).updateProfile(
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        imageFile: _imageFile,
      );

      if (mounted) {
        setState(() {
          _isEditing = false;
          _imageFile = null;
        });
        
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.profileUpdated ?? 'Profile updated'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n?.profileUpdateError ?? 'Error updating profile'}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final padding = ResponsiveBreakpoints.getPadding(context);

    return Scaffold(
      backgroundColor: Colors.transparent, 
      body: Stack(
        children: [
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth = isDesktop ? 1000.0 : double.infinity;
                final horizontalPadding = isDesktop ? (constraints.maxWidth - maxWidth) / 2 : 0.0;
                
                return Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          padding.left + horizontalPadding, 
                          padding.top, 
                          padding.right + horizontalPadding, 
                          padding.bottom * 1.5
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight - 100,
                            maxWidth: maxWidth,
                          ),
                          child: Column(
                            children: [
                              _buildHeader(user),
                              
                              const SizedBox(height: 30),
                              
                              _buildProfileCard(user),
                              
                              const SizedBox(height: 30),
                              
                              _buildStatsSection(),
                              
                              const SizedBox(height: 30),
                              
                              _buildActionButtons(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          if (authState.isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primaryGreen,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _isEditing ? FloatingActionButton.extended(
        onPressed: authState.isLoading ? null : _saveProfile,
        label: Text(authState.isLoading ? AppLocalizations.of(context)!.saving : AppLocalizations.of(context)!.saveChanges),
        icon: authState.isLoading 
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.check_rounded),
        backgroundColor: AppTheme.primaryGreen,
      ) : FloatingActionButton.extended(
        onPressed: _toggleEdit,
        label: Text(AppLocalizations.of(context)!.editProfile),
        icon: const Icon(Icons.edit_rounded),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }

  Widget _buildHeader(user) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final avatarSize = isDesktop ? 160.0 : 130.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: isDesktop ? 40 : 30, horizontal: isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Back Button Row
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/dashboard');
                }
              },
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.getBackgroundColor(context).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppTheme.getTextColor(context),
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _pickImage,
            child: Stack(
              children: [
                Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.primaryGreen.withOpacity(0.2),
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryGreen.withOpacity(0.1),
                        blurRadius: 15,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: _imageFile != null
                        ? Image.file(_imageFile!, fit: BoxFit.cover)
                        : user?.profilePicture != null && user!.profilePicture!.isNotEmpty
                            ? NetworkImageWidget(
                                imageUrl: user.profilePicture!,
                                fit: BoxFit.cover,
                                errorWidget: _buildInitialsAvatar(user, avatarSize),
                              )
                            : _buildInitialsAvatar(user, avatarSize),
                  ),
                ),
                if (_isEditing)
                  Positioned(
                    bottom: 5,
                    right: 5,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryGreen,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            user?.fullName ?? AppLocalizations.of(context)!.fullName,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isDesktop ? 32 : 26,
              fontWeight: FontWeight.w800,
              color: AppTheme.getTextColor(context),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            user?.email ?? AppLocalizations.of(context)!.email,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isDesktop ? 18 : 16,
              color: AppTheme.getSecondaryTextColor(context),
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_isEditing)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                AppLocalizations.of(context)!.tapToChangePhoto,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInitialsAvatar(user, double size) {
    return Container(
      color: AppTheme.primaryGreen.withOpacity(0.1),
      child: Center(
        child: Text(
          user?.fullName != null && user!.fullName.isNotEmpty 
              ? user!.fullName.substring(0, 1).toUpperCase() 
              : AppLocalizations.of(context)!.appName.substring(0,1),
          style: TextStyle(
            color: AppTheme.primaryGreen,
            fontSize: size * 0.4,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(user) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
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
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(width: 15),
              Text(
                AppLocalizations.of(context)!.profileInformation,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.getTextColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          _buildInfoField(
            label: AppLocalizations.of(context)!.fullName,
            controller: _nameController,
            hint: AppLocalizations.of(context)!.enterFullName,
            isEnabled: _isEditing,
            icon: Icons.person_rounded,
          ),
          const SizedBox(height: 20),
          _buildInfoField(
            label: AppLocalizations.of(context)!.emailAddress,
            controller: _emailController,
            hint: AppLocalizations.of(context)!.enterEmail,
            isEnabled: false,
            icon: Icons.email_rounded,
          ),
          const SizedBox(height: 20),
          _buildInfoField(
            label: AppLocalizations.of(context)!.phoneNumber,
            controller: _phoneController,
            hint: AppLocalizations.of(context)!.enterPhone,
            isEnabled: _isEditing,
            icon: Icons.phone_rounded,
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required bool isEnabled,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.getSecondaryTextColor(context),
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          enabled: isEnabled,
          keyboardType: keyboardType,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isEnabled ? AppTheme.getTextColor(context) : AppTheme.getSecondaryTextColor(context),
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20, color: isEnabled ? AppTheme.primaryGreen : AppTheme.getSecondaryTextColor(context)),
            filled: true,
            fillColor: isEnabled ? AppTheme.getBackgroundColor(context).withOpacity(0.5) : AppTheme.getBackgroundColor(context).withOpacity(0.2),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppTheme.primaryGreen.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    final stats = ref.watch(userProfileStatsSimpleProvider);
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Responsive grid columns based on screen width
    int crossAxisCount;
    if (screenWidth >= 1200) {
      crossAxisCount = 4;
    } else if (screenWidth >= 800) {
      crossAxisCount = 4;
    } else if (screenWidth >= 600) {
      crossAxisCount = 4;
    } else if (screenWidth >= 400) {
      crossAxisCount = 2;
    } else {
      crossAxisCount = 2;
    }
    
    // Calculate responsive child aspect ratio to prevent overflow
    // Lower ratio = taller cards = more vertical space for content
    final double childAspectRatio = screenWidth < 360 ? 0.9 : (screenWidth < 400 ? 0.95 : 1.0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10, bottom: 20),
          child: Text(
            AppLocalizations.of(context)!.yourProgress,
            style: TextStyle(
              fontSize: screenWidth < 360 ? 18 : 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.getTextColor(context),
              letterSpacing: -0.5,
            ),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: screenWidth < 360 ? 12 : 16,
              crossAxisSpacing: screenWidth < 360 ? 12 : 16,
              childAspectRatio: childAspectRatio,
              children: [
                _buildStatCard(AppLocalizations.of(context)!.enrolled, stats.enrolledCourses.toString(), Icons.book_rounded, Colors.blue, constraints),
                _buildStatCard(AppLocalizations.of(context)!.completed, stats.completedCourses.toString(), Icons.check_circle_rounded, Colors.green, constraints),
                _buildStatCard(AppLocalizations.of(context)!.certificates, stats.certificatesEarned.toString(), Icons.emoji_events_rounded, Colors.orange, constraints),
                _buildStatCard(AppLocalizations.of(context)!.quizzes, stats.quizzesTaken.toString(), Icons.quiz_rounded, Colors.purple, constraints),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, BoxConstraints constraints) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final isVerySmallScreen = screenWidth < 320;
    
    // Responsive sizing - ensure text fits within card
    final double iconSize = isVerySmallScreen ? 20 : (isSmallScreen ? 22 : 26);
    final double iconPadding = isVerySmallScreen ? 10 : (isSmallScreen ? 12 : 14);
    final double valueFontSize = isVerySmallScreen ? 20 : (isSmallScreen ? 24 : 28);
    final double titleFontSize = isVerySmallScreen ? 11 : (isSmallScreen ? 12 : 13);
    final double containerPadding = isVerySmallScreen ? 16 : (isSmallScreen ? 20 : 24);
    final double verticalSpacing = isVerySmallScreen ? 8 : (isSmallScreen ? 10 : 12);
    
    return Container(
      padding: EdgeInsets.all(containerPadding),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(isSmallScreen ? 20 : 28),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: isSmallScreen ? 10 : 15,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.1), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(iconPadding),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: iconSize),
          ),
          SizedBox(height: verticalSpacing),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: valueFontSize,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.getTextColor(context),
                ),
              ),
            ),
          ),
          SizedBox(height: isVerySmallScreen ? 4 : 6),
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.w600,
                color: AppTheme.getSecondaryTextColor(context),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final user = ref.read(authProvider).user;
    final hasCompletedOnboarding = user?.hasCompletedOnboarding ?? false;
    
    return Column(
      children: [
        _buildLanguageSwitcher(),
        const SizedBox(height: 15),
        _buildContactUsButton(),
        const SizedBox(height: 15),
        _buildActionButton(
          AppLocalizations.of(context)!.settings,
          Icons.settings_rounded,
          () => context.push('/settings'),
          Colors.blueGrey,
        ),
        if (hasCompletedOnboarding) ...[
          const SizedBox(height: 15),
          _buildActionButton(
            AppLocalizations.of(context)!.resetOnboarding,
            Icons.refresh_rounded,
            () => _showResetOnboardingDialog(),
            Colors.orange,
          ),
        ],
        const SizedBox(height: 15),
        _buildActionButton(
          AppLocalizations.of(context)!.logout,
          Icons.logout_rounded,
          () => _showLogoutDialog(),
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildActionButton(String title, IconData icon, VoidCallback onTap, Color color) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: AppTheme.getCardColor(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 15),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.getTextColor(context),
                ),
              ),
              const Spacer(),
              Icon(Icons.chevron_right_rounded, color: AppTheme.getSecondaryTextColor(context).withOpacity(0.5)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSwitcher() {
    return Consumer(
      builder: (context, ref, child) {
        final currentLocale = ref.watch(localeProvider);
        final currentLang = currentLocale.languageCode;
        
        return Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: AppTheme.getCardColor(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: PopupMenuButton<String>(
              child: Row(
                children: [
                  Icon(Icons.language_rounded, color: AppTheme.primaryGreen, size: 24),
                  const SizedBox(width: 15),
                  Text(
                    AppLocalizations.of(context)!.language,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.getTextColor(context),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currentLang == 'en' ? '🇬🇧' : '🇷🇼',
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: AppTheme.getSecondaryTextColor(context).withOpacity(0.5),
                      ),
                    ],
                  ),
                ],
              ),
              color: AppTheme.getCardColor(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (String languageCode) async {
                await ref.read(localeProvider.notifier).setLanguage(languageCode);
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem<String>(
                  value: 'en',
                  child: Row(
                    children: [
                      const Text('🇬🇧', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 12),
                      Text(
                        'English',
                        style: TextStyle(
                          color: AppTheme.getTextColor(context),
                          fontWeight: currentLang == 'en'
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      if (currentLang == 'en')
                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Icon(Icons.check, color: AppTheme.primaryGreen),
                        ),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'rw',
                  child: Row(
                    children: [
                      const Text('🇷🇼', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 12),
                      Text(
                        'Kinyarwanda',
                        style: TextStyle(
                          color: AppTheme.getTextColor(context),
                          fontWeight: currentLang == 'rw'
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      if (currentLang == 'rw')
                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Icon(Icons.check, color: AppTheme.primaryGreen),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContactUsButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showContactInfoDialog(context),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryGreen,
                AppTheme.primaryGreen.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryGreen.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.contact_support_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.contactUs,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Get help & support',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showContactInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.contact_support,
                  color: AppTheme.primaryGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)!.contactUs,
                style: TextStyle(
                  color: AppTheme.getTextColor(context),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildContactMethod(
                  context,
                  icon: Icons.message,
                  title: AppLocalizations.of(context)!.whatsapp,
                  subtitle: '+250 793 828 834',
                  onTap: () => _launchWhatsApp('250793828834'),
                ),
                const SizedBox(height: 8),
                _buildContactMethod(
                  context,
                  icon: Icons.message,
                  title: AppLocalizations.of(context)!.whatsapp,
                  subtitle: '+250 788 535 156',
                  onTap: () => _launchWhatsApp('250788535156'),
                ),
                const SizedBox(height: 16),
                _buildContactMethod(
                  context,
                  icon: Icons.phone,
                  title: AppLocalizations.of(context)!.callUs,
                  subtitle: '+250 788 535 156',
                  onTap: () => _launchPhone('250788535156'),
                ),
                const SizedBox(height: 8),
                _buildContactMethod(
                  context,
                  icon: Icons.phone,
                  title: AppLocalizations.of(context)!.callUs,
                  subtitle: '+250 793 828 834',
                  onTap: () => _launchPhone('250793828834'),
                ),
                const SizedBox(height: 8),
                _buildContactMethod(
                  context,
                  icon: Icons.phone,
                  title: AppLocalizations.of(context)!.callUs,
                  subtitle: '0781671517',
                  onTap: () => _launchPhone('0781671517'),
                ),
                const SizedBox(height: 16),
                _buildContactMethod(
                  context,
                  icon: Icons.email,
                  title: AppLocalizations.of(context)!.emailUs,
                  subtitle: 'info@excellencecoachinghub.com',
                  onTap: () => _launchEmail('info@excellencecoachinghub.com'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                AppLocalizations.of(context)!.close,
                style: TextStyle(
                  color: AppTheme.getSecondaryTextColor(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContactMethod(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark
              ? AppTheme.primaryGreen.withOpacity(0.1)
              : AppTheme.primaryGreen.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? AppTheme.primaryGreen.withOpacity(0.3)
                : AppTheme.primaryGreen.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: AppTheme.primaryGreen,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppTheme.getTextColor(context),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.getSecondaryTextColor(context),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppTheme.getSecondaryTextColor(context),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchWhatsApp(String phoneNumber) async {
    final Uri whatsappUri = Uri(
      scheme: 'https',
      host: 'api.whatsapp.com',
      path: 'send',
      queryParameters: {'phone': phoneNumber},
    );

    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else if (context.mounted) {
        _showWhatsAppFallbackDialog(context, phoneNumber);
      }
    } catch (_) {
      if (context.mounted) _showWhatsAppFallbackDialog(context, phoneNumber);
    }
  }

  void _showWhatsAppFallbackDialog(BuildContext context, String phoneNumber) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 10),
              Text('WhatsApp Not Available'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'WhatsApp is not installed or not accessible on this device.',
              ),
              const SizedBox(height: 16),
              const Text(
                'Alternative options:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildFallbackOption(
                context,
                icon: Icons.phone,
                title: 'Call Directly',
                subtitle: phoneNumber,
                onTap: () => _launchPhone(phoneNumber),
              ),
              const SizedBox(height: 8),
              _buildFallbackOption(
                context,
                icon: Icons.copy,
                title: 'Copy Number',
                subtitle: 'Copy to clipboard',
                onTap: () => _copyToClipboard(context, phoneNumber, 'Phone number'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _launchPhone(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else if (context.mounted) {
        _showPhoneFallbackDialog(context, phoneNumber);
      }
    } catch (_) {
      if (context.mounted) _showPhoneFallbackDialog(context, phoneNumber);
    }
  }

  void _showPhoneFallbackDialog(BuildContext context, String phoneNumber) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.phone_disabled, color: Colors.orange),
              SizedBox(width: 10),
              Text('Call Not Available'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Phone calls are not supported on this device.'),
              const SizedBox(height: 16),
              const Text(
                'Alternative options:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildFallbackOption(
                context,
                icon: Icons.copy,
                title: 'Copy Number',
                subtitle: 'Copy to clipboard',
                onTap: () => _copyToClipboard(context, phoneNumber, 'Phone number'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
    );
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch email client'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch email client'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildFallbackOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.getCardColor(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.getSecondaryTextColor(context).withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.getTextColor(context), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.getTextColor(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.getSecondaryTextColor(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copyToClipboard(
    BuildContext context,
    String text,
    String label,
  ) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$label copied to clipboard'),
          backgroundColor: AppTheme.primaryGreen,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.logOut),
        content: Text(AppLocalizations.of(context)!.areYouSureLogout),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
            },
            child: Text(AppLocalizations.of(context)!.logOut, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showResetOnboardingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.resetOnboarding),
        content: Text(AppLocalizations.of(context)!.resetOnboardingConfirm),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(authProvider.notifier).updateProfile(
                  hasCompletedOnboarding: false,
                  interests: null,
                  shortTermGoal: null,
                  midTermGoal: null,
                  longTermGoal: null,
                );
                // Clear local storage
                final storageManager = StorageManager();
                await storageManager.clearOnboarding();
                // Navigate to onboarding
                if (mounted) {
                  context.go('/interest-selection');
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${AppLocalizations.of(context)!.resetOnboardingFailed}: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text(AppLocalizations.of(context)!.reset, style: const TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }
}
