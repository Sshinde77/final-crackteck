import 'package:flutter/material.dart';

import '../constants/app_strings.dart';
import '../core/secure_storage_service.dart';
import '../routes/app_routes.dart';
import '../services/session_manager.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrapSession();
    });
  }

  Future<void> _bootstrapSession() async {
    await SecureStorageService.refreshSessionCache();

    final isAuthenticated = await SessionManager.isLoggedIn(
      checkExpiry: false,
    );
    if (!mounted) return;

    if (!isAuthenticated) {
      await SessionManager.clearSession();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.roleSelection);
      return;
    }

    final roleId = await SessionManager.getStoredRoleId(forceReload: true);
    if (!mounted || roleId == null) {
      await SessionManager.clearSession();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.roleSelection);
      return;
    }

    Navigator.pushReplacementNamed(
      context,
      SessionManager.defaultRouteForRole(roleId),
      arguments: SessionManager.defaultArgumentsForRole(
        roleId,
        _roleNameForId(roleId),
      ),
    );
  }

  String _roleNameForId(int roleId) {
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

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
