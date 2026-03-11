import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/services/categories_service.dart';
import 'package:excellencecoachinghub/models/category.dart';
import 'package:excellencecoachinghub/presentation/providers/course_provider.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';
import 'package:excellencecoachinghub/utils/category_utils.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backendCategories = ref.watch(backendCategoriesProvider);
    final spacing = ResponsiveBreakpoints.getSpacing(context);
    final padding = ResponsiveBreakpoints.getPadding(context);
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: backendCategories.when(
          data: (categories) => _buildMainContent(context, categories, padding, spacing),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) {
            final categories = CategoriesService.getAllCategories();
            return _buildMainContent(context, categories, padding, spacing);
          },
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, List<dynamic> categories, EdgeInsets padding, double spacing) {
    return SingleChildScrollView(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          SizedBox(height: spacing),
          _buildCategoryGrid(context, categories),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Explore Categories',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppTheme.blackColor,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Find the perfect course to advance your career and skills.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.greyColor,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryGrid(BuildContext context, List<dynamic> categories) {
    final gridCount = ResponsiveGridCount(context);
    
    // Modern soft color palette for categories
    final List<Color> cardColors = [
      const Color(0xFF10B981), // Emerald
      const Color(0xFF3B82F6), // Blue
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFFF59E0B), // Amber
      const Color(0xFFEF4444), // Red/Rose
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFFF97316), // Orange
      const Color(0xFFEC4899), // Pink
    ];

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
        final categoryColor = cardColors[index % cardColors.length];
        return _buildCategoryCard(context, categories[index], categoryColor);
      },
    );
  }

  Widget _buildCategoryCard(BuildContext context, dynamic category, Color color) {
    final icon = CategoryUtils.getCategoryIcon(category.id, name: category.name);
    final cardColor = CategoryUtils.getCategoryColor(category.id, name: category.name);
    
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: cardColor.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: cardColor.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToCategory(context, category),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: cardColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      size: 32,
                      color: cardColor,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  category.name,
                  style: const TextStyle(
                    color: AppTheme.blackColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: cardColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${category.subcategories.length} Topics',
                    style: TextStyle(
                      color: cardColor.withOpacity(0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
