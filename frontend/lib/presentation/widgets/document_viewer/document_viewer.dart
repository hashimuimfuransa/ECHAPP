import 'package:flutter/material.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class DocumentViewer extends StatefulWidget {
  final String documentPath;
  final String title;
  final bool isPdf;
  final bool canDownload;

  const DocumentViewer({
    super.key,
    required this.documentPath,
    required this.title,
    this.isPdf = true,
    this.canDownload = false,
  });

  @override
  State<DocumentViewer> createState() => _DocumentViewerState();
}

class _DocumentViewerState extends State<DocumentViewer> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  bool _isLoading = true;
  int _pageCount = 0;
  int _currentPage = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (widget.isPdf) ...[
            IconButton(
              icon: const Icon(Icons.zoom_in),
              onPressed: () => _pdfViewerController.zoomLevel = (_pdfViewerController.zoomLevel + 0.25).clamp(1.0, 3.0),
              tooltip: 'Zoom In',
            ),
            IconButton(
              icon: const Icon(Icons.zoom_out),
              onPressed: () => _pdfViewerController.zoomLevel = (_pdfViewerController.zoomLevel - 0.25).clamp(1.0, 3.0),
              tooltip: 'Zoom Out',
            ),
          ],
          if (widget.canDownload)
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _handleDownload,
              tooltip: 'Download',
            ),
        ],
      ),
      body: _buildDocumentViewer(),
      bottomNavigationBar: widget.isPdf && !_isLoading ? _buildBottomBar() : null,
    );
  }

  Widget _buildDocumentViewer() {
    if (widget.isPdf) {
      return Stack(
        children: [
          SfPdfViewer.network(
            widget.documentPath,
            key: _pdfViewerKey,
            controller: _pdfViewerController,
            onDocumentLoaded: (PdfDocumentLoadedDetails details) {
              setState(() {
                _isLoading = false;
                _pageCount = details.document.pages.count;
              });
            },
            onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
              setState(() {
                _isLoading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to load PDF: ${details.description}'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            onPageChanged: (PdfPageChangedDetails details) {
              setState(() {
                _currentPage = details.newPageNumber;
              });
            },
            enableTextSelection: true,
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryGreen,
              ),
            ),
        ],
      );
    } else {
      return _buildTextDocument();
    }
  }

  Widget _buildBottomBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: AppTheme.primaryGreen),
            onPressed: _currentPage > 1 ? () => _pdfViewerController.previousPage() : null,
          ),
          Text(
            'Page $_currentPage of $_pageCount',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.blackColor,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: AppTheme.primaryGreen),
            onPressed: _currentPage < _pageCount ? () => _pdfViewerController.nextPage() : null,
          ),
        ],
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
              child: SelectableText(
                'Title: ${widget.title}\n\n'
                'Content path: ${widget.documentPath}\n\n'
                'This document is opened in restricted view mode. Downloading is disabled for security reasons.',
                style: const TextStyle(
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

  void _handleDownload() {
    // Implementation for download if canDownload is true
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Download functionality for authorized documents')),
    );
  }
}
