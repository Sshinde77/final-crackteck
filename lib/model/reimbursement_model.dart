enum ReimbursementStatus {
  pending,
  approved,
  rejected;

  String get label {
    switch (this) {
      case ReimbursementStatus.pending:
        return 'Pending';
      case ReimbursementStatus.approved:
        return 'Approved';
      case ReimbursementStatus.rejected:
        return 'Rejected';
    }
  }
}

class ReimbursementModel {
  final double amount;
  final String reason;
  final ReimbursementStatus status;
  final String? receiptImagePath;
  final DateTime createdAt;

  const ReimbursementModel({
    required this.amount,
    required this.reason,
    required this.status,
    this.receiptImagePath,
    required this.createdAt,
  });

  factory ReimbursementModel.dummy({
    required double amount,
    required String reason,
    required ReimbursementStatus status,
  }) {
    return ReimbursementModel(
      amount: amount,
      reason: reason,
      status: status,
      createdAt: DateTime.now(),
    );
  }
}
