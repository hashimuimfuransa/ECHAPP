import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/services/categories_service.dart';
import 'package:excellencecoachinghub/models/category.dart';
import 'package:excellencecoachinghub/presentation/providers/course_provider.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get backend categories
    final backendCategories = ref.watch(backendCategoriesProvider);
    
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
                child: backendCategories.when(
                  data: (categories) {
                    // Filter featured and popular categories from backend data
                    final featuredCategories = categories.where((cat) => cat.isFeatured ?? false).toList();
                    final popularCategories = categories.where((cat) => cat.isPopular ?? false).toList();
                    
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Featured Categories
                          if (featuredCategories.isNotEmpty) ...[
                            _buildSectionTitle(context, 'Featured Categories'),
                            const SizedBox(height: 15),
                            ResponsiveBreakpoints.isDesktop(context) 
                              ? _buildCategoryGrid(context, featuredCategories) 
                              : _buildCategoryHorizontalList(context, featuredCategories),
                            const SizedBox(height: 30),
                          ],
                          
                          // Popular Categories
                          if (popularCategories.isNotEmpty) ...[
                            _buildSectionTitle(context, 'Popular Categories'),
                            const SizedBox(height: 15),
                            _buildCategoryList(context, popularCategories),
                            const SizedBox(height: 30),
                          ],
                          
                          // All Categories
                          _buildSectionTitle(context, 'All Categories'),
                          const SizedBox(height: 15),
                          _buildCategoryGrid(context, categories),
                        ],
                      ),
                    );
                  },
                  loading: () {
                    return const Center(child: CircularProgressIndicator());
                  },
                  error: (error, stack) {
                    // Fallback to predefined categories if backend fails
                    final categories = CategoriesService.getAllCategories();
                    final featuredCategories = CategoriesService.getFeaturedCategories(categories);
                    final popularCategories = CategoriesService.getPopularCategories(categories);
                    
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Featured Categories
                          if (featuredCategories.isNotEmpty) ...[
                            _buildSectionTitle(context, 'Featured Categories'),
                            const SizedBox(height: 15),
                            ResponsiveBreakpoints.isDesktop(context) 
                              ? _buildCategoryGrid(context, featuredCategories) 
                              : _buildCategoryHorizontalList(context, featuredCategories),
                            const SizedBox(height: 30),
                          ],
                          
                          // Popular Categories
                          if (popularCategories.isNotEmpty) ...[
                            _buildSectionTitle(context, 'Popular Categories'),
                            const SizedBox(height: 15),
                            _buildCategoryList(context, popularCategories),
                            const SizedBox(height: 30),
                          ],
                          
                          // All Categories
                          _buildSectionTitle(context, 'All Categories'),
                          const SizedBox(height: 15),
                          _buildCategoryGrid(context, categories),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
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
              color: AppTheme.blackColor, 
              size: 24),
          ),
          const Text(
            'Coaching Categories',
            style: TextStyle(
              color: AppTheme.blackColor,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppTheme.blackColor,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildCategoryGrid(BuildContext context, List<Category> categories) {
    final gridCount = ResponsiveGridCount(context);
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridCount.crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: gridCount.childAspectRatio,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _buildCategoryCard(context, category);
      },
    );
  }

  Widget _buildCategoryList(BuildContext context, List<Category> categories) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      separatorBuilder: (context, index) => const SizedBox(height: 15),
      itemBuilder: (context, index) {
        final category = categories[index];
        return _buildCategoryListItem(context, category);
      },
    );
  }

  Widget _buildLevelSection(BuildContext context, List<Category> allCategories, int level, String title) {
    final levelCategories = CategoriesService.getCategoriesByLevel(allCategories, level);
    if (levelCategories.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Theme.of(context).textTheme.titleMedium?.color,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: levelCategories.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final category = levelCategories[index];
            return _buildCategoryListItem(context, category);
          },
        ),
      ],
    );
  }

  Widget _buildCategoryCard(BuildContext context, dynamic category) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _navigateToCategory(context, category),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    category.icon,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                category.name,
                style: const TextStyle(
                  color: AppTheme.blackColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                '${category.subcategories.length} courses',
                style: TextStyle(
                  color: AppTheme.greyColor,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryListItem(BuildContext context, dynamic category) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.whiteColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.greyColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ListTile(
        onTap: () => _navigateToCategory(context, category),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              category.icon,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        title: Text(
          category.name,
          style: const TextStyle(
            color: AppTheme.blackColor,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            category.description,
            style: TextStyle(
              color: AppTheme.greyColor,
              fontSize: 13,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: AppTheme.greyColor,
          size: 16,
        ),
      ),
    );
  }

  Widget _buildCategoryHorizontalList(BuildContext context, List<Category> categories) {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return Container(
            margin: EdgeInsets.only(
              right: 15,
              left: index == 0 ? 0 : 0,
            ),
            width: 160,
            child: _buildCategoryCard(context, category),
          );
        },
      ),
    );
  }

  void _navigateToCategory(BuildContext context, dynamic category) {
    // Navigate to courses screen filtered by this category
    context.push('/courses', extra: {
      'categoryId': category.id,
      'categoryName': category.name,
    });
  }
}
