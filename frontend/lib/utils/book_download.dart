import 'package:excellencecoachinghub/data/services/gutenberg_service.dart';
import 'package:excellencecoachinghub/models/download.dart';

/// Everything needed to hand a library book to `DownloadService`.
///
/// Books come from two places — Project Gutenberg ([Book]) and admin uploads
/// (a raw JSON map) — and both the Library grid and the book reader need to
/// agree on the download's identity, otherwise the same book would download
/// twice and neither screen would see the other's progress.
class BookDownloadTarget {
  const BookDownloadTarget({
    required this.url,
    required this.fileExtension,
    required this.lessonId,
    required this.title,
    this.author,
    this.coverUrl,
  });

  /// Direct link to the book file.
  final String url;

  /// Extension to store the file under (".pdf", ".txt", …). Gutenberg links
  /// like ".../1234.txt.utf-8" can't be sniffed from the URL alone.
  final String fileExtension;

  /// The id passed to `DownloadService` as `lessonId`.
  final String lessonId;

  final String title;
  final String? author;

  /// The book's cover art, saved with the download so Downloads can show the
  /// real cover instead of a generic file icon.
  final String? coverUrl;

  /// Key of the resulting record in `DownloadService`, i.e. `Download.id`.
  String get downloadId => '${DownloadType.material.name}_$lessonId';
}

/// Formats worth downloading, best first. Anything not listed (cover images,
/// RDF metadata, mobipocket) is skipped.
const Map<String, String> _downloadableFormats = {
  'application/pdf': '.pdf',
  'text/plain': '.txt',
  'application/epub+zip': '.epub',
  'text/html': '.html',
};

/// Resolves [book] — a Gutenberg [Book] or an admin book map — into something
/// downloadable, or null when the book has no usable file.
BookDownloadTarget? resolveBookDownload(dynamic book) {
  if (book is Book) {
    final format = _pickGutenbergFormat(book);
    if (format == null) return null;
    return BookDownloadTarget(
      url: format.key,
      fileExtension: format.value,
      lessonId: 'book_${book.id}',
      title: book.title,
      author: book.displayAuthor,
      coverUrl: book.coverUrl,
    );
  }

  if (book is Map) {
    final url = _firstNonEmpty(book, const [
      'pdfUrl',
      'fileUrl',
      'url',
      'downloadUrl',
      'file_url',
      'download_url',
    ]);
    if (url == null) return null;

    final id = book['id']?.toString() ?? book['_id']?.toString();
    if (id == null || id.isEmpty) return null;

    return BookDownloadTarget(
      url: url,
      fileExtension: _extensionFromUrl(url),
      lessonId: 'book_$id',
      title: book['title']?.toString() ?? book['name']?.toString() ?? 'Untitled',
      author: book['author']?.toString(),
      coverUrl: _firstNonEmpty(book, const ['coverUrl', 'cover', 'thumbnail', 'imageUrl']),
    );
  }

  return null;
}

/// Picks the most readable format Gutenberg offers for [book], as a
/// url → extension pair.
MapEntry<String, String>? _pickGutenbergFormat(Book book) {
  final formats = book.formats;
  if (formats == null || formats.isEmpty) return null;

  final ranked = _downloadableFormats.keys.toList();
  MapEntry<String, String>? best;
  int bestRank = ranked.length;

  formats.forEach((mimeType, url) {
    if (url.isEmpty) return;
    // Gutenberg publishes zipped variants under the same mime types; they can't
    // be read without unpacking, so keep looking.
    if (Uri.tryParse(url)?.path.toLowerCase().endsWith('.zip') ?? false) return;

    final baseMime = mimeType.split(';').first.trim().toLowerCase();
    final rank = ranked.indexOf(baseMime);
    if (rank == -1 || rank >= bestRank) return;

    bestRank = rank;
    best = MapEntry(url, _downloadableFormats[baseMime]!);
  });

  return best;
}

String? _firstNonEmpty(Map book, List<String> keys) {
  for (final key in keys) {
    final value = book[key]?.toString();
    if (value != null && value.isNotEmpty) return value;
  }
  return null;
}

String _extensionFromUrl(String url) {
  final path = (Uri.tryParse(url)?.path ?? url).toLowerCase();
  for (final extension in const ['.pdf', '.epub', '.txt', '.md', '.docx', '.doc', '.html']) {
    if (path.endsWith(extension)) return extension;
  }
  return '.pdf';
}
