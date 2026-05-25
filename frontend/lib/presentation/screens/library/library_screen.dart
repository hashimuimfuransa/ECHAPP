import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/data/services/gutenberg_service.dart';
import 'package:excellencecoachinghub/presentation/screens/library/book_reader_screen.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  List<Book> _allBooks = [];
  List<Book> _filteredBooks = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _errorMessage;
  final GutenbergService _gutenbergService = GutenbergService();
  final TextEditingController _searchController = TextEditingController();
  String _selectedLanguage = 'All';
  String _selectedSubject = 'All';
  bool _showFilters = false;
  final ScrollController _scrollController = ScrollController();
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    // Load initial books with microtask for better performance
    Future.microtask(() => _loadInitialBooks());
    _scrollController.addListener(_onScroll);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Library',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.getTextColor(context),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Browse all available courses',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.getSecondaryTextColor(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1F2937) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _filterBooks,
                      decoration: InputDecoration(
                        hintText: 'Search books...',
                        hintStyle: TextStyle(
                          color: AppTheme.getSecondaryTextColor(context),
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: AppTheme.getSecondaryTextColor(context),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showFilters ? Icons.tune_rounded : Icons.tune_outlined,
                            color: _showFilters ? const Color(0xFF10B981) : AppTheme.getSecondaryTextColor(context),
                          ),
                          onPressed: () {
                            setState(() {
                              _showFilters = !_showFilters;
                            });
                          },
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Filters
            if (_showFilters) _buildFilters(context),
            // Content
            Expanded(
              child: _isLoading && _allBooks.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF10B981)),
                    )
                  : _errorMessage != null && _allBooks.isEmpty
                      ? _buildErrorWidget()
                      : _buildCoursesList(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: const Color(0xFFEF4444),
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading courses',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.getTextColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Something went wrong',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.getSecondaryTextColor(context),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadInitialBooks,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allLanguages = <String>[
      'All',
      ..._allBooks
          .where((book) => book.languages.isNotEmpty)
          .map((book) => book.languages.first as String)
          .where((lang) => lang.isNotEmpty)
          .toSet()
    ];
    
    // Use academic categories from the service with priority subjects first
    final academicCategories = <String>[
      'All Academic',
      'ICT',
      'Math',
      'Science',
      'Geography',
      ..._gutenbergService.getAcademicCategories()
    ];
    
    final allSubjects = <String>[
      'All',
      ..._allBooks
          .where((book) => book.subjects.isNotEmpty)
          .map((book) => book.subjects.first as String)
          .where((subj) => subj.isNotEmpty)
          .toSet()
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filters',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.getTextColor(context),
                ),
              ),
              TextButton(
                onPressed: _resetFilters,
                child: Text(
                  'Reset',
                  style: TextStyle(
                    color: const Color(0xFF10B981),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Language Filter
          Text(
            'Language',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.getTextColor(context),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: allLanguages.length,
              itemBuilder: (context, index) {
                final language = allLanguages[index];
                final isSelected = _selectedLanguage == language;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(language),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedLanguage = language;
                        _applyFilters();
                      });
                    },
                    backgroundColor: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
                    selectedColor: const Color(0xFF10B981).withOpacity(0.2),
                    checkmarkColor: const Color(0xFF10B981),
                    labelStyle: TextStyle(
                      color: isSelected 
                          ? const Color(0xFF10B981) 
                          : AppTheme.getTextColor(context),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Academic Category Filter
          Text(
            'Academic Category',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.getTextColor(context),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: academicCategories.length,
              itemBuilder: (context, index) {
                final category = academicCategories[index];
                final isSelected = _selectedSubject == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category.length > 15 ? category.substring(0, 15) + '...' : category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedSubject = category;
                        _applyFilters();
                      });
                    },
                    backgroundColor: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
                    selectedColor: const Color(0xFF10B981).withOpacity(0.2),
                    checkmarkColor: const Color(0xFF10B981),
                    labelStyle: TextStyle(
                      color: isSelected 
                          ? const Color(0xFF10B981) 
                          : AppTheme.getTextColor(context),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Subject Filter
          Text(
            'General Subject',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.getTextColor(context),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: allSubjects.length,
              itemBuilder: (context, index) {
                final subject = allSubjects[index];
                final isSelected = _selectedSubject == subject;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(subject.length > 15 ? subject.substring(0, 15) + '...' : subject),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedSubject = subject;
                        _applyFilters();
                      });
                    },
                    backgroundColor: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
                    selectedColor: const Color(0xFF10B981).withOpacity(0.2),
                    checkmarkColor: const Color(0xFF10B981),
                    labelStyle: TextStyle(
                      color: isSelected 
                          ? const Color(0xFF10B981) 
                          : AppTheme.getTextColor(context),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoursesList(BuildContext context) {
    if (_filteredBooks.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.library_books_rounded,
              color: AppTheme.getSecondaryTextColor(context),
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _allBooks.isEmpty ? 'No books available' : 'No books found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.getTextColor(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _allBooks.isEmpty ? 'Check back later for new books' : 'Try adjusting your filters',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.getSecondaryTextColor(context),
              ),
            ),
            if (_allBooks.isNotEmpty && _filteredBooks.isEmpty) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _resetFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Clear Filters'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshBooks,
      color: const Color(0xFF10B981),
      child: GridView.builder(
        controller: _scrollController,
        padding: ResponsiveBreakpoints.getPadding(context),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: ResponsiveBreakpoints.isDesktop(context) ? 3 : 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        itemCount: _filteredBooks.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _filteredBooks.length && _hasMore) {
            return _buildLoadingIndicator();
          }
          return _buildBookCard(context, _filteredBooks[index]);
        },
      ),
    );
  }

  Widget _buildBookCard(BuildContext context, Book book) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        _openBook(context, book);
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book Cover
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: book.coverUrl != null && book.coverUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: book.coverUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: const Color(0xFF10B981).withOpacity(0.1),
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Center(
                            child: Icon(
                              Icons.menu_book_rounded,
                              color: const Color(0xFF10B981),
                              size: 48,
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Icon(
                          Icons.menu_book_rounded,
                          color: const Color(0xFF10B981),
                          size: 48,
                        ),
                      ),
              ),
            ),
            // Book Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.getTextColor(context),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.displayAuthor,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.getSecondaryTextColor(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          Icons.download_rounded,
                          color: const Color(0xFF10B981),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${book.downloadCount ?? 0}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.getSecondaryTextColor(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (book.languages.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.language_rounded,
                            color: const Color(0xFF10B981),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            book.languages[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.getSecondaryTextColor(context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _filterBooks(String query) {
    setState(() {
      _filteredBooks = _allBooks.where((book) {
        return book.title.toLowerCase().contains(query.toLowerCase()) ||
          book.displayAuthor.toLowerCase().contains(query.toLowerCase()) ||
          book.languages.any((language) => language.toLowerCase().contains(query.toLowerCase())) ||
          book.subjects.any((subject) => subject.toLowerCase().contains(query.toLowerCase()));
      }).toList();
    });
  }

  Future<void> _applyFilters() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<Book> booksToFilter = _allBooks;

      // If a priority subject is selected, fetch subject-specific books
      if (['ICT', 'Math', 'Science', 'Geography'].contains(_selectedSubject)) {
        final subjectBooks = await _gutenbergService.searchBySubject(_selectedSubject, limit: 100);
        booksToFilter = subjectBooks;
      }

      setState(() {
        _filteredBooks = booksToFilter.where((book) {
          final languageMatch = _selectedLanguage == 'All' || book.languages.contains(_selectedLanguage);
          
          // Handle academic category filtering
          bool subjectMatch = false;
          if (_selectedSubject == 'All') {
            subjectMatch = true;
          } else if (_selectedSubject == 'All Academic') {
            // Show all academic books
            subjectMatch = _isAcademicBook(book);
          } else if (['ICT', 'Math', 'Science', 'Geography'].contains(_selectedSubject)) {
            // Already filtered by searchBySubject
            subjectMatch = true;
          } else {
            // Filter by specific academic category or general subject
            subjectMatch = book.subjects.any((subject) => 
                subject.toLowerCase().contains(_selectedSubject.toLowerCase()));
          }
          
          return languageMatch && subjectMatch;
        }).toList();
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error filtering books: $error'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  // Helper method to check if a book is academic
  bool _isAcademicBook(Book book) {
    final titleLower = book.title.toLowerCase();
    final subjectsLower = book.subjects.map((s) => s.toLowerCase()).join(' ');
    
    // Check for academic keywords
    final academicKeywords = [
      'textbook', 'handbook', 'manual', 'guide', 'introduction', 
      'principles', 'theory', 'methods', 'studies', 'research',
      'academic', 'scholar', 'university', 'college', 'education',
      'learning', 'course', 'lecture', 'treatise', 'dissertation', 'thesis'
    ];
    
    final hasAcademicKeyword = academicKeywords.any((keyword) =>
        titleLower.contains(keyword) || subjectsLower.contains(keyword));
    
    // Check for academic subjects
    final academicSubjects = [
      'Science', 'Mathematics', 'Physics', 'Chemistry', 'Biology', 'Medicine',
      'Engineering', 'Computer Science', 'Philosophy', 'History', 'Literature',
      'Psychology', 'Sociology', 'Economics', 'Political Science', 'Education',
      'Law', 'Business', 'Technology', 'Religion', 'Art', 'Music', 'Linguistics',
      'Anthropology', 'Geography', 'Archaeology', 'Astronomy', 'Geology',
      'Botany', 'Zoology'
    ];
    
    final hasAcademicSubject = book.subjects.any((subject) =>
        academicSubjects.any((academicSubject) =>
            subject.toLowerCase().contains(academicSubject.toLowerCase())));
    
    return hasAcademicKeyword || hasAcademicSubject;
  }

  void _openBook(BuildContext context, Book book) {
    // Navigate to the book reader screen using GoRouter
    context.push('/books/${book.id}', extra: book);
  }

  void _resetFilters() {
    setState(() {
      _selectedLanguage = 'All';
      _selectedSubject = 'All';
      _filteredBooks = _allBooks;
    });
  }

  Future<void> _loadInitialBooks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentPage = 1;
      _allBooks.clear();
      _filteredBooks.clear();
      _hasMore = true;
    });
    
    try {
      final books = await _gutenbergService.fetchAcademicBooks(page: 1, limit: _pageSize);
      if (mounted) {
        setState(() {
          _allBooks = books;
          _filteredBooks = books;
          _isLoading = false;
          _hasMore = books.length == _pageSize;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = error.toString();
        });
      }
    }
  }

  Future<void> _loadMoreBooks() async {
    if (_isLoadingMore || !_hasMore) return;
    
    setState(() {
      _isLoadingMore = true;
    });
    
    try {
      final newBooks = await _gutenbergService.fetchAcademicBooks(page: _currentPage + 1, limit: _pageSize);
      if (mounted) {
        setState(() {
          _currentPage++;
          _allBooks.addAll(newBooks);
          _filteredBooks = _allBooks;
          _isLoadingMore = false;
          // Consider hasMore true if we got any books, not just full page
          _hasMore = newBooks.isNotEmpty;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final delta = 300.0; // Load more when 300px from the bottom
    
    if (maxScroll - currentScroll <= delta && !_isLoadingMore && _hasMore) {
      _loadMoreBooks();
    }
  }

  Future<void> _refreshBooks() async {
    await _loadInitialBooks();
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFF10B981)),
            const SizedBox(height: 8),
            Text(
              'Loading more books...',
              style: TextStyle(
                color: AppTheme.getSecondaryTextColor(context),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
