import 'package:flutter_test/flutter_test.dart';
import 'package:excellencecoachinghub/data/services/gutenberg_service.dart';

void main() {
  group('Library Tests', () {
    test('Book.fromJson handles mixed format types', () {
      // Test data that simulates the problematic API response
      final testBookData = {
        'id': 123,
        'title': 'Test Book',
        'authors': [{'name': 'Test Author'}],
        'languages': ['en'],
        'subjects': ['Fiction', 'Test'],
        'formats': {
          'application/pdf': 'https://example.com/book.pdf',
          'application/epub': true,  // This boolean was causing the error
          'text/html': 'https://example.com/book.html',
          'text/plain': false,  // Another boolean value
        },
        'download_count': 100,
        'copyright': true,  // Boolean copyright field
        'media_type': 'text',
      };

      // This should not throw an exception anymore
      expect(() => Book.fromJson(testBookData), returnsNormally);

      final book = Book.fromJson(testBookData);
      
      expect(book.id, 123);
      expect(book.title, 'Test Book');
      expect(book.displayAuthor, 'Test Author');
      expect(book.languages, ['en']);
      expect(book.formats, isNotNull);
      expect(book.formats!.length, 4);
      expect(book.formats!['application/epub'], 'true');  // Boolean converted to string
      expect(book.formats!['text/plain'], 'false');     // Boolean converted to string
      expect(book.formats!['application/pdf'], 'https://example.com/book.pdf');
      expect(book.copyright, 'true');  // Boolean converted to string
    });

    test('Book.fromJson handles null formats', () {
      final testBookData = {
        'id': 456,
        'title': 'Test Book 2',
        'authors': [],
        'languages': ['en'],
        'subjects': [],
        'download_count': 50,
      };

      final book = Book.fromJson(testBookData);
      
      expect(book.id, 456);
      expect(book.formats, isNull);
      expect(book.displayAuthor, 'Unknown Author');
    });

    test('Book.fromJson handles missing fields', () {
      final testBookData = {
        'id': 789,
        'title': 'Minimal Book',
        'authors': [{'name': 'Minimal Author'}],
        'languages': [],
        'subjects': [],
      };

      final book = Book.fromJson(testBookData);
      
      expect(book.id, 789);
      expect(book.title, 'Minimal Book');
      expect(book.downloadCount, isNull);
      expect(book.copyright, isNull);
      expect(book.mediaType, isNull);
    });
  });
}
