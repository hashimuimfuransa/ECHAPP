import 'package:flutter/foundation.dart';

/// Navigation performance monitoring utility
class NavigationPerformanceMonitor {
  static final Map<String, DateTime> _navigationStartTimes = {};
  static final Map<String, List<int>> _navigationDurations = {};
  static const int _maxHistorySize = 50;
  
  /// Start timing a navigation operation
  static void startNavigation(String route) {
    _navigationStartTimes[route] = DateTime.now();
  }
  
  /// End timing a navigation operation and record the duration
  static void endNavigation(String route) {
    final startTime = _navigationStartTimes[route];
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime).inMilliseconds;
      _recordDuration(route, duration);
      _navigationStartTimes.remove(route);
      
      if (kDebugMode) {
        debugPrint('Navigation to $route took ${duration}ms');
      }
      
      // Warn if navigation is taking too long
      if (duration > 500) {
        debugPrint('⚠️ Slow navigation detected: $route took ${duration}ms');
      }
    }
  }
  
  /// Record navigation duration for analytics
  static void _recordDuration(String route, int duration) {
    _navigationDurations.putIfAbsent(route, () => <int>[]);
    final durations = _navigationDurations[route]!;
    
    durations.add(duration);
    
    // Keep only recent history
    if (durations.length > _maxHistorySize) {
      durations.removeAt(0);
    }
  }
  
  /// Get average navigation time for a route
  static double getAverageTime(String route) {
    final durations = _navigationDurations[route];
    if (durations == null || durations.isEmpty) return 0.0;
    
    return durations.reduce((a, b) => a + b) / durations.length;
  }
  
  /// Get navigation performance statistics
  static Map<String, dynamic> getPerformanceStats() {
    final stats = <String, dynamic>{};
    
    for (final entry in _navigationDurations.entries) {
      final route = entry.key;
      final durations = entry.value;
      
      if (durations.isNotEmpty) {
        stats[route] = {
          'average': getAverageTime(route),
          'min': durations.reduce((a, b) => a < b ? a : b),
          'max': durations.reduce((a, b) => a > b ? a : b),
          'count': durations.length,
        };
      }
    }
    
    return stats;
  }
  
  /// Clear all performance data
  static void clearStats() {
    _navigationStartTimes.clear();
    _navigationDurations.clear();
  }
  
  /// Check if navigation performance is degrading
  static bool isPerformanceDegrading(String route) {
    final durations = _navigationDurations[route];
    if (durations == null || durations.length < 5) return false;
    
    // Compare recent average with overall average
    final recentAverage = durations
        .skip(durations.length - 5)
        .reduce((a, b) => a + b) / 5;
    final overallAverage = getAverageTime(route);
    
    return recentAverage > overallAverage * 1.5; // 50% slower than average
  }
}

/// Widget performance monitoring
class WidgetPerformanceMonitor {
  static final Map<String, DateTime> _buildStartTimes = {};
  static final Map<String, List<int>> _buildDurations = {};
  
  /// Start timing a widget build
  static void startBuild(String widgetName) {
    if (kDebugMode) {
      _buildStartTimes[widgetName] = DateTime.now();
    }
  }
  
  /// End timing a widget build
  static void endBuild(String widgetName) {
    if (kDebugMode) {
      final startTime = _buildStartTimes[widgetName];
      if (startTime != null) {
        final duration = DateTime.now().difference(startTime).inMilliseconds;
        _recordBuildDuration(widgetName, duration);
        _buildStartTimes.remove(widgetName);
        
        // Warn if widget build is taking too long
        if (duration > 16) { // 16ms = 60fps
          debugPrint('⚠️ Slow widget build: $widgetName took ${duration}ms');
        }
      }
    }
  }
  
  static void _recordBuildDuration(String widgetName, int duration) {
    _buildDurations.putIfAbsent(widgetName, () => <int>[]);
    final durations = _buildDurations[widgetName]!;
    
    durations.add(duration);
    
    // Keep only recent history
    if (durations.length > 100) {
      durations.removeAt(0);
    }
  }
  
  /// Get widget build statistics
  static Map<String, double> getBuildStats() {
    final stats = <String, double>{};
    
    for (final entry in _buildDurations.entries) {
      final widgetName = entry.key;
      final durations = entry.value;
      
      if (durations.isNotEmpty) {
        stats[widgetName] = durations.reduce((a, b) => a + b) / durations.length;
      }
    }
    
    return stats;
  }
}

/// Mixin for performance monitoring widgets
mixin PerformanceMonitorMixin {
  String get widgetName => runtimeType.toString();
  
  void startBuildTiming() {
    WidgetPerformanceMonitor.startBuild(widgetName);
  }
  
  void endBuildTiming() {
    WidgetPerformanceMonitor.endBuild(widgetName);
  }
}
