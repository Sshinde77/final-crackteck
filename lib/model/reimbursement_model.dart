enum ReimbursementStatus {
  pending,
  approved,
  rejected;

  static ReimbursementStatus fromRaw(dynamic value) {
    final normalized = value?.toString().trim().toLowerCase() ?? '';

    switch (normalized) {
      case 'approved':
      case 'approve':
      case 'accepted':
      case 'success':
        return ReimbursementStatus.approved;
      case 'rejected':
      case 'reject':
      case 'declined':
      case 'failed':
        return ReimbursementStatus.rejected;
      case 'pending':
      case 'in review':
      case 'under review':
      default:
        return ReimbursementStatus.pending;
    }
  }

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
  final String? id;
  final double amount;
  final String reason;
  final ReimbursementStatus status;
  final String? receiptImagePath;
  final DateTime createdAt;

  const ReimbursementModel({
    this.id,
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

  factory ReimbursementModel.fromJson(Map<String, dynamic> json) {
    return ReimbursementModel(
      id: _readString(json, const [
        'id',
        'reimbursement_id',
        'staff_reimbursement_id',
      ]),
      amount: _readDouble(json, const [
        'amount',
        'reimbursement_amount',
        'total_amount',
        'claim_amount',
      ]),
      reason: _readString(json, const [
            'reason',
            'description',
            'remarks',
            'note',
            'expense_reason',
            'title',
          ]) ??
          'No reason provided',
      status: ReimbursementStatus.fromRaw(
        json['status'] ?? json['approval_status'] ?? json['state'],
      ),
      receiptImagePath: _readString(json, const [
        'receipt_url',
        'receipt',
        'receipt_image',
        'receipt_image_path',
        'attachment',
        'bill_image',
      ]),
      createdAt: _readDateTime(json, const [
            'created_at',
            'date',
            'submitted_at',
            'request_date',
          ]) ??
          DateTime.now(),
    );
  }

  static String? _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) {
        return text;
      }
    }
    return null;
  }

  static double _readDouble(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is num) {
        return value.toDouble();
      }
      if (value is String) {
        final normalized = value.replaceAll(',', '').trim();
        final parsed = double.tryParse(normalized);
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return 0;
  }

  static DateTime? _readDateTime(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is DateTime) {
        return value;
      }
      if (value is String && value.trim().isNotEmpty) {
        final parsed = DateTime.tryParse(value.trim());
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return null;
  }
}
