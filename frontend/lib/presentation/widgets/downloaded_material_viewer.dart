import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/models/download.dart';
import 'package:excellencecoachinghub/utils/screen_wakelock.dart';

/// Opens a completed [download] from the copy on disk.
///
/// Everything here reads the local file, never the network, so a book or
/// material downloaded from the Library opens the same way with no connection.
/// PDFs and text render in-app; anything else (EPUB, Word, …) is handed to the
/// platform viewer.
Future<void> openDownloadedMaterial(BuildContext context, Download download) async {
  final file = File(download.localPath);
  if (!await file.exists()) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('File not found on this device. Please download it again.'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  final extension = p.extension(download.localPath).toLowerCase();
  if (!context.mounted) return;

  if (extension == '.pdf') {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _LocalPdfViewer(download: download)),
    );
    return;
  }

  if (const ['.txt', '.md', '.markdown'].contains(extension)) {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _LocalTextViewer(download: download)),
    );
    return;
  }

  // EPUB, Word, HTML and friends: no in-app renderer, so let the device pick
  // an app that can read it.
  String failure;
  try {
    final result = await OpenFile.open(download.localPath);
    if (result.type == ResultType.done) return;
    failure = result.type == ResultType.noAppToOpen
        ? 'No app on this device can open ${extension.replaceFirst('.', '').toUpperCase()} files.'
        : 'Could not open this file: ${result.message}';
  } catch (e) {
    failure = 'Could not open this file: $e';
  }

  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(failure), backgroundColor: Colors.orange),
  );
}

class _LocalPdfViewer extends StatelessWidget {
  const _LocalPdfViewer({required this.download});

  final Download download;

  @override
  Widget build(BuildContext context) {
    return KeepScreenAwake(
      child: Scaffold(
        appBar: AppBar(
          title: Text(download.originalTitle),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SfPdfViewer.file(File(download.localPath)),
      ),
    );
  }
}

class _LocalTextViewer extends StatefulWidget {
  const _LocalTextViewer({required this.download});

  final Download download;

  @override
  State<_LocalTextViewer> createState() => _LocalTextViewerState();
}

class _LocalTextViewerState extends State<_LocalTextViewer> {
  late final Future<String> _content;

  @override
  void initState() {
    super.initState();
    _content = _readFile();
  }

  Future<String> _readFile() async {
    // Gutenberg plain text comes in a mix of encodings; malformed bytes
    // shouldn't stop the rest of the book from being readable.
    final bytes = await File(widget.download.localPath).readAsBytes();
    return const Utf8Decoder(allowMalformed: true).convert(bytes);
  }

  bool get _isMarkdown {
    final extension = p.extension(widget.download.localPath).toLowerCase();
    return extension == '.md' || extension == '.markdown';
  }

  @override
  Widget build(BuildContext context) {
    return KeepScreenAwake(
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.download.originalTitle),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: FutureBuilder<String>(
          future: _content,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryGreen),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Could not read this file: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.getSecondaryTextColor(context)),
                  ),
                ),
              );
            }

            final text = snapshot.data ?? '';
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _isMarkdown
                  ? MarkdownBody(
                      data: text,
                      styleSheet: MarkdownStyleSheet(
                        h1: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        h2: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        h3: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                        p: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                    )
                  : SelectableText(
                      text,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: AppTheme.getTextColor(context),
                      ),
                    ),
            );
          },
        ),
      ),
    );
  }
}
