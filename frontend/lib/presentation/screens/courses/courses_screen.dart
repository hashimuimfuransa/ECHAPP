import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellence_coaching_hub/config/app_theme.dart';
import 'package:excellence_coaching_hub/data/repositories/course_repository.dart';
import 'package:excellence_coaching_hub/models/course.dart';
import 'package:excellence_coaching_hub/services/categories_service.dart';
import 'package:excellence_coaching_hub/utils/responsive_utils.dart';
import 'package:excellence_coaching_hub/widgets/responsive_navigation_drawer.dart';
import 'package:excellence_coaching_hub/utils/course_navigation_utils.dart';

class CoursesScreen extends ConsumerStatefulWidget {
  final String? categoryId;
  final String? categoryName;

  const CoursesScreen({super.key, this.categoryId, this.categoryName});

  @override
  ConsumerState<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends ConsumerState<CoursesScreen> {
  late Future<List<Course>> _coursesFuture;

  @override
  void initState() {
    super.initState();
    _coursesFuture = CourseRepository().getCourses(categoryId: widget.categoryId) as Future<List<Course>>;
  }

  @override
  Widget build(BuildContext context) {
    if (ResponsiveBreakpoints.isDesktop(context)) {
      return Scaffold(
        body: Row(
          children: [
            // Desktop Navigation Drawer
            ResponsiveNavigationDrawer(currentPage: 'courses'),
            
            // Main Content Area
            Expanded(
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: SafeArea(
                  child: Column(
                    children: [
                      // Header for desktop
                      _buildDesktopHeader(context),
                      
                      // Content
                      Expanded(
                        child: SingleChildScrollView(
                          padding: ResponsiveBreakpoints.getPadding(context),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Search Bar
                              _buildSearchBar(context),
                              
                              const SizedBox(height: 25),
                              
                              // Categories Section
                              _buildCategoriesSection(context),
                              
                              const SizedBox(height: 25),
                              
                              // All Courses with responsive grid
                              FutureBuilder<List<Course>>(
                                future: _coursesFuture,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Center(child: CircularProgressIndicator());
                                  } else if (snapshot.hasError) {
                                    return Center(child: Text('Error: ${snapshot.error}'));
                                  } else if (snapshot.hasData) {
                                    final courses = snapshot.data!;
                                    return _buildResponsiveAllCourses(context, courses);
                                  } else {
                                    return const Center(child: Text('No courses found.'));
                                  }
                                },
                              ),
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
        body: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(context),
                
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search Bar
                        _buildSearchBar(context),
                        
                        const SizedBox(height: 25),
                        
                        // Categories Section
                        _buildCategoriesSection(context),
                        
                        const SizedBox(height: 25),
                        
                        // All Courses
                        FutureBuilder<List<Course>>(
                          future: _coursesFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            } else if (snapshot.hasError) {
                              return Center(child: Text('Error: ${snapshot.error}'));
                            } else if (snapshot.hasData) {
                              final courses = snapshot.data!;
                              return _buildAllCourses(context, courses);
                            } else {
                              return const Center(child: Text('No courses found.'));
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        drawer: ResponsiveNavigationDrawer(currentPage: 'courses'),
      );
    }
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
            widget.categoryName != null ? widget.categoryName! : 'All Courses',
            style: TextStyle(
              color: Theme.of(context).textTheme.headlineSmall?.color,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.greyColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.filter_list,
              color: AppTheme.greyColor,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopHeader(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: ResponsiveBreakpoints.getPadding(context),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            widget.categoryName != null ? widget.categoryName! : 'All Courses',
            style: TextStyle(
              color: Theme.of(context).textTheme.headlineSmall?.color,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.search, size: 28),
                onPressed: () {
                  // Handle search
                },
              ),
              const SizedBox(width: 16),
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: AppTheme.greyColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.filter_list,
                  color: AppTheme.greyColor,
                  size: 24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.greyColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: AppTheme.greyColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: const TextField(
        style: TextStyle(color: AppTheme.blackColor),
        decoration: InputDecoration(
          hintText: 'Search courses...',
          hintStyle: TextStyle(color: AppTheme.greyColor),
          prefixIcon: Icon(
            Icons.search,
            color: AppTheme.greyColor,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesSection(BuildContext context) {
    final categories = ref.watch(categoriesProvider);
    final allCategories = [
      {'name': 'All', 'color': AppTheme.primaryGreen, 'id': 'all'},
      ...categories.map((cat) => {
        'name': cat.name,
        'color': AppTheme.primaryGreen, // Default color
        'id': cat.id,
      }),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Categories',
          style: TextStyle(
            color: AppTheme.blackColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 45,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: allCategories.length,
            itemBuilder: (context, index) {
              final category = allCategories[index];
              return Container(
                margin: EdgeInsets.only(
                  right: 12,
                  left: index == 0 ? 0 : 0,
                ),
                child: FilterChip(
                  label: Text(
                    category['name'] as String,
                    style: TextStyle(
                      color: index == 0 
                          ? AppTheme.whiteColor 
                          : AppTheme.greyColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  selected: widget.categoryId == null && index == 0 || 
                           widget.categoryId == category['id'],
                  selectedColor: (category['color'] as Color),
                  backgroundColor: AppTheme.greyColor.withOpacity(0.1),
                  showCheckmark: false,
                  onSelected: (selected) {
                    if (index == 0) {
                      // Navigate to all courses
                      context.push('/courses');
                    } else {
                      // Navigate to courses in selected category
                      context.push('/courses', extra: {
                        'categoryId': category['id'], 
                        'categoryName': category['name']
                      });
                    }
                  },
                  side: BorderSide(
                    color: index == 0 
                        ? (category['color'] as Color) 
                        : AppTheme.greyColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAllCourses(BuildContext context, List<Course> courses) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Courses',
              style: TextStyle(
                color: AppTheme.blackColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${courses.length} courses',
              style: const TextStyle(
                color: AppTheme.greyColor,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: courses.length,
          itemBuilder: (context, index) {
            final course = courses[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 15),
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
                child: InkWell(
                  onTap: () {
                    // Navigate to course details
                    context.push('/course/${course.id}');
                  },
                  borderRadius: BorderRadius.circular(15),
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Row(
                      children: [
                        // Course Image
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppTheme.greyColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.play_circle_outline,
                            color: AppTheme.greyColor,
                            size: 35,
                          ),
                        ),
                        const SizedBox(width: 15),
                        
                        // Course Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                course.title,
                                style: const TextStyle(
                                  color: AppTheme.blackColor,
                                  fontSize: 16,
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
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.access_time,
                                    color: AppTheme.greyColor,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${course.duration} hours',
                                    style: const TextStyle(
                                      color: AppTheme.greyColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Icon(
                                    Icons.people_outline,
                                    color: AppTheme.greyColor,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    '0 students', // This would come from the API
                                    style: TextStyle(
                                      color: AppTheme.greyColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    '4.5 ', // This would come from the API
                                    style: TextStyle(
                                      color: AppTheme.blackColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.greyColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      course.level,
                                      style: const TextStyle(
                                        color: AppTheme.greyColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // Price and Enroll
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$${course.price}',
                              style: const TextStyle(
                                color: AppTheme.primaryGreen,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AppTheme.primaryGreen, Color(0xFF00cdac)],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Enroll',
                                style: TextStyle(
                                  color: AppTheme.whiteColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildResponsiveAllCourses(BuildContext context, List<Course> courses) {
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
                'Courses',
                style: TextStyle(
                  color: AppTheme.blackColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${courses.length} courses',
                style: const TextStyle(
                  color: AppTheme.greyColor,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: gridCount.crossAxisCount,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: gridCount.childAspectRatio,
            ),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              return _buildResponsiveCourseCard(context, course);
            },
          ),
        ],
      );
    } else {
      // List layout for mobile/tablet (same as original)
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Courses',
                style: TextStyle(
                  color: AppTheme.blackColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${courses.length} courses',
                style: const TextStyle(
                  color: AppTheme.greyColor,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                child: _buildCourseListItem(context, course),
              );
            },
          ),
        ],
      );
    }
  }

  Widget _buildResponsiveCourseCard(BuildContext context, Course course) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    
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
      child: InkWell(
        onTap: () {
          context.push('/course/${course.id}');
        },
        borderRadius: BorderRadius.circular(isDesktop ? 18 : 15),
        child: Padding(
          padding: EdgeInsets.all(isDesktop ? 20 : 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course Image
              Container(
                height: isDesktop ? 140.0 : 100.0,
                decoration: BoxDecoration(
                  color: AppTheme.greyColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(isDesktop ? 14.0 : 12.0),
                ),
                child: Icon(
                  Icons.play_circle_outline,
                  color: AppTheme.greyColor,
                  size: isDesktop ? 40.0 : 35.0,
                ),
              ),
              SizedBox(height: isDesktop ? 16 : 12),
              
              // Course Title
              Text(
                course.title,
                style: TextStyle(
                  color: AppTheme.blackColor,
                  fontSize: isDesktop ? 18 : 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: isDesktop ? 8 : 5),
              
              // Instructor
              Text(
                'by ${course.createdBy.fullName}',
                style: TextStyle(
                  color: AppTheme.greyColor,
                  fontSize: isDesktop ? 14 : 13,
                ),
              ),
              SizedBox(height: isDesktop ? 12 : 8),
              
              // Duration and Students
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    color: AppTheme.greyColor,
                    size: isDesktop ? 16 : 14,
                  ),
                  SizedBox(width: 4),
                  Text(
                    '${course.duration}h',
                    style: TextStyle(
                      color: AppTheme.greyColor,
                      fontSize: isDesktop ? 13 : 12,
                    ),
                  ),
                  SizedBox(width: isDesktop ? 16 : 12),
                  Icon(
                    Icons.people_outline,
                    color: AppTheme.greyColor,
                    size: isDesktop ? 16 : 14,
                  ),
                  SizedBox(width: 4),
                  const Text(
                    '0',
                    style: TextStyle(
                      color: AppTheme.greyColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              SizedBox(height: isDesktop ? 12 : 8),
              
              // Rating and Level
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '4.5',
                        style: TextStyle(
                          color: AppTheme.blackColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 10 : 8,
                      vertical: isDesktop ? 4 : 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.greyColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      course.level,
                      style: TextStyle(
                        color: AppTheme.greyColor,
                        fontSize: isDesktop ? 12 : 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              
              // Price and Enroll Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '\$${course.price.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: AppTheme.primaryGreen,
                      fontSize: isDesktop ? 20 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 16 : 12,
                      vertical: isDesktop ? 8 : 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryGreen, Color(0xFF00cdac)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Enroll',
                      style: TextStyle(
                        color: AppTheme.whiteColor,
                        fontSize: isDesktop ? 14 : 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseListItem(BuildContext context, Course course) {
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
        onTap: () => CourseNavigationUtils.navigateToCourse(context, ref, course),
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              // Course Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.greyColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.play_circle_outline,
                  color: AppTheme.greyColor,
                  size: 35,
                ),
              ),
              const SizedBox(width: 15),
              
              // Course Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      style: const TextStyle(
                        color: AppTheme.blackColor,
                        fontSize: 16,
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
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          color: AppTheme.greyColor,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${course.duration} hours',
                          style: const TextStyle(
                            color: AppTheme.greyColor,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.people_outline,
                          color: AppTheme.greyColor,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          '0 students',
                          style: TextStyle(
                            color: AppTheme.greyColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          '4.5 ',
                          style: TextStyle(
                            color: AppTheme.blackColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.greyColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            course.level,
                            style: const TextStyle(
                              color: AppTheme.greyColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Price and Enroll
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${course.price}',
                    style: const TextStyle(
                      color: AppTheme.primaryGreen,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryGreen, Color(0xFF00cdac)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Enroll',
                      style: TextStyle(
                        color: AppTheme.whiteColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}