import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellence_coaching_hub/config/app_theme.dart';
import 'package:excellence_coaching_hub/services/categories_service.dart';
import 'package:excellence_coaching_hub/data/models/coaching_category.dart';
import 'package:excellence_coaching_hub/presentation/providers/course_provider.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final popularCategories = CategoriesService.getPopularCategories(categories);
    final featuredCategories = CategoriesService.getFeaturedCategories(categories);

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
                      // Featured Categories
                      if (featuredCategories.isNotEmpty) ...[
                        _buildSectionTitle(context, '⭐ Featured Categories'),
                        const SizedBox(height: 15),
                        _buildCategoryGrid(context, featuredCategories),
                        const SizedBox(height: 30),
                      ],
                      
                      // Popular Categories
                      if (popularCategories.isNotEmpty) ...[
                        _buildSectionTitle(context, '⭐ Popular Categories'),
                        const SizedBox(height: 15),
                        _buildCategoryList(context, popularCategories),
                        const SizedBox(height: 30),
                      ],
                      
                      // All Categories by Level
                      _buildSectionTitle(context, 'All Categories'),
                      const SizedBox(height: 15),
                      
                      // Level 1 - All levels
                      _buildLevelSection(context, categories, 1, '🎓 All Levels'),
                      const SizedBox(height: 20),
                      
                      // Level 2 - Fluency
                      _buildLevelSection(context, categories, 2, '💬 Fluency'),
                      const SizedBox(height: 20),
                      
                      // Level 3 - In-demand
                      _buildLevelSection(context, categories, 3, '🔥 In-demand'),
                      const SizedBox(height: 20),
                      
                      // Level 4 - Career-ready
                      _buildLevelSection(context, categories, 4, '🎯 Career-ready'),
                      const SizedBox(height: 20),
                      
                      // Level 5 - Growth
                      _buildLevelSection(context, categories, 5, '🌱 Growth'),
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
            'Coaching Categories',
            style: TextStyle(
              color: Theme.of(context).textTheme.headlineSmall?.color,
              fontSize: 22,
              fontWeight: FontWeight.bold,
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
      style: TextStyle(
        color: Theme.of(context).textTheme.titleLarge?.color,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildCategoryGrid(BuildContext context, List<CoachingCategory> categories) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 1.2,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _buildCategoryCard(context, category);
      },
    );
  }

  Widget _buildCategoryList(BuildContext context, List<CoachingCategory> categories) {
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

  Widget _buildLevelSection(BuildContext context, List<CoachingCategory> allCategories, int level, String title) {
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
        onTap: () => _navigateToCategory(context, category),
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                category.icon,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(height: 10),
              Text(
                category.name,
                style: TextStyle(
                  color: Theme.of(context).textTheme.titleMedium?.color,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 5),
              Text(
                '${category.subcategories.length} subcategories',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
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

  Widget _buildCategoryListItem(BuildContext context, dynamic category) {
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
      child: ListTile(
        onTap: () => _navigateToCategory(context, category),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              category.icon,
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
        title: Text(
          category.name,
          style: TextStyle(
            color: Theme.of(context).textTheme.titleMedium?.color,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              category.description,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: 13,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              '${category.subcategories.length} subcategories • ${category.subcategories.join(', ')}',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Theme.of(context).iconTheme.color,
          size: 16,
        ),
        contentPadding: const EdgeInsets.all(15),
      ),
    );
  }

  void _navigateToCategory(BuildContext context, dynamic category) {
    // Navigate to courses screen filtered by this category
    context.push('/courses', extra: {
      'categoryId': category.id, 
      'categoryName': category.name
    });
  }
}