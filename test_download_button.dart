import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excellencecoachinghub/presentation/screens/learning/professional_lesson_screen.dart';

/// Test widget to verify download button responsiveness
class DownloadButtonTestWidget extends ConsumerStatefulWidget {
  const DownloadButtonTestWidget({super.key});

  @override
  ConsumerState<DownloadButtonTestWidget> createState() => _DownloadButtonTestWidgetState();
}

class _DownloadButtonTestWidgetState extends ConsumerState<DownloadButtonTestWidget> {
  int _clickCount = 0;
  String _lastError = '';
  bool _isLoading = false;

  void _testDownloadButton() {
    setState(() {
      _clickCount++;
      _lastError = '';
    });
    
    print('Download button test click #$_clickCount');
    
    // Navigate to a lesson screen to test the download button
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ProfessionalLessonScreen(
          lessonId: 'test_lesson_id', // Use a real lesson ID from your app
          isAdminPreview: false,
        ),
      ),
    ).then((result) {
      print('Returned from lesson screen with result: $result');
    });
  }

  void _simulateError() {
    setState(() {
      _lastError = 'Simulated error for testing';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Download Button Test'),
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
                      'Download Button Test',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('Click Count: $_clickCount'),
                    if (_lastError.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Error: $_lastError',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _testDownloadButton,
              child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Test Download Button'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _simulateError,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Simulate Error'),
            ),
            const SizedBox(height: 16),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Instructions:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('1. Click "Test Download Button" to navigate to lesson screen'),
                    Text('2. Try clicking the download button in the lesson'),
                    Text('3. Check console logs for debugging information'),
                    Text('4. Look for error messages or progress updates'),
                    SizedBox(height: 8),
                    Text(
                      'Expected behavior:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('- Button should respond immediately when clicked'),
                    Text('- Progress bar should appear if download starts'),
                    Text('- Console should show debug messages'),
                  ],
                ),
              ),
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
        home: DownloadButtonTestWidget(),
      ),
    ),
  );
}
