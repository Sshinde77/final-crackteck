import 'package:final_crackteck/services/session_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:final_crackteck/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App launches to role selection when logged out', (tester) async {
    await SessionManager.clearSession();

    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(find.textContaining('Select your'), findsOneWidget);
  });
}

