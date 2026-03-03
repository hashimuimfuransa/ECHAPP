import '../../services/api/category_service.dart';
import '../../models/category.dart';

class CategoryRepository {
  final CategoryService _categoryService;

  CategoryRepository({CategoryService? categoryService}) 
      : _categoryService = categoryService ?? CategoryService();

  Future<List<Category>> getAllCategories() async {
    return await _categoryService.getAllCategories();
  }

  Future<List<Category>> getPopularCategories() async {
    return await _categoryService.getPopularCategories();
  }

  Future<List<Category>> getFeaturedCategories() async {
    return await _categoryService.getFeaturedCategories();
  }

  Future<List<Category>> getCategoriesByLevel(int level) async {
    return await _categoryService.getCategoriesByLevel(level);
  }

  Future<Category> getCategoryById(String id) async {
    return await _categoryService.getCategoryById(id);
  }

  Future<List<Category>> searchCategories(String query) async {
    return await _categoryService.searchCategories(query);
  }

  Future<Category> createCategory({
    required String name,
    String? description,
    String? icon,
    List<String>? subcategories,
    bool? isPopular,
    bool? isFeatured,
    int? level,
  }) async {
    return await _categoryService.createCategory(
      name: name,
      description: description,
      icon: icon,
      subcategories: subcategories,
      isPopular: isPopular,
      isFeatured: isFeatured,
      level: level,
    );
  }

  Future<Category> updateCategory({
    required String id,
    String? name,
    String? description,
    String? icon,
    List<String>? subcategories,
    bool? isPopular,
    bool? isFeatured,
    int? level,
  }) async {
    return await _categoryService.updateCategory(
      id: id,
      name: name,
      description: description,
      icon: icon,
      subcategories: subcategories,
      isPopular: isPopular,
      isFeatured: isFeatured,
      level: level,
    );
  }

  Future<void> deleteCategory(String id) async {
    await _categoryService.deleteCategory(id);
  }
}
