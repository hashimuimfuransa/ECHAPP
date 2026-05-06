import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/data/services/gutenberg_service.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';
import 'package:url_launcher/url_launcher.dart';

class BookReaderScreen extends ConsumerStatefulWidget {
  final Book book;

  const BookReaderScreen({
    super.key,
    required this.book,
  });

  @override
  ConsumerState<BookReaderScreen> createState() => _BookReaderScreenState();
}

class _BookReaderScreenState extends ConsumerState<BookReaderScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;
  bool _isDarkMode = false;
  double _fontSize = 16.0;
  String _selectedFormat = 'text/plain';

  @override
  void initState() {
    super.initState();
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Set default format preference
    if (widget.book.formats != null) {
      if (widget.book.formats!.containsKey('text/html')) {
        _selectedFormat = 'text/html';
      } else if (widget.book.formats!.containsKey('text/plain')) {
        _selectedFormat = 'text/plain';
      } else if (widget.book.formats!.containsKey('application/pdf')) {
        _selectedFormat = 'application/pdf';
      } else {
        _selectedFormat = widget.book.formats!.keys.first;
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDarkMode ? const Color(0xFF1F2937) : const Color(0xFFF9FAFB),
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          if (_showSearch) _buildSearchBar(context),
          Expanded(
            child: _buildContent(context),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActions(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
      elevation: 0,
      title: Text(
        widget.book.title.length > 30 
            ? '${widget.book.title.substring(0, 30)}...' 
            : widget.book.title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppTheme.getTextColor(context),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _showSearch ? Icons.close : Icons.search,
            color: AppTheme.getTextColor(context),
          ),
          onPressed: () {
            setState(() {
              _showSearch = !_showSearch;
              if (!_showSearch) {
                _searchController.clear();
              }
            });
          },
        ),
        PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            color: AppTheme.getTextColor(context),
          ),
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'format',
              child: Text('Change Format'),
            ),
            const PopupMenuItem(
              value: 'font_size',
              child: Text('Font Size'),
            ),
            const PopupMenuItem(
              value: 'theme',
              child: Text('Toggle Theme'),
            ),
            const PopupMenuItem(
              value: 'download',
              child: Text('Download Book'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF374151) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isDarkMode ? const Color(0xFF4B5563) : const Color(0xFFE5E7EB),
        ),
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(
          color: AppTheme.getTextColor(context),
        ),
        decoration: InputDecoration(
          hintText: 'Search in book...',
          hintStyle: TextStyle(
            color: AppTheme.getSecondaryTextColor(context),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: AppTheme.getSecondaryTextColor(context),
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: AppTheme.getSecondaryTextColor(context),
                  ),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: (value) {
          setState(() {});
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (widget.book.formats == null || widget.book.formats!.isEmpty) {
      return _buildNoContentWidget(context);
    }

    final formatUrl = widget.book.formats![_selectedFormat];
    if (formatUrl == null || formatUrl.isEmpty) {
      return _buildNoContentWidget(context);
    }

    // For HTML and text formats, we'll show a web view
    if (_selectedFormat.startsWith('text/') || _selectedFormat.contains('html')) {
      return _buildWebView(context, formatUrl);
    }
    
    // For PDF, we'll show a download prompt
    if (_selectedFormat.contains('pdf')) {
      return _buildPDFViewer(context, formatUrl);
    }

    // For other formats, show download option
    return _buildDownloadWidget(context, formatUrl);
  }

  Widget _buildNoContentWidget(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book_outlined,
            color: AppTheme.getSecondaryTextColor(context),
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'No readable content available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.getTextColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This book may not be available in a readable format',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.getSecondaryTextColor(context),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _showFormatSelection,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            child: const Text('Try Another Format'),
          ),
        ],
      ),
    );
  }

  Widget _buildWebView(BuildContext context, String url) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF374151) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isDarkMode ? const Color(0xFF4B5563) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: const Color(0xFF10B981),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Reading ${_getFormatDisplayName(_selectedFormat)} format',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.getSecondaryTextColor(context),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _showFormatSelection,
                  child: Text(
                    'Change',
                    style: TextStyle(
                      color: const Color(0xFF10B981),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.web_rounded,
                      color: AppTheme.getSecondaryTextColor(context),
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Web Content Viewer',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.getTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This book is available in web format',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.getSecondaryTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _launchUrl(url),
                      icon: const Icon(Icons.open_in_browser),
                      label: const Text('Open in Browser'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPDFViewer(BuildContext context, String url) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF374151) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isDarkMode ? const Color(0xFF4B5563) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.picture_as_pdf,
                  color: Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'PDF Document',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.getSecondaryTextColor(context),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _showFormatSelection,
                  child: Text(
                    'Change',
                    style: TextStyle(
                      color: const Color(0xFF10B981),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.picture_as_pdf,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'PDF Document',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.getTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This book is available as a PDF',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.getSecondaryTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _launchUrl(url),
                          icon: const Icon(Icons.open_in_browser),
                          label: const Text('Open'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _downloadBook(url),
                          icon: const Icon(Icons.download),
                          label: const Text('Download'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6B7280),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadWidget(BuildContext context, String url) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.download_rounded,
            color: const Color(0xFF10B981),
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'Download Available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.getTextColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This book is available for download',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.getSecondaryTextColor(context),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _downloadBook(url),
            icon: const Icon(Icons.download),
            label: const Text('Download Book'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton.extended(
          onPressed: _showFormatSelection,
          icon: const Icon(Icons.format_list_bulleted),
          label: const Text('Format'),
          backgroundColor: const Color(0xFF10B981),
          foregroundColor: Colors.white,
        ),
        const SizedBox(width: 12),
        FloatingActionButton(
          onPressed: () {
            setState(() {
              _isDarkMode = !_isDarkMode;
            });
          },
          backgroundColor: _isDarkMode ? const Color(0xFF374151) : Colors.white,
          child: Icon(
            _isDarkMode ? Icons.light_mode : Icons.dark_mode,
            color: _isDarkMode ? Colors.white : Colors.black,
          ),
        ),
      ],
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'format':
        _showFormatSelection();
        break;
      case 'font_size':
        _showFontSizeSelection();
        break;
      case 'theme':
        setState(() {
          _isDarkMode = !_isDarkMode;
        });
        break;
      case 'download':
        if (widget.book.formats != null && widget.book.formats!.isNotEmpty) {
          _downloadBook(widget.book.formats!.values.first);
        }
        break;
    }
  }

  void _showFormatSelection() {
    if (widget.book.formats == null || widget.book.formats!.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Format'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: widget.book.formats!.length,
            itemBuilder: (context, index) {
              final entry = widget.book.formats!.entries.elementAt(index);
              final format = entry.key;
              final isSelected = format == _selectedFormat;
              
              return ListTile(
                title: Text(_getFormatDisplayName(format)),
                subtitle: Text(format),
                trailing: isSelected 
                    ? const Icon(Icons.check, color: Color(0xFF10B981))
                    : null,
                onTap: () {
                  setState(() {
                    _selectedFormat = format;
                  });
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showFontSizeSelection() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Font Size'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Slider(
              value: _fontSize,
              min: 12.0,
              max: 24.0,
              divisions: 6,
              label: '${_fontSize.toInt()}',
              onChanged: (value) {
                setState(() {
                  _fontSize = value;
                });
              },
            ),
            Text(
              'Preview: ${_fontSize.toInt()}px',
              style: TextStyle(fontSize: _fontSize),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _downloadBook(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open download link'),
              backgroundColor: Color(0xFFEF4444),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading book: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open book'),
              backgroundColor: Color(0xFFEF4444),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening book: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  String _getFormatDisplayName(String format) {
    switch (format) {
      case 'text/plain':
        return 'Plain Text';
      case 'text/html':
        return 'HTML';
      case 'application/pdf':
        return 'PDF';
      case 'application/epub+zip':
        return 'EPUB';
      case 'application/zip':
        return 'ZIP';
      default:
        return format.split('/').last.toUpperCase();
    }
  }
}
