import 'package:http/http.dart' as http;
import 'frontend/lib/data/services/gutenberg_service.dart';

void main() async {
  print('Testing Gutenberg Service fix...');
  
  try {
    final service = GutenbergService();
    final books = await service.fetchBooks(limit: 5);
    
    print('✅ Successfully fetched ${books.length} books');
    
    for (int i = 0; i < books.length; i++) {
      final book = books[i];
      print('\nBook ${i + 1}:');
      print('  Title: ${book.title}');
      print('  Author: ${book.displayAuthor}');
      print('  Languages: ${book.languages.join(', ')}');
      print('  Formats count: ${book.formats?.length ?? 0}');
      
      if (book.formats != null && book.formats!.isNotEmpty) {
        print('  Sample formats:');
        book.formats!.entries.take(3).forEach((entry) {
          print('    ${entry.key}: ${entry.value}');
        });
      }
    }
    
    print('\n🎉 Test completed successfully!');
    
  } catch (e, stackTrace) {
    print('❌ Error: $e');
    print('Stack trace: $stackTrace');
  }
}
