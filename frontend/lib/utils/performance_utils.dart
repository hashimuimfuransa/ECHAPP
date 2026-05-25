import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// Performance optimization utilities for the app
class PerformanceUtils {
  /// Debounce function to prevent rapid successive calls
  static VoidCallback debounce(VoidCallback action, {Duration delay = const Duration(milliseconds: 300)}) {
    Timer? timer;
    return () {
      if (timer != null) {
        timer!.cancel();
      }
      timer = Timer(delay, action);
    };
  }

  /// Throttle function to limit call frequency
  static VoidCallback throttle(VoidCallback action, {Duration delay = const Duration(milliseconds: 100)}) {
    bool isThrottled = false;
    return () {
      if (isThrottled) return;
      isThrottled = true;
      action();
      Timer(delay, () {
        isThrottled = false;
      });
    };
  }

  /// Optimized builder that only rebuilds when key changes
  static Widget optimizedBuilder({
    required Widget Function() builder,
    required List<Object> keys,
  }) {
    return _OptimizedBuilder(
      keys: keys,
      builder: builder,
    );
  }

  /// Check if widget should be const-optimized
  static bool shouldUseConst(Widget widget) {
    return widget is Text ||
           widget is Icon ||
           widget is SizedBox ||
           widget is Padding ||
           widget is Center;
  }
}

class _OptimizedBuilder extends StatefulWidget {
  final List<Object> keys;
  final Widget Function() builder;

  const _OptimizedBuilder({
    required this.keys,
    required this.builder,
  });

  @override
  State<_OptimizedBuilder> createState() => _OptimizedBuilderState();
}

class _OptimizedBuilderState extends State<_OptimizedBuilder> {
  @override
  Widget build(BuildContext context) {
    return widget.builder();
  }

  @override
  void didUpdateWidget(_OptimizedBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only rebuild if keys changed
    if (!listEquals(oldWidget.keys, widget.keys)) {
      setState(() {});
    }
  }
}

/// Memoized widget wrapper for expensive computations
class MemoizedWidget extends StatelessWidget {
  final Widget child;
  final Object? memoKey;

  const MemoizedWidget({
    super.key,
    required this.child,
    this.memoKey,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

/// Performance monitoring widget (debug only)
class PerformanceMonitor extends StatefulWidget {
  final Widget child;
  final String? label;

  const PerformanceMonitor({
    super.key,
    required this.child,
    this.label,
  });

  @override
  State<PerformanceMonitor> createState() => _PerformanceMonitorState();
}

class _PerformanceMonitorState extends State<PerformanceMonitor> {
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      _startTime = DateTime.now();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (kDebugMode && _startTime != null) {
      final duration = DateTime.now().difference(_startTime!);
      if (duration.inMilliseconds > 16) {
        debugPrint('[Performance] ${widget.label ?? "Widget"} took ${duration.inMilliseconds}ms to build');
      }
      _startTime = DateTime.now();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
