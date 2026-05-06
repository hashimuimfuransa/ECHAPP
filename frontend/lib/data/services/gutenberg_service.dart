import 'dart:convert';
import 'package:http/http.dart' as http;

class GutenbergService {
  static const String _baseUrl = 'https://gutendex.com/books';
  static const String _apiKey = '6f1287f783msh8f55507f1cfdaedp103856jsncf7ec095c134';
  static const String _rapidApiHost = 'gutendex.com';

  Future<List<Book>> fetchBooks({int page = 1, int limit = 20}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?page=$page&limit=$limit'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        return results.map((book) => Book.fromJson(book)).toList();
      } else {
        throw Exception('Failed to load books: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching books: $e');
    }
  }

  Future<List<Book>> searchBooks(String query, {int page = 1, int limit = 20}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?search=$query&page=$page&limit=$limit'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        return results.map((book) => Book.fromJson(book)).toList();
      } else {
        throw Exception('Failed to search books: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching books: $e');
    }
  }
}

class Book {
  final int id;
  final String title;
  final List<String> authors;
  final List<String> languages;
  final String? coverUrl;
  final int? downloadCount;
  final List<String> subjects;
  final String? copyright;
  final String? mediaType;
  final Map<String, String>? formats;

  Book({
    required this.id,
    required this.title,
    required this.authors,
    required this.languages,
    this.coverUrl,
    this.downloadCount,
    required this.subjects,
    this.copyright,
    this.mediaType,
    this.formats,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    final authors = (json['authors'] as List?)
            ?.map((author) => author['name'] as String)
            .toList() ??
        ['Unknown Author'];
    
    final subjects = (json['subjects'] as List?)
            ?.map((subject) => subject as String)
            .toList() ??
        [];

    String? coverUrl;
    Map<String, String>? formats;
    
    if (json['formats'] != null) {
      final formatsData = json['formats'] as Map<String, dynamic>;
      coverUrl = formatsData['image/jpeg'] as String?;
      
      // Convert formats map to handle both string and boolean values
      formats = <String, String>{};
      formatsData.forEach((key, value) {
        if (value is String) {
          formats![key] = value;
        } else if (value is bool) {
          formats![key] = value.toString();
        } else if (value != null) {
          formats![key] = value.toString();
        }
      });
    }

    return Book(
      id: json['id'] as int,
      title: json['title'] as String,
      authors: authors,
      languages: (json['languages'] as List?)?.map((lang) => lang.toString()).toList() ?? ['en'],
      coverUrl: coverUrl,
      downloadCount: json['download_count'] as int?,
      subjects: subjects,
      copyright: json['copyright']?.toString(),
      mediaType: json['media_type']?.toString(),
      formats: formats,
    );
  }

  String get displayAuthor => authors.isNotEmpty ? authors[0] : 'Unknown Author';
  String get displaySubjects => subjects.take(3).join(', ');
}
