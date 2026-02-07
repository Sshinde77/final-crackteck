import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:final_crackteck/model/sales_person/followup_model.dart';
import 'package:final_crackteck/model/sales_person/followup_provider.dart';
import '../../core/secure_storage_service.dart';
import '../../routes/app_routes.dart';
import '../../widgets/bottom_navigation.dart';

class SalesPersonFollowUpScreen extends StatefulWidget {
  const SalesPersonFollowUpScreen({super.key, required String roleName, required int roleId});

  @override
  State<SalesPersonFollowUpScreen> createState() =>
      _SalesPersonFollowUpScreenState();
}

class _SalesPersonFollowUpScreenState extends State<SalesPersonFollowUpScreen> {
  // Colors
  static const Color midGreen = Color(0xFF1F8B00);
  static const Color darkGreen = Color(0xFF145A00);
  bool _moreOpen = false;
  int _navIndex = 0;

  int _roleId = 3;
  String _roleName = 'Salesperson';

  final TextEditingController _searchCtrl = TextEditingController();

  // ✅ Status filters (same 3 as Leads)
  final Set<FollowUpStatus> _statusFilters = {};

  // ✅ Selected date filter
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadRoleFromStorage();
    // Trigger initial follow-ups load after first frame so Provider is available.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<FollowUpProvider>(context, listen: false);
      provider.loadFollowUps();
    });
  }

  Future<void> _loadRoleFromStorage() async {
    final storedRoleId = await SecureStorageService.getRoleId();
    if (!mounted) return;
    if (storedRoleId != null) {
      setState(() {
        _roleId = storedRoleId;
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showViewPopup(FollowUpItem item) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (ctx) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ===== HEADER =====
                  const Text(
                    "Follow-Up",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),

                  _row("Lead ID", item.leadId),
                  _row("Number", item.number),
                  _row("Name", item.name),
                  _row("Email", "example@.com"), // static for now
                  _row("Date", item.date),
                  _row("Time", item.time),

                  const SizedBox(height: 6),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Status",
                        style: TextStyle(color: Colors.grey),
                      ),
                      Text(
                        statusLabel(item.status),
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  _row("Remarks", "Interested in Mac support service"),

                  const SizedBox(height: 18),

                  // ===== TIMELINE =====
                  Row(
                    children: [
                      _dot(active: true),
                      _line(),
                      _dot(active: true),
                      _line(),
                      _dot(active: false),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("20/03/25", style: TextStyle(fontSize: 10)),
                      Text("22/03/25", style: TextStyle(fontSize: 10)),
                      Text("25/03/25", style: TextStyle(fontSize: 10)),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ===== CALL / CHAT =====
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.call),
                          label: const Text("Call"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: darkGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.chat),
                          label: const Text("Chat"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: darkGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ===== EDIT / DELETE =====
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE6D6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: TextButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.edit, color: Colors.orange),
                            label: const Text(
                              "Edit",
                              style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE0E0),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: TextButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.delete, color: Colors.red),
                            label: const Text(
                              "Delete",
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w800,
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
  }

  Widget _row(String k, String v) {
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

  Widget _dot({required bool active}) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: active ? Colors.green : Colors.grey.shade300,
        shape: BoxShape.circle,
      ),
      child: active
          ? const Icon(Icons.check, size: 12, color: Colors.white)
          : null,
    );
  }

  Widget _line() {
    return Expanded(child: Container(height: 2, color: Colors.green));
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  DateTime? _parseDMY(String dmy) {
    // expects dd/MM/yyyy
    try {
      final parts = dmy.split("/");
      if (parts.length != 3) return null;
      final dd = int.parse(parts[0]);
      final mm = int.parse(parts[1]);
      final yy = int.parse(parts[2]);
      return DateTime(yy, mm, dd);
    } catch (_) {
      return null;
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatDMY(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yy = d.year.toString();
    return "$dd/$mm/$yy";
  }

  FollowUpItem _mapFollowUpModelToItem(FollowUpModel model) {
    final nestedLead = model.lead;
    final name = nestedLead?.name ?? '';
    final company = nestedLead?.companyName ?? '';
    final industry = nestedLead?.industryType ?? '';
    final number = nestedLead?.phone ?? '';

    final statusRaw = model.status.toLowerCase();
    FollowUpStatus status;
    if (statusRaw == 'done' || statusRaw == 'completed') {
      status = FollowUpStatus.confirmed;
    } else if (statusRaw == 'cancelled' || statusRaw == 'canceled') {
      status = FollowUpStatus.cancelled;
    } else {
      // Treat "Pending", "Rescheduled" and any unknowns as pending.
      status = FollowUpStatus.pending;
    }

    final idStr = model.leadId.isNotEmpty
        ? model.leadId
        : (nestedLead?.id.toString() ?? '');

    return FollowUpItem(
      leadId: idStr,
      name: name,
      number: number,
      date: _formatDMY(model.followupDate),
      time: model.followupTime,
      company: company,
      industry: industry,
      status: status,
    );
  }

  List<FollowUpItem> _filteredFollowUpsFrom(List<FollowUpModel> source) {
    final q = _searchCtrl.text.trim().toLowerCase();
    final items = source.map(_mapFollowUpModelToItem).toList();

    return items.where((x) {
      final matchesSearch =
          q.isEmpty ||
          x.leadId.toLowerCase().contains(q) ||
          x.name.toLowerCase().contains(q) ||
          x.number.toLowerCase().contains(q) ||
          x.date.toLowerCase().contains(q) ||
          x.time.toLowerCase().contains(q) ||
          x.company.toLowerCase().contains(q) ||
          x.industry.toLowerCase().contains(q) ||
          statusLabel(x.status).toLowerCase().contains(q);

      final matchesStatus =
          _statusFilters.isEmpty || _statusFilters.contains(x.status);

      final matchesDate = _selectedDate == null
          ? true
          : (() {
              final itemDate = _parseDMY(x.date);
              if (itemDate == null) return false;
              return _isSameDay(itemDate, _selectedDate!);
            })();

      return matchesSearch && matchesStatus && matchesDate;
    }).toList();
  }

  Future<void> _openFilterPopup() async {
    final tempStatuses = Set<FollowUpStatus>.from(_statusFilters);
    DateTime? tempDate = _selectedDate;

    await showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            Widget checkRow(FollowUpStatus s) {
              final checked = tempStatuses.contains(s);
              return InkWell(
                onTap: () => setModalState(() {
                  checked ? tempStatuses.remove(s) : tempStatuses.add(s);
                }),
                child: Row(
                  children: [
                    Icon(
                      checked ? Icons.check_box : Icons.check_box_outline_blank,
                      color: checked ? darkGreen : const Color(0xFFBDBDBD),
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      statusLabel(s),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              );
            }

            Future<void> pickDate() async {
              final picked = await showDatePicker(
                context: ctx,
                initialDate: tempDate ?? DateTime.now(),
                firstDate: DateTime(2020, 1, 1),
                lastDate: DateTime(2035, 12, 31),
              );
              if (picked != null) {
                setModalState(() => tempDate = picked);
              }
            }

            return Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: MediaQuery.of(ctx).size.width * 0.84,
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
                      const SizedBox(height: 12),

                      // ✅ 3 options like Leads
                      checkRow(FollowUpStatus.confirmed),
                      const SizedBox(height: 10),
                      checkRow(FollowUpStatus.pending),
                      const SizedBox(height: 10),
                      checkRow(FollowUpStatus.cancelled),

                      const SizedBox(height: 16),

                      // ✅ Date filter (Calendar button inside popup)
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
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                height: 44,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.black12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_month_outlined,
                                      color: darkGreen,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        tempDate == null
                                            ? "Select date"
                                            : _formatDMY(tempDate!),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: Colors.black54,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          InkWell(
                            onTap: () => setModalState(() => tempDate = null),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              height: 44,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFE0E0),
                                borderRadius: BorderRadius.circular(10),
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
                                    ..addAll(tempStatuses);
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

  @override
  Widget build(BuildContext context) {
    final followUpProvider = Provider.of<FollowUpProvider>(context);
    final list = _filteredFollowUpsFrom(followUpProvider.followUps);

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
          "Follow-Up",
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
                onRefresh: () => followUpProvider.loadFollowUps(),
                child: Stack(
                  children: [
                    ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = list[index];
                        return FollowUpCard(
                          item: item,
                          onView: () => _showViewPopup(item),
                          onEdit: () => _snack("Edit ${item.leadId}"),
                          onStatusTap: () =>
                              _snack("Status: ${statusLabel(item.status)}"),
                        );
                      },
                    ),

                    if (followUpProvider.loading)
                      const Center(child: CircularProgressIndicator()),

                    if (!followUpProvider.loading &&
                        followUpProvider.error != null)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Failed to load follow-ups',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                followUpProvider.error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () =>
                                    followUpProvider.loadFollowUps(),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      ),

                    if (!followUpProvider.loading &&
                        followUpProvider.error == null &&
                        list.isEmpty)
                      const Center(
                        child: Text(
                          "No follow-ups found",
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),

                    // Floating "Add Follow-Up" button
                    Positioned(
                      right: 16,
                      bottom: 18,
                      child: InkWell(
                        onTap: () {
                          Navigator.pushNamed(context, AppRoutes.newfollowupscreen);
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
                                "Add Follow-Up",
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
        roleId: _roleId,
        roleName: _roleName,
        onHome: () {
          // From follow-up screen, treat Home as "back to dashboard".
          Navigator.pop(context);
        },
        onProfile: () {},
        onMore: () => setState(() => _moreOpen = true),
        onLess: () => setState(() => _moreOpen = false),
        onLeads: () {
          Navigator.pushNamed(context, AppRoutes.salespersonLeads);
        },
        onFollowUp: () {},
        onMeeting: () {},
        onQuotation: () {},
      ),
    );
  }
}

// ======================= CARD =======================

class FollowUpCard extends StatelessWidget {
  static const Color darkGreen = Color(0xFF145A00);

  final FollowUpItem item;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onStatusTap;

  const FollowUpCard({
    super.key,
    required this.item,
    required this.onView,
    required this.onEdit,
    required this.onStatusTap,
  });

  @override
  Widget build(BuildContext context) {
    final pill = statusPill(item.status);

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
          _kv("Name", item.name),
          _kv("Number", item.number),
          _kv("Date", item.date),
          _kv("Time", item.time),
          _kv("Status", statusLabel(item.status)),
          const SizedBox(height: 12),

          // View / Edit / Status (same style as Leads)
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
                      pill.text,
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

// ======================= MODEL + STATUS =======================

enum FollowUpStatus { confirmed, pending, cancelled }

class FollowUpItem {
  final String leadId;
  final String name;
  final String number;
  final String date; // dd/MM/yyyy
  final String time;

  final String company;
  final String industry;

  final FollowUpStatus status;

  FollowUpItem({
    required this.leadId,
    required this.name,
    required this.number,
    required this.date,
    required this.time,
    required this.company,
    required this.industry,
    required this.status,
  });
}

String statusLabel(FollowUpStatus s) {
  switch (s) {
    case FollowUpStatus.confirmed:
      return "Confirmed";
    case FollowUpStatus.pending:
      return "Pending";
    case FollowUpStatus.cancelled:
      return "Canceled";
  }
}

class _Pill {
  final Color bg;
  final Color fg;
  final String text;
  const _Pill({required this.bg, required this.fg, required this.text});
}

_Pill statusPill(FollowUpStatus s) {
  switch (s) {
    case FollowUpStatus.confirmed:
      return const _Pill(
        bg: Color(0xFF145A00),
        fg: Colors.white,
        text: "Confirmed",
      );
    case FollowUpStatus.pending:
      return const _Pill(
        bg: Color(0xFFEDEDED),
        fg: Colors.black87,
        text: "Pending",
      );
    case FollowUpStatus.cancelled:
      return const _Pill(
        bg: Color(0xFFFFE0E0),
        fg: Colors.red,
        text: "Canceled",
      );
  }
}
