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
import 'package:excellence_coaching_hub/models/category.dart';
import 'package:excellence_coaching_hub/presentation/providers/course_provider.dart';

class CoursesScreen extends ConsumerStatefulWidget {
  final String? categoryId;
  final String? categoryName;

  const CoursesScreen({super.key, this.categoryId, this.categoryName});

  @override
  ConsumerState<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends ConsumerState<CoursesScreen> {
  late Future<List<Course>> _coursesFuture;
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'all';
  List<Course> _allCourses = [];
  List<Course> _filteredCourses = [];

  @override
  void initState() {
    super.initState();
    // If widget.categoryId is provided, load courses for that category
    _coursesFuture = CourseRepository().getCourses(categoryId: widget.categoryId);
    _coursesFuture.then((courses) {
      setState(() {
        _allCourses = courses;
        _filteredCourses = courses;
        if (widget.categoryId != null) {
          _selectedCategory = widget.categoryId!;
        }
      });
      // Apply initial filter if needed
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.categoryId != null) {
          setState(() {
            _selectedCategory = widget.categoryId!;
          });
          _filterCourses();
        }
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCourses() {
    setState(() {
      List<Course> filtered = _allCourses;
      
      // Apply category filter
      if (_selectedCategory != 'all') {
        filtered = filtered.where((course) {
          // Check if course belongs to selected category
          bool matchesCategory = false;
          
          // If course has categoryId field set
          if (course.categoryId != null && course.categoryId == _selectedCategory) {
            matchesCategory = true;
          }
          // If course has category object with id field
          else if (course.category != null) {
            if (course.category!['id'] == _selectedCategory || course.category!['_id'] == _selectedCategory) {
              matchesCategory = true;
            }
          }
          
          return matchesCategory;
        }).toList();
      }
      
      // Apply search filter
      if (_searchController.text.isNotEmpty) {
        filtered = filtered.where((course) =>
          course.title.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          course.description.toLowerCase().contains(_searchController.text.toLowerCase())
        ).toList();
      }
      
      _filteredCourses = filtered;
    });
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
                              const SizedBox(height: 25),
                              
                              // Categories Section
                              _buildCategoriesSection(context),
                              
                              const SizedBox(height: 25),
                              
                              // All Courses with responsive grid
                              _buildResponsiveAllCourses(context, _filteredCourses),
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
                        const SizedBox(height: 25),
                        
                        // Categories Section
                        _buildCategoriesSection(context),
                        
                        const SizedBox(height: 25),
                        
                        // All Courses
                        _buildAllCourses(context, _filteredCourses),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
          const SizedBox(height: 15),
          // Search Bar for mobile
          Container(
            decoration: BoxDecoration(
              color: AppTheme.greyColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: AppTheme.greyColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _filterCourses(),
              style: TextStyle(color: AppTheme.blackColor),
              decoration: InputDecoration(
                hintText: 'Search courses...',
                hintStyle: TextStyle(color: AppTheme.greyColor),
                prefixIcon: Icon(
                  Icons.search,
                  color: AppTheme.greyColor,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: AppTheme.greyColor),
                      onPressed: () {
                        _searchController.clear();
                        _filterCourses();
                      },
                    )
                  : null,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
              ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
          const SizedBox(height: 20),
          // Search Bar for desktop
          Container(
            decoration: BoxDecoration(
              color: AppTheme.greyColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: AppTheme.greyColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _filterCourses(),
              style: TextStyle(color: AppTheme.blackColor),
              decoration: InputDecoration(
                hintText: 'Search courses...',
                hintStyle: TextStyle(color: AppTheme.greyColor),
                prefixIcon: Icon(
                  Icons.search,
                  color: AppTheme.greyColor,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: AppTheme.greyColor),
                      onPressed: () {
                        _searchController.clear();
                        _filterCourses();
                      },
                    )
                  : null,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildCategoriesSection(BuildContext context) {
    // Get backend categories
    final backendCategories = ref.watch(backendCategoriesProvider);
    
    return backendCategories.when(
      data: (categories) {
        // Combine with 'All' option
        final allCategories = [
          {'name': 'All', 'color': AppTheme.primaryGreen, 'id': 'all'},
          ...categories.map((cat) => {
            'name': cat.name,
            'color': AppTheme.primaryGreen,
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
                          color: _selectedCategory == category['id'] 
                              ? AppTheme.whiteColor 
                              : AppTheme.greyColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      selected: _selectedCategory == category['id'],
                      selectedColor: (category['color'] as Color),
                      backgroundColor: AppTheme.greyColor.withOpacity(0.1),
                      showCheckmark: false,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = category['id'] as String;
                        });
                        _filterCourses();
                      },
                      side: BorderSide(
                        color: _selectedCategory == category['id'] 
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
      },
      loading: () {
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
                itemCount: 5, // Show placeholder for loading
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(right: 12),
                    height: 45,
                    width: 100,
                    decoration: BoxDecoration(
                      color: AppTheme.greyColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      error: (error, stack) {
        // Fallback to predefined categories if backend fails
        final categories = CategoriesService.getAllCategories();
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
                          color: _selectedCategory == category['id'] 
                              ? AppTheme.whiteColor 
                              : AppTheme.greyColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      selected: _selectedCategory == category['id'],
                      selectedColor: (category['color'] as Color),
                      backgroundColor: AppTheme.greyColor.withOpacity(0.1),
                      showCheckmark: false,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = category['id'] as String;
                        });
                        _filterCourses();
                      },
                      side: BorderSide(
                        color: _selectedCategory == category['id'] 
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
      },
    );
  }

  Widget _buildAllCourses(BuildContext context, List<Course> courses) {
    if (courses.isEmpty) {
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
          Container(
            padding: const EdgeInsets.all(40),
            alignment: Alignment.center,
            child: Column(
              children: [
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: AppTheme.greyColor,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No courses found',
                  style: TextStyle(
                    color: AppTheme.greyColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Try adjusting your search or filter criteria',
                  style: TextStyle(
                    color: AppTheme.greyColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
    
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
                            image: course.thumbnail != null && course.thumbnail!.isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(course.thumbnail!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: course.thumbnail == null || course.thumbnail!.isEmpty
                              ? const Icon(
                                  Icons.play_circle_outline,
                                  color: AppTheme.greyColor,
                                  size: 35,
                                )
                              : null,
                        ),
                        const SizedBox(width: 15),
                        
                        // Course Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                course.title ?? 'Untitled Course',
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
                              'RWF ${course.price}',
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
    
    if (courses.isEmpty) {
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
                  fontSize: isDesktop ? 24 : 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${courses.length} courses',
                style: TextStyle(
                  color: AppTheme.greyColor,
                  fontSize: isDesktop ? 16 : 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          Container(
            padding: EdgeInsets.all(isDesktop ? 60 : 40),
            alignment: Alignment.center,
            child: Column(
              children: [
                Icon(
                  Icons.search_off,
                  size: isDesktop ? 80 : 64,
                  color: AppTheme.greyColor,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No courses found',
                  style: TextStyle(
                    color: AppTheme.greyColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Try adjusting your search or filter criteria',
                  style: TextStyle(
                    color: AppTheme.greyColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
    
    if (isDesktop) {
      // Grid layout for desktop
      final gridCount = ResponsiveGridCount(context);
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
        borderRadius: BorderRadius.circular(isDesktop ? 16 : 12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.08),
            blurRadius: isDesktop ? 10 : 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
          width: 0.5,
        ),
      ),
      child: InkWell(
        onTap: () => CourseNavigationUtils.navigateToCourse(context, ref, course),
        borderRadius: BorderRadius.circular(isDesktop ? 16 : 12),
        child: Padding(
          padding: EdgeInsets.all(isDesktop ? 18 : 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course Image
              ClipRRect(
                borderRadius: BorderRadius.circular(isDesktop ? 12.0 : 10.0),
                child: Container(
                  height: isDesktop ? 130.0 : 90.0,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.greyColor.withOpacity(0.1),
                  ),
                  child: course.thumbnail != null && course.thumbnail!.isNotEmpty
                      ? Image.network(
                          course.thumbnail!,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: AppTheme.greyColor.withOpacity(0.1),
                              child: Icon(
                                Icons.play_circle_outline,
                                color: AppTheme.greyColor,
                                size: isDesktop ? 36.0 : 30.0,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppTheme.greyColor.withOpacity(0.1),
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                color: AppTheme.greyColor,
                                size: isDesktop ? 36.0 : 30.0,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: AppTheme.greyColor.withOpacity(0.1),
                          child: Icon(
                            Icons.play_circle_outline,
                            color: AppTheme.greyColor,
                            size: isDesktop ? 36.0 : 30.0,
                          ),
                        ),
                ),
              ),
              SizedBox(height: isDesktop ? 14 : 10),
              
              // Course Title
              Text(
                course.title ?? 'Untitled Course',
                style: TextStyle(
                  color: AppTheme.blackColor,
                  fontSize: isDesktop ? 17 : 15,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: isDesktop ? 6 : 4),
              
              // Instructor
              Text(
                'by ${course.createdBy.fullName}',
                style: TextStyle(
                  color: AppTheme.greyColor,
                  fontSize: isDesktop ? 13 : 12,
                ),
              ),
              SizedBox(height: isDesktop ? 10 : 6),
              
              // Duration and Students
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    color: AppTheme.greyColor,
                    size: isDesktop ? 15 : 13,
                  ),
                  SizedBox(width: 4),
                  Text(
                    '${course.duration}h',
                    style: TextStyle(
                      color: AppTheme.greyColor,
                      fontSize: isDesktop ? 12 : 11,
                    ),
                  ),
                  SizedBox(width: isDesktop ? 14 : 10),
                  Icon(
                    Icons.people_outline,
                    color: AppTheme.greyColor,
                    size: isDesktop ? 15 : 13,
                  ),
                  SizedBox(width: 4),
                  const Text(
                    '0',
                    style: TextStyle(
                      color: AppTheme.greyColor,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              SizedBox(height: isDesktop ? 10 : 6),
              
              // Rating and Level
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 15,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '4.5',
                        style: TextStyle(
                          color: AppTheme.blackColor,
                          fontSize: 12,
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
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      course.level,
                      style: TextStyle(
                        color: AppTheme.greyColor,
                        fontSize: isDesktop ? 11 : 10,
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
                    'RWF ${course.price.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: AppTheme.primaryGreen,
                      fontSize: isDesktop ? 18 : 16,
                      fontWeight: FontWeight.w600,
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
                        fontSize: isDesktop ? 13 : 11,
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
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.greyColor.withOpacity(0.1),
                  ),
                  child: course.thumbnail != null && course.thumbnail!.isNotEmpty
                      ? Image.network(
                          course.thumbnail!,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: AppTheme.greyColor.withOpacity(0.1),
                              child: const Icon(
                                Icons.play_circle_outline,
                                color: AppTheme.greyColor,
                                size: 35,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppTheme.greyColor.withOpacity(0.1),
                              child: const Icon(
                                Icons.image_not_supported_outlined,
                                color: AppTheme.greyColor,
                                size: 35,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: AppTheme.greyColor.withOpacity(0.1),
                          child: const Icon(
                            Icons.play_circle_outline,
                            color: AppTheme.greyColor,
                            size: 35,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 15),
              
              // Course Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title ?? 'Untitled Course',
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
                    'RWF ${course.price}',
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