import '../../models/category.dart';

import '../infrastructure/api_client.dart';
import '../../config/api_config.dart';

/// Service for category-related API operations
class CategoryService {
  final ApiClient _apiClient;

  CategoryService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Get all categories
  Future<List<Category>> getAllCategories() async {
    try {
      final response = await _apiClient.get(ApiConfig.categories);
      response.validateStatus();
      
      final apiResponse = response.toApiResponseList(Category.fromJson);

      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      } else {
        throw ApiException(apiResponse.message);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch categories: $e');
    }
  }

  /// Get popular categories
  Future<List<Category>> getPopularCategories() async {
    try {
      final response = await _apiClient.get('${ApiConfig.categories}/popular');
      response.validateStatus();
      
      final apiResponse = response.toApiResponseList(Category.fromJson);

      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      } else {
        throw ApiException(apiResponse.message);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch popular categories: $e');
    }
  }

  /// Get featured categories
  Future<List<Category>> getFeaturedCategories() async {
    try {
      final response = await _apiClient.get('${ApiConfig.categories}/featured');
      response.validateStatus();
      
      final apiResponse = response.toApiResponseList(Category.fromJson);

      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      } else {
        throw ApiException(apiResponse.message);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch featured categories: $e');
    }
  }

  /// Get categories by level
  Future<List<Category>> getCategoriesByLevel(int level) async {
    try {
      final response = await _apiClient.get('${ApiConfig.categories}/level/$level');
      response.validateStatus();
      
      final apiResponse = response.toApiResponseList(Category.fromJson);

      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      } else {
        throw ApiException(apiResponse.message);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch categories by level: $e');
    }
  }

  /// Get category by ID
  Future<Category> getCategoryById(String id) async {
    try {
      final response = await _apiClient.get('${ApiConfig.categories}/$id');
      response.validateStatus();
      
      final apiResponse = response.toApiResponse(Category.fromJson);
      
      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      } else {
        throw ApiException(apiResponse.message);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch category: $e');
    }
  }

  /// Search categories
  Future<List<Category>> searchCategories(String query) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.categories}/search',
        queryParams: {'query': query},
      );
      response.validateStatus();
      
      final apiResponse = response.toApiResponseList(Category.fromJson);

      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      } else {
        throw ApiException(apiResponse.message);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to search categories: $e');
    }
  }

  /// Create a new category (admin only)
  Future<Category> createCategory({
    required String name,
    String? description,
    String? icon,
    List<String>? subcategories,
    bool? isPopular,
    bool? isFeatured,
    int? level,
  }) async {
    try {
      final requestBody = {
        'name': name,
        if (description != null) 'description': description,
        if (icon != null) 'icon': icon,
        if (subcategories != null) 'subcategories': subcategories,
        if (isPopular != null) 'isPopular': isPopular,
        if (isFeatured != null) 'isFeatured': isFeatured,
        if (level != null) 'level': level,
      };

      final response = await _apiClient.post(
        ApiConfig.categories,
        body: requestBody,
      );

      response.validateStatus();
      final apiResponse = response.toApiResponse(Category.fromJson);
      
      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      } else {
        throw ApiException(apiResponse.message);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to create category: $e');
    }
  }

  /// Update an existing category (admin only)
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
    try {
      final requestBody = <String, dynamic>{
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (icon != null) 'icon': icon,
        if (subcategories != null) 'subcategories': subcategories,
        if (isPopular != null) 'isPopular': isPopular,
        if (isFeatured != null) 'isFeatured': isFeatured,
        if (level != null) 'level': level,
      };

      final response = await _apiClient.put(
        '${ApiConfig.categories}/$id',
        body: requestBody,
      );

      response.validateStatus();
      final apiResponse = response.toApiResponse(Category.fromJson);
      
      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      } else {
        throw ApiException(apiResponse.message);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to update category: $e');
    }
  }

  /// Delete a category (admin only)
  Future<void> deleteCategory(String id) async {
    try {
      final response = await _apiClient.delete('${ApiConfig.categories}/$id');
      response.validateStatus();
      
      final apiResponse = response.toApiResponse((_) => null);
      
      if (!apiResponse.success) {
        throw ApiException(apiResponse.message);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to delete category: $e');
    }
  }

  /// Dispose of resources
  void dispose() {
    _apiClient.dispose();
  }
}
