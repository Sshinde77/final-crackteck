import 'package:final_crackteck/routes/app_routes.dart';
import 'package:final_crackteck/routes/route_generator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'model/sales_person/dashboard_provider.dart';
import 'provider/attendance_provider.dart';

import 'constants/app_strings.dart';
import 'core/navigation_service.dart';
import 'services/notification_service.dart';

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

class _CrackTechAppState extends State<CrackTechApp> {
  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    
  }

  Future<void> _initializeNotifications() async {
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
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData (
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
          useMaterial3: true,
        ),
        initialRoute: AppRoutes.roleSelection,
        onGenerateRoute: RouteGenerator.generateRoute,
      ),
    );
  }
}
