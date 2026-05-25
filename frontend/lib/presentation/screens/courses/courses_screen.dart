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
  final String? searchQuery;

  const CoursesScreen({super.key, this.categoryId, this.categoryName, this.searchQuery});

  @override
  ConsumerState<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends ConsumerState<CoursesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _selectedCategory = 'all';
  List<Course> _allCourses = [];
  List<Course> _filteredCourses = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  static const int _pageSize = 20;

  String? _errorMessage;

  final CourseRepository _repository = CourseRepository();

  @override
  void initState() {
    super.initState();
    // Preload categories for faster access
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(categoryPreloadProvider);
    });

    _scrollController.addListener(_onScroll);

    if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
      _searchController.text = widget.searchQuery!;
    }
    if (widget.categoryId != null) {
      _selectedCategory = widget.categoryId!;
    }

    // Load initial page with debounce for better performance
    Future.microtask(() => _loadPage(1, reset: true));
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      if (!_isLoadingMore && _hasMore) {
        _loadNextPage();
      }
    }
  }

  Future<void> _loadPage(int page, {bool reset = false}) async {
    if (!mounted) return;
    if (reset) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      // Use recommended courses when no filters are applied
      if (page == 1 && reset && _selectedCategory == 'all' && _searchController.text.isEmpty && widget.categoryId == null && widget.searchQuery == null) {
        // Load recommended courses for first page
        final recommended = await _repository.getRecommendedCourses();
        if (!mounted) return;
        setState(() {
          _allCourses = recommended;
          _currentPage = 1;
          _hasMore = false; // Recommendations are a fixed set
          _isLoading = false;
          _isLoadingMore = false;
          _filteredCourses = _allCourses;
        });
      } else {
        // Use regular pagination when filters are applied
        final result = await _repository.getCoursesPaged(
          page: page,
          limit: _pageSize,
          categoryId: _selectedCategory == 'all' ? null : _selectedCategory,
          search: _searchController.text.isNotEmpty ? _searchController.text : null,
        );

        if (!mounted) return;
        setState(() {
          if (reset) {
            _allCourses = result.courses;
          } else {
            _allCourses = [..._allCourses, ...result.courses];
          }
          _currentPage = result.currentPage;
          _hasMore = result.hasNextPage;
          _isLoading = false;
          _isLoadingMore = false;
          _filteredCourses = _allCourses;
        });
      }

    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _loadNextPage() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;
    setState(() => _isLoadingMore = true);
    await _loadPage(_currentPage + 1);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _filterCourses() {
    if (!mounted) return;
    debugPrint('CoursesScreen: Reloading courses for category $_selectedCategory');
    _loadPage(1, reset: true);
  }
  
  @override
  Widget build(BuildContext context) {
    final enrolledCoursesAsync = ref.watch(enrolledCoursesProvider);
    
    // Cache MediaQuery results to avoid repeated expensive lookups
    final mediaQueryData = MediaQuery.of(context);
    final screenWidth = mediaQueryData.size.width;
    final isDark = mediaQueryData.platformBrightness == Brightness.dark;
    
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
                      controller: _scrollController,
                      slivers: [
                        SliverPadding(
                          padding: ResponsiveBreakpoints.getPadding(context),
                          sliver: SliverToBoxAdapter(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
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
                        if (_isLoadingMore)
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Center(
                                child: CircularProgressIndicator(color: AppTheme.primaryGreen),
                              ),
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
    
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: _getResponsiveHorizontalPadding(context),
        vertical: _getResponsiveVerticalPadding(context),
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Search Bar
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) => _filterCourses(),
              style: TextStyle(
                color: AppTheme.getTextColor(context),
                fontSize: _getResponsiveTextSize(context) * 1.1,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Search courses, instructors...',
                hintStyle: TextStyle(
                  color: AppTheme.greyColor.withOpacity(0.7),
                  fontSize: _getResponsiveTextSize(context) * 1.1,
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: Container(
                  margin: const EdgeInsets.only(left: 12, right: 8),
                  child: Icon(
                    Icons.search_rounded,
                    color: const Color(0xFF10B981),
                    size: _getResponsiveIconSize(context) * 0.8,
                  ),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear_rounded, 
                        color: AppTheme.greyColor,
                        size: _getResponsiveIconSize(context) * 0.7,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        _filterCourses();
                      },
                    )
                  : Container(
                      margin: const EdgeInsets.only(right: 12),
                      child: Icon(
                        Icons.tune_rounded,
                        color: const Color(0xFF10B981).withOpacity(0.7),
                        size: _getResponsiveIconSize(context) * 0.7,
                      ),
                    ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: _getResponsiveHorizontalPadding(context) * 0.5,
                  vertical: _getResponsiveVerticalPadding(context) * 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCategoryPopup(BuildContext context) {
    // Use cached categories provider to avoid unnecessary API calls
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
              'gradient': [const Color(0xFF10B981), const Color(0xFF059669)],
            },
            ...categories.asMap().entries.map((entry) {
              var cat = entry.value;
              final categoryId = cat.id;
              final color = CategoryUtils.getCategoryColor(categoryId, name: cat.name);
              return {
                'name': cat.name,
                'color': color,
                'id': categoryId,
                'icon': CategoryUtils.getCategoryIcon(categoryId, name: cat.name),
                'description': 'Courses in ${cat.name} category',
                'gradient': [color, color.withOpacity(0.8)],
              };
            }),
          ];
          
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
              maxWidth: MediaQuery.of(context).size.width * 0.95,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2937) : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Modern Header with gradient
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF10B981),
                        const Color(0xFF059669),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Handle bar
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.category_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Select Category',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Choose a category to filter courses',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Modern Categories Grid
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    child: GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _getResponsiveCrossAxisCount(context),
                        crossAxisSpacing: _getResponsiveSpacing(context) * 1.2,
                        mainAxisSpacing: _getResponsiveSpacing(context) * 1.2,
                        childAspectRatio: _getResponsiveAspectRatio(context),
                      ),
                      itemCount: allCategories.length,
                      itemBuilder: (context, index) {
                        final category = allCategories[index];
                        final isSelected = _selectedCategory == category['id'];
                        final categoryColor = category['color'] as Color;
                        final gradient = category['gradient'] as List<Color>;
                        
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategory = category['id'] as String;
                            });
                            _filterCourses();
                            Navigator.of(context).pop();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: EdgeInsets.all(_getResponsiveCardPadding(context) * 1.2),
                            decoration: BoxDecoration(
                              gradient: isSelected 
                                  ? LinearGradient(
                                      colors: gradient,
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color: isSelected 
                                  ? null
                                  : (isDark ? const Color(0xFF374151) : const Color(0xFFF9FAFB)),
                              borderRadius: BorderRadius.circular(_getResponsiveBorderRadius(context) * 1.2),
                              border: Border.all(
                                color: isSelected 
                                      ? Colors.transparent
                                      : (isDark ? const Color(0xFF4B5563) : const Color(0xFFE5E7EB)),
                                width: 1.5,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: categoryColor.withOpacity(0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      ),
                                    ]
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: _getResponsiveIconSize(context) * 1.3,
                                  height: _getResponsiveIconSize(context) * 1.3,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: gradient,
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(_getResponsiveIconRadius(context) * 1.2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: categoryColor.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    category['icon'] as IconData,
                                    color: Colors.white,
                                    size: _getResponsiveIconSize(context) * 0.7,
                                  ),
                                ),
                                SizedBox(height: _getResponsiveSpacing(context) * 0.8),
                                Text(
                                  category['name'] as String,
                                  style: TextStyle(
                                    fontSize: _getResponsiveTextSize(context) * 1.1,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected 
                                        ? Colors.white
                                        : AppTheme.getTextColor(context),
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
        loading: () => _buildCategoryLoadingState(context),
        error: (_, __) => _buildCategoryErrorState(context),
      ),
    );
  }

  double _getResponsiveHorizontalPadding(BuildContext context, {double? screenWidth}) {
    screenWidth ??= MediaQuery.of(context).size.width;
    if (screenWidth < 320) {
      return 8; // Ultra small screens
    } else if (screenWidth < 480) {
      return 12; // Small mobile screens
    } else if (screenWidth < 768) {
      return 16; // Standard mobile
    } else if (screenWidth < 1024) {
      return 20; // Tablets
    } else if (screenWidth < 1440) {
      return 24; // Small desktop
    } else {
      return 32; // Large desktop
    }
  }

  double _getResponsiveVerticalPadding(BuildContext context, {double? screenWidth}) {
    screenWidth ??= MediaQuery.of(context).size.width;
    if (screenWidth < 320) {
      return 6; // Ultra small screens
    } else if (screenWidth < 480) {
      return 8; // Small mobile screens
    } else if (screenWidth < 768) {
      return 12; // Standard mobile
    } else if (screenWidth < 1024) {
      return 16; // Tablets
    } else if (screenWidth < 1440) {
      return 20; // Small desktop
    } else {
      return 24; // Large desktop
    }
  }

  int _getResponsiveCrossAxisCount(BuildContext context, {double? screenWidth}) {
    screenWidth ??= MediaQuery.of(context).size.width;
    if (screenWidth < 320) {
      return 1; // Ultra small screens (old phones)
    } else if (screenWidth < 480) {
      return 2; // Small mobile screens
    } else if (screenWidth < 768) {
      return 2; // Standard mobile
    } else if (screenWidth < 1024) {
      return 3; // Tablets
    } else if (screenWidth < 1440) {
      return 4; // Small desktop
    } else {
      return 5; // Large desktop
    }
  }

  double _getResponsiveSpacing(BuildContext context, {double? screenWidth}) {
    screenWidth ??= MediaQuery.of(context).size.width;
    if (screenWidth < 320) {
      return 4; // Ultra small screens
    } else if (screenWidth < 480) {
      return 6; // Small mobile screens
    } else if (screenWidth < 768) {
      return 8; // Standard mobile
    } else if (screenWidth < 1024) {
      return 10; // Tablets
    } else if (screenWidth < 1440) {
      return 12; // Small desktop
    } else {
      return 16; // Large desktop
    }
  }

  double _getResponsiveAspectRatio(BuildContext context, {double? screenWidth}) {
    screenWidth ??= MediaQuery.of(context).size.width;
    if (screenWidth < 320) {
      return 0.9; // Ultra small screens - more square
    } else if (screenWidth < 480) {
      return 1.0; // Small mobile screens
    } else if (screenWidth < 768) {
      return 1.1; // Standard mobile
    } else if (screenWidth < 1024) {
      return 1.2; // Tablets
    } else if (screenWidth < 1440) {
      return 1.3; // Small desktop
    } else {
      return 1.4; // Large desktop
    }
  }

  double _getResponsiveCardPadding(BuildContext context, {double? screenWidth}) {
    screenWidth ??= MediaQuery.of(context).size.width;
    if (screenWidth < 320) {
      return 6; // Ultra small screens
    } else if (screenWidth < 480) {
      return 8; // Small mobile screens
    } else if (screenWidth < 768) {
      return 10; // Standard mobile
    } else if (screenWidth < 1024) {
      return 12; // Tablets
    } else if (screenWidth < 1440) {
      return 14; // Small desktop
    } else {
      return 16; // Large desktop
    }
  }

  double _getResponsiveBorderRadius(BuildContext context, {double? screenWidth}) {
    screenWidth ??= MediaQuery.of(context).size.width;
    if (screenWidth < 320) {
      return 6; // Ultra small screens
    } else if (screenWidth < 480) {
      return 8; // Small mobile screens
    } else if (screenWidth < 768) {
      return 10; // Standard mobile
    } else if (screenWidth < 1024) {
      return 12; // Tablets
    } else if (screenWidth < 1440) {
      return 14; // Small desktop
    } else {
      return 16; // Large desktop
    }
  }

  double _getResponsiveIconSize(BuildContext context, {double? screenWidth}) {
    screenWidth ??= MediaQuery.of(context).size.width;
    if (screenWidth < 320) {
      return 20; // Ultra small screens
    } else if (screenWidth < 480) {
      return 24; // Small mobile screens
    } else if (screenWidth < 768) {
      return 28; // Standard mobile
    } else if (screenWidth < 1024) {
      return 32; // Tablets
    } else if (screenWidth < 1440) {
      return 36; // Small desktop
    } else {
      return 40; // Large desktop
    }
  }

  double _getResponsiveIconRadius(BuildContext context, {double? screenWidth}) {
    screenWidth ??= MediaQuery.of(context).size.width;
    if (screenWidth < 320) {
      return 4; // Ultra small screens
    } else if (screenWidth < 480) {
      return 6; // Small mobile screens
    } else if (screenWidth < 768) {
      return 8; // Standard mobile
    } else if (screenWidth < 1024) {
      return 10; // Tablets
    } else if (screenWidth < 1440) {
      return 12; // Small desktop
    } else {
      return 14; // Large desktop
    }
  }

  double _getResponsiveTextSize(BuildContext context, {double? screenWidth}) {
    screenWidth ??= MediaQuery.of(context).size.width;
    if (screenWidth < 320) {
      return 11; // Ultra small screens
    } else if (screenWidth < 480) {
      return 12; // Small mobile screens
    } else if (screenWidth < 768) {
      return 13; // Standard mobile
    } else if (screenWidth < 1024) {
      return 14; // Tablets
    } else if (screenWidth < 1440) {
      return 15; // Small desktop
    } else {
      return 16; // Large desktop
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
      child: const Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF10B981)),
            SizedBox(height: 20),
            Text(
              'Loading categories...',
              style: TextStyle(
                color: AppTheme.greyColor,
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
      child: const Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFEF4444),
              size: 48,
            ),
            SizedBox(height: 20),
            Text(
              'Failed to load categories',
              style: TextStyle(
                color: AppTheme.greyColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Please try again later',
              style: TextStyle(
                color: AppTheme.greyColor,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernCourseCard(BuildContext context, Course course) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(_getResponsiveBorderRadius(context) * 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => CourseNavigationUtils.navigateToCourse(context, ref, course),
          borderRadius: BorderRadius.circular(_getResponsiveBorderRadius(context) * 1.2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course Image with Overlay
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(_getResponsiveBorderRadius(context) * 1.2),
                          topRight: Radius.circular(_getResponsiveBorderRadius(context) * 1.2),
                        ),
                        color: AppTheme.greyColor.withOpacity(0.1),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(_getResponsiveBorderRadius(context) * 1.2),
                          topRight: Radius.circular(_getResponsiveBorderRadius(context) * 1.2),
                        ),
                        child: course.thumbnail != null && course.thumbnail!.isNotEmpty
                            ? NetworkImageWidget(
                                imageUrl: course.thumbnail!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                placeholder: Container(
                                  color: AppTheme.greyColor.withOpacity(0.1),
                                  child: Icon(
                                    Icons.play_circle_outline,
                                    color: AppTheme.greyColor,
                                    size: _getResponsiveIconSize(context) * 0.8,
                                  ),
                                ),
                              )
                            : Container(
                                color: const Color(0xFF10B981).withOpacity(0.1),
                                child: Icon(
                                  Icons.play_circle_outline,
                                  color: const Color(0xFF10B981),
                                  size: _getResponsiveIconSize(context) * 0.8,
                                ),
                              ),
                      ),
                    ),
                    // Duration Badge
                    Positioned(
                      top: _getResponsiveSpacing(context) * 0.5,
                      right: _getResponsiveSpacing(context) * 0.5,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: _getResponsiveHorizontalPadding(context) * 0.3,
                          vertical: _getResponsiveVerticalPadding(context) * 0.2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time,
                              color: Colors.white,
                              size: _getResponsiveIconSize(context) * 0.4,
                            ),
                            SizedBox(width: _getResponsiveSpacing(context) * 0.2),
                            Text(
                              course.formattedDuration,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: _getResponsiveTextSize(context) * 0.8,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Course Info
              Expanded(
                flex: 2,
                child: Padding(
                  padding: EdgeInsets.all(_getResponsiveCardPadding(context)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Title
                      Text(
                        course.title ?? 'Untitled Course',
                        style: TextStyle(
                          color: AppTheme.getTextColor(context),
                          fontSize: _getResponsiveTextSize(context) * 1.1,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: _getResponsiveSpacing(context) * 0.3),
                      // Instructor
                      Text(
                        'by ${course.displayInstructor}',
                        style: TextStyle(
                          color: AppTheme.getSecondaryTextColor(context),
                          fontSize: _getResponsiveTextSize(context) * 0.9,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: _getResponsiveSpacing(context) * 0.5),
                      // Stats Row
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: _getResponsiveHorizontalPadding(context) * 0.3,
                              vertical: _getResponsiveVerticalPadding(context) * 0.2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  color: const Color(0xFF10B981),
                                  size: _getResponsiveIconSize(context) * 0.4,
                                ),
                                SizedBox(width: _getResponsiveSpacing(context) * 0.2),
                                Text(
                                  '${course.enrollmentCount ?? 0}',
                                  style: TextStyle(
                                    color: const Color(0xFF10B981),
                                    fontSize: _getResponsiveTextSize(context) * 0.8,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
            const SizedBox(height: 12),
            _buildNoCoursesFound(context),
          ],
        ),
      );
    }
    
    // Group courses by category
    final groupedCourses = _groupCoursesByCategory(courses);
    
    // Build slivers for each category
    final slivers = <Widget>[];
    
    for (final entry in groupedCourses.entries) {
      final categoryName = entry.key;
      final categoryCourses = entry.value;
      
      if (categoryCourses.isEmpty) continue;
      
      // Add category header
      slivers.add(SliverToBoxAdapter(
        child: _buildCategoryHeader(context, categoryName, categoryCourses.length),
      ));
      slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 12)));
      
      // Add courses for this category
      if (isDesktop) {
        final gridCount = ResponsiveGridCount(context);
        slivers.add(SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: gridCount.crossAxisCount,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: gridCount.childAspectRatio,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildResponsiveCourseCard(context, categoryCourses[index], enrolledCourses),
            childCount: categoryCourses.length,
          ),
        ));
      } else {
        slivers.add(SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => Container(
              margin: const EdgeInsets.only(bottom: 15),
              child: _buildCourseListItem(context, categoryCourses[index], enrolledCourses),
            ),
            childCount: categoryCourses.length,
          ),
        ));
      }
      
      // Add spacing between categories
      slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 24)));
    }
    
    return SliverMainAxisGroup(
      slivers: slivers,
    );
  }

  Widget _buildCategoryHeader(BuildContext context, String categoryName, int courseCount) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryGreen, Color(0xFF00cdac)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              categoryName,
              style: TextStyle(
                color: Colors.white,
                fontSize: isDesktop ? 16 : 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$courseCount courses',
            style: TextStyle(
              color: AppTheme.greyColor,
              fontSize: isDesktop ? 14 : 12,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, List<Course>> _groupCoursesByCategory(List<Course> courses) {
    final Map<String, List<Course>> grouped = {};
    
    // Define category order - starting with Technical & Digital Coaching
    final categoryOrder = [
      'Digital and Tech coaching',
      'Entrepreneurship & Innovation Hub',
      'Jobseeker Coaching',
      'Laguange coaching',
      'Mental Health & Parental Coaching',
      'Professional Coaching',
    ];
    
    // Initialize all categories in order
    for (final categoryName in categoryOrder) {
      grouped[categoryName] = [];
    }
    
    // Add 'Uncategorized' at the end
    grouped['Uncategorized'] = [];
    
    // Group courses by category
    for (final course in courses) {
      String? categoryName;
      
      // Try to get category name from course.category (populated object)
      if (course.category != null && course.category! is Map<String, dynamic>) {
        final categoryMap = course.category! as Map<String, dynamic>;
        categoryName = categoryMap['name'] as String?;
        
        // Debug logging
        if (categoryName == null) {
          print('Course: ${course.title} - Category object found but no name field: ${categoryMap.keys}');
        }
      }
      
      // If no category name, try to get by categoryId
      if (categoryName == null && course.categoryId != null) {
        // This would require categories data, but for now we'll use a mapping
        final categoryMapping = {
          '69c503cb27858856e87d0027': 'Digital and Tech coaching',
          '69c50aa727858856e87d003f': 'Entrepreneurship & Innovation Hub',
          '69c5067c27858856e87d002f': 'Jobseeker Coaching',
          '69c5017a27858856e87d001f': 'Laguange coaching',
          '69c5116627858856e87d004f': 'Mental Health & Parental Coaching',
          '69c50a3327858856e87d0037': 'Professional Coaching',
        };
        categoryName = categoryMapping[course.categoryId];
        
        // Debug logging
        print('Course: ${course.title} - Using categoryId mapping: ${course.categoryId} -> $categoryName');
      }
      
      // Add to appropriate category
      if (categoryName != null && grouped.containsKey(categoryName)) {
        grouped[categoryName]!.add(course);
      } else {
        grouped['Uncategorized']!.add(course);
      }
    }
    
    // Remove empty categories (except Uncategorized if it has courses)
    final filteredGrouped = <String, List<Course>>{};
    for (final entry in grouped.entries) {
      if (entry.value.isNotEmpty) {
        filteredGrouped[entry.key] = entry.value;
      }
    }
    
    return filteredGrouped;
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
