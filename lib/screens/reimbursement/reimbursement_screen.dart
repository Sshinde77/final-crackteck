import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../model/reimbursement_model.dart';
import 'add_reimbursement_screen.dart';

enum ReimbursementFilter {
  all('All'),
  pending('Pending'),
  approved('Approved'),
  rejected('Rejected');

  final String label;

  const ReimbursementFilter(this.label);
}

class ReimbursementScreen extends StatefulWidget {
  const ReimbursementScreen({super.key});

  @override
  State<ReimbursementScreen> createState() => _ReimbursementScreenState();
}

class _ReimbursementScreenState extends State<ReimbursementScreen> {
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

  ReimbursementFilter _selectedFilter = ReimbursementFilter.all;

  List<ReimbursementModel> get _filteredReimbursements {
    if (_selectedFilter == ReimbursementFilter.all) {
      return _reimbursements;
    }

    final ReimbursementStatus status = switch (_selectedFilter) {
      ReimbursementFilter.pending => ReimbursementStatus.pending,
      ReimbursementFilter.approved => ReimbursementStatus.approved,
      ReimbursementFilter.rejected => ReimbursementStatus.rejected,
      ReimbursementFilter.all => ReimbursementStatus.pending,
    };

    return _reimbursements
        .where((reimbursement) => reimbursement.status == status)
        .toList();
  }

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
      _selectedFilter = ReimbursementFilter.all;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reimbursement request added successfully.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<ReimbursementModel> filteredReimbursements =
        _filteredReimbursements;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Reimbursement',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddReimbursementForm,
        backgroundColor: const Color(0xFF145A00),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Reimbursement',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                children: [
                  _ReimbursementOverviewCard(
                    totalCount: _reimbursements.length,
                    filteredCount: filteredReimbursements.length,
                    selectedFilter: _selectedFilter,
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: ReimbursementFilter.values.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final ReimbursementFilter filter =
                            ReimbursementFilter.values[index];
                        final bool isSelected = filter == _selectedFilter;

                        return ChoiceChip(
                          label: Text(filter.label),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() {
                              _selectedFilter = filter;
                            });
                          },
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF374151),
                          ),
                          backgroundColor: Colors.white,
                          selectedColor: const Color(0xFF145A00),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isSelected
                                  ? const Color(0xFF145A00)
                                  : const Color(0xFFD9DEE7),
                            ),
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? const Color(0xFF145A00)
                                : const Color(0xFFD9DEE7),
                          ),
                          showCheckmark: false,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: filteredReimbursements.isEmpty
                  ? const _EmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                      itemCount: filteredReimbursements.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final ReimbursementModel reimbursement =
                            filteredReimbursements[index];
                        return ReimbursementListCard(
                          reimbursement: reimbursement,
                          currencyFormat: _currencyFormat,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReimbursementOverviewCard extends StatelessWidget {
  final int totalCount;
  final int filteredCount;
  final ReimbursementFilter selectedFilter;

  const _ReimbursementOverviewCard({
    required this.totalCount,
    required this.filteredCount,
    required this.selectedFilter,
  });

  @override
  Widget build(BuildContext context) {
    final String helperText = selectedFilter == ReimbursementFilter.all
        ? 'Showing all reimbursement requests'
        : 'Filtered by ${selectedFilter.label.toLowerCase()} status';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFE9F6E5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: Color(0xFF145A00),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$filteredCount of $totalCount requests',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  helperText,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ReimbursementListCard extends StatelessWidget {
  final ReimbursementModel reimbursement;
  final NumberFormat currencyFormat;

  const ReimbursementListCard({
    super.key,
    required this.reimbursement,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 16,
            offset: Offset(0, 8),
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
                    Text(
                      currencyFormat.format(reimbursement.amount),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Reimbursement Amount',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(status: reimbursement.status),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  size: 18,
                  color: Color(0xFF145A00),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  reimbursement.reason,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
            ],
          ),
          if (reimbursement.receiptImagePath != null &&
              reimbursement.receiptImagePath!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.attach_file_rounded,
                    size: 16,
                    color: Color(0xFF145A00),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Receipt attached',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
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

class StatusBadge extends StatelessWidget {
  final ReimbursementStatus status;

  const StatusBadge({
    super.key,
    required this.status,
  });

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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 72,
              width: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFE9F6E5),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.inbox_outlined,
                size: 34,
                color: Color(0xFF145A00),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No reimbursement requests found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try a different filter or add a new reimbursement request.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
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
