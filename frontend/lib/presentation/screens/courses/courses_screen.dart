import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/data/repositories/course_repository.dart';
import 'package:excellencecoachinghub/models/course.dart';
import 'package:excellencecoachinghub/services/categories_service.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';
import 'package:excellencecoachinghub/utils/category_utils.dart';
import 'package:excellencecoachinghub/widgets/network_image_widget.dart';
import 'package:excellencecoachinghub/utils/course_navigation_utils.dart';
import 'package:excellencecoachinghub/presentation/providers/course_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/enrollment_provider.dart';

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
  bool _isLoading = true;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Always load ALL courses initially so that 'All' category works
    // and we can filter client-side as needed.
    _coursesFuture = CourseRepository().getCourses();
    _coursesFuture.then((courses) {
      if (mounted) {
        setState(() {
          _allCourses = courses;
          _filteredCourses = courses;
          _isLoading = false;
          _errorMessage = null;
          if (widget.categoryId != null) {
            _selectedCategory = widget.categoryId!;
          }
        });
        
        // Auto-show category popup after a short delay for better UX
        if (widget.categoryId == null) {
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) {
              _showCategoryPopup(context);
            }
          });
        }
        
        // Apply initial filter if needed
        if (widget.categoryId != null && widget.categoryId != 'all') {
          _filterCourses();
        }
      }
    }).catchError((error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = error.toString();
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCourses() {
    if (!mounted) return;
    
    debugPrint('CoursesScreen: Filtering courses for category $_selectedCategory');
    
    setState(() {
      List<Course> filtered = _allCourses;
      
      // Apply category filter
      if (_selectedCategory != 'all') {
        filtered = filtered.where((course) {
          // Check if course belongs to selected category
          bool matchesCategory = false;
          
          // If course has categoryId field set
          if (course.categoryId != null && (course.categoryId == _selectedCategory || course.categoryId.toString() == _selectedCategory)) {
            matchesCategory = true;
          }
          // If course has category object with id field
          else if (course.category != null) {
            final catId = course.category!['id'] ?? course.category!['_id'];
            if (catId != null && catId.toString() == _selectedCategory) {
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
      
      debugPrint('CoursesScreen: Found ${filtered.length} courses after filtering');
      _filteredCourses = filtered;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final enrolledCoursesAsync = ref.watch(enrolledCoursesProvider);
    
    return Scaffold(
      backgroundColor: Colors.transparent, // Let MainLayout background show through
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            _buildResponsiveSearchBar(context),
            
            // Content
            Expanded(
              child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryGreen),
                  )
                : _errorMessage != null
                  ? _buildErrorWidget()
                  : CustomScrollView(
                      slivers: [
                        SliverPadding(
                          padding: ResponsiveBreakpoints.getPadding(context),
                          sliver: SliverToBoxAdapter(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 25),
                              ],
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: ResponsiveBreakpoints.getPadding(context),
                          sliver: enrolledCoursesAsync.when(
                            data: (enrolledCourses) => _buildSliverAllCourses(context, _filteredCourses, enrolledCourses),
                            loading: () => const SliverToBoxAdapter(
                              child: Center(child: CircularProgressIndicator()),
                            ),
                            error: (err, stack) => _buildSliverAllCourses(context, _filteredCourses, []),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 40)),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveSearchBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: _getResponsiveHorizontalPadding(context),
        vertical: _getResponsiveVerticalPadding(context),
      ),
      child: Row(
        children: [
          // Search Bar
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF374151) : const Color(0xFFE2E8F0),
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => _filterCourses(),
                style: TextStyle(
                  color: AppTheme.getTextColor(context),
                  fontSize: _getResponsiveTextSize(context),
                ),
                decoration: InputDecoration(
                  hintText: 'Search courses...',
                  hintStyle: TextStyle(
                    color: AppTheme.greyColor,
                    fontSize: _getResponsiveTextSize(context),
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: AppTheme.greyColor,
                    size: _getResponsiveIconSize(context) * 0.8,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: AppTheme.greyColor),
                        onPressed: () {
                          _searchController.clear();
                          _filterCourses();
                        },
                      )
                    : null,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: _getResponsiveHorizontalPadding(context),
                    vertical: _getResponsiveVerticalPadding(context) * 0.8,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: _getResponsiveSpacing(context) * 0.5),
          // Category Filter Button
          Container(
            width: _getResponsiveIconSize(context) + 8,
            height: _getResponsiveIconSize(context) + 8,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981),
              borderRadius: BorderRadius.circular(_getResponsiveBorderRadius(context)),
            ),
            child: IconButton(
              onPressed: () => _showCategoryPopup(context),
              icon: Icon(
                Icons.filter_list_rounded,
                color: Colors.white,
                size: _getResponsiveIconSize(context) * 0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCategoryPopup(BuildContext context) {
    final backendCategories = ref.watch(backendCategoriesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => backendCategories.when(
        data: (categories) {
          // Combine with 'All' option
          final allCategories = [
            {
              'name': 'All Courses', 
              'color': AppTheme.primaryGreen, 
              'id': 'all',
              'icon': CategoryUtils.getCategoryIcon('all', name: 'all'),
              'description': 'Browse all available courses',
            },
            ...categories.asMap().entries.map((entry) {
              var cat = entry.value;
              final categoryId = cat.id;
              return {
                'name': cat.name,
                'color': CategoryUtils.getCategoryColor(categoryId, name: cat.name),
                'id': categoryId,
                'icon': CategoryUtils.getCategoryIcon(categoryId, name: cat.name),
                'description': 'Courses in ${cat.name} category',
              };
            }),
          ];
          
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2937) : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Compact Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.filter_list_rounded,
                        color: const Color(0xFF10B981),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Select Category',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.getTextColor(context),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.close_rounded,
                          color: AppTheme.getSecondaryTextColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
                // Compact Categories Grid
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _getResponsiveCrossAxisCount(context),
                        crossAxisSpacing: _getResponsiveSpacing(context),
                        mainAxisSpacing: _getResponsiveSpacing(context),
                        childAspectRatio: _getResponsiveAspectRatio(context),
                      ),
                      itemCount: allCategories.length,
                      itemBuilder: (context, index) {
                        final category = allCategories[index];
                        final isSelected = _selectedCategory == category['id'];
                        final categoryColor = category['color'] as Color;
                        
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategory = category['id'] as String;
                            });
                            _filterCourses();
                            Navigator.of(context).pop();
                          },
                          child: Container(
                            padding: EdgeInsets.all(_getResponsiveCardPadding(context)),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? categoryColor.withOpacity(0.1)
                                  : (isDark ? const Color(0xFF374151) : const Color(0xFFF9FAFB)),
                              borderRadius: BorderRadius.circular(_getResponsiveBorderRadius(context)),
                              border: Border.all(
                                color: isSelected 
                                      ? categoryColor
                                      : (isDark ? const Color(0xFF4B5563) : const Color(0xFFE5E7EB)),
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: _getResponsiveIconSize(context),
                                      height: _getResponsiveIconSize(context),
                                      decoration: BoxDecoration(
                                        color: categoryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(_getResponsiveIconRadius(context)),
                                      ),
                                      child: Icon(
                                        category['icon'] as IconData,
                                        color: categoryColor,
                                        size: _getResponsiveIconSize(context) * 0.5,
                                      ),
                                    ),
                                    SizedBox(width: _getResponsiveSpacing(context) * 0.5),
                                    Expanded(
                                      child: Text(
                                        category['name'] as String,
                                        style: TextStyle(
                                          fontSize: _getResponsiveTextSize(context),
                                          fontWeight: FontWeight.w600,
                                          color: isSelected 
                                              ? categoryColor
                                              : AppTheme.getTextColor(context),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
        loading: () => _buildCategoryLoadingState(context),
        error: (_, __) => _buildCategoryErrorState(context),
      ),
    );
  }

  double _getResponsiveHorizontalPadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 400) {
      return 12; // Very small screens
    } else if (screenWidth < 600) {
      return 16; // Small mobile screens
    } else {
      return 20; // Medium tablets and desktop
    }
  }

  double _getResponsiveVerticalPadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 400) {
      return 8; // Very small screens
    } else if (screenWidth < 600) {
      return 12; // Small mobile screens
    } else {
      return 16; // Medium tablets and desktop
    }
  }

  int _getResponsiveCrossAxisCount(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 400) {
      return 2; // Very small screens
    } else if (screenWidth < 600) {
      return 2; // Small mobile screens
    } else if (screenWidth < 800) {
      return 3; // Medium tablets
    } else {
      return 4; // Large tablets and desktop
    }
  }

  double _getResponsiveSpacing(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 400) {
      return 6; // Very small screens
    } else if (screenWidth < 600) {
      return 8; // Small mobile screens
    } else if (screenWidth < 800) {
      return 10; // Medium tablets
    } else {
      return 12; // Large tablets and desktop
    }
  }

  double _getResponsiveAspectRatio(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 400) {
      return 1.0; // Very small screens - more square
    } else if (screenWidth < 600) {
      return 1.1; // Small mobile screens
    } else if (screenWidth < 800) {
      return 1.2; // Medium tablets
    } else {
      return 1.3; // Large tablets and desktop
    }
  }

  double _getResponsiveCardPadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 400) {
      return 8; // Very small screens
    } else if (screenWidth < 600) {
      return 10; // Small mobile screens
    } else {
      return 12; // Medium tablets and desktop
    }
  }

  double _getResponsiveBorderRadius(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 400) {
      return 8; // Very small screens
    } else if (screenWidth < 600) {
      return 10; // Small mobile screens
    } else {
      return 12; // Medium tablets and desktop
    }
  }

  double _getResponsiveIconSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 400) {
      return 24; // Very small screens
    } else if (screenWidth < 600) {
      return 28; // Small mobile screens
    } else {
      return 32; // Medium tablets and desktop
    }
  }

  double _getResponsiveIconRadius(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 400) {
      return 6; // Very small screens
    } else if (screenWidth < 600) {
      return 8; // Small mobile screens
    } else {
      return 10; // Medium tablets and desktop
    }
  }

  double _getResponsiveTextSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 400) {
      return 12; // Very small screens
    } else if (screenWidth < 600) {
      return 13; // Small mobile screens
    } else {
      return 14; // Medium tablets and desktop
    }
  }

  Widget _buildCategoryLoadingState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Color(0xFF10B981)),
            const SizedBox(height: 20),
            Text(
              'Loading categories...',
              style: TextStyle(
                color: AppTheme.getSecondaryTextColor(context),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryErrorState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: const Color(0xFFEF4444),
              size: 48,
            ),
            const SizedBox(height: 20),
            Text(
              'Failed to load categories',
              style: TextStyle(
                color: AppTheme.getTextColor(context),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please try again later',
              style: TextStyle(
                color: AppTheme.getSecondaryTextColor(context),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
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
              Text(
                'Courses',
                style: TextStyle(
                  color: AppTheme.getTextColor(context),
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
            Text(
              'Courses',
              style: TextStyle(
                color: AppTheme.getTextColor(context),
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
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: course.thumbnail != null && course.thumbnail!.isNotEmpty
                                ? NetworkImageWidget(
                                    imageUrl: course.thumbnail!,
                                    fit: BoxFit.cover,
                                    width: 80,
                                    height: 80,
                                    placeholder: Container(
                                      color: AppTheme.greyColor.withOpacity(0.1),
                                      child: const Icon(
                                        Icons.play_circle_outline,
                                        color: AppTheme.greyColor,
                                        size: 35,
                                      ),
                                    ),
                                  )
                                : const Icon(
                                    Icons.play_circle_outline,
                                    color: AppTheme.greyColor,
                                    size: 35,
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
                                style: TextStyle(
                                  color: AppTheme.getTextColor(context),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'by ${course.displayInstructor}',
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
                                    course.formattedDuration,
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
                                  Text(
                                    '${course.enrollmentCount ?? 0} students',
                                    style: const TextStyle(
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
                                  Text(
                                    (course.averageRating ?? 0.0).toStringAsFixed(1),
                                    style: TextStyle(
                                      color: AppTheme.getTextColor(context),
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

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Failed to load courses',
              style: TextStyle(
                color: AppTheme.getTextColor(context),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.greyColor),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                initState();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAllCourses(BuildContext context, List<Course> courses, List<Course> enrolledCourses) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    
    if (courses.isEmpty) {
      return SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCoursesHeader(context, courses.length),
            const SizedBox(height: 25),
            _buildNoCoursesFound(context),
          ],
        ),
      );
    }
    
    if (isDesktop) {
      final gridCount = ResponsiveGridCount(context);
      return SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(child: _buildCoursesHeader(context, courses.length)),
          const SliverToBoxAdapter(child: SizedBox(height: 25)),
          SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: gridCount.crossAxisCount,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: gridCount.childAspectRatio,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildResponsiveCourseCard(context, courses[index], enrolledCourses),
              childCount: courses.length,
            ),
          ),
        ],
      );
    } else {
      return SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(child: _buildCoursesHeader(context, courses.length)),
          const SliverToBoxAdapter(child: SizedBox(height: 15)),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => Container(
                margin: const EdgeInsets.only(bottom: 15),
                child: _buildCourseListItem(context, courses[index], enrolledCourses),
              ),
              childCount: courses.length,
            ),
          ),
        ],
      );
    }
  }

  Widget _buildCoursesHeader(BuildContext context, int count) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Courses',
          style: TextStyle(
            color: AppTheme.getTextColor(context),
            fontSize: isDesktop ? 24 : 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '$count courses',
          style: TextStyle(
            color: AppTheme.greyColor,
            fontSize: isDesktop ? 16 : 14,
          ),
        ),
      ],
    );
  }

  Widget _buildNoCoursesFound(BuildContext context) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    return Container(
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
    );
  }

  Widget _buildResponsiveCourseCard(BuildContext context, Course course, List<Course> enrolledCourses) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final bool isEnrolled = enrolledCourses.any((e) => e.id == course.id);
    
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
        onTap: () {
          if (isEnrolled) {
            context.push('/learning/${course.id}');
          } else {
            CourseNavigationUtils.navigateToCourse(context, ref, course);
          }
        },
        borderRadius: BorderRadius.circular(isDesktop ? 16 : 12),
        child: Padding(
          padding: EdgeInsets.all(isDesktop ? 18 : 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course Image
              ClipRRect(
                borderRadius: BorderRadius.circular(isDesktop ? 12.0 : 10.0),
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppTheme.greyColor.withOpacity(0.1),
                      ),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: course.thumbnail != null && course.thumbnail!.isNotEmpty
                            ? NetworkImageWidget(
                                imageUrl: course.thumbnail!,
                                fit: BoxFit.cover,
                                placeholder: Container(
                                  color: AppTheme.greyColor.withOpacity(0.1),
                                  child: Icon(
                                    Icons.play_circle_outline,
                                    color: AppTheme.greyColor,
                                    size: isDesktop ? 36.0 : 30.0,
                                  ),
                                ),
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
                    if (isEnrolled)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded, color: Colors.white, size: 10),
                              SizedBox(width: 4),
                              Text(
                                'ENROLLED',
                                style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if ((course.price ?? 0) > 0)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '20% OFF',
                            style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: isDesktop ? 14 : 10),
              
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Course Title
                    Text(
                      course.title ?? 'Untitled Course',
                      style: TextStyle(
                        color: AppTheme.getTextColor(context),
                        fontSize: isDesktop ? 16 : 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: isDesktop ? 4 : 2),
                    
                    // Instructor
                    Text(
                      'by ${course.displayInstructor}',
                      style: TextStyle(
                        color: AppTheme.greyColor,
                        fontSize: isDesktop ? 12 : 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: isDesktop ? 8 : 4),
                    
                    // Duration and Students
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: AppTheme.greyColor,
                          size: isDesktop ? 14 : 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          course.formattedDuration,
                          style: TextStyle(
                            color: AppTheme.greyColor,
                            fontSize: isDesktop ? 11 : 10,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(
                          Icons.people_outline,
                          color: AppTheme.greyColor,
                          size: isDesktop ? 14 : 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${course.enrollmentCount ?? 0}',
                          style: const TextStyle(
                            color: AppTheme.greyColor,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isDesktop ? 8 : 4),
                    
                    // Rating and Level
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              (course.averageRating ?? 0.0).toStringAsFixed(1),
                              style: TextStyle(
                                color: AppTheme.getTextColor(context),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 8 : 6,
                            vertical: isDesktop ? 2 : 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.greyColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            course.level,
                            style: TextStyle(
                              color: AppTheme.greyColor,
                              fontSize: isDesktop ? 10 : 9,
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
                        if ((course.price ?? 0) > 0)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'RWF ${((course.price ?? 0) / 0.8).toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: isDesktop ? 10 : 9,
                                  decoration: TextDecoration.lineThrough,
                                  color: AppTheme.greyColor.withOpacity(0.6),
                                ),
                              ),
                              Text(
                                'RWF ${(course.price ?? 0).toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: AppTheme.primaryGreen,
                                  fontSize: isDesktop ? 15 : 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          )
                        else
                          Text(
                            'FREE',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: isDesktop ? 15 : 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 12 : 8,
                            vertical: isDesktop ? 6 : 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppTheme.primaryGreen, Color(0xFF00cdac)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isEnrolled ? 'Open' : 'Enroll', // Shortened text for mobile
                            style: TextStyle(
                              color: AppTheme.whiteColor,
                              fontSize: isDesktop ? 11 : 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseListItem(BuildContext context, Course course, List<Course> enrolledCourses) {
    final bool isEnrolled = enrolledCourses.any((e) => e.id == course.id);
    
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
        onTap: () {
          if (isEnrolled) {
            context.push('/learning/${course.id}');
          } else {
            CourseNavigationUtils.navigateToCourse(context, ref, course);
          }
        },
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              // Course Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.greyColor.withOpacity(0.1),
                      ),
                      child: course.thumbnail != null && course.thumbnail!.isNotEmpty
                          ? NetworkImageWidget(
                              imageUrl: course.thumbnail!,
                              fit: BoxFit.cover,
                              width: 80,
                              height: 80,
                              placeholder: Container(
                                color: AppTheme.greyColor.withOpacity(0.1),
                                child: const Icon(
                                  Icons.play_circle_outline,
                                  color: AppTheme.greyColor,
                                  size: 35,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.play_circle_outline,
                              color: AppTheme.greyColor,
                              size: 35,
                            ),
                    ),
                    if (isEnrolled)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 10),
                        ),
                      )
                    else if ((course.price ?? 0) > 0)
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '20% OFF',
                            style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                  ],
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
                      style: TextStyle(
                        color: AppTheme.getTextColor(context),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'by ${course.displayInstructor}',
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
                          course.formattedDuration,
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
                        Text(
                          '${course.enrollmentCount ?? 0} students',
                          style: const TextStyle(
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
                        Text(
                          (course.averageRating ?? 0.0).toStringAsFixed(1),
                          style: TextStyle(
                            color: AppTheme.getTextColor(context),
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
                  if ((course.price ?? 0) > 0)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'RWF ${((course.price ?? 0) / 0.8).toStringAsFixed(0)}',
                          style: TextStyle(
                            color: AppTheme.greyColor.withOpacity(0.6),
                            fontSize: 11,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        Text(
                          'RWF ${course.price}',
                          style: const TextStyle(
                            color: AppTheme.primaryGreen,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  else
                    const Text(
                      'FREE',
                      style: TextStyle(
                        color: Colors.green,
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
                    child: Text(
                      isEnrolled ? 'Continue' : 'Enroll',
                      style: const TextStyle(
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
