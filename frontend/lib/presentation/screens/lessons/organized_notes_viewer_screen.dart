import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import '../../../models/lesson.dart';
import '../../../services/api/lesson_service.dart';

class OrganizedNotesViewerScreen extends StatefulWidget {
  final String lessonId;
  final Lesson lesson;

  const OrganizedNotesViewerScreen({
    super.key,
    required this.lessonId,
    required this.lesson,
  });

  @override
  State<OrganizedNotesViewerScreen> createState() => _OrganizedNotesViewerScreenState();
}

class _OrganizedNotesViewerScreenState extends State<OrganizedNotesViewerScreen> {
  late Future<Map<String, dynamic>?> _notesFuture;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _notesFuture = _fetchOrganizedNotes();
  }

  Future<Map<String, dynamic>?> _fetchOrganizedNotes() async {
    try {
      final service = LessonService();
      final notes = await service.getOrganizedNotesForLesson(widget.lessonId);
      setState(() {
        _isLoading = false;
      });
      return notes;
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lesson.title),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading notes: $_error',
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isLoading = true;
                            _error = null;
                            _notesFuture = _fetchOrganizedNotes();
                          });
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : FutureBuilder<Map<String, dynamic>?>(
                  future: _notesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError || snapshot.data == null) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.note_alt_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No organized notes available for this lesson',
                              style: TextStyle(fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Upload a document for AI processing to generate organized notes',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    final notes = snapshot.data!;
                    return _buildNotesContent(notes);
                  },
                ),
    );
  }

  Widget _buildNotesContent(Map<String, dynamic> notes) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notes['title'] ?? 'Organized Notes',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                const SizedBox(height: 8),
                if (notes['extractedFrom'] != null)
                  Text(
                    'Extracted from: ${notes['extractedFrom']}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.greyColor,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Summary
          if (notes['summary'] != null) ...[
            const Text(
              'Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  notes['summary'],
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Keywords
          if (notes['keywords'] != null && (notes['keywords'] as List).isNotEmpty) ...[
            const Text(
              'Key Topics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (notes['keywords'] as List)
                  .map((keyword) => Chip(
                        label: Text(keyword.toString()),
                        backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                        labelStyle: const TextStyle(
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.w500,
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Sections
          const Text(
            'Detailed Content',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Build sections
          ..._buildSections(notes['sections'] ?? []),
        ],
      ),
    );
  }

  List<Widget> _buildSections(List<dynamic> sections) {
    if (sections.isEmpty) {
      return [
        Card(
          elevation: 2,
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'No sections available in the organized notes.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ];
    }

    return sections
        .map((section) => _buildSectionCard(section))
        .expand((widget) => [widget, const SizedBox(height: 16)])
        .toList()
      ..removeLast(); // Remove the last SizedBox
  }

  Widget _buildSectionCard(dynamic section) {
    return Card(
      elevation: 2,
      child: ExpansionTile(
        title: Text(
          section['heading'] ?? 'Untitled Section',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              section['content'] ?? '',
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class LessonService {
  Future<dynamic> getOrganizedNotesForLesson(String lessonId) async {}
}