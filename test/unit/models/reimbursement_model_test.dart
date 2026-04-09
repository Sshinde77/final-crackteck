import 'package:final_crackteck/model/reimbursement_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ReimbursementStatus.fromRaw normalizes common variants', () {
    expect(ReimbursementStatus.fromRaw('approved'), ReimbursementStatus.approved);
    expect(ReimbursementStatus.fromRaw('Accepted'), ReimbursementStatus.approved);
    expect(ReimbursementStatus.fromRaw('rejected'), ReimbursementStatus.rejected);
    expect(ReimbursementStatus.fromRaw('under review'), ReimbursementStatus.pending);
  });

  test('ReimbursementModel.fromJson parses amount and created_at', () {
    final model = ReimbursementModel.fromJson(<String, dynamic>{
      'id': '55',
      'amount': '1,200',
      'reason': 'Fuel',
      'status': 'approved',
      'created_at': '2026-04-08T10:00:00Z',
      'receipt_url': '/receipts/55.png',
    });

    expect(model.id, '55');
    expect(model.amount, 1200);
    expect(model.reason, 'Fuel');
    expect(model.status, ReimbursementStatus.approved);
    expect(model.receiptImagePath, contains('receipts'));
  });
}

