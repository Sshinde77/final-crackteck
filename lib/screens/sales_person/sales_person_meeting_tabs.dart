import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:final_crackteck/model/sales_person/meeting_model.dart';
import 'package:final_crackteck/model/sales_person/meetings_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/bottom_navigation.dart';

class SalesPersonMeetingScreen extends StatefulWidget {
  final int roleId;
  final String roleName;

  const SalesPersonMeetingScreen({
    super.key,
    required this.roleId,
    required this.roleName,
  });

  @override
  State<SalesPersonMeetingScreen> createState() =>
      _SalesPersonMeetingScreenState();
}

class _SalesPersonMeetingScreenState extends State<SalesPersonMeetingScreen> {
  static const Color midGreen = Color(0xFF1F8B00);
  static const Color darkGreen = Color(0xFF145A00);

  bool _moreOpen = false;
  int _navIndex = 0;

  final TextEditingController _searchCtrl = TextEditingController();

  // Popup filter values (like screenshot)
  final Set<String> _statusFilters = <String>{};

  // ✅ NEW: Date filter (single date like your screenshot)
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    // Trigger initial meetings load after first frame so Provider is available.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<MeetingsProvider>(context, listen: false);
      // We pass placeholder IDs here; ApiService.fetchMeetings will prefer
      // the values stored in SecureStorageService, matching fetchLeads pattern.
      provider.loadMeetings('', widget.roleId);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ✅ NEW: Parse "May 30, 2025 – 11:00 AM" to DateTime(2025,5,30)
  DateTime? _parseMeetingDate(String raw) {
    try {
      // split by en-dash or hyphen with spaces around
      final parts = raw.split(RegExp(r'\s[–-]\s'));
      final datePart = parts.isNotEmpty ? parts.first.trim() : raw.trim();

      // datePart like: "May 30, 2025" or "Jun 01, 2025"
      final byComma = datePart.split(',');
      if (byComma.length < 2) return null;

      final left = byComma[0].trim(); // "May 30"
      final yearStr = byComma[1].trim(); // "2025"
      final year = int.parse(yearStr);

      final leftParts = left.split(RegExp(r'\s+'));
      if (leftParts.length < 2) return null;

      final monthStr = leftParts[0].trim();
      final day = int.parse(leftParts[1].trim());

      final month = _monthNumber(monthStr);
      if (month == null) return null;

      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }

  int? _monthNumber(String m) {
    final key = m.toLowerCase();
    const map = {
      "jan": 1,
      "january": 1,
      "feb": 2,
      "february": 2,
      "mar": 3,
      "march": 3,
      "apr": 4,
      "april": 4,
      "may": 5,
      "jun": 6,
      "june": 6,
      "jul": 7,
      "july": 7,
      "aug": 8,
      "august": 8,
      "sep": 9,
      "sept": 9,
      "september": 9,
      "oct": 10,
      "october": 10,
      "nov": 11,
      "november": 11,
      "dec": 12,
      "december": 12,
    };
    return map[key];
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  DateTime? _parseApiDate(String raw) {
    if (raw.isEmpty) return null;
    try {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) return parsed;
      // Fallback: try dd/MM/yyyy like other screens.
      if (raw.contains('/')) {
        final parts = raw.split('/');
        if (parts.length == 3) {
          final dd = int.parse(parts[0]);
          final mm = int.parse(parts[1]);
          final yy = int.parse(parts[2]);
          return DateTime(yy, mm, dd);
        }
      }
    } catch (_) {}
    return null;
  }

  String _formatShortDate(DateTime d) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return "${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}";
  }

  String _formatMeetingDateTime(DateTime? date, String time) {
    if (date == null) {
      return time.trim().isEmpty ? '' : time.trim();
    }
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    final monthName = months[date.month - 1];
    final datePart = "$monthName ${date.day}, ${date.year}";
    final timePart = time.trim().isEmpty ? '' : " – ${time.trim()}";
    return "$datePart$timePart";
  }

  _MeetingItem _mapMeetingModelToItem(MeetingModel model) {
    final nestedLead = model.lead;
    // Prefer lead name, then company name, then meeting title.
    String title = '';
    if (nestedLead != null && nestedLead.name.isNotEmpty) {
      title = nestedLead.name;
    } else if (nestedLead != null && nestedLead.companyName.isNotEmpty) {
      title = nestedLead.companyName;
    } else if (model.meetTitle.isNotEmpty) {
      title = model.meetTitle;
    } else {
      title = 'Meeting #${model.id}';
    }

    final location = model.location.isNotEmpty
        ? model.location
        : (nestedLead?.companyName ?? '');

    final idStr = model.leadId.isNotEmpty
        ? model.leadId
        : (nestedLead?.id.toString() ?? '');

    final statusRaw = model.status.toLowerCase();
    String pillStatus;
    if (statusRaw == 'cancelled' || statusRaw == 'canceled') {
      pillStatus = 'Cancelled';
    } else if (statusRaw == 'scheduled') {
      pillStatus = 'Scheduled';
    } else if (statusRaw == 'completed' || statusRaw == 'done') {
      // Map completed/done to "Confirmed" pill to match existing UI.
      pillStatus = 'Confirmed';
    } else {
      pillStatus = 'Pending';
    }

    final date = _parseApiDate(model.date);
    final dateTimeStr = _formatMeetingDateTime(date, model.time);

    return _MeetingItem(
      leadId: idStr,
      meetingId: model.id.toString(),
      title: title,
      dateTime: dateTimeStr,
      location: location,
      status: model.status,
      pillStatus: pillStatus,
      contactName: nestedLead?.name ?? '',
      contactEmailOrPhone: (nestedLead?.phone ?? '').isNotEmpty
          ? (nestedLead?.phone ?? '')
          : (nestedLead?.email ?? ''),
      leadName: nestedLead?.name ?? '',
      phone: nestedLead?.phone ?? '',
      email: nestedLead?.email ?? '',
      requirementType: nestedLead?.requirementType ?? '',
      budgetRange: nestedLead?.budgetRange ?? '',
      meetingTitle: model.meetTitle,
      rawDate: model.date,
      rawTime: model.time,
      rawStartTime: model.startTime,
      rawEndTime: model.endTime,
      meetingType: model.meetingType,
      agenda: model.meetAgenda,
      followUpTask: model.followUp,
    );
  }

  List<_MeetingItem> _filteredMeetingsFrom(List<MeetingModel> source) {
    final q = _searchCtrl.text.trim().toLowerCase();
    final baseItems = source.map(_mapMeetingModelToItem).toList();

    final list = baseItems.where((x) {
      final matchesSearch =
          q.isEmpty ||
              x.leadId.toLowerCase().contains(q) ||
              x.meetingId.toLowerCase().contains(q) ||
              x.title.toLowerCase().contains(q) ||
              x.dateTime.toLowerCase().contains(q) ||
              x.location.toLowerCase().contains(q) ||
              x.status.toLowerCase().contains(q) ||
              x.pillStatus.toLowerCase().contains(q);

      final matchesStatus =
          _statusFilters.isEmpty || _statusFilters.contains(x.pillStatus);

      final matchesDate = _selectedDate == null
          ? true
          : (() {
        final d = _parseMeetingDate(x.dateTime);
        if (d == null) return false;
        return _isSameDay(d, _selectedDate!);
      })();

      return matchesSearch && matchesStatus && matchesDate;
    }).toList();

    list.sort((a, b) {
      final da = _parseMeetingDate(a.dateTime);
      final db = _parseMeetingDate(b.dateTime);
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da);
    });

    return list;
  }

  Future<void> _openFilterPopup() async {
    final temp = Set<String>.from(_statusFilters);

    // ✅ NEW: temp date inside popup
    DateTime? tempDate = _selectedDate;

    await showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            Widget checkboxItem({
              required String label,
              required bool checked,
              required VoidCallback onTap,
            }) {
              return InkWell(
                onTap: onTap,
                child: Row(
                  children: [
                    Icon(
                      checked ? Icons.check_box : Icons.check_box_outline_blank,
                      color: checked ? darkGreen : const Color(0xFFBDBDBD),
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            }

            Future<void> pickDate() async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: ctx,
                initialDate: tempDate ?? now,
                firstDate: DateTime(now.year - 5),
                lastDate: DateTime(now.year + 5),
                helpText: "Select date",
              );

              if (picked != null) {
                setModalState(() => tempDate = picked);
              }
            }

            return Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: MediaQuery.of(ctx).size.width * 0.82,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Status",
                        style: TextStyle(
                          color: darkGreen,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                            child: checkboxItem(
                              label: "Pending",
                              checked: temp.contains("Pending"),
                              onTap: () => setModalState(() {
                                temp.contains("Pending")
                                    ? temp.remove("Pending")
                                    : temp.add("Pending");
                              }),
                            ),
                          ),
                          Expanded(
                            child: checkboxItem(
                              label: "Scheduled",
                              checked: temp.contains("Scheduled"),
                              onTap: () => setModalState(() {
                                temp.contains("Scheduled")
                                    ? temp.remove("Scheduled")
                                    : temp.add("Scheduled");
                              }),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: checkboxItem(
                              label: "Confirmed",
                              checked: temp.contains("Confirmed"),
                              onTap: () => setModalState(() {
                                temp.contains("Confirmed")
                                    ? temp.remove("Confirmed")
                                    : temp.add("Confirmed");
                              }),
                            ),
                          ),
                          Expanded(
                            child: checkboxItem(
                              label: "Cancelled",
                              checked: temp.contains("Cancelled"),
                              onTap: () => setModalState(() {
                                temp.contains("Cancelled")
                                    ? temp.remove("Cancelled")
                                    : temp.add("Cancelled");
                              }),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // ✅ NEW: Date UI exactly like your image
                      const Text(
                        "Date",
                        style: TextStyle(
                          color: darkGreen,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: pickDate,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                height: 46,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.black12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_month,
                                      color: darkGreen,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        tempDate == null
                                            ? "Select date"
                                            : _formatShortDate(tempDate!),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: Colors.black54,
                                      size: 22,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          InkWell(
                            onTap: () => setModalState(() => tempDate = null),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: 46,
                              width: 84,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFE0E0),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                "Clear",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => Navigator.pop(ctx),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFE0E0),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: const Text(
                                  "Close",
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _statusFilters
                                    ..clear()
                                    ..addAll(temp);

                                  // ✅ save date
                                  _selectedDate = tempDate;
                                });
                                Navigator.pop(ctx);
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDFFFD7),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: const Text(
                                  "Save",
                                  style: TextStyle(
                                    color: darkGreen,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final meetingsProvider = Provider.of<MeetingsProvider>(context);
    final list = _filteredMeetingsFrom(meetingsProvider.meetings);

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
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Meeting",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
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
      body: SafeArea(
        child: Column(
          children: [
            // Search + Filter row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search,
                            color: Colors.black45,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchCtrl,
                              decoration: const InputDecoration(
                                hintText: "Search",
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: _openFilterPopup,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 50,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: const Icon(
                        Icons.filter_alt_outlined,
                        color: darkGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: RefreshIndicator(
                onRefresh: () =>
                    meetingsProvider.refreshMeetings('', widget.roleId),
                child: Stack(
                  children: [
                    ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 130),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = list[index];
                        return _MeetingCard(
                          item: item,
                          onView: () {
                            showDialog(
                              context: context,
                              barrierDismissible: true,
                              builder: (_) => _MeetingCenterDialog(item: item),
                            );
                          },
                          onEdit: () => _snack("Edit ${item.meetingId}"),
                          onStatusTap: () =>
                              _snack("Status ${item.pillStatus}"),
                        );
                      },
                    ),

                    if (meetingsProvider.isLoading &&
                        meetingsProvider.meetings.isEmpty)
                      const Center(child: CircularProgressIndicator()),

                    if (!meetingsProvider.isLoading &&
                        meetingsProvider.errorMessage != null)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Failed to load meetings',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                meetingsProvider.errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () =>
                                    meetingsProvider.loadMeetings(
                                      '',
                                      widget.roleId,
                                    ),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      ),

                    if (!meetingsProvider.isLoading &&
                        meetingsProvider.errorMessage == null &&
                        list.isEmpty)
                      const Center(
                        child: Text(
                          "No meetings found",
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),

                    // Add Meeting button
                    Positioned(
                      right: 16,
                      bottom: 18,
                      child: InkWell(
                        onTap: () {
                          Navigator.pushNamed(context, AppRoutes.salespernewsonMeeting);
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: darkGreen,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.14),
                                blurRadius: 14,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add, color: Colors.white, size: 18),
                              SizedBox(width: 8),
                              Text(
                                "Add Meeting",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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

// =================== CARD ===================

class _MeetingCard extends StatelessWidget {
  final _MeetingItem item;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onStatusTap;

  const _MeetingCard({
    required this.item,
    required this.onView,
    required this.onEdit,
    required this.onStatusTap,
  });

  static const Color darkGreen = Color(0xFF145A00);

  @override
  Widget build(BuildContext context) {
    final pill = _pillStyle(item.pillStatus);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        children: [
          _kv("Lead ID", item.leadId),
          _kv("Meeting ID", item.meetingId),
          _kv("Title", item.title),
          _kv("Date & Time", item.dateTime),
          _kv("Location", item.location),
          _kv("Status", item.status),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SmallButton(
                  bg: const Color(0xFFE9FFE6),
                  fg: darkGreen,
                  label: "View",
                  icon: Icons.remove_red_eye_outlined,
                  onTap: onView,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SmallButton(
                  bg: const Color(0xFFFFE6D6),
                  fg: Colors.deepOrange,
                  label: "Edit",
                  icon: Icons.edit_outlined,
                  onTap: onEdit,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: onStatusTap,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: pill.bg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      item.pillStatus,
                      style: TextStyle(
                        color: pill.fg,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  _PillStyle _pillStyle(String s) {
    switch (s) {
      case "Cancelled":
        return const _PillStyle(bg: Color(0xFFFFE0E0), fg: Colors.red);
      case "Pending":
        return const _PillStyle(bg: Color(0xFFEDEDED), fg: Colors.black87);
      case "Scheduled":
        return const _PillStyle(bg: Color(0xFFE7F2FF), fg: Color(0xFF0057B7));
      case "Confirmed":
        return const _PillStyle(bg: darkGreen, fg: Colors.white);
      default:
        return const _PillStyle(bg: Color(0xFFEDEDED), fg: Colors.black87);
    }
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              k,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
          Text(
            v,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _PillStyle {
  final Color bg;
  final Color fg;
  const _PillStyle({required this.bg, required this.fg});
}

class _SmallButton extends StatelessWidget {
  final Color bg;
  final Color fg;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _SmallButton({
    required this.bg,
    required this.fg,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(color: fg, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

// =================== MODEL ===================

class _MeetingItem {
  final String leadId;
  final String meetingId;
  final String title;
  final String dateTime;
  final String location;
  final String status;

  /// This is what the popup filters (Pending / Scheduled / Confirmed / Cancelled)
  final String pillStatus;
  // Extra fields for the detail dialog.
  final String contactName;
  final String contactEmailOrPhone;
  final String rawDate;
  final String rawTime;
  final String rawStartTime;
  final String rawEndTime;
  final String meetingType;
  final String agenda;
  final String followUpTask;
  final String leadName;
  final String phone;
  final String email;
  final String requirementType;
  final String budgetRange;
  final String meetingTitle;

  const _MeetingItem({
    required this.leadId,
    required this.meetingId,
    required this.title,
    required this.dateTime,
    required this.location,
    required this.status,
    required this.pillStatus,
    this.contactName = '',
    this.contactEmailOrPhone = '',
    this.rawDate = '',
    this.rawTime = '',
    this.rawStartTime = '',
    this.rawEndTime = '',
    this.meetingType = '',
    this.agenda = '',
    this.followUpTask = '',
    this.leadName = '',
    this.phone = '',
    this.email = '',
    this.requirementType = '',
    this.budgetRange = '',
    this.meetingTitle = '',
  });
}

const Color kDarkGreen = Color(0xFF145A00);

class _MeetingCenterDialog extends StatelessWidget {
  final _MeetingItem item;

  const _MeetingCenterDialog({required this.item});

  List<String> _splitTimeRange(String value) {
    final raw = value.trim();
    if (raw.isEmpty) return const <String>[];

    final match = RegExp(
      r'^\s*(.+?)\s*(?:-|–|to)\s*(.+?)\s*$',
      caseSensitive: false,
    ).firstMatch(raw);
    if (match != null) {
      return <String>[match.group(1)!.trim(), match.group(2)!.trim()];
    }
    return <String>[raw];
  }

  @override
  Widget build(BuildContext context) {
    final name = item.leadName.isNotEmpty
        ? item.leadName
        : (item.contactName.isNotEmpty ? item.contactName : item.title);
    final phone = item.phone.trim();
    final email = item.email.trim();
    final requirementType = item.requirementType.trim();
    final budgetRange = item.budgetRange.trim();
    final meetingTitle = item.meetingTitle.trim().isNotEmpty
        ? item.meetingTitle.trim()
        : item.title;
    final meetingType = item.meetingType.trim();
    final location = item.location.trim();
    final popupDate = item.rawDate.isNotEmpty
        ? item.rawDate
        : (item.dateTime.split('–').first.trim());
    final popupTime = item.rawTime.isNotEmpty
        ? item.rawTime
        : (item.dateTime.split('–').length > 1
        ? item.dateTime.split('–')[1].trim()
        : '');
    final parsedRange = _splitTimeRange(popupTime);
    final startTime = item.rawStartTime.trim().isNotEmpty
        ? item.rawStartTime.trim()
        : (parsedRange.isNotEmpty ? parsedRange.first : '');
    final endTime = item.rawEndTime.trim().isNotEmpty
        ? item.rawEndTime.trim()
        : (parsedRange.length > 1 ? parsedRange[1] : '');

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 345,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: SingleChildScrollView(
            // ✅ meeting popup is bigger, scroll if needed
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Meeting",
                    style: TextStyle(
                      color: kDarkGreen,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                _KVRow(label: "Lead ID", value: item.leadId),
                _KVRow(label: "Meeting ID", value: item.meetingId),
                _KVRow(label: "Name", value: name.isNotEmpty ? name : '--'),
                _KVRow(label: "Phone", value: phone.isNotEmpty ? phone : '--'),
                _KVRow(label: "Email", value: email.isNotEmpty ? email : '--'),
                _KVRow(
                  label: "Requirement Type",
                  value: requirementType.isNotEmpty ? requirementType : '--',
                ),
                _KVRow(
                  label: "Budget Range",
                  value: budgetRange.isNotEmpty ? budgetRange : '--',
                ),
                _KVRow(label: "Meeting Title", value: meetingTitle),
                _KVRow(
                  label: "Meeting Type",
                  value: meetingType.isNotEmpty ? meetingType : '--',
                ),
                _KVRow(label: "Date", value: popupDate.isNotEmpty ? popupDate : '--'),
                _KVRow(
                  label: "Start Time",
                  value: startTime.isNotEmpty ? startTime : '--',
                ),
                _KVRow(
                  label: "End Time",
                  value: endTime.isNotEmpty ? endTime : '--',
                ),
                _KVRow(
                  label: "Location / Meeting Link",
                  value: location.isNotEmpty ? location : '--',
                  multiline: true,
                ),
                _KVRow(
                  label: "Status",
                  value: item.status,
                  statusRed: item.pillStatus == 'Cancelled',
                ),
                if (item.agenda.isNotEmpty)
                  _KVRow(
                    label: "Meeting Agenda / Notes",
                    value: item.agenda,
                    multiline: true,
                  ),
                if (item.followUpTask.isNotEmpty)
                  _KVRow(
                    label: "Follow-up Task",
                    value: item.followUpTask,
                    multiline: true,
                  ),

                const SizedBox(height: 8),

                // Row(
                //   crossAxisAlignment: CrossAxisAlignment.start,
                //   children: [
                //     const SizedBox(
                //       width: 140,
                //       child: Text(
                //         "Attachments",
                //         style: TextStyle(fontSize: 12, color: Colors.black54),
                //       ),
                //     ),
                //     Expanded(
                //       child: Container(
                //         height: 86,
                //         alignment: Alignment.center,
                //         decoration: BoxDecoration(
                //           color: Colors.black12,
                //           borderRadius: BorderRadius.circular(10),
                //         ),
                //         child: const Text(
                //           "IMAGE",
                //           style: TextStyle(
                //             fontWeight: FontWeight.w800,
                //             color: Colors.black54,
                //           ),
                //         ),
                //       ),
                //     ),
                //   ],
                // ),

                const SizedBox(height: 16),

                // Row(
                //   children: [
                //     Expanded(
                //       child: _GreenButton(
                //         icon: Icons.call,
                //         label: "Call",
                //         onTap: () {},
                //       ),
                //     ),
                //     const SizedBox(width: 12),
                //     Expanded(
                //       child: _GreenButton(
                //         icon: Icons.chat_bubble_outline,
                //         label: "Chat",
                //         onTap: () {},
                //       ),
                //     ),
                //   ],
                // ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _SoftActionButton(
                        icon: Icons.edit_outlined,
                        label: "Edit",
                        bg: const Color(0xFFFFE6D6),
                        fg: Colors.deepOrange,
                        onTap: () {},
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SoftActionButton(
                        icon: Icons.delete_outline,
                        label: "Delete",
                        bg: const Color(0xFFFFE6E6),
                        fg: Colors.red,
                        onTap: () {},
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// =======================
/// SHARED UI
/// =======================
class _KVRow extends StatelessWidget {
  final String label;
  final String value;
  final bool multiline;
  final bool statusRed;

  const _KVRow({
    required this.label,
    required this.value,
    this.multiline = false,
    this.statusRed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: multiline
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: multiline ? 3 : 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: statusRed ? Colors.red : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GreenButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _GreenButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: kDarkGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _SoftActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;

  const _SoftActionButton({
    required this.icon,
    required this.label,
    required this.bg,
    required this.fg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: fg),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(color: fg, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}
