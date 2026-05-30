import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../config/api_config.dart';

class BookService {
  // Fetch all published books from backend
  Future<List<dynamic>> fetchBooks({
    String? subject,
    String? language,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final idToken = await user.getIdToken(true);

      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (subject != null && subject != 'All') {
        queryParams['subject'] = subject;
      }

      if (language != null && language != 'All') {
        queryParams['language'] = language;
      }

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/books')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data']['books'] as List<dynamic>;
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch books');
        }
      } else {
        throw Exception('Failed to fetch books: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Error fetching books: $error');
    }
  }

  // Get a single book by ID
  Future<dynamic> getBookById(String bookId) async {
    try {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final idToken = await user.getIdToken(true);

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/books/$bookId'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch book');
        }
      } else {
        throw Exception('Failed to fetch book: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Error fetching book: $error');
    }
  }
}
