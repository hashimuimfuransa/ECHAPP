/// Decides which routes are usable without a network connection.
///
/// Anything not listed here as offline-safe is treated as online-only and is
/// redirected to [offlineFallbackRoute] while the device is offline.
class OfflineRoutePolicy {
  const OfflineRoutePolicy._();

  /// Where users land when they hit an online-only screen while offline.
  static const String offlineFallbackRoute = '/downloads';

  /// Screens that work with no connection.
  ///
  /// Two groups live here:
  ///  * Auth / onboarding / static pages. These do need the network to finish
  ///    their job, but bouncing a signed-out user into the app shell is worse
  ///    than letting the screen show its own offline message — the login flow
  ///    already handles that case itself.
  ///  * Screens backed by local storage or cache: Downloads, Settings,
  ///    Profile, and the Dashboard (which caches courses and shows its own
  ///    offline banner).
  static const Set<String> _offlineSafeRoutes = {
    // Splash, onboarding and auth
    '/',
    '/landing',
    '/language-selection',
    '/auth-selection',
    '/email-auth-option',
    '/login',
    '/register',
    '/forgot-password',
    '/enter-reset-code',
    '/reset-password',
    '/phone-auth',
    '/phone-collection',
    '/name-collection',
    '/interest-selection',
    // Static content
    '/privacy',
    '/terms',
    '/help',
    // Locally backed app screens
    '/downloads',
    '/dashboard',
    '/settings',
    '/profile',
  };

  /// Route prefixes that stay reachable offline (public deep links whose own
  /// error state is more useful than a redirect).
  static const List<String> _offlineSafePrefixes = [
    '/verify-certificate/',
  ];

  /// True when [location] needs a live connection to be of any use.
  static bool requiresInternet(String location) {
    final path = _normalize(location);
    if (_offlineSafeRoutes.contains(path)) return false;
    for (final prefix in _offlineSafePrefixes) {
      if (path.startsWith(prefix)) return false;
    }
    return true;
  }

  /// Strips query string / fragment and any trailing slash so '/courses?x=1'
  /// and '/courses/' both match '/courses'.
  static String _normalize(String location) {
    var path = location.split('?').first.split('#').first;
    if (path.length > 1 && path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }
    return path.isEmpty ? '/' : path;
  }
}
