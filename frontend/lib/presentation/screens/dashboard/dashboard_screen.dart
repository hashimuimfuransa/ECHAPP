import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellence_coaching_hub/presentation/providers/auth_provider.dart';
import 'package:excellence_coaching_hub/config/app_theme.dart';
import 'package:excellence_coaching_hub/presentation/providers/course_provider.dart';
import 'package:excellence_coaching_hub/data/models/course.dart';
import 'package:excellence_coaching_hub/utils/responsive_utils.dart';
import 'package:excellence_coaching_hub/widgets/responsive_navigation_drawer.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final enrolledCoursesAsync = ref.watch(enrolledCoursesProvider);
    final popularCoursesAsync = ref.watch(popularCoursesProvider);

    if (ResponsiveBreakpoints.isDesktop(context)) {
      return Scaffold(
        body: Row(
          children: [
            // Desktop Navigation Drawer
            ResponsiveNavigationDrawer(currentPage: 'dashboard'),
            
            // Main Content Area
            Expanded(
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: SafeArea(
                  child: Column(
                    children: [
                      // Header for desktop
                      _buildDesktopHeader(context, user),
                      
                      // Content
                      Expanded(
                        child: SingleChildScrollView(
                          padding: ResponsiveBreakpoints.getPadding(context),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Welcome Section
                              _buildWelcomeCard(context, user),
                              
                              const SizedBox(height: 25),
                              
                              // Admin Access Button (visible only for admins)
                              if (ref.watch(authProvider.notifier).isAdmin) ...[
                                _buildAdminAccessButton(context),
                                const SizedBox(height: 25),
                              ],
                              
                              // Quick Actions with responsive grid
                              _buildResponsiveQuickActions(context),
                              
                              const SizedBox(height: 25),
                              
                              // Continue Learning
                              enrolledCoursesAsync.when(
                                data: (enrolledCourses) => _buildContinueLearning(context, enrolledCourses),
                                loading: () => _buildLoadingCard(context, 'Continue Learning'),
                                error: (error, stack) => _buildErrorCard(context, 'Continue Learning', error.toString()),
                              ),
                              
                              const SizedBox(height: 25),
                              
                              // Popular Courses with responsive grid
                              popularCoursesAsync.when(
                                data: (popularCourses) => _buildResponsivePopularCourses(context, popularCourses),
                                loading: () => _buildLoadingCard(context, 'Popular Courses'),
                                error: (error, stack) => _buildErrorCard(context, 'Popular Courses', error.toString()),
                              ),
                              
                              // Add some bottom padding
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Mobile layout (existing code)
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(context, user),
                    
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome Section
                      _buildWelcomeCard(context, user),
                                    
                      const SizedBox(height: 25),
                                    
                      // Admin Access Button (visible only for admins)
                      if (ref.watch(authProvider.notifier).isAdmin) ...[
                        _buildAdminAccessButton(context),
                        const SizedBox(height: 25),
                      ],
                                    
                      // Quick Actions
                      _buildQuickActions(context),
                                    
                      const SizedBox(height: 25),
                                    
                      // Continue Learning
                      enrolledCoursesAsync.when(
                        data: (enrolledCourses) => _buildContinueLearning(context, enrolledCourses),
                        loading: () => _buildLoadingCard(context, 'Continue Learning'),
                        error: (error, stack) => _buildErrorCard(context, 'Continue Learning', error.toString()),
                      ),
                                    
                      const SizedBox(height: 25),
                                    
                      // Popular Courses
                      popularCoursesAsync.when(
                        data: (popularCourses) => _buildPopularCourses(context, popularCourses),
                        loading: () => _buildLoadingCard(context, 'Popular Courses'),
                        error: (error, stack) => _buildErrorCard(context, 'Popular Courses', error.toString()),
                      ),
                      
                      // Add some bottom padding to ensure content isn't cut off
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomNavBar(context),
        drawer: ResponsiveNavigationDrawer(currentPage: 'dashboard'),
      );
    }
  }

  Widget _buildHeader(BuildContext context, user) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back,',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontSize: 16,
                ),
              ),
              Text(
                user?.fullName ?? 'Student',
                style: TextStyle(
                  color: Theme.of(context).textTheme.headlineSmall?.color,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          PopupMenuButton(
            icon: CircleAvatar(
              radius: 25,
              backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
              child: Text(
                user?.fullName.substring(0, 1).toUpperCase() ?? 'U',
                style: const TextStyle(
                  color: AppTheme.primaryGreen,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            color: AppTheme.whiteColor,
            onSelected: (value) {
              if (value == 'logout') {
                _showLogoutDialog(context);
              }
            },
            itemBuilder: (context) {
              return <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'profile',
                  child: const Row(
                    children: [
                      Icon(Icons.person_outline, color: AppTheme.blackColor, size: 20),
                      SizedBox(width: 10),
                      Text('Profile', style: TextStyle(color: AppTheme.blackColor)),
                    ],
                  ),
                  onTap: () => context.push('/profile'),
                ),
                PopupMenuItem<String>(
                  value: 'settings',
                  child: const Row(
                    children: [
                      Icon(Icons.settings_outlined, color: AppTheme.blackColor, size: 20),
                      SizedBox(width: 10),
                      Text('Settings', style: TextStyle(color: AppTheme.blackColor)),
                    ],
                  ),
                  onTap: () => context.push('/settings'),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red, size: 20),
                      SizedBox(width: 10),
                      Text('Logout', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopHeader(BuildContext context, user) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: ResponsiveBreakpoints.getPadding(context),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back,',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontSize: 18,
                ),
              ),
              Text(
                user?.fullName ?? 'Student',
                style: TextStyle(
                  color: Theme.of(context).textTheme.headlineSmall?.color,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, size: 28),
                onPressed: () {
                  // Handle notifications
                },
              ),
              const SizedBox(width: 16),
              PopupMenuButton(
                icon: CircleAvatar(
                  radius: 25,
                  backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                  child: Text(
                    user?.fullName.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(
                      color: AppTheme.primaryGreen,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                color: AppTheme.whiteColor,
                onSelected: (value) {
                  if (value == 'logout') {
                    _showLogoutDialog(context);
                  }
                },
                itemBuilder: (context) {
                  return <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'profile',
                      child: const Row(
                        children: [
                          Icon(Icons.person_outline, color: AppTheme.blackColor, size: 20),
                          SizedBox(width: 10),
                          Text('Profile', style: TextStyle(color: AppTheme.blackColor)),
                        ],
                      ),
                      onTap: () => context.push('/profile'),
                    ),
                    PopupMenuItem<String>(
                      value: 'settings',
                      child: const Row(
                        children: [
                          Icon(Icons.settings_outlined, color: AppTheme.blackColor, size: 20),
                          SizedBox(width: 10),
                          Text('Settings', style: TextStyle(color: AppTheme.blackColor)),
                        ],
                      ),
                      onTap: () => context.push('/settings'),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem<String>(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout, color: Colors.red, size: 20),
                          SizedBox(width: 10),
                          Text('Logout', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ];
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context, user) {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryGreen,
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: const Icon(
                    Icons.auto_graph_outlined,
                    color: AppTheme.whiteColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 15),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ready to Learn?',
                        style: TextStyle(
                          color: AppTheme.blackColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Continue your learning journey today',
                        style: TextStyle(
                          color: AppTheme.greyColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  context.push('/courses');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: AppTheme.whiteColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  'Start Learning Now',
                  style: TextStyle(
                    fontSize: 16,
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

  Widget _buildAdminAccessButton(BuildContext context) {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryGreen,
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings,
                    color: AppTheme.whiteColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 15),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Admin Panel',
                        style: TextStyle(
                          color: AppTheme.blackColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Manage courses, students, and platform settings',
                        style: TextStyle(
                          color: AppTheme.greyColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, color: AppTheme.primaryGreen),
                  onPressed: () => context.push('/admin'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      {
        'title': 'Browse Categories',
        'subtitle': 'Explore coaching categories',
        'icon': Icons.category_outlined,
        'color': AppTheme.primaryGreen,
        'onTap': () => _navigateToCategories(context),
      },
      {
        'title': 'My Learning',
        'subtitle': 'Continue courses',
        'icon': Icons.play_circle_outline,
        'color': const Color(0xFF00cdac),
        'onTap': () => context.push('/my-courses'),
      },
      {
        'title': 'Certificates',
        'subtitle': 'View achievements',
        'icon': Icons.verified_outlined,
        'color': const Color(0xFFfa709a),
        'onTap': () => context.push('/certificates'),
      },
      {
        'title': 'Learning Path',
        'subtitle': 'Track progress',
        'icon': Icons.timeline_outlined,
        'color': const Color(0xFFf093fb),
        'onTap': () => context.push('/learning-path'),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            color: AppTheme.blackColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        LayoutBuilder(
          builder: (context, constraints) {
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1.3,
              ),
              itemCount: actions.length,
              itemBuilder: (context, index) {
                final action = actions[index];
                return _buildActionCard(
                  context,
                  action['title'] as String,
                  action['subtitle'] as String,
                  action['icon'] as IconData,
                  action['color'] as Color,
                  action['onTap'] as Function,
                );
              },
            );
          }
        ),
      ],
    );
  }

  Widget _buildResponsiveQuickActions(BuildContext context) {
    final actions = [
      {
        'title': 'Browse Categories',
        'subtitle': 'Explore coaching categories',
        'icon': Icons.category_outlined,
        'color': AppTheme.primaryGreen,
        'onTap': () => _navigateToCategories(context),
      },
      {
        'title': 'My Learning',
        'subtitle': 'Continue courses',
        'icon': Icons.play_circle_outline,
        'color': const Color(0xFF00cdac),
        'onTap': () => context.push('/my-courses'),
      },
      {
        'title': 'Certificates',
        'subtitle': 'View achievements',
        'icon': Icons.verified_outlined,
        'color': const Color(0xFFfa709a),
        'onTap': () => context.push('/certificates'),
      },
      {
        'title': 'Learning Path',
        'subtitle': 'Track progress',
        'icon': Icons.timeline_outlined,
        'color': const Color(0xFFf093fb),
        'onTap': () => context.push('/learning-path'),
      },
    ];

    final gridCount = ResponsiveGridCount(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            color: AppTheme.blackColor,
            fontSize: ResponsiveBreakpoints.isDesktop(context) ? 24 : 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: gridCount.crossAxisCount,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: gridCount.childAspectRatio,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return _buildResponsiveActionCard(
              context,
              action['title'] as String,
              action['subtitle'] as String,
              action['icon'] as IconData,
              action['color'] as Color,
              action['onTap'] as Function,
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, String title, String subtitle, IconData icon, Color color, Function onTap) {
    return Container(
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
      child: InkWell(
        onTap: () => onTap(),
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.blackColor,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppTheme.greyColor,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveActionCard(BuildContext context, String title, String subtitle, IconData icon, Color color, Function onTap) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final double iconSize = isDesktop ? 32.0 : 28.0;
    final double fontSize = isDesktop ? 16.0 : 15.0;
    final double subtitleFontSize = isDesktop ? 13.0 : 12.0;
    final double borderRadius = isDesktop ? 18.0 : 15.0;
    final double containerPadding = isDesktop ? 20.0 : 15.0;
    final double iconContainerPadding = isDesktop ? 14.0 : 12.0;
    final double iconBorderRadius = isDesktop ? 14.0 : 12.0;
    final double verticalSpacing = isDesktop ? 12.0 : 10.0;
    final double subtitleSpacing = isDesktop ? 5.0 : 3.0;
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: isDesktop ? 12.0 : 10.0,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => onTap(),
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(
          padding: EdgeInsets.all(containerPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(iconContainerPadding),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(iconBorderRadius),
                ),
                child: Icon(icon, color: color, size: iconSize),
              ),
              SizedBox(height: verticalSpacing),
              Text(
                title,
                style: TextStyle(
                  color: AppTheme.blackColor,
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: subtitleSpacing),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppTheme.greyColor,
                  fontSize: subtitleFontSize,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContinueLearning(BuildContext context, List<Course> enrolledCourses) {
    if (enrolledCourses.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Continue Learning',
            style: TextStyle(
              color: AppTheme.blackColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
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
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppTheme.greyColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.play_circle_outline,
                          color: AppTheme.greyColor,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 15),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'No courses in progress',
                              style: TextStyle(
                                color: AppTheme.blackColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Start a course to see your progress here',
                              style: TextStyle(
                                color: AppTheme.greyColor,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Start Now',
                          style: TextStyle(
                            color: AppTheme.primaryGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Continue Learning',
            style: TextStyle(
              color: AppTheme.blackColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: enrolledCourses.length,
              itemBuilder: (context, index) {
                final course = enrolledCourses[index];
                return Container(
                  width: 280,
                  margin: const EdgeInsets.only(right: 15),
                  child: Container(
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
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppTheme.greyColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.play_circle_outline,
                              color: AppTheme.greyColor,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  course.title,
                                  style: const TextStyle(
                                    color: AppTheme.blackColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'In Progress',
                                  style: TextStyle(
                                    color: AppTheme.primaryGreen,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Continue',
                              style: TextStyle(
                                color: AppTheme.primaryGreen,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    }
  }

  Widget _buildPopularCourses(BuildContext context, List<Course> popularCourses) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Popular Courses',
              style: TextStyle(
                color: AppTheme.blackColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/courses'),
              child: const Text(
                'View All',
                style: TextStyle(
                  color: AppTheme.primaryGreen,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: popularCourses.length,
            itemBuilder: (context, index) {
              final course = popularCourses[index];
              return Container(
                width: 250,
                margin: EdgeInsets.only(
                  right: 15,
                  left: index == 0 ? 0 : 0,
                ),
                child: Container(
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
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppTheme.greyColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.play_circle_outline,
                              color: AppTheme.greyColor,
                              size: 35,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          course.title,
                          style: const TextStyle(
                            color: AppTheme.blackColor,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'by ${course.createdBy.fullName}',
                          style: const TextStyle(
                            color: AppTheme.greyColor,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 14,
                                ),
                                SizedBox(width: 3),
                                Text(
                                  '4.8', // In a real app, this would come from the course data
                                  style: TextStyle(
                                    color: AppTheme.blackColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '\$${course.price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: AppTheme.primaryGreen,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResponsivePopularCourses(BuildContext context, List<Course> popularCourses) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final gridCount = ResponsiveGridCount(context);
    
    if (isDesktop) {
      // Grid layout for desktop
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Popular Courses',
                style: TextStyle(
                  color: AppTheme.blackColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => context.push('/courses'),
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: AppTheme.primaryGreen,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: gridCount.crossAxisCount,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: gridCount.childAspectRatio,
            ),
            itemCount: popularCourses.length,
            itemBuilder: (context, index) {
              final course = popularCourses[index];
              return _buildResponsiveCourseCard(context, course);
            },
          ),
        ],
      );
    } else {
      // Horizontal scroll for mobile/tablet
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Popular Courses',
                style: TextStyle(
                  color: AppTheme.blackColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => context.push('/courses'),
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: AppTheme.primaryGreen,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: popularCourses.length,
              itemBuilder: (context, index) {
                final course = popularCourses[index];
                return Container(
                  width: 250,
                  margin: EdgeInsets.only(
                    right: 15,
                    left: index == 0 ? 0 : 0,
                  ),
                  child: _buildCourseCard(context, course),
                );
              },
            ),
          ),
        ],
      );
    }
  }

  Widget _buildResponsiveCourseCard(BuildContext context, Course course) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final imageSize = isDesktop ? 120.0 : 80.0;
    final titleFontSize = isDesktop ? 16.0 : 15.0;
    final subtitleFontSize = isDesktop ? 13.0 : 12.0;
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(isDesktop ? 18 : 15),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: isDesktop ? 12 : 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 16 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: imageSize,
              decoration: BoxDecoration(
                color: AppTheme.greyColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(isDesktop ? 12 : 10),
              ),
              child: const Center(
                child: Icon(
                  Icons.play_circle_outline,
                  color: AppTheme.greyColor,
                  size: 35,
                ),
              ),
            ),
            SizedBox(height: isDesktop ? 12 : 10),
            Text(
              course.title,
              style: TextStyle(
                color: AppTheme.blackColor,
                fontSize: titleFontSize,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 5),
            Text(
              'by ${course.createdBy.fullName}',
              style: TextStyle(
                color: AppTheme.greyColor,
                fontSize: subtitleFontSize,
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 14,
                    ),
                    SizedBox(width: 3),
                    Text(
                      '4.8',
                      style: TextStyle(
                        color: AppTheme.blackColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Text(
                  '\$${course.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: AppTheme.primaryGreen,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseCard(BuildContext context, Course course) {
    return Container(
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
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.greyColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Icon(
                  Icons.play_circle_outline,
                  color: AppTheme.greyColor,
                  size: 35,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              course.title,
              style: const TextStyle(
                color: AppTheme.blackColor,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 5),
            Text(
              'by ${course.createdBy.fullName}',
              style: const TextStyle(
                color: AppTheme.greyColor,
                fontSize: 12,
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 14,
                    ),
                    SizedBox(width: 3),
                    Text(
                      '4.8',
                      style: TextStyle(
                        color: AppTheme.blackColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Text(
                  '\$${course.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: AppTheme.primaryGreen,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: AppTheme.whiteColor,
        border: Border(
          top: BorderSide(
            color: AppTheme.greyColor.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(context, Icons.home_filled, 'Home', true, () {}),
          _buildNavItem(context, Icons.search_outlined, 'Search', false, () => context.push('/courses')),
          _buildNavItem(context, Icons.bookmark_border_outlined, 'My Courses', false, () => context.push('/my-courses')),
          _buildNavItem(context, Icons.person_outline, 'Profile', false, () => context.push('/profile')),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label, bool isSelected, Function onTap) {
    return InkWell(
      onTap: () => onTap(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? AppTheme.primaryGreen : AppTheme.greyColor,
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? AppTheme.primaryGreen : AppTheme.greyColor,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.whiteColor,
          title: const Text(
            'Logout',
            style: TextStyle(color: AppTheme.blackColor),
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: AppTheme.greyColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppTheme.greyColor),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ref.read(authProvider.notifier).logout();
                context.go('/login');
              },
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoadingCard(BuildContext context, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.blackColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
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
          child: const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorCard(BuildContext context, String title, String errorMessage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.blackColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
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
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Text(
                'Error loading data: $errorMessage',
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToCategories(BuildContext context) {
    context.push('/categories');
  }
}