import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:excellencecoachinghub/utils/navigation_optimizer.dart';
import 'package:excellencecoachinghub/utils/navigation_performance_monitor.dart';

/// Test helper for navigation improvements
class NavigationTestHelper {
  /// Test navigation performance
  static Future<void> testNavigationPerformance() async {
    debugPrint('=== Testing Navigation Performance ===');
    
    // Test 1: Navigation timing
    final stopwatch = Stopwatch()..start();
    NavigationPerformanceMonitor.startNavigation('/dashboard');
    await Future.delayed(const Duration(milliseconds: 50)); // Simulate navigation
    NavigationPerformanceMonitor.endNavigation('/dashboard');
    stopwatch.stop();
    
    debugPrint('Navigation test completed in ${stopwatch.elapsedMilliseconds}ms');
    
    // Test 2: Performance stats
    final stats = NavigationPerformanceMonitor.getPerformanceStats();
    debugPrint('Performance stats: $stats');
    
    // Test 3: Route caching
    final isCached = NavigationOptimizer.isRouteCached('/dashboard');
    debugPrint('Route /dashboard cached: $isCached');
  }
  
  /// Test navigation optimization features
  static void testNavigationOptimizations() {
    debugPrint('=== Testing Navigation Optimizations ===');
    
    // Test debouncing
    final testRoute = '/test-route';
    NavigationPerformanceMonitor.startNavigation(testRoute);
    NavigationPerformanceMonitor.endNavigation(testRoute);
    
    // Test cache functionality
    NavigationOptimizer.clearCache();
    final cacheEmpty = !NavigationOptimizer.isRouteCached(testRoute);
    debugPrint('Cache cleared successfully: $cacheEmpty');
  }
  
  /// Simulate navigation scenarios
  static Future<void> simulateNavigationScenarios() async {
    debugPrint('=== Simulating Navigation Scenarios ===');
    
    // Scenario 1: Rapid navigation attempts
    for (int i = 0; i < 5; i++) {
      NavigationPerformanceMonitor.startNavigation('/rapid-test-$i');
      await Future.delayed(const Duration(milliseconds: 10));
      NavigationPerformanceMonitor.endNavigation('/rapid-test-$i');
    }
    
    // Scenario 2: Heavy navigation (simulating complex screens)
    NavigationPerformanceMonitor.startNavigation('/heavy-screen');
    await Future.delayed(const Duration(milliseconds: 200));
    NavigationPerformanceMonitor.endNavigation('/heavy-screen');
    
    // Scenario 3: Tab navigation optimization
    final tabs = ['/dashboard', '/courses', '/library', '/downloads'];
    for (final tab in tabs) {
      NavigationPerformanceMonitor.startNavigation(tab);
      await Future.delayed(const Duration(milliseconds: 30));
      NavigationPerformanceMonitor.endNavigation(tab);
    }
    
    debugPrint('Navigation scenarios completed');
  }
  
  /// Generate navigation performance report
  static Map<String, dynamic> generatePerformanceReport() {
    final stats = NavigationPerformanceMonitor.getPerformanceStats();
    final buildStats = WidgetPerformanceMonitor.getBuildStats();
    
    return {
      'navigation_performance': stats,
      'widget_build_performance': buildStats,
      'recommendations': _generateRecommendations(stats),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
  
  static List<String> _generateRecommendations(Map<String, dynamic> stats) {
    final recommendations = <String>[];
    
    for (final entry in stats.entries) {
      final route = entry.key;
      final data = entry.value as Map<String, dynamic>;
      final average = data['average'] as double;
      
      if (average > 300) {
        recommendations.add('Route $route is slow (${average.round()}ms avg). Consider lazy loading or optimization.');
      }
      
      if (NavigationPerformanceMonitor.isPerformanceDegrading(route)) {
        recommendations.add('Route $route shows performance degradation. Monitor for memory leaks.');
      }
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('All routes are performing well within acceptable limits.');
    }
    
    return recommendations;
  }
}

/// Widget for testing navigation in development
class NavigationTestWidget extends StatefulWidget {
  const NavigationTestWidget({super.key});
  
  @override
  State<NavigationTestWidget> createState() => _NavigationTestWidgetState();
}

class _NavigationTestWidgetState extends State<NavigationTestWidget> {
  String _testResult = 'Press button to run tests';
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Navigation Test')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _runTests,
              child: const Text('Run Navigation Tests'),
            ),
            const SizedBox(height: 16),
            Text(_testResult),
          ],
        ),
      ),
    );
  }
  
  Future<void> _runTests() async {
    setState(() {
      _testResult = 'Running tests...';
    });
    
    try {
      await NavigationTestHelper.testNavigationPerformance();
      NavigationTestHelper.testNavigationOptimizations();
      await NavigationTestHelper.simulateNavigationScenarios();
      
      final report = NavigationTestHelper.generatePerformanceReport();
      setState(() {
        _testResult = 'Tests completed successfully!\\n\\nReport:\\n${report.toString()}';
      });
    } catch (e) {
      setState(() {
        _testResult = 'Test failed: $e';
      });
    }
  }
}
