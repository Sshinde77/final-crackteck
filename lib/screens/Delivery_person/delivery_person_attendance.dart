import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../provider/attendance_provider.dart';
import '../../provider/delivery_person/delivery_attendance_provider.dart';

class DeliveryPersonAttendanceScreen extends StatefulWidget {
  final int roleId;
  final String roleName;

  const DeliveryPersonAttendanceScreen({
    super.key,
    required this.roleId,
    required this.roleName,
  });

  @override
  State<DeliveryPersonAttendanceScreen> createState() =>
      _DeliveryPersonAttendanceScreenState();
}

class _DeliveryPersonAttendanceScreenState
    extends State<DeliveryPersonAttendanceScreen> {
  static const Color brandGreen = Color(0xFF1B6E1B);
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AttendanceProvider>().initialize(roleId: widget.roleId);
      context.read<DeliveryAttendanceProvider>().load();
    });
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    final parsed = DateTime.tryParse(text);
    if (parsed == null) return null;
    return parsed.isUtc ? parsed.toLocal() : parsed;
  }

  String _formatTime(DateTime? value) {
    if (value == null) return '--';
    return DateFormat('hh:mm a').format(value);
  }

  Duration? _calculateDuration(DateTime? loginAt, DateTime? logoutAt) {
    if (loginAt == null || logoutAt == null) return null;
    if (logoutAt.isBefore(loginAt)) return Duration.zero;
    return logoutAt.difference(loginAt);
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '--';
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds hrs';
  }

  String _deriveStatus(Map<String, dynamic> log, DateTime? logoutAt) {
    if (logoutAt != null) return 'Completed';
    final rawStatus = (log['status'] ??
            log['attendance_status'] ??
            log['state'] ??
            '')
        .toString()
        .trim();
    if (rawStatus.isNotEmpty) {
      return rawStatus;
    }
    return 'In Progress';
  }

  List<_AttendanceRecord> _visibleRecords(List<Map<String, dynamic>> logs) {
    final records = <_AttendanceRecord>[];

    for (final log in logs) {
      final loginAt = _parseDateTime(
        log['login_at'] ??
            log['check_in'] ??
            log['check_in_at'] ??
            log['clock_in'] ??
            log['clock_in_at'],
      );
      final logoutAt = _parseDateTime(
        log['logout_at'] ??
            log['check_out'] ??
            log['check_out_at'] ??
            log['clock_out'] ??
            log['clock_out_at'],
      );

      final date = loginAt ?? logoutAt;
      if (_selectedDate != null && date != null && !_isSameDate(date, _selectedDate!)) {
        continue;
      }
      if (_selectedDate != null && date == null) {
        continue;
      }

      final duration = _calculateDuration(loginAt, logoutAt);
      final rawId = (log['id'] ?? log['attendance_id'] ?? '').toString().trim();

      records.add(
        _AttendanceRecord(
          date: date,
          loginTime: _formatTime(loginAt),
          logoutTime: _formatTime(logoutAt),
          logId: rawId.isEmpty ? '--' : '#ATT$rawId',
          status: _deriveStatus(log, logoutAt),
          totalHours: _formatDuration(duration),
          workingHours: _formatDuration(duration),
        ),
      );
    }

    records.sort(
      (a, b) => (b.date?.millisecondsSinceEpoch ?? 0).compareTo(
        a.date?.millisecondsSinceEpoch ?? 0,
      ),
    );
    return records;
  }

  Future<void> _openCalendar() async {
    final now = DateTime.now();
    final provider = context.read<DeliveryAttendanceProvider>();
    final records = _visibleRecords(provider.logs);
    final initial = _selectedDate ?? (records.isNotEmpty ? records.first.date ?? now : now);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      helpText: 'Select attendance date',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: brandGreen,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  void _clearFilter() {
    setState(() => _selectedDate = null);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DeliveryAttendanceProvider>();
    final records = _visibleRecords(provider.logs);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: brandGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Attendance',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButton: _CalendarFab(onTap: _openCalendar),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            if (_selectedDate != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.event, size: 18, color: brandGreen),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('dd MMM yyyy').format(_selectedDate!),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _clearFilter,
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : records.isEmpty
                      ? _EmptyState(
                          date: _selectedDate,
                          onPick: _openCalendar,
                          onClear: _selectedDate == null ? null : _clearFilter,
                        )
                      : RefreshIndicator(
                          onRefresh: provider.load,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 10, 16, 90),
                            itemCount: records.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              return _AttendanceCard(record: records[index]);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceRecord {
  const _AttendanceRecord({
    required this.date,
    required this.loginTime,
    required this.logoutTime,
    required this.logId,
    required this.status,
    required this.totalHours,
    required this.workingHours,
  });

  final DateTime? date;
  final String loginTime;
  final String logoutTime;
  final String logId;
  final String status;
  final String totalHours;
  final String workingHours;
}

class _AttendanceCard extends StatelessWidget {
  const _AttendanceCard({required this.record});

  final _AttendanceRecord record;

  static const Color brandGreen = Color(0xFF1B6E1B);

  @override
  Widget build(BuildContext context) {
    final effectiveDate = record.date ?? DateTime.now();
    final day = DateFormat('dd').format(effectiveDate);
    final month = DateFormat('MMMM').format(effectiveDate);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EAED)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8EAED)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  day,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  month,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Login & Out',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${record.loginTime}  -  ${record.logoutTime}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: brandGreen,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _kv('Log ID', record.logId),
                const SizedBox(height: 6),
                _kv('Status', record.status),
                const SizedBox(height: 6),
                _kv('Total Hours', record.totalHours),
                const SizedBox(height: 6),
                _kv('Working Hours', record.workingHours),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kv(String key, String value) {
    return Row(
      children: [
        Text(
          key,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.date,
    required this.onPick,
    required this.onClear,
  });

  final DateTime? date;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'No attendance records found.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onPick,
              style: ElevatedButton.styleFrom(backgroundColor: _CalendarFab.green),
              child: Text(
                date == null ? 'Select Date' : 'Change Date',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            if (onClear != null) ...[
              const SizedBox(height: 8),
              TextButton(onPressed: onClear, child: const Text('Clear Filter')),
            ],
          ],
        ),
      ),
    );
  }
}

class _CalendarFab extends StatelessWidget {
  const _CalendarFab({required this.onTap});

  final VoidCallback onTap;

  static const Color green = Color(0xFF1B6E1B);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onTap,
      backgroundColor: green,
      icon: const Icon(Icons.calendar_month, color: Colors.white),
      label: const Text(
        'Calendar',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
