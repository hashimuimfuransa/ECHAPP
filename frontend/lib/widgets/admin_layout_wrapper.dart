import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/presentation/providers/auth_provider.dart';

/// Wrapper widget for admin screens that handles auth state changes and logout redirection
class AdminLayoutWrapper extends ConsumerStatefulWidget {
  final Widget child;
  final String? screenName;

  const AdminLayoutWrapper({
    super.key,
    required this.child,
    this.screenName,
  });

  @override
  ConsumerState<AdminLayoutWrapper> createState() => _AdminLayoutWrapperState();
}

class _AdminLayoutWrapperState extends ConsumerState<AdminLayoutWrapper> {
  bool _hasInitialized = false;

  @override
  Widget build(BuildContext context) {
    // Listen for auth state changes to handle logout redirection
    ref.listen(authProvider, (previous, next) {
      debugPrint('AdminLayoutWrapper (${widget.screenName ?? 'Admin Screen'}): Auth state changed - User: ${next.user}, Loading: ${next.isLoading}');
      
      // Check if user is logged out (user is null and not in loading state)
      if (next.user == null && !next.isLoading) {
        debugPrint('AdminLayoutWrapper (${widget.screenName ?? 'Admin Screen'}): User logged out, redirecting to login screen');
        
        // Use Future.microtask to ensure the navigation happens after the current build cycle
        Future.microtask(() {
          if (mounted) {
            _redirectToAuthScreen();
          }
        });
      }
    });

    // Check authentication status on first build
    if (!_hasInitialized) {
      _hasInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkAuthenticationAndRedirect();
      });
    }

    return widget.child;
  }

  void _checkAuthenticationAndRedirect() {
    final authState = ref.read(authProvider);
    debugPrint('AdminLayoutWrapper (${widget.screenName ?? 'Admin Screen'}): Initial auth check - User: ${authState.user}, Loading: ${authState.isLoading}');
    
    // If user is not authenticated and not in loading state, redirect immediately
    if (authState.user == null && !authState.isLoading) {
      debugPrint('AdminLayoutWrapper (${widget.screenName ?? 'Admin Screen'}): Unauthenticated user detected, redirecting to login screen');
      _redirectToAuthScreen();
    } else if (authState.user != null && authState.user?.role != 'admin') {
      debugPrint('AdminLayoutWrapper (${widget.screenName ?? 'Admin Screen'}): Non-admin user detected, redirecting to student dashboard');
      // Redirect non-admin users to student dashboard
      Future.microtask(() {
        if (mounted) {
          context.go('/dashboard');
        }
      });
    }
  }

  void _redirectToAuthScreen() {
    if (!mounted) return;
    
    // Redirect to appropriate auth screen based on platform
    final isDesktop = !kIsWeb && (defaultTargetPlatform == TargetPlatform.windows || 
                                defaultTargetPlatform == TargetPlatform.linux || 
                                defaultTargetPlatform == TargetPlatform.macOS);
    if (isDesktop) {
      debugPrint('AdminLayoutWrapper: Redirecting to /email-auth-option (desktop)');
      context.go('/email-auth-option');
    } else {
      debugPrint('AdminLayoutWrapper: Redirecting to /auth-selection (mobile)');
      context.go('/auth-selection');
    }
  }
}
