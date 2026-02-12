import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../model/sales_person/task_model.dart';
import '../../routes/app_routes.dart';
import '../../services/dashboard_service.dart';
import '../../widgets/bottom_navigation.dart';

class TaskScreen extends StatefulWidget {
  final int roleId;
  final String roleName;

  const TaskScreen({Key? key, required this.roleId, required this.roleName})
    : super(key: key);

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  static const Color darkGreen = Color(0xFF145A00);
  static const Color midGreen = Color(0xFF1F7A05);

  bool _moreOpen = false;
  int _navIndex = 0;

  late DateTime _selectedDate;
  late List<DateTime> _weekMonToSat;
  late String _monthLabel;

  List<_TaskItem> _allTasks = <_TaskItem>[];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedDate = _stripTime(DateTime.now());
    _weekMonToSat = _weekFromDate(_selectedDate);
    _monthLabel = _monthName(_selectedDate.month);
    _loadTasks();
  }

  DateTime _stripTime(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  int _daysInMonth(int year, int month) {
    final firstNextMonth = month == 12
        ? DateTime(year + 1, 1, 1)
        : DateTime(year, month + 1, 1);
    return firstNextMonth.subtract(const Duration(days: 1)).day;
  }

  List<DateTime> _weekFromDate(DateTime date) {
    final monday = date.subtract(Duration(days: date.weekday - 1));
    return List.generate(6, (i) => _stripTime(monday.add(Duration(days: i))));
  }

  String _monthName(int m) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[m - 1];
  }

  void _setSelectedDate(DateTime d) {
    final clean = _stripTime(d);
    setState(() {
      _selectedDate = clean;
      _weekMonToSat = _weekFromDate(clean);
      _monthLabel = _monthName(clean.month);
    });
  }

  void _setMonth(int newMonth) {
    final maxDay = _daysInMonth(_selectedDate.year, newMonth);
    final newDay = math.min(_selectedDate.day, maxDay);
    final newDate = DateTime(_selectedDate.year, newMonth, newDay);

    setState(() {
      _selectedDate = _stripTime(newDate);
      _weekMonToSat = _weekFromDate(_selectedDate);
      _monthLabel = _monthName(newMonth);
    });
  }

  List<_TaskItem> get _tasksForSelectedDay {
    final tasks = _allTasks
        .where((t) => _isSameDay(t.date, _selectedDate))
        .toList();
    tasks.sort((a, b) => a.sortOrderMinutes.compareTo(b.sortOrderMinutes));
    return tasks;
  }

  Future<void> _openDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime(DateTime.now().year + 2),
    );

    if (picked != null) {
      _setSelectedDate(picked);
    }
  }

  String _normalizeError(Object e) {
    final raw = e.toString().trim();
    const prefix = 'Exception: ';
    if (raw.startsWith(prefix)) {
      return raw.substring(prefix.length).trim();
    }
    return raw;
  }

  String _firstNonEmpty(Iterable<String> values, {String fallback = 'N/A'}) {
    for (final value in values) {
      final clean = value.trim();
      if (clean.isNotEmpty && clean.toLowerCase() != 'n/a') {
        return clean;
      }
    }
    return fallback;
  }

  DateTime? _parseTaskDate(String raw) {
    final clean = raw.trim();
    if (clean.isEmpty) return null;

    final parsed = DateTime.tryParse(clean);
    if (parsed != null) {
      return _stripTime(parsed);
    }

    final slash = clean.split('/');
    if (slash.length == 3) {
      final a = int.tryParse(slash[0]);
      final b = int.tryParse(slash[1]);
      final c = int.tryParse(slash[2]);
      if (a != null && b != null && c != null) {
        if (slash[0].length == 4) {
          return DateTime(a, b, c);
        }
        return DateTime(c, b, a);
      }
    }

    final dash = clean.split('-');
    if (dash.length == 3) {
      final a = int.tryParse(dash[0]);
      final b = int.tryParse(dash[1]);
      final c = int.tryParse(dash[2]);
      if (a != null && b != null && c != null) {
        if (dash[0].length == 4) {
          return DateTime(a, b, c);
        }
        return DateTime(c, b, a);
      }
    }

    return null;
  }

  int? _parseTimeToMinutes(String raw) {
    final clean = raw.trim();
    if (clean.isEmpty) return null;

    final dateTimeParsed = DateTime.tryParse(clean);
    if (dateTimeParsed != null) {
      return (dateTimeParsed.hour * 60) + dateTimeParsed.minute;
    }

    final match = RegExp(
      r'^\s*(\d{1,2})[:.](\d{1,2})(?::\d{1,2})?\s*([AaPp][Mm])?\s*$',
    ).firstMatch(clean);
    if (match == null) return null;

    var hour = int.tryParse(match.group(1) ?? '');
    final minute = int.tryParse(match.group(2) ?? '');
    final amPm = (match.group(3) ?? '').toUpperCase();
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;

    if (amPm == 'AM' && hour == 12) {
      hour = 0;
    } else if (amPm == 'PM' && hour != 12) {
      hour += 12;
    }
    return (hour * 60) + minute;
  }

  String _formatTimeLabel(String raw) {
    final minutes = _parseTimeToMinutes(raw);
    if (minutes == null) {
      final fallback = raw.trim();
      return fallback.isEmpty ? '--' : fallback;
    }
    final hour24 = minutes ~/ 60;
    final minute = minutes % 60;
    final period = hour24 >= 12 ? 'PM' : 'AM';
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    return '$hour12:${minute.toString().padLeft(2, '0')} $period';
  }

  String _formatDisplayId(String raw, String prefix) {
    final clean = raw.trim();
    if (clean.isEmpty || clean.toLowerCase() == 'n/a') {
      return 'N/A';
    }
    final asInt = int.tryParse(clean);
    if (asInt != null) {
      return '$prefix-${asInt.toString().padLeft(3, '0')}';
    }
    return clean;
  }

  _TaskItem _mapTaskToUi(TaskModel task) {
    final meet = task.meet;
    final followup = task.followup;
    final isMeeting = meet != null;
    final isFollowup = !isMeeting && followup != null;

    final rawDate = isMeeting
        ? meet.date
        : (isFollowup ? followup!.followupDate : '');
    final rawTime = isMeeting
        ? meet.time
        : (isFollowup ? followup!.followupTime : '');
    final date = _parseTaskDate(rawDate) ?? _selectedDate;
    final sortMinutes = _parseTimeToMinutes(rawTime) ?? (24 * 60);

    final leadId = _firstNonEmpty(<String>[
      task.leadId,
      task.leadDetails?.id.toString() ?? '',
      if (isMeeting) meet.leadId.toString(),
      if (isFollowup) followup!.leadId.toString(),
    ]);
    final phone = _firstNonEmpty(<String>[
      task.phone,
      task.leadDetails?.phone ?? '',
      if (isMeeting) meet.leadDetails?.phone ?? '',
      if (isFollowup) followup!.leadDetails?.phone ?? '',
    ]);
    final location = _firstNonEmpty(<String>[
      task.location,
      if (isMeeting) meet.location,
      task.leadDetails?.companyName ?? '',
      if (isMeeting) meet.leadDetails?.companyName ?? '',
      if (isFollowup) followup!.leadDetails?.companyName ?? '',
    ]);

    final title = isMeeting
        ? 'Meeting'
        : (isFollowup ? 'Follow Up' : _firstNonEmpty(<String>[task.title], fallback: 'Task'));

    late final List<String> leftLabels;
    late final List<String> rightValues;

    if (isMeeting) {
      leftLabels = <String>['Lead ID', 'Meeting ID', 'Number', 'Location'];
      rightValues = <String>[
        _formatDisplayId(leadId, 'L'),
        _formatDisplayId(meet.id.toString(), 'M'),
        phone,
        location,
      ];
    } else if (isFollowup) {
      final followupTitle = _firstNonEmpty(<String>[
        task.title,
        followup!.remarks,
        'Follow Up',
      ]);
      leftLabels = <String>['Lead ID', 'Title', 'Number', 'Location'];
      rightValues = <String>[
        _formatDisplayId(leadId, 'L'),
        followupTitle,
        phone,
        location,
      ];
    } else {
      leftLabels = <String>['Lead ID', 'Task ID', 'Number', 'Location'];
      rightValues = <String>[
        _formatDisplayId(leadId, 'L'),
        _formatDisplayId(task.id.toString(), 'T'),
        phone,
        location,
      ];
    }

    return _TaskItem(
      date: date,
      time: _formatTimeLabel(rawTime),
      title: title,
      leftLabels: leftLabels,
      rightValues: rightValues,
      sortOrderMinutes: sortMinutes,
    );
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final tasks = await DashboardService.getTasks();
      final mapped = tasks.map(_mapTaskToUi).toList()
        ..sort((a, b) {
          final byDate = a.date.compareTo(b.date);
          if (byDate != 0) return byDate;
          return a.sortOrderMinutes.compareTo(b.sortOrderMinutes);
        });

      if (!mounted) return;
      setState(() {
        _allTasks = mapped;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _normalizeError(e);
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showTaskDetails(_TaskItem item) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: const TextStyle(
                  color: darkGreen,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),
              for (int i = 0; i < item.leftLabels.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 108,
                        child: Text(
                          item.leftLabels[i],
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item.rightValues[i],
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
                  const SizedBox(
                    width: 108,
                    child: Text(
                      'Time',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item.time,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = _stripTime(DateTime.now());
    final tasks = _tasksForSelectedDay;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 70,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [midGreen, darkGreen],
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Task',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        actions: const [
          Icon(Icons.notifications_none, color: Colors.white),
          SizedBox(width: 16),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadTasks,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _MonthDropdown(
                    label: _monthLabel,
                    onChangedMonthIndex: _setMonth,
                  ),
                  const Spacer(),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: darkGreen,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: _openDatePicker,
                      icon: const Icon(
                        Icons.calendar_month_outlined,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _WeekStrip(
                dates: _weekMonToSat,
                selectedDate: _selectedDate,
                isToday: (d) => _isSameDay(d, today),
                onTapDay: _setSelectedDate,
              ),
              const SizedBox(height: 14),
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFD0D0)),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Failed to load tasks. Pull to refresh or retry.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _loadTasks,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              if (_isLoading && _allTasks.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(darkGreen),
                    ),
                  ),
                )
              else if (tasks.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'No tasks for ${_selectedDate.day}-${_selectedDate.month}-${_selectedDate.year}',
                    style: const TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                _TimelineList(
                  tasks: tasks,
                  onCardTap: _showTaskDetails,
                  onViewTap: _showTaskDetails,
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CrackteckBottomSwitcher(
        isMoreOpen: _moreOpen,
        currentIndex: _navIndex,
        roleId: widget.roleId,
        roleName: widget.roleName,
        onHome: () {
          Navigator.pushNamed(context, AppRoutes.salespersonDashboard);
        },
        onProfile: () {
          Navigator.pushNamed(context, AppRoutes.salespersonProfile);
        },
        onMore: () => setState(() => _moreOpen = true),
        onLess: () => setState(() => _moreOpen = false),
        onLeads: () {
          Navigator.pushNamed(context, AppRoutes.salespersonLeads);
        },
        onFollowUp: () {
          Navigator.pushNamed(context, AppRoutes.salespersonFollowUp);
        },
        onMeeting: () {
          Navigator.pushNamed(context, AppRoutes.salespersonMeeting);
        },
        onQuotation: () {
          Navigator.pushNamed(context, AppRoutes.salespersonQuotation);
        },
      ),
    );
  }
}

// -------------------- MONTH DROPDOWN --------------------

class _MonthDropdown extends StatelessWidget {
  final String label;
  final ValueChanged<int> onChangedMonthIndex;

  const _MonthDropdown({
    required this.label,
    required this.onChangedMonthIndex,
  });

  static const Color darkGreen = Color(0xFF145A00);

  @override
  Widget build(BuildContext context) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
          icon: Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(left: 10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: darkGreen),
            ),
            child: const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: darkGreen,
            ),
          ),
          items: [
            for (final m in months) DropdownMenuItem<String>(value: m, child: Text(m)),
          ],
          onChanged: (v) {
            if (v == null) return;
            final idx = months.indexOf(v);
            if (idx >= 0) {
              onChangedMonthIndex(idx + 1);
            }
          },
        ),
      ),
    );
  }
}

// -------------------- WEEK STRIP --------------------

class _WeekStrip extends StatelessWidget {
  final List<DateTime> dates;
  final DateTime selectedDate;
  final bool Function(DateTime) isToday;
  final ValueChanged<DateTime> onTapDay;

  const _WeekStrip({
    required this.dates,
    required this.selectedDate,
    required this.isToday,
    required this.onTapDay,
  });

  static const Color darkGreen = Color(0xFF145A00);

  String _dayLetter(DateTime d) {
    const map = {1: 'M', 2: 'T', 3: 'W', 4: 'T', 5: 'F', 6: 'S', 7: 'S'};
    return map[d.weekday] ?? '';
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < dates.length; i++)
          Expanded(
            child: InkWell(
              onTap: () => onTapDay(dates[i]),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 56,
                margin: EdgeInsets.only(right: i == dates.length - 1 ? 0 : 10),
                decoration: BoxDecoration(
                  color: _sameDay(dates[i], selectedDate)
                      ? const Color(0xFFF3FAF2)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _sameDay(dates[i], selectedDate)
                        ? darkGreen
                        : (isToday(dates[i]) ? Colors.black26 : Colors.black12),
                    width: _sameDay(dates[i], selectedDate) ? 1.3 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _dayLetter(dates[i]),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _sameDay(dates[i], selectedDate)
                            ? darkGreen
                            : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${dates[i].day}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: _sameDay(dates[i], selectedDate)
                            ? darkGreen
                            : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// -------------------- TIMELINE LIST --------------------

class _TimelineList extends StatelessWidget {
  final List<_TaskItem> tasks;
  final ValueChanged<_TaskItem> onCardTap;
  final ValueChanged<_TaskItem> onViewTap;

  const _TimelineList({
    required this.tasks,
    required this.onCardTap,
    required this.onViewTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < tasks.length; i++)
          _TimelineRow(
            item: tasks[i],
            isLast: i == tasks.length - 1,
            onCardTap: onCardTap,
            onViewTap: onViewTap,
          ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final _TaskItem item;
  final bool isLast;
  final ValueChanged<_TaskItem> onCardTap;
  final ValueChanged<_TaskItem> onViewTap;

  const _TimelineRow({
    required this.item,
    required this.isLast,
    required this.onCardTap,
    required this.onViewTap,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 62,
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                item.time,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 16,
            child: Column(
              children: [
                const SizedBox(height: 6),
                Expanded(
                  child: Container(
                    width: 2,
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (!isLast) const SizedBox(height: 10),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: _TaskCard(
                item: item,
                onTap: () => onCardTap(item),
                onView: () => onViewTap(item),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------- TASK CARD --------------------

class _TaskCard extends StatelessWidget {
  final _TaskItem item;
  final VoidCallback onTap;
  final VoidCallback onView;

  const _TaskCard({
    required this.item,
    required this.onTap,
    required this.onView,
  });

  static const Color darkGreen = Color(0xFF145A00);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    style: const TextStyle(
                      color: darkGreen,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
                InkWell(
                  onTap: onView,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 28,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: darkGreen,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.remove_red_eye_outlined,
                          color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'View',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (int i = 0; i < item.leftLabels.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 86,
                      child: Text(
                        item.leftLabels[i],
                        style: const TextStyle(fontSize: 11, color: Colors.black54),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item.rightValues[i],
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// -------------------- MODEL --------------------

class _TaskItem {
  final DateTime date;
  final String time;
  final String title;
  final List<String> leftLabels;
  final List<String> rightValues;
  final int sortOrderMinutes;

  const _TaskItem({
    required this.date,
    required this.time,
    required this.title,
    required this.leftLabels,
    required this.rightValues,
    required this.sortOrderMinutes,
  });
}
