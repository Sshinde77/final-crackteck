import 'package:final_crackteck/routes/app_routes.dart';
import 'package:final_crackteck/routes/route_generator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'model/sales_person/dashboard_provider.dart';

import 'constants/app_strings.dart';
import 'core/navigation_service.dart';

void main() {
  runApp(const CrackTechApp());
}

class CrackTechApp extends StatelessWidget {
  const CrackTechApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<DashboardProvider>(
      create: (_) => DashboardProvider(),
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
