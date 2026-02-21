import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/presentation/providers/auth_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/user_profile_provider.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
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

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
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
    });
  }

  void _saveProfile() {
    // In a real app, you would save to backend
    setState(() {
      _isEditing = false;
    });
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile updated successfully!'),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final isTablet = ResponsiveBreakpoints.isTablet(context);
    final padding = ResponsiveBreakpoints.getPadding(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: Theme.of(context).brightness == Brightness.dark
                ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                : [const Color(0xFFF8FAFC), const Color(0xFFF0F9FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = isDesktop ? 1000.0 : double.infinity;
              final horizontalPadding = isDesktop ? (constraints.maxWidth - maxWidth) / 2 : 0.0;
              
              return Column(
                children: [
                  _buildEnhancedHeader(context),
                  
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
                            _buildEnhancedProfilePicture(user),
                            
                            SizedBox(height: isDesktop ? 40 : 30),
                            
                            _buildEnhancedProfileInfo(user),
                            
                            SizedBox(height: isDesktop ? 40 : 30),
                            
                            _buildStatsSection(),
                            
                            SizedBox(height: isDesktop ? 40 : 30),
                            
                            _buildEnhancedActionButtons(),
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
      ),
    );
  }

  Widget _buildEnhancedHeader(BuildContext context) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final padding = isDesktop ? 24.0 : 16.0;
    final fontSize = isDesktop ? 26.0 : 22.0;
    
    return Container(
      margin: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context).withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(padding * 0.6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: () {
                  final user = ref.read(authProvider).user;
                  if (user?.role == 'admin') {
                    context.go('/admin');
                  } else {
                    context.go('/dashboard');
                  }
                },
                icon: Icon(Icons.arrow_back_rounded, 
                  color: AppTheme.primaryGreen, 
                  size: 24),
              ),
            ),
            Text(
              'My Profile',
              style: TextStyle(
                color: AppTheme.getTextColor(context),
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: _toggleEdit,
                icon: Icon(
                  _isEditing ? Icons.close_rounded : Icons.edit_rounded,
                  color: AppTheme.primaryGreen,
                  size: 24,
                ),
              ),
            ),
          ],
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
              color: Theme.of(context).iconTheme.color, 
              size: 28),
          ),
          Text(
            'My Profile',
            style: TextStyle(
              color: Theme.of(context).textTheme.headlineSmall?.color,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            onPressed: _toggleEdit,
            icon: Icon(
              _isEditing ? Icons.close : Icons.edit_outlined,
              color: AppTheme.getTextColor(context),
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedProfilePicture(user) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final avatarSize = isDesktop ? 140.0 : 120.0;
    final nameFontSize = isDesktop ? 28.0 : 24.0;
    final emailFontSize = isDesktop ? 18.0 : 16.0;
    
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 40 : 25),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryGreen.withOpacity(0.8),
                        AppTheme.primaryGreen,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(avatarSize / 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryGreen.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      user?.fullName.substring(0, 1).toUpperCase() ?? 'U',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: avatarSize * 0.35,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (_isEditing)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryGreen.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: isDesktop ? 28 : 20),
            Text(
              user?.fullName ?? 'User Name',
              style: TextStyle(
                color: AppTheme.getTextColor(context),
                fontSize: nameFontSize,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              user?.email ?? 'user@example.com',
              style: TextStyle(
                color: AppTheme.getSecondaryTextColor(context),
                fontSize: emailFontSize,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_isEditing)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Tap to change photo',
                    style: TextStyle(
                      color: AppTheme.primaryGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePicture(user) {
    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
              child: Text(
                user?.fullName.substring(0, 1).toUpperCase() ?? 'U',
                style: const TextStyle(
                  color: AppTheme.primaryGreen,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (_isEditing)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    color: AppTheme.whiteColor,
                    size: 20,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 15),
        if (_isEditing)
          const Text(
            'Tap to change photo',
            style: TextStyle(
              color: AppTheme.greyColor,
              fontSize: 14,
            ),
          ),
      ],
    );
  }

  Widget _buildEnhancedProfileInfo(user) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final padding = isDesktop ? 32.0 : 25.0;
    final titleFontSize = isDesktop ? 24.0 : 22.0;
    final spacing = isDesktop ? 28.0 : 20.0;
    
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Information',
              style: TextStyle(
                color: AppTheme.getTextColor(context),
                fontSize: titleFontSize,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
            SizedBox(height: spacing),
            
            _buildEnhancedInfoField(
              label: 'Full Name',
              controller: _nameController,
              icon: Icons.person_rounded,
              isEditable: _isEditing,
            ),
            
            SizedBox(height: spacing),
            
            _buildEnhancedInfoField(
              label: 'Email Address',
              controller: _emailController,
              icon: Icons.email_rounded,
              isEditable: false,
            ),
            
            SizedBox(height: spacing),
            
            _buildEnhancedInfoField(
              label: 'Phone Number',
              controller: _phoneController,
              icon: Icons.phone_rounded,
              isEditable: _isEditing,
            ),
            
            SizedBox(height: spacing),
            
            _buildEnhancedInfoField(
              label: 'Member Since',
              controller: TextEditingController(
                text: user?.createdAt != null 
                  ? '${user!.createdAt.month}/${user.createdAt.year}' 
                  : 'Unknown'
              ),
              icon: Icons.calendar_today_rounded,
              isEditable: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedInfoField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool isEditable,
  }) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final padding = isDesktop ? 20.0 : 16.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.getSecondaryTextColor(context),
            fontSize: isDesktop ? 15 : 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: isDesktop ? 12 : 10),
        if (isEditable)
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).inputDecorationTheme.fillColor ?? 
                      AppTheme.greyColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Theme.of(context).dividerColor.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: TextField(
              controller: controller,
              style: TextStyle(
                color: AppTheme.getTextColor(context),
                fontSize: isDesktop ? 17 : 16,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                prefixIcon: Icon(
                  icon, 
                  color: AppTheme.primaryGreen.withOpacity(0.6), 
                  size: 22
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: padding, 
                  vertical: isDesktop ? 18 : 16
                ),
                hintText: 'Enter $label',
                hintStyle: TextStyle(
                  color: AppTheme.getSecondaryTextColor(context).withOpacity(0.5),
                  fontSize: 14,
                ),
              ),
              onTap: () {
                // Add visual feedback on focus
              },
            ),
          )
        else
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: padding, 
              vertical: isDesktop ? 18 : 16
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).inputDecorationTheme.fillColor ?? 
                      AppTheme.greyColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Theme.of(context).dividerColor.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon, 
                  color: AppTheme.primaryGreen.withOpacity(0.6), 
                  size: 22
                ),
                SizedBox(width: isDesktop ? 16 : 12),
                Expanded(
                  child: Text(
                    controller.text,
                    style: TextStyle(
                      color: AppTheme.getTextColor(context),
                      fontSize: isDesktop ? 17 : 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildProfileInfo(user) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Information',
              style: TextStyle(
                color: AppTheme.getTextColor(context),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // Name Field
            _buildInfoField(
              label: 'Full Name',
              controller: _nameController,
              icon: Icons.person_outline,
              isEditable: _isEditing,
            ),
            
            const SizedBox(height: 15),
            
            // Email Field
            _buildInfoField(
              label: 'Email',
              controller: _emailController,
              icon: Icons.email_outlined,
              isEditable: false, // Email usually not editable
            ),
            
            const SizedBox(height: 15),
            
            // Phone Field
            _buildInfoField(
              label: 'Phone',
              controller: _phoneController,
              icon: Icons.phone_outlined,
              isEditable: _isEditing,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool isEditable,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.greyColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        if (isEditable)
          TextField(
            controller: controller,
            style: const TextStyle(color: AppTheme.blackColor),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppTheme.greyColor),
              filled: true,
              fillColor: AppTheme.greyColor.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppTheme.greyColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppTheme.primaryGreen,
                  width: 2,
                ),
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.greyColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.greyColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppTheme.greyColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    controller.text,
                    style: TextStyle(
                      color: AppTheme.getTextColor(context),
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStatsSection() {
    final userProfileStatsAsync = ref.watch(userProfileStatsProvider);
    
    return userProfileStatsAsync.when(
      data: (stats) {
        final statData = [
          {
            'title': 'Courses Enrolled', 
            'value': stats.enrolledCourses.toString(), 
            'icon': Icons.school_outlined, 
            'color': AppTheme.primaryGreen
          },
          {
            'title': 'Certificates', 
            'value': stats.certificatesEarned.toString(), 
            'icon': Icons.verified_outlined, 
            'color': const Color(0xFF00cdac)
          },
          {
            'title': 'Hours Learned', 
            'value': stats.totalStudyHours.toString(), 
            'icon': Icons.access_time_outlined, 
            'color': const Color(0xFFfa709a)
          },
          {
            'title': 'Completed', 
            'value': stats.completedCourses.toString(), 
            'icon': Icons.check_circle_outline, 
            'color': const Color(0xFFf093fb)
          },
        ];

        final isDesktop = ResponsiveBreakpoints.isDesktop(context);
        final isTablet = ResponsiveBreakpoints.isTablet(context);
        final gridCount = isDesktop ? 4 : (isTablet ? 3 : 2);
        final spacing = isDesktop ? 20.0 : 15.0;
        final padding = isDesktop ? 32.0 : 20.0;
        
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.getCardColor(context),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Learning Statistics',
                  style: TextStyle(
                    color: AppTheme.getTextColor(context),
                    fontSize: isDesktop ? 24 : 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: spacing),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: gridCount,
                    crossAxisSpacing: spacing,
                    mainAxisSpacing: spacing,
                    childAspectRatio: isDesktop ? 1.0 : 1.3,
                  ),
                  itemCount: statData.length,
                  itemBuilder: (context, index) {
                    final stat = statData[index];
                    final color = stat['color'] as Color;
                    
                    return Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).inputDecorationTheme.fillColor ?? 
                                AppTheme.greyColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).dividerColor.withOpacity(0.1),
                          width: 1.5,
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(isDesktop ? 16 : 12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.all(isDesktop ? 12 : 10),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                stat['icon'] as IconData,
                                color: color,
                                size: isDesktop ? 28 : 24,
                              ),
                            ),
                            SizedBox(height: isDesktop ? 12 : 8),
                            Text(
                              stat['value'] as String,
                              style: TextStyle(
                                color: AppTheme.getTextColor(context),
                                fontSize: isDesktop ? 22 : 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: isDesktop ? 6 : 4),
                            Text(
                              stat['title'] as String,
                              style: TextStyle(
                                color: AppTheme.getSecondaryTextColor(context),
                                fontSize: isDesktop ? 13 : 12,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
      loading: () => Container(
        height: 200,
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Container(
        height: 200,
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            'Error loading stats: $error',
            style: TextStyle(color: AppTheme.getErrorColor(context)),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedActionButtons() {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final buttonHeight = isDesktop ? 56.0 : 54.0;
    final spacing = isDesktop ? 32.0 : 25.0;
    final padding = isDesktop ? 24.0 : 15.0;
    
    return Column(
      children: [
        if (_isEditing)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryGreen,
                  AppTheme.primaryGreen.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGreen.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: buttonHeight,
              child: ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Save Changes',
                  style: TextStyle(
                    fontSize: isDesktop ? 18 : 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ),
        SizedBox(height: spacing),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.getCardColor(context),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              children: [
                _buildEnhancedActionButton(
                  icon: Icons.settings_rounded,
                  title: 'Account Settings',
                  subtitle: 'Manage your account preferences',
                  onTap: () {
                    context.push('/settings');
                  },
                ),
                Divider(
                  color: Theme.of(context).dividerColor.withOpacity(0.2),
                  height: 1,
                  thickness: 1,
                ),
                _buildEnhancedActionButton(
                  icon: Icons.privacy_tip_rounded,
                  title: 'Privacy & Security',
                  subtitle: 'Manage your privacy settings',
                  onTap: () {
                    context.push('/privacy');
                  },
                ),
                Divider(
                  color: Theme.of(context).dividerColor.withOpacity(0.2),
                  height: 1,
                  thickness: 1,
                ),
                _buildEnhancedActionButton(
                  icon: Icons.help_rounded,
                  title: 'Help & Support',
                  subtitle: 'Get help with your account',
                  onTap: () {
                    context.push('/help');
                  },
                ),
                Divider(
                  color: Theme.of(context).dividerColor.withOpacity(0.2),
                  height: 1,
                  thickness: 1,
                ),
                _buildEnhancedActionButton(
                  icon: Icons.logout_rounded,
                  title: 'Sign Out',
                  subtitle: 'Log out from your account',
                  onTap: () {
                    _showLogoutDialog(context);
                  },
                  isDestructive: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Function onTap,
    bool isDestructive = false,
  }) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final iconColor = isDestructive 
        ? Colors.red.shade600 
        : AppTheme.primaryGreen.withOpacity(0.6);
    final titleColor = isDestructive 
        ? Colors.red.shade600 
        : AppTheme.getTextColor(context);
    final iconBgColor = isDestructive 
        ? Colors.red.withOpacity(0.1) 
        : AppTheme.primaryGreen.withOpacity(0.1);
    
    return InkWell(
      onTap: () => onTap(),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: isDesktop ? 18 : 15,
          horizontal: 4,
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isDesktop ? 14 : 12),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon, 
                color: iconColor, 
                size: isDesktop ? 24 : 22,
              ),
            ),
            SizedBox(width: isDesktop ? 18 : 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: titleColor,
                      fontSize: isDesktop ? 17 : 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppTheme.getSecondaryTextColor(context),
                      fontSize: isDesktop ? 14 : 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppTheme.getSecondaryTextColor(context),
              size: isDesktop ? 18 : 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (_isEditing)
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: AppTheme.whiteColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Text(
                'Save Changes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        const SizedBox(height: 15),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              children: [
                _buildActionButton(
                  icon: Icons.settings_outlined,
                  title: 'Account Settings',
                  subtitle: 'Manage your account preferences',
                  onTap: () {
                    context.push('/settings');
                  },
                ),
                Divider(color: Theme.of(context).dividerColor, height: 1),
                _buildActionButton(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy & Security',
                  subtitle: 'Manage your privacy settings',
                  onTap: () {
                    context.push('/privacy');
                  },
                ),
                Divider(color: Theme.of(context).dividerColor, height: 1),
                _buildActionButton(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  subtitle: 'Get help with your account',
                  onTap: () {
                    context.push('/help');
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
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
                color: AppTheme.getSecondaryTextColor(context).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTheme.getSecondaryTextColor(context), size: 24),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppTheme.getTextColor(context),
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

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ref.read(authProvider.notifier).logout();
                context.go('/login');
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
