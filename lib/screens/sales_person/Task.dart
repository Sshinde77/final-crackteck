import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../widgets/bottom_navigation.dart';

class TaskScreen extends StatefulWidget {
  final int roleId;
  final String roleName;

  // const SalespersonDashboard({super.key});
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

  // ✅ selected date (drives month + week + tasks)
  late DateTime _selectedDate;

  // ✅ week view (Mon–Sat)
  late List<DateTime> _weekMonToSat;

  // ✅ month dropdown label
  late String _monthLabel;

  // Dummy tasks; add `date:` so we can filter by selected date
  late List<_TaskItem> _allTasks;

  @override
  void initState() {
    super.initState();

    _selectedDate = _stripTime(DateTime.now());
    _weekMonToSat = _weekFromDate(_selectedDate);
    _monthLabel = _monthName(_selectedDate.month);

    _allTasks = [
      _TaskItem(
        date: _selectedDate,
        time: "9:30 Am",
        title: "Meeting",
        leftLabels: ["Lead ID", "Meeting ID", "Number", "Location"],
        rightValues: ["L-001", "M-001", "+91 **** ****", "ABC Corp HQ"],
      ),
      _TaskItem(
        date: _selectedDate,
        time: "10:00 Am",
        title: "Follow Up",
        leftLabels: ["Lead ID", "Title", "Number", "Location"],
        rightValues: ["L-001", "M-001", "+91 **** ****", "ABC Corp HQ"],
      ),
      _TaskItem(
        date: _selectedDate,
        time: "10:30 Am",
        title: "Follow Up",
        leftLabels: ["Lead ID", "Title", "Number", "Location"],
        rightValues: ["L-001", "M-001", "+91 **** ****", "ABC Corp HQ"],
      ),
      _TaskItem(
        date: _selectedDate,
        time: "11:00 Am",
        title: "Meeting",
        leftLabels: ["Lead ID", "Meeting ID", "Number", "Location"],
        rightValues: ["L-001", "M-001", "+91 **** ****", "ABC Corp HQ"],
      ),
      // Example task on another day (to show filtering works)
      _TaskItem(
        date: _selectedDate.add(const Duration(days: 1)),
        time: "1:00 Pm",
        title: "Meeting",
        leftLabels: ["Lead ID", "Meeting ID", "Number", "Location"],
        rightValues: ["L-020", "M-020", "+91 **** ****", "Client Office"],
      ),
    ];
  }

  // ------------------ date helpers ------------------

  DateTime _stripTime(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  int _daysInMonth(int year, int month) {
    final firstNextMonth = (month == 12) ? DateTime(year + 1, 1, 1) : DateTime(year, month + 1, 1);
    return firstNextMonth.subtract(const Duration(days: 1)).day;
  }

  List<DateTime> _weekFromDate(DateTime date) {
    // Monday is 1
    final monday = date.subtract(Duration(days: date.weekday - 1));
    return List.generate(6, (i) => _stripTime(monday.add(Duration(days: i))));
  }

  String _monthName(int m) {
    const months = [
      "January","February","March","April","May","June",
      "July","August","September","October","November","December"
    ];
    return months[m - 1];
  }

  void _setSelectedDate(DateTime d) {
    final clean = _stripTime(d);
    setState(() {
      _selectedDate = clean;
      _weekMonToSat = _weekFromDate(clean);
      _monthLabel = _monthName(clean.month); // ✅ month auto changes on date tap
    });
  }

  void _setMonth(int newMonth) {
    // Keep same day if possible, else clamp to last day of new month
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
    return _allTasks.where((t) => _isSameDay(t.date, _selectedDate)).toList();
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

  // ------------------ UI ------------------

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
          "Task",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          IconButton(
            onPressed: () {
              // Navigator.pushNamed(
              //   context,
              //   AppRoutes.NotificationScreen,
              //   arguments: NotificationArguments(
              //     roleId: widget.roleId,
              //     roleName: widget.roleName,
              //   ),
              // );
            },
            icon: const Icon(Icons.notifications_none, color: Colors.white),
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month dropdown + calendar icon (both clickable)
            Row(
              children: [
                _MonthDropdown(
                  label: _monthLabel,
                  onChangedMonthIndex: (monthIndex1to12) {
                    _setMonth(monthIndex1to12);
                  },
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
                    icon: const Icon(Icons.calendar_month_outlined, color: Colors.white),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Week row (Mon–Sat) ✅ clickable + highlights selected + month changes automatically
            _WeekStrip(
              dates: _weekMonToSat,
              selectedDate: _selectedDate,
              isToday: (d) => _isSameDay(d, today),
              onTapDay: (d) => _setSelectedDate(d),
            ),

            const SizedBox(height: 14),

            // Timeline list (cards + view button are clickable)
            if (tasks.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "No tasks for ${_selectedDate.day}-${_selectedDate.month}-${_selectedDate.year}",
                  style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700),
                ),
              )
            else
              _TimelineList(
                tasks: tasks,
                onCardTap: (t) {
                  // TODO: open task details
                },
                onViewTap: (t) {
                  // TODO: open task details
                },
              ),
          ],
        ),
      ),

      bottomNavigationBar: CrackteckBottomSwitcher(
        isMoreOpen: _moreOpen,
        currentIndex: _navIndex,
        roleId: widget.roleId,
        roleName: widget.roleName,

               onHome: () { Navigator.pushNamed(context, AppRoutes.salespersonDashboard);},
        onProfile: () { Navigator.pushNamed(context, AppRoutes.salespersonProfile);},
        onMore: () => setState(() => _moreOpen = true),
        onLess: () => setState(() => _moreOpen = false),
        onLeads: () { Navigator.pushNamed(context, AppRoutes.salespersonLeads);},
        onFollowUp: () { Navigator.pushNamed(context, AppRoutes.salespersonFollowUp);},
        onMeeting: () { Navigator.pushNamed(context, AppRoutes.salespersonMeeting);},
        onQuotation: () { Navigator.pushNamed(context, AppRoutes.salespersonQuotation);},
      ),

    );
  }
}

// -------------------- MONTH DROPDOWN --------------------

class _MonthDropdown extends StatelessWidget {
  final String label;
  final ValueChanged<int> onChangedMonthIndex; // 1..12

  const _MonthDropdown({
    required this.label,
    required this.onChangedMonthIndex,
  });

  static const Color darkGreen = Color(0xFF145A00);

  @override
  Widget build(BuildContext context) {
    const months = [
      "January","February","March","April","May","June",
      "July","August","September","October","November","December"
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
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black87),
          icon: Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(left: 10),
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: darkGreen)),
            child: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: darkGreen),
          ),
          items: [
            for (final m in months)
              DropdownMenuItem<String>(value: m, child: Text(m)),
          ],
          onChanged: (v) {
            if (v == null) return;
            final idx = months.indexOf(v);
            if (idx >= 0) onChangedMonthIndex(idx + 1); // 1..12
          },
        ),
      ),
    );
  }
}

// -------------------- WEEK STRIP (CLICKABLE) --------------------

class _WeekStrip extends StatelessWidget {
  final List<DateTime> dates; // Mon–Sat
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
    const map = {1: "M", 2: "T", 3: "W", 4: "T", 5: "F", 6: "S", 7: "S"};
    return map[d.weekday] ?? "";
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
                  color: _sameDay(dates[i], selectedDate) ? const Color(0xFFF3FAF2) : Colors.white,
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
                        color: _sameDay(dates[i], selectedDate) ? darkGreen : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${dates[i].day}",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: _sameDay(dates[i], selectedDate) ? darkGreen : Colors.black87,
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
          Container(
            width: 16,
            alignment: Alignment.topCenter,
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

// -------------------- TASK CARD (CLICKABLE) --------------------

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
                        Icon(Icons.remove_red_eye_outlined, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text(
                          "View",
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
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
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
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

  const _TaskItem({
    required this.date,
    required this.time,
    required this.title,
    required this.leftLabels,
    required this.rightValues,
  });
}
