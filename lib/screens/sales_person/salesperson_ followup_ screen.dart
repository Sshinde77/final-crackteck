import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:final_crackteck/model/sales_person/followup_model.dart';
import 'package:final_crackteck/model/sales_person/followup_provider.dart';
import 'package:final_crackteck/screens/sales_person/Sales_new_follow-up_screen.dart';
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

  Future<void> _openEditFollowUp(FollowUpItem item) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => NewFollowUpScreen(
          roleId: _roleId,
          roleName: _roleName,
          isEdit: true,
          followUpId: item.followUpId,
          initialLeadId: item.leadNumericId,
          initialLeadIdDisplay: item.leadId,
          initialClientName: item.name,
          initialPhone: item.number,
          initialEmail: item.email,
          initialFollowUpDate: item.date,
          initialFollowUpTime: item.time,
          initialRemarks: item.remarks,
          initialFollowUpStatus: item.statusText,
        ),
      ),
    );

    if (!mounted) return;
    if (updated == true) {
      await Provider.of<FollowUpProvider>(context, listen: false).loadFollowUps();
    }
  }

  Future<void> _deleteFollowUp(FollowUpItem item) async {
    final provider = Provider.of<FollowUpProvider>(context, listen: false);
    final deleted = await provider.deleteFollowUp(item.followUpId);
    if (!mounted) return;

    if (deleted) {
      _snack("Follow-up deleted successfully");
      return;
    }

    _snack(provider.error ?? "Failed to delete follow-up. Please try again.");
  }

  void _showViewPopup(FollowUpItem item) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (ctx) {
        String apiValue(String value) {
          final v = value.trim();
          return v.isEmpty ? '-' : v;
        }

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
                  const Text(
                    "Follow-Up",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  _row("Lead ID", apiValue(item.leadId)),
                  _row("Name", apiValue(item.name)),
                  _row("Phone", apiValue(item.number)),
                  _row("Email", apiValue(item.email)),
                  _row("Requirement Type", apiValue(item.requirementType)),
                  _row("Budget Range", apiValue(item.budgetRange)),
                  _row("Urgency", apiValue(item.urgency)),
                  _row("Lead Status", apiValue(item.leadStatusText)),
                  _row("Follow-up Date", apiValue(item.date)),
                  _row("Follow-up Time", apiValue(item.time)),
                  _row("Follow-up Status", apiValue(item.statusText)),
                  _row("Remarks", apiValue(item.remarks)),
                  const SizedBox(height: 12),
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
                            onPressed: () {
                              Navigator.pop(ctx);
                              _openEditFollowUp(item);
                            },
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
                            onPressed: () {
                              Navigator.pop(ctx);
                              _deleteFollowUp(item);
                            },
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

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  DateTime? _parseDMY(String dmy) {
    // supports yyyy-MM-dd and dd/MM/yyyy
    try {
      if (dmy.contains('-')) {
        final parsed = DateTime.tryParse(dmy);
        if (parsed != null) {
          return DateTime(parsed.year, parsed.month, parsed.day);
        }
      }

      final parts = dmy.split("/");
      if (parts.length == 3) {
        final dd = int.parse(parts[0]);
        final mm = int.parse(parts[1]);
        final yy = int.parse(parts[2]);
        return DateTime(yy, mm, dd);
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatDMY(DateTime d) {
    final yyyy = d.year.toString().padLeft(4, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return "$yyyy-$mm-$dd";
  }

  FollowUpItem _mapFollowUpModelToItem(FollowUpModel model) {
    final nestedLead = model.lead;
    final name = nestedLead?.name ?? '';
    final number = nestedLead?.phone ?? '';
    final email = nestedLead?.email ?? '';
    final requirementType = nestedLead?.requirementType ?? '';
    final budgetRange = nestedLead?.budgetRange ?? '';
    final urgency = nestedLead?.urgency ?? '';
    final leadStatus = nestedLead?.status.toLowerCase() ?? '';

    final followUpStatusRaw = model.status.toLowerCase();
    FollowUpStatus status;
    if (followUpStatusRaw == 'done' || followUpStatusRaw == 'completed') {
      status = FollowUpStatus.confirmed;
    } else if (followUpStatusRaw == 'cancelled' || followUpStatusRaw == 'canceled') {
      status = FollowUpStatus.cancelled;
    } else {
      // Treat "Pending", "Rescheduled" and any unknowns as pending.
      status = FollowUpStatus.pending;
    }

    final idStr = model.leadId.isNotEmpty
        ? model.leadId
        : (nestedLead?.id.toString() ?? '');
    final leadNumericId = int.tryParse(idStr) ?? nestedLead?.id;

    return FollowUpItem(
      followUpId: model.id.toString(),
      leadId: idStr,
      leadNumericId: leadNumericId,
      name: name,
      number: number,
      email: email,
      requirementType: requirementType,
      budgetRange: budgetRange,
      urgency: urgency,
      leadStatusText: leadStatus,
      date: _formatDMY(model.followupDate),
      time: model.followupTime,
      statusText: followUpStatusRaw,
      remarks: model.remarks,
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
          x.statusText.toLowerCase().contains(q) ||
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
                          onEdit: () => _openEditFollowUp(item),
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
          Navigator.pushNamed(context, AppRoutes.salespersonDashboard);
        },
        onProfile: () { Navigator.pushNamed(context, AppRoutes.salespersonProfile);},
        onMore: () => setState(() => _moreOpen = true),
        onLess: () => setState(() => _moreOpen = false),
        onLeads: () {
          Navigator.pushNamed(context, AppRoutes.salespersonLeads);
        },
        onFollowUp: () { Navigator.pushNamed(context, AppRoutes.salespersonFollowUp);},
        onMeeting: () { Navigator.pushNamed(context, AppRoutes.salespersonMeeting);},
        onQuotation: () { Navigator.pushNamed(context, AppRoutes.salespersonQuotation);},
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
          _kv("Name", item.name),
          _kv("Phone", item.number),
          _kv("Follow-up Date", item.date),
          _kv("Follow-up Time", item.time),
          _kv("Status", item.statusText),
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
  final String followUpId;
  final String leadId;
  final int? leadNumericId;
  final String name;
  final String number;
  final String email;
  final String requirementType;
  final String budgetRange;
  final String urgency;
  final String leadStatusText;
  final String date; // yyyy-MM-dd
  final String time;
  final String remarks;
  final String statusText;

  final FollowUpStatus status;

  FollowUpItem({
    required this.followUpId,
    required this.leadId,
    required this.leadNumericId,
    required this.name,
    required this.number,
    required this.email,
    required this.requirementType,
    required this.budgetRange,
    required this.urgency,
    required this.leadStatusText,
    required this.date,
    required this.time,
    required this.remarks,
    required this.statusText,
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
