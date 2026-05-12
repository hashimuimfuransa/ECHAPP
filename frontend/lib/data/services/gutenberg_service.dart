import 'dart:convert';
import 'package:http/http.dart' as http;

class GutenbergService {
  static const String _baseUrl = 'https://gutendex.com/books';
  static const String _apiKey = '6f1287f783msh8f55507f1cfdaedp103856jsncf7ec095c134';
  static const String _rapidApiHost = 'gutendex.com';

  // Academic subjects and categories
  static const List<String> _academicSubjects = [
    'Science',
    'Mathematics',
    'Physics',
    'Chemistry',
    'Biology',
    'Medicine',
    'Engineering',
    'Computer Science',
    'Philosophy',
    'History',
    'Literature',
    'Psychology',
    'Sociology',
    'Economics',
    'Political Science',
    'Education',
    'Law',
    'Business',
    'Technology',
    'Religion',
    'Art',
    'Music',
    'Linguistics',
    'Anthropology',
    'Geography',
    'Archaeology',
    'Astronomy',
    'Geology',
    'Botany',
    'Zoology'
  ];

  // Priority subjects for better subject coverage
  static const List<String> _prioritySubjects = [
    'Computer Science', // ICT
    'Mathematics',     // Math
    'Science',          // General Science
    'Physics',         // Science
    'Chemistry',       // Science
    'Biology',         // Science
    'Geography',       // Geography
    'Technology',      // ICT
    'Engineering',     // ICT/Math
  ];

  // Subject mappings for better matching
  static const Map<String, List<String>> _subjectMappings = {
    'ICT': ['Computer Science', 'Technology', 'Information Technology', 'Programming', 'Software', 'Computing'],
    'Math': ['Mathematics', 'Algebra', 'Geometry', 'Calculus', 'Statistics', 'Trigonometry'],
    'Science': ['Science', 'Physics', 'Chemistry', 'Biology', 'Botany', 'Zoology', 'Astronomy'],
    'Geography': ['Geography', 'Cartography', 'Topography', 'Geology'],
  };

  static const List<String> _academicKeywords = [
    'textbook',
    'handbook',
    'manual',
    'guide',
    'introduction',
    'principles',
    'theory',
    'methods',
    'studies',
    'research',
    'academic',
    'scholar',
    'university',
    'college',
    'education',
    'learning',
    'course',
    'lecture',
    'treatise',
    'dissertation',
    'thesis'
  ];

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

  // Fetch academic books prioritized by academic subjects
  Future<List<Book>> fetchAcademicBooks({int page = 1, int limit = 20}) async {
    try {
      // Prioritize fetching from priority subjects first
      final academicBooks = <Book>[];
      
      // Fetch books from priority subjects to ensure good coverage
      for (final subject in _prioritySubjects) {
        if (academicBooks.length >= limit) break;
        
        try {
          final response = await http.get(
            Uri.parse('$_baseUrl?topic=$subject&page=$page&limit=${(limit ~/ _prioritySubjects.length) + 2}'),
          );
          
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            final results = data['results'] as List;
            final books = results.map((book) => Book.fromJson(book)).toList();
            academicBooks.addAll(books);
          }
        } catch (e) {
          print('Error fetching books for subject $subject: $e');
          continue;
        }
      }
      
      // If we still don't have enough books, fetch general academic books
      if (academicBooks.length < limit) {
        final fetchLimit = (limit - academicBooks.length) * 2;
        final response = await http.get(
          Uri.parse('$_baseUrl?page=$page&limit=$fetchLimit'),
        );
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final results = data['results'] as List;
          final allBooks = results.map((book) => Book.fromJson(book)).toList();
          
          // Filter for academic books
          final filteredBooks = allBooks.where(_isAcademicBook).toList();
          academicBooks.addAll(filteredBooks);
        }
      }
      
      // Remove duplicates and sort by academic relevance
      final uniqueBooks = _removeDuplicateBooks(academicBooks);
      uniqueBooks.sort((a, b) {
        final aScore = _calculateAcademicScore(a);
        final bScore = _calculateAcademicScore(b);
        
        if (aScore != bScore) {
          return bScore.compareTo(aScore);
        }
        
        return (b.downloadCount ?? 0).compareTo(a.downloadCount ?? 0);
      });
      
      return uniqueBooks.take(limit).toList();
    } catch (e) {
      throw Exception('Error fetching academic books: $e');
    }
  }

  // Remove duplicate books based on ID
  List<Book> _removeDuplicateBooks(List<Book> books) {
    final seen = <int>{};
    final unique = <Book>[];
    
    for (final book in books) {
      if (!seen.contains(book.id)) {
        seen.add(book.id);
        unique.add(book);
      }
    }
    
    return unique;
  }

  // Search books by specific subject (ICT, Math, Science, Geography)
  Future<List<Book>> searchBySubject(String subject, {int page = 1, int limit = 20}) async {
    try {
      final searchTerms = _subjectMappings[subject.toUpperCase()] ?? [subject];
      final books = <Book>[];
      
      for (final term in searchTerms) {
        if (books.length >= limit) break;
        
        try {
          final response = await http.get(
            Uri.parse('$_baseUrl?topic=$term&page=$page&limit=${(limit ~/ searchTerms.length) + 2}'),
          );
          
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            final results = data['results'] as List;
            final termBooks = results.map((book) => Book.fromJson(book)).toList();
            books.addAll(termBooks);
          }
        } catch (e) {
          print('Error searching for term $term: $e');
          continue;
        }
      }
      
      // Remove duplicates and sort
      final uniqueBooks = _removeDuplicateBooks(books);
      uniqueBooks.sort((a, b) => (b.downloadCount ?? 0).compareTo(a.downloadCount ?? 0));
      
      return uniqueBooks.take(limit).toList();
    } catch (e) {
      throw Exception('Error searching by subject $subject: $e');
    }
  }

  // Search books by academic subject
  Future<List<Book>> searchByAcademicSubject(String subject, {int page = 1, int limit = 20}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?topic=$subject&page=$page&limit=$limit'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        final books = results.map((book) => Book.fromJson(book)).toList();
        
        // Filter and sort by academic relevance
        final academicBooks = books.where(_isAcademicBook).toList();
        academicBooks.sort((a, b) => (b.downloadCount ?? 0).compareTo(a.downloadCount ?? 0));
        
        return academicBooks;
      } else {
        throw Exception('Failed to search academic books: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching academic books: $e');
    }
  }

  // Get academic categories for filtering
  List<String> getAcademicCategories() {
    return List.from(_academicSubjects);
  }

  // Check if a book is academic
  bool _isAcademicBook(Book book) {
    final titleLower = book.title.toLowerCase();
    final subjectsLower = book.subjects.map((s) => s.toLowerCase()).join(' ');
    
    // Check if any academic subject is in the book's subjects
    final hasAcademicSubject = book.subjects.any((subject) =>
        _academicSubjects.any((academicSubject) =>
            subject.toLowerCase().contains(academicSubject.toLowerCase())));
    
    // Check if any academic keyword is in title or subjects
    final hasAcademicKeyword = _academicKeywords.any((keyword) =>
        titleLower.contains(keyword) || subjectsLower.contains(keyword));
    
    // Bonus for priority subjects
    final hasPrioritySubject = book.subjects.any((subject) =>
        _prioritySubjects.any((prioritySubject) =>
            subject.toLowerCase().contains(prioritySubject.toLowerCase())));
    
    return hasAcademicSubject || hasAcademicKeyword || hasPrioritySubject;
  }

  // Calculate academic relevance score
  int _calculateAcademicScore(Book book) {
    int score = 0;
    final titleLower = book.title.toLowerCase();
    final subjectsLower = book.subjects.map((s) => s.toLowerCase()).join(' ');
    
    // Score for academic subjects
    for (final subject in _academicSubjects) {
      if (subjectsLower.contains(subject.toLowerCase())) {
        score += 10;
      }
    }
    
    // Score for academic keywords
    for (final keyword in _academicKeywords) {
      if (titleLower.contains(keyword)) {
        score += 5;
      }
      if (subjectsLower.contains(keyword)) {
        score += 3;
      }
    }
    
    // Bonus for high download count (indicates quality/relevance)
    if (book.downloadCount != null && book.downloadCount! > 1000) {
      score += 2;
    }
    
    return score;
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
