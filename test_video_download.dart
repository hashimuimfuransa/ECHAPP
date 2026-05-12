import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excellencecoachinghub/services/download_service.dart';
import 'package:excellencecoachinghub/presentation/providers/download_provider.dart';

/// Test widget to verify video download functionality and progress display
class VideoDownloadTestWidget extends ConsumerStatefulWidget {
  const VideoDownloadTestWidget({super.key});

  @override
  ConsumerState<VideoDownloadTestWidget> createState() => _VideoDownloadTestWidgetState();
}

class _VideoDownloadTestWidgetState extends ConsumerState<VideoDownloadTestWidget> {
  final DownloadService _downloadService = DownloadService();
  bool _isInitialized = false;
  String _testResult = 'Not tested';

  @override
  void initState() {
    super.initState();
    _initializeTest();
  }

  Future<void> _initializeTest() async {
    try {
      await _downloadService.init();
      setState(() {
        _isInitialized = true;
        _testResult = 'Service initialized successfully';
      });
    } catch (e) {
      setState(() {
        _testResult = 'Initialization failed: $e';
      });
    }
  }

  Future<void> _testDownloadProgress() async {
    setState(() {
      _testResult = 'Testing download progress simulation...';
    });

    try {
      // Simulate a download with progress updates
      const testUrl = 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';
      const testLessonId = 'test_lesson_123';
      const testFileName = 'test_video';
      const testTitle = 'Test Video Download';

      await _downloadService.downloadVideo(
        url: testUrl,
        fileName: testFileName,
        originalTitle: testTitle,
        lessonId: testLessonId,
        onProgress: (progress) {
          print('Progress: ${(progress * 100).toInt()}%');
          if (mounted) {
            setState(() {
              _testResult = 'Download progress: ${(progress * 100).toInt()}%';
            });
          }
        },
        onSuccess: () {
          if (mounted) {
            setState(() {
              _testResult = 'Download completed successfully!';
            });
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _testResult = 'Download failed: $error';
            });
          }
        },
      );
    } catch (e) {
      setState(() {
        _testResult = 'Test failed: $e';
      });
    }
  }

  void _checkDownloadStatus() {
    final downloads = _downloadService.getAllDownloads();
    setState(() {
      _testResult = 'Total downloads: ${downloads.length}\n';
      for (final download in downloads) {
        _testResult += '- ${download.originalTitle}: ${download.status} (${(download.downloadProgress * 100).toInt()}%)\n';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Download Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Service Status',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isInitialized ? '✅ Initialized' : '⏳ Initializing...',
                      style: TextStyle(
                        fontSize: 16,
                        color: _isInitialized ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Test Results',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _testResult,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isInitialized ? _testDownloadProgress : null,
              child: const Text('Test Download Progress'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isInitialized ? _checkDownloadStatus : null,
              child: const Text('Check Download Status'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Main function to run the test
void main() {
  runApp(
    const ProviderScope(
      child: MaterialApp(
        home: VideoDownloadTestWidget(),
      ),
    ),
  );
}
