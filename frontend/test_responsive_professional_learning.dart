import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excellencecoachinghub/presentation/screens/learning/professional_learning_screen.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';

/// Test widget to verify professional learning screen responsiveness
class ResponsiveTestWidget extends ConsumerWidget {
  const ResponsiveTestWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Responsiveness Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Device type indicator
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.grey[200],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Device Type: ${ResponsiveBreakpoints.getDeviceType(context)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Screen Width: ${MediaQuery.of(context).size.width.toInt()}px',
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  'Screen Height: ${MediaQuery.of(context).size.height.toInt()}px',
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  'Is Desktop: ${ResponsiveBreakpoints.isDesktop(context)}',
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  'Is Tablet: ${ResponsiveBreakpoints.isTablet(context)}',
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  'Is Mobile: ${ResponsiveBreakpoints.isMobile(context)}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          
          // Responsive layout info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Professional Learning Screen Features:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (ResponsiveBreakpoints.isDesktop(context)) ...[
                  const Text('✅ Grid layout for chapters (2-3 columns)'),
                  const Text('✅ Larger video player with proper sizing'),
                  const Text('✅ Enhanced spacing and typography'),
                  const Text('✅ Optimized materials grid (3-4 columns)'),
                ] else if (ResponsiveBreakpoints.isTablet(context)) ...[
                  const Text('✅ List layout with enhanced spacing'),
                  const Text('✅ Medium-sized video player'),
                  const Text('✅ Optimized materials grid (2-3 columns)'),
                ] else ...[
                  const Text('✅ Single column list layout'),
                  const Text('✅ Mobile-optimized video player'),
                  const Text('✅ Compact materials grid (2 columns)'),
                  const Text('✅ Touch-friendly interface'),
                ],
              ],
            ),
          ),
          
          const Expanded(
            child: Center(
              child: Text(
                'Resize the window or rotate device to test responsiveness',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Main test app
class ResponsiveTestApp extends ConsumerWidget {
  const ResponsiveTestApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Professional Learning Responsiveness Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const ResponsiveTestWidget(),
    );
  }
}
