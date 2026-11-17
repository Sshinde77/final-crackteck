import 'package:srb_computer_engineer/core/navigation_service.dart';
import 'package:srb_computer_engineer/routes/route_generator.dart';
import 'package:flutter/material.dart';

/// Shared widget-test harness that matches the app's navigation style.
Widget buildTestApp({
  Widget? home,
  String? initialRoute,
  Map<String, WidgetBuilder>? routes,
}) {
  return MaterialApp(
    navigatorKey: NavigationService.navigatorKey,
    navigatorObservers: <NavigatorObserver>[
      NavigationService.navigatorObserver,
    ],
    home: home,
    initialRoute: initialRoute,
    routes: routes ?? const <String, WidgetBuilder>{},
    onGenerateRoute: RouteGenerator.generateRoute,
  );
}
