import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../constants/app_strings.dart';
import '../core/secure_storage_service.dart';
import '../routes/app_routes.dart';

/// Global navigation service to allow non-UI layers to trigger
/// navigation without tight coupling to widget contexts.
class NavigationService {
  NavigationService._();

  /// Global navigator key used by [MaterialApp].
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static final NavigatorObserver navigatorObserver = _LoggingNavigatorObserver();
  static String? _currentRouteName;
  static bool _isNavigatingToAuthRoot = false;

  static String? get currentRouteName => _currentRouteName;

  @visibleForTesting
  static void resetForTesting() {
    _currentRouteName = null;
    _isNavigatingToAuthRoot = false;
  }

  static void updateCurrentRoute(String? routeName, {required String source}) {
    _currentRouteName = routeName;
    debugPrint(
      'NavigationService.updateCurrentRoute '
      'route=${routeName ?? 'unknown'} source=$source',
    );
  }

  static Future<void> navigateToAuthRootIfUnauthenticated({
    int? roleId,
    String source = 'unknown',
  }) async {
    final token = await SecureStorageService.getAccessToken(forceReload: true);
    final hasToken = token != null && token.trim().isNotEmpty;
    debugPrint(
      'NavigationService.navigateToAuthRootIfUnauthenticated '
      'source=$source hasToken=$hasToken route=${_currentRouteName ?? 'unknown'}',
    );
    if (hasToken) return;
    await navigateToAuthRoot(roleId: roleId, source: source);
  }

  /// Navigate back to the authentication entry point while
  /// clearing the existing navigation stack.
  ///
  /// This uses the existing route configuration and does **not**
  /// introduce any new routes or change route names.
  static Future<void> navigateToAuthRoot({
    int? roleId,
    String source = 'unknown',
    bool force = false,
  }) async {
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      debugPrint(
        'NavigationService.navigateToAuthRoot aborted: navigator unavailable '
        'source=$source',
      );
      return;
    }

    if (_isNavigatingToAuthRoot) {
      debugPrint(
        'NavigationService.navigateToAuthRoot skipped: already navigating '
        'source=$source',
      );
      return;
    }

    if (!force) {
      final token = await SecureStorageService.getAccessToken(forceReload: true);
      final hasToken = token != null && token.trim().isNotEmpty;
      if (hasToken) {
        debugPrint(
          'NavigationService.navigateToAuthRoot blocked: token still present '
          'source=$source route=${_currentRouteName ?? 'unknown'}',
        );
        return;
      }
    }

    final resolvedRoleId = roleId ?? await SecureStorageService.getRoleId();
    debugPrint(
      'NavigationService.navigateToAuthRoot '
      'source=$source roleId=$resolvedRoleId '
      'currentRoute=${_currentRouteName ?? 'unknown'}',
    );

    if (_currentRouteName == AppRoutes.login && resolvedRoleId != null) return;
    if (_currentRouteName == AppRoutes.roleSelection && resolvedRoleId == null) {
      return;
    }

    _isNavigatingToAuthRoot = true;
    try {
      await Future<void>.delayed(Duration.zero);
      if (resolvedRoleId != null) {
        navigator.pushNamedAndRemoveUntil(
          AppRoutes.login,
          (route) => false,
          arguments: LoginArguments(
            roleId: resolvedRoleId,
            roleName: _roleNameForId(resolvedRoleId),
          ),
        );
        return;
      }

      navigator.pushNamedAndRemoveUntil(
        AppRoutes.roleSelection,
        (route) => false,
      );
    } finally {
      _isNavigatingToAuthRoot = false;
    }
  }

  static String _roleNameForId(int roleId) {
    switch (roleId) {
      case 1:
        return AppStrings.fieldExecutive;
      case 2:
        return AppStrings.deliveryMan;
      case 3:
        return AppStrings.salesPerson;
      default:
        return 'User';
    }
  }
}

class _LoggingNavigatorObserver extends NavigatorObserver {
  String? _routeName(Route<dynamic>? route) => route?.settings.name;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final routeName = _routeName(route);
    NavigationService.updateCurrentRoute(routeName, source: 'didPush');
    debugPrint(
      'Navigator.didPush route=${routeName ?? 'unknown'} '
      'previous=${_routeName(previousRoute) ?? 'unknown'}',
    );
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    NavigationService.updateCurrentRoute(
      _routeName(previousRoute),
      source: 'didPop',
    );
    debugPrint(
      'Navigator.didPop route=${_routeName(route) ?? 'unknown'} '
      'revealed=${_routeName(previousRoute) ?? 'unknown'}',
    );
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    NavigationService.updateCurrentRoute(
      _routeName(newRoute),
      source: 'didReplace',
    );
    debugPrint(
      'Navigator.didReplace old=${_routeName(oldRoute) ?? 'unknown'} '
      'new=${_routeName(newRoute) ?? 'unknown'}',
    );
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    debugPrint(
      'Navigator.didRemove route=${_routeName(route) ?? 'unknown'} '
      'previous=${_routeName(previousRoute) ?? 'unknown'}',
    );
    super.didRemove(route, previousRoute);
  }
}
