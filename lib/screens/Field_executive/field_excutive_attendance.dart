// main.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const field_executive_attendance(roleId: 0, roleName: ''));
}

class field_executive_attendance extends StatelessWidget {
  final int roleId;
  final String roleName;
  const field_executive_attendance({super.key,
    required this.roleId,
    required this.roleName,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Attendance',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: null,
      ),
      home: const AttendanceScreen(),
    );
  }
}

class AttendanceRecord {
  final DateTime date; // date only
  final String loginTime;
  final String logoutTime;
  final String serviceId;
  final String status;
  final Duration totalHours;
  final Duration workingHours;

  const AttendanceRecord({
    required this.date,
    required this.loginTime,
    required this.logoutTime,
    required this.serviceId,
    required this.status,
    required this.totalHours,
    required this.workingHours,
  });
}

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  static const Color brandGreen = Color(0xFF1B6E1B);

  // Sample data (replace with API/Firebase later)
  final List<AttendanceRecord> _all = [
    AttendanceRecord(
      date: DateTime(2026, 4, 17),
      loginTime: "09:00 AM",
      logoutTime: "05:00 PM",
      serviceId: "#UORD658858DYE",
      status: "Completed",
      totalHours: const Duration(hours: 8),
      workingHours: const Duration(hours: 6),
    ),
    AttendanceRecord(
      date: DateTime(2026, 4, 16),
      loginTime: "09:00 AM",
      logoutTime: "05:00 PM",
      serviceId: "#UORD658858DYE",
      status: "Completed",
      totalHours: const Duration(hours: 8),
      workingHours: const Duration(hours: 6),
    ),
    AttendanceRecord(
      date: DateTime(2026, 4, 15),
      loginTime: "09:00 AM",
      logoutTime: "05:00 PM",
      serviceId: "#UORD658858DYE",
      status: "Completed",
      totalHours: const Duration(hours: 8),
      workingHours: const Duration(hours: 6),
    ),
    AttendanceRecord(
      date: DateTime(2026, 4, 14),
      loginTime: "09:00 AM",
      logoutTime: "05:00 PM",
      serviceId: "#UORD658858DYE",
      status: "Completed",
      totalHours: const Duration(hours: 8),
      workingHours: const Duration(hours: 6),
    ),
  ];

  DateTime? _selectedDate; // if selected from calendar

  List<AttendanceRecord> get _visibleList {
    if (_selectedDate == null) return _all..sort((a, b) => b.date.compareTo(a.date));
    return _all
        .where((r) => _isSameDate(r.date, _selectedDate!))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _hhmmss(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$h:$m:$s hrs";
  }

  Future<void> _openCalendar() async {
    final now = DateTime.now();
    final initial = _selectedDate ?? _all.first.date;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      helpText: "Select attendance date",
      builder: (context, child) {
        // Make the popup feel branded (optional)
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
      setState(() => _selectedDate = DateTime(picked.year, picked.month, picked.day));
    }
  }

  void _clearFilter() {
    setState(() => _selectedDate = null);
  }

  @override
  Widget build(BuildContext context) {
    final list = _visibleList;

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
          "Attendance",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),

      // Floating "Calendar" button like the screenshot
      floatingActionButton: _CalendarFab(
        onTap: _openCalendar,
      ),

      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),

            // Optional: show selected date chip + clear
            if (_selectedDate != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                            DateFormat("dd MMM yyyy").format(_selectedDate!),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _clearFilter,
                      child: const Text("Clear"),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 8),

            Expanded(
              child: list.isEmpty
                  ? _EmptyState(
                date: _selectedDate,
                onPick: _openCalendar,
                onClear: _selectedDate == null ? null : _clearFilter,
              )
                  : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 90),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final r = list[index];
                  return _AttendanceCard(
                    record: r,
                    hhmmss: _hhmmss,
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

class _AttendanceCard extends StatelessWidget {
  final AttendanceRecord record;
  final String Function(Duration) hhmmss;

  const _AttendanceCard({
    required this.record,
    required this.hhmmss,
  });

  static const Color brandGreen = Color(0xFF1B6E1B);

  @override
  Widget build(BuildContext context) {
    final day = DateFormat("dd").format(record.date);
    final month = DateFormat("MMMM").format(record.date);

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
          // Date tile (left)
          Container(
            width: 64,
            padding: const EdgeInsets.symmetric(vertical: 10),
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

          // Details (right)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Login & Out line
                Row(
                  children: [
                    const Text(
                      "Login & Out",
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      "${record.loginTime}  -  ${record.logoutTime}",
                      style: const TextStyle(
                        fontSize: 12,
                        color: brandGreen,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                _kv("Service ID", record.serviceId),
                const SizedBox(height: 6),
                _kv("Status", record.status),
                const SizedBox(height: 6),
                _kv("Total Hours", hhmmss(record.totalHours)),
                const SizedBox(height: 6),
                _kv("Working Hours", hhmmss(record.workingHours)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Row(
      children: [
        Text(
          k,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          v,
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

class _CalendarFab extends StatelessWidget {
  final VoidCallback onTap;
  const _CalendarFab({required this.onTap});

  static const Color brandGreen = Color(0xFF1B6E1B);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: brandGreen,
      elevation: 4,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.calendar_month_rounded, color: Colors.white, size: 22),
              SizedBox(width: 8),
              Text(
                "Calendar",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final DateTime? date;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  const _EmptyState({
    required this.date,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final msg = (date == null)
        ? "No attendance loaded."
        : "No attendance found for\n${DateFormat("dd MMM yyyy").format(date!)}";

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_busy_rounded, size: 46),
            const SizedBox(height: 10),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              children: [
                ElevatedButton(
                  onPressed: onPick,
                  child: const Text("Pick a date"),
                ),
                if (onClear != null)
                  OutlinedButton(
                    onPressed: onClear,
                    child: const Text("Clear filter"),
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
