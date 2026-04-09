import 'package:final_crackteck/screens/reimbursement/add_reimbursement_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AddReimbursementScreen', () {
    testWidgets('shows snackbar when submitting without receipt', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AddReimbursementScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Act
      await tester.enterText(find.byType(TextFormField).first, '120');
      await tester.enterText(find.byType(TextFormField).last, 'Fuel');
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Please upload a receipt image.'), findsOneWidget);
    });
  });
}

