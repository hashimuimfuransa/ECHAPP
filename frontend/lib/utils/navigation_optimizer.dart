import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Navigation optimization utility for faster, more reliable navigation
class NavigationOptimizer {
  // Cache for navigation states to prevent redundant operations
  static final Map<String, bool> _navigationCache = {};
  static final Map<String, DateTime> _lastNavigationTime = {};
  
  /// Optimized navigation with debouncing and state caching
  static Future<void> navigateToRoute(
    BuildContext context,
    String route, {
    Map<String, String>? queryParameters,
    Object? extra,
    bool replace = false,
    bool clearStack = false,
  }) async {
    if (!context.mounted) return;
    
    final cacheKey = '$route${queryParameters?.toString() ?? ''}';
    final now = DateTime.now();
    
    // Debounce rapid navigation attempts (within 100ms)
    final lastNav = _lastNavigationTime[cacheKey];
    if (lastNav != null && now.difference(lastNav).inMilliseconds < 100) {
      return;
    }
    
    _lastNavigationTime[cacheKey] = now;
    
    try {
      if (clearStack) {
        context.go(route, extra: extra);
      } else if (replace) {
        context.replace(route, extra: extra);
      } else {
        context.push(route, extra: extra);
      }
      _navigationCache[cacheKey] = true;
    } catch (e) {
      debugPrint('Navigation error: $e');
      // Fallback navigation
      if (context.mounted) {
        context.go(route, extra: extra);
      }
    }
  }
  
  /// Safe back navigation with fallback
  static void navigateBack(BuildContext context, {String? fallbackRoute}) {
    if (!context.mounted) return;
    
    if (context.canPop()) {
      context.pop();
    } else if (fallbackRoute != null) {
      context.go(fallbackRoute);
    } else {
      // Default fallback based on current route
      final currentRoute = GoRouterState.of(context).uri.path;
      if (currentRoute.startsWith('/admin')) {
        context.go('/admin');
      } else {
        context.go('/dashboard');
      }
    }
  }
  
  /// Optimized tab navigation for bottom navigation
  static void navigateToTab(BuildContext context, String tabRoute) {
    if (!context.mounted) return;
    
    final currentRoute = GoRouterState.of(context).uri.path;
    
    // Only navigate if not already on the target route
    if (currentRoute != tabRoute) {
      context.go(tabRoute);
    }
  }
  
  /// Clear navigation cache (useful for logout)
  static void clearCache() {
    _navigationCache.clear();
    _lastNavigationTime.clear();
  }
  
  /// Check if route is already in navigation history
  static bool isRouteCached(String route) {
    return _navigationCache.containsKey(route);
  }
}

/// Mixin for widgets that need optimized navigation
mixin NavigationMixin {
  
  /// Navigate with optimization
  Future<void> navigateTo(
    BuildContext context,
    String route, {
    Map<String, String>? queryParameters,
    Object? extra,
    bool replace = false,
    bool clearStack = false,
  }) async {
    await NavigationOptimizer.navigateToRoute(
      context,
      route,
      queryParameters: queryParameters,
      extra: extra,
      replace: replace,
      clearStack: clearStack,
    );
  }
  
  /// Safe back navigation
  void navigateBack(BuildContext context, {String? fallbackRoute}) {
    NavigationOptimizer.navigateBack(context, fallbackRoute: fallbackRoute);
  }
}

/// Provider for navigation state management
final navigationStateProvider = StateNotifierProvider<NavigationStateNotifier, NavigationState>((ref) {
  return NavigationStateNotifier();
});

class NavigationStateNotifier extends StateNotifier<NavigationState> {
  NavigationStateNotifier() : super(const NavigationState());
  
  void updateCurrentRoute(String route) {
    state = state.copyWith(currentRoute: route, lastUpdated: DateTime.now());
  }
  
  void setNavigationLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }
  
  void clearNavigationHistory() {
    state = const NavigationState();
  }
}

class NavigationState {
  final String currentRoute;
  final DateTime? lastUpdated;
  final bool isLoading;
  
  const NavigationState({
    this.currentRoute = '',
    this.lastUpdated,
    this.isLoading = false,
  });
  
  NavigationState copyWith({
    String? currentRoute,
    DateTime? lastUpdated,
    bool? isLoading,
  }) {
    return NavigationState(
      currentRoute: currentRoute ?? this.currentRoute,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Widget for optimized route transitions
class OptimizedPageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  final Duration transitionDuration;
  final bool maintainState;
  
  OptimizedPageRoute({
    required this.child,
    this.transitionDuration = const Duration(milliseconds: 200),
    this.maintainState = true,
  }) : super(
    pageBuilder: (context, animation, secondaryAnimation) => child,
    transitionDuration: transitionDuration,
    maintainState: maintainState,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation.drive(CurveTween(curve: Curves.easeOutCubic)),
        child: SlideTransition(
          position: animation.drive(
            Tween(begin: const Offset(0.0, 0.05), end: Offset.zero)
                .chain(CurveTween(curve: Curves.easeOutCubic)),
          ),
          child: child,
        ),
      );
    },
  );
}
