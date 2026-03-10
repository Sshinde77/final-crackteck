import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../model/reimbursement_model.dart';
import '../../screens/reimbursement/add_reimbursement_screen.dart';

class ReimbursementSection extends StatefulWidget {
  final String title;
  final String subtitle;

  const ReimbursementSection({
    super.key,
    this.title = 'Reimbursement',
    this.subtitle = 'Track submitted expenses and add new reimbursement requests.',
  });

  @override
  State<ReimbursementSection> createState() => _ReimbursementSectionState();
}

class _ReimbursementSectionState extends State<ReimbursementSection> {
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '\u20B9',
    decimalDigits: 0,
  );

  late final List<ReimbursementModel> _reimbursements = [
    ReimbursementModel.dummy(
      amount: 500,
      reason: 'Petrol Expense',
      status: ReimbursementStatus.pending,
    ),
    ReimbursementModel.dummy(
      amount: 1200,
      reason: 'Client Meeting Travel',
      status: ReimbursementStatus.approved,
    ),
    ReimbursementModel.dummy(
      amount: 300,
      reason: 'Office Supplies',
      status: ReimbursementStatus.rejected,
    ),
  ];

  Future<void> _openAddReimbursementForm() async {
    final ReimbursementModel? result = await Navigator.push<ReimbursementModel>(
      context,
      MaterialPageRoute(
        builder: (context) => const AddReimbursementScreen(),
      ),
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _reimbursements.insert(0, result);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reimbursement request added successfully.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFE9F6E5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Color(0xFF145A00),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ..._reimbursements.map(
            (reimbursement) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ReimbursementCard(
                reimbursement: reimbursement,
                currencyFormat: _currencyFormat,
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _openAddReimbursementForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF145A00),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Add Reimbursement',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReimbursementCard extends StatelessWidget {
  final ReimbursementModel reimbursement;
  final NumberFormat currencyFormat;

  const _ReimbursementCard({
    required this.reimbursement,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Amount',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currencyFormat.format(reimbursement.amount),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: reimbursement.status),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Reason',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            reimbursement.reason,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          if (reimbursement.receiptImagePath != null &&
              reimbursement.receiptImagePath!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 16,
                    color: Color(0xFF145A00),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Receipt attached',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF145A00),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ReimbursementStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final _StatusStyle style = _StatusStyle.fromStatus(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: style.backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: style.textColor,
        ),
      ),
    );
  }
}

class _StatusStyle {
  final Color backgroundColor;
  final Color textColor;

  const _StatusStyle({
    required this.backgroundColor,
    required this.textColor,
  });

  factory _StatusStyle.fromStatus(ReimbursementStatus status) {
    switch (status) {
      case ReimbursementStatus.pending:
        return const _StatusStyle(
          backgroundColor: Color(0xFFFFF1E6),
          textColor: Color(0xFFE67E22),
        );
      case ReimbursementStatus.approved:
        return const _StatusStyle(
          backgroundColor: Color(0xFFEAF8EC),
          textColor: Color(0xFF2E7D32),
        );
      case ReimbursementStatus.rejected:
        return const _StatusStyle(
          backgroundColor: Color(0xFFFDECEC),
          textColor: Color(0xFFC62828),
        );
    }
  }
}
