import 'dart:convert';
import 'package:final_crackteck/login_screen.dart';
import 'package:final_crackteck/role_screen.dart';
import 'package:final_crackteck/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/transparent_asset_bundle.dart';
import 'support/secure_storage_mock.dart';
import 'support/test_bootstrap.dart';

Widget _testApp() {
  return DefaultAssetBundle(
    bundle: TransparentAssetBundle(),
    child: MaterialApp(
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case AppRoutes.login:
            final args = settings.arguments as LoginArguments?;
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => LoginScreen(
                roleId: args?.roleId ?? 1,
                roleName: args?.roleName ?? 'User',
                redirectRoute: args?.redirectRoute,
                redirectArguments: args?.redirectArguments,
              ),
            );
          case AppRoutes.FieldExecutiveDashboard:
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const Scaffold(body: Text('FE Dashboard')),
            );
        }

        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const rolesccreen(),
        );
      },
    ),
  );
}

void main() {
  setUp(() async {
    await testBootstrap();
  });

  tearDown(() {
    SecureStorageMock.reset();
  });

  testWidgets('tapping Field Executive redirects to login when logged out',
      (tester) async {
    await tester.pumpWidget(_testApp());
    expect(find.text('Field Executive'), findsOneWidget);

    await tester.tap(find.text('Field Executive'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
