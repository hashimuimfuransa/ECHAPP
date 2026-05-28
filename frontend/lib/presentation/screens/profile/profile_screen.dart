import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/widgets/network_image_widget.dart';
import 'package:excellencecoachinghub/presentation/providers/auth_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/user_profile_provider.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/config/storage_manager.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
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
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
        label: Text(authState.isLoading ? 'Saving...' : 'Save Changes'),
        icon: authState.isLoading 
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.check_rounded),
        backgroundColor: AppTheme.primaryGreen,
      ) : FloatingActionButton.extended(
        onPressed: _toggleEdit,
        label: const Text('Edit Profile'),
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
            user?.fullName ?? 'User Name',
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
            user?.email ?? 'email@example.com',
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
                'Tap photo to change',
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
              : 'U',
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
                'Profile Information',
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
            label: 'Full Name',
            controller: _nameController,
            hint: 'Enter your full name',
            isEnabled: _isEditing,
            icon: Icons.person_rounded,
          ),
          const SizedBox(height: 20),
          _buildInfoField(
            label: 'Email Address',
            controller: _emailController,
            hint: 'email@example.com',
            isEnabled: false,
            icon: Icons.email_rounded,
          ),
          const SizedBox(height: 20),
          _buildInfoField(
            label: 'Phone Number',
            controller: _phoneController,
            hint: 'Enter your phone number',
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
            'Your Progress',
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
                _buildStatCard('Enrolled', stats.enrolledCourses.toString(), Icons.book_rounded, Colors.blue, constraints),
                _buildStatCard('Completed', stats.completedCourses.toString(), Icons.check_circle_rounded, Colors.green, constraints),
                _buildStatCard('Certificates', stats.certificatesEarned.toString(), Icons.emoji_events_rounded, Colors.orange, constraints),
                _buildStatCard('Quizzes', stats.quizzesTaken.toString(), Icons.quiz_rounded, Colors.purple, constraints),
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
        _buildActionButton(
          'Settings',
          Icons.settings_rounded,
          () => context.push('/settings'),
          Colors.blueGrey,
        ),
        if (hasCompletedOnboarding) ...[
          const SizedBox(height: 15),
          _buildActionButton(
            'Reset Onboarding',
            Icons.refresh_rounded,
            () => _showResetOnboardingDialog(),
            Colors.orange,
          ),
        ],
        const SizedBox(height: 15),
        _buildActionButton(
          'Log Out',
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

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
            },
            child: const Text('Log Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showResetOnboardingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Onboarding'),
        content: const Text('This will reset your onboarding status and you will need to complete it again. Do you want to continue?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
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
                      content: Text('Failed to reset onboarding: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Reset', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }
}
