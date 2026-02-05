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
}