import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../models/coaching_category.dart';

class CategoryRepository {
  Future<List<CoachingCategory>> getAllCategories() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.categories),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Category API Response: $data');
        final categoriesJson = data['data'] as List;
        print('Categories JSON: $categoriesJson');
        
        final categories = categoriesJson
            .map((json) => CoachingCategory.fromJson(json as Map<String, dynamic>))
            .toList();
        print('Parsed categories: ${categories.length}');
        return categories;
      } else {
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getAllCategories: $e');
      throw Exception('Error fetching categories: $e');
    }
  }

  Future<List<CoachingCategory>> getPopularCategories() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.categories}/popular'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final categoriesJson = data['data'] as List;
        
        return categoriesJson
            .map((json) => CoachingCategory.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to load popular categories: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching popular categories: $e');
    }
  }

  Future<List<CoachingCategory>> getFeaturedCategories() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.categories}/featured'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final categoriesJson = data['data'] as List;
        
        return categoriesJson
            .map((json) => CoachingCategory.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to load featured categories: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching featured categories: $e');
    }
  }
}