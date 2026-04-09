import 'package:final_crackteck/routes/app_routes.dart';
import 'package:final_crackteck/routes/route_generator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'model/sales_person/dashboard_provider.dart';
import 'provider/attendance_provider.dart';

import 'constants/app_strings.dart';
import 'core/navigation_service.dart';
import 'core/secure_storage_service.dart';
import 'services/notification_service.dart';

const bool _notificationsDisabled = bool.fromEnvironment(
  'DISABLE_NOTIFICATIONS',
  defaultValue: bool.fromEnvironment('FLUTTER_TEST'),
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }
  runApp(const CrackTechApp()); 
}

class CrackTechApp extends StatefulWidget {
  const CrackTechApp({super.key});

  @override
  State<CrackTechApp> createState() => _CrackTechAppState();
}

class _CrackTechAppState extends State<CrackTechApp>
    with WidgetsBindingObserver {
  AppLifecycleState? _lastLifecycleState;
  bool _isHandlingResume = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeNotifications();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint(
      'CrackTechApp.didChangeAppLifecycleState '
      'previous=${_lastLifecycleState?.name ?? 'none'} '
      'current=${state.name} '
      'route=${NavigationService.currentRouteName ?? 'unknown'}',
    );
    _lastLifecycleState = state;

    if (state == AppLifecycleState.resumed) {
      _handleAppResumed();
    }
  }

  Future<void> _handleAppResumed() async {
    if (_isHandlingResume) {
      debugPrint('CrackTechApp._handleAppResumed skipped: already running');
      return;
    }

    _isHandlingResume = true;
    try {
      await SecureStorageService.refreshSessionCache(reason: 'app_resumed');
      final token = await SecureStorageService.getAccessToken(forceReload: true);
      final roleId = await SecureStorageService.getRoleId(forceReload: true);
      final hasToken = token != null && token.trim().isNotEmpty;

      debugPrint(
        'CrackTechApp._handleAppResumed '
        'hasToken=$hasToken roleId=$roleId '
        'route=${NavigationService.currentRouteName ?? 'unknown'}',
      );

      if (!hasToken) {
        await NavigationService.navigateToAuthRootIfUnauthenticated(
          roleId: roleId,
          source: 'app_resumed',
        );
      }
    } catch (error, stackTrace) {
      debugPrint('CrackTechApp._handleAppResumed failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _isHandlingResume = false;
    }
  }

  Future<void> _initializeNotifications() async {
    if (_notificationsDisabled) {
      debugPrint('Notification initialization skipped (disabled for this build).');
      return;
    }
    try {
      await NotificationService.instance.initialize();
    } catch (error, stackTrace) {
      debugPrint('Notification initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<DashboardProvider>(
          create: (_) => DashboardProvider(),
        ),
        ChangeNotifierProvider<AttendanceProvider>(
          create: (_) => AttendanceProvider(),
        ),
      ],
      child: MaterialApp(
        navigatorKey: NavigationService.navigatorKey,
        navigatorObservers: <NavigatorObserver>[
          NavigationService.navigatorObserver,
        ],
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData (
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
          useMaterial3: true,
        ),
        initialRoute: AppRoutes.splash,
        onGenerateRoute: RouteGenerator.generateRoute,
      ),
    );
  }
}
