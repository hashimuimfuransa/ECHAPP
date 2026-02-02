import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:excellence_coaching_hub/config/app_theme.dart';
import 'dart:io';

class DocumentViewer extends StatefulWidget {
  final String documentPath;
  final String title;
  final bool isPdf;

  const DocumentViewer({
    super.key,
    required this.documentPath,
    required this.title,
    this.isPdf = true,
  });

  @override
  State<DocumentViewer> createState() => _DocumentViewerState();
}

class _DocumentViewerState extends State<DocumentViewer> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  double _zoomLevel = 1.0;
  bool _showControls = true;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: _zoomIn,
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: _zoomOut,
          ),
          IconButton(
            icon: const Icon(Icons.fullscreen),
            onPressed: _toggleFullscreen,
          ),
        ],
      ),
      body: _buildDocumentViewer(),
    );
  }

  Widget _buildDocumentViewer() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showControls = !_showControls;
        });
      },
      child: Stack(
        children: [
          // Document content
          _buildDocumentContent(),
          
          // Controls overlay
          if (_showControls) _buildControlsOverlay(),
        ],
      ),
    );
  }

  Widget _buildDocumentContent() {
    if (widget.isPdf) {
      // For PDF files, we'll simulate pages
      return PageView.builder(
        controller: _pageController,
        onPageChanged: (page) {
          setState(() {
            _currentPage = page;
          });
        },
        itemCount: 10, // Simulate 10 pages
        itemBuilder: (context, index) {
          return _buildPdfPage(index);
        },
      );
    } else {
      // For text documents
      return _buildTextDocument();
    }
  }

  Widget _buildPdfPage(int pageNumber) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 200,
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.borderGrey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.picture_as_pdf,
                    size: 60,
                    color: AppTheme.primaryGreen,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'PDF Document Content',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Page ${pageNumber + 1}',
                    style: const TextStyle(
                      color: AppTheme.greyColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'This is a placeholder for PDF content. In a real implementation, you would use a PDF rendering library like pdf_flutter or syncfusion_flutter_pdfviewer.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.greyColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextDocument() {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Document Content',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.blackColor,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderGrey),
              ),
              child: const SelectableText(
                'This is a sample text document content.\n\n'
                'In a real implementation, this would display the actual content of text files like .txt, .doc, or .docx files.\n\n'
                'Features that would be implemented:\n'
                '• Text selection and copying\n'
                '• Search functionality\n'
                '• Font size adjustment\n'
                '• Dark mode support\n'
                '• Table of contents navigation\n\n'
                'For document formats like Word documents, you would typically:\n'
                '1. Extract text content from the document\n'
                '2. Display it in a scrollable text widget\n'
                '3. Preserve basic formatting where possible\n'
                '4. Handle images and tables appropriately',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: AppTheme.blackColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black54,
            Colors.transparent,
            Colors.transparent,
            Colors.black54,
          ],
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              Text(
                widget.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 48), // Balance for back button
            ],
          ),
          
          // Bottom controls
          if (widget.isPdf) ...[
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: _previousPage,
                  ),
                  const SizedBox(width: 15),
                  Text(
                    '${_currentPage + 1}/10',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 15),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward, color: Colors.white),
                    onPressed: _nextPage,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _zoomIn() {
    setState(() {
      _zoomLevel = (_zoomLevel * 1.2).clamp(1.0, 3.0);
    });
  }

  void _zoomOut() {
    setState(() {
      _zoomLevel = (_zoomLevel / 1.2).clamp(0.5, 1.0);
    });
  }

  void _toggleFullscreen() {
    setState(() {
      // Handle fullscreen toggle
    });
  }

  void _nextPage() {
    if (_currentPage < 9) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
}