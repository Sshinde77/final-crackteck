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

  /// Navigate back to the authentication entry point while
  /// clearing the existing navigation stack.
  ///
  /// This uses the existing route configuration and does **not**
  /// introduce any new routes or change route names.
  static Future<void> navigateToAuthRoot({int? roleId}) async {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    final resolvedRoleId = roleId ?? await SecureStorageService.getRoleId();
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
