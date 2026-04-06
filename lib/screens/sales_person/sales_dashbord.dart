import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:final_crackteck/core/secure_storage_service.dart';
import 'package:final_crackteck/model/sales_person/dashboard_provider.dart';
import 'package:final_crackteck/model/sales_person/lead_model.dart';
import 'package:final_crackteck/model/sales_person/task_model.dart';
import 'package:final_crackteck/routes/app_routes.dart';
import 'package:final_crackteck/services/api_service.dart';
import 'package:final_crackteck/widgets/bottom_navigation.dart';

class SalespersonDashboard extends StatefulWidget {
  const SalespersonDashboard({Key? key}) : super(key: key);

  @override
  State<SalespersonDashboard> createState() => _SalespersonDashboardState();
}

class _SalespersonDashboardState extends State<SalespersonDashboard> {
  static const darkGreen = Color(0xFF145A00);
  static const midGreen = Color(0xFF1F7A05);

  String _reportValue = "Today's Sales Report";

  int _currentIndex = 0; // 0 = Home, 2 = Profile
  bool _isMoreOpen = false;
  List<LeadModel> _overviewLeads = <LeadModel>[];
  bool _overviewLeadsLoading = false;
  bool _overviewLeadsLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardForCurrentUser();
    });
  }

  Future<void> _loadDashboardForCurrentUser() async {
    final userId = await SecureStorageService.getUserId();
    final roleId = await SecureStorageService.getRoleId() ?? 3;
    if (!mounted) return;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not found. Please log in again.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final provider = Provider.of<DashboardProvider>(context, listen: false);
    await Future.wait<void>([
      provider.loadDashboard(userId.toString()),
      _loadOverviewLeads(userId.toString(), roleId),
    ]);
  }

  Future<void> _loadOverviewLeads(String userId, int roleId) async {
    if (mounted) {
      setState(() {
        _overviewLeadsLoading = true;
      });
    }

    try {
      final List<LeadModel> allLeads = <LeadModel>[];
      int page = 1;
      int lastPage = 1;

      do {
        final result = await ApiService.fetchLeads(userId, roleId, page: page);
        final data = result['data'];
        if (data is List) {
          for (final item in data) {
            if (item is Map<String, dynamic>) {
              allLeads.add(LeadModel.fromJson(item));
            }
          }
        }

        final meta = result['meta'];
        if (meta is Map<String, dynamic>) {
          lastPage = _asInt(meta['last_page'], fallback: page);
        } else {
          lastPage = page;
        }
        page++;
      } while (page <= lastPage);

      allLeads.sort((a, b) {
        final aDate = _leadUpdatedAt(a) ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = _leadUpdatedAt(b) ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

      if (!mounted) return;
      setState(() {
        _overviewLeads = allLeads;
        _overviewLeadsLoaded = true;
        _overviewLeadsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _overviewLeadsLoading = false;
      });
    }
  }

  int _asInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }
    return fallback;
  }

  DateTime? _parseApiDate(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;

    return DateTime.tryParse(value) ??
        DateTime.tryParse(value.replaceFirst(' ', 'T'));
  }

  DateTime? _leadUpdatedAt(LeadModel lead) {
    return _parseApiDate(lead.updatedAt) ?? _parseApiDate(lead.createdAt);
  }

  bool _isWithinSelectedRange(DateTime dateTime) {
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_reportValue == "Today's Sales Report") {
      return date == today;
    }

    if (_reportValue == 'Monthly Sales Report') {
      final start = today.subtract(Duration(days: today.weekday - 1));
      final end = start.add(const Duration(days: 6));
      return !date.isBefore(start) && !date.isAfter(end);
    }

    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0);
    return !date.isBefore(start) && !date.isAfter(end);
  }

  _LeadOverviewCounts _fallbackOverviewCounts(DashboardProvider provider) {
    return _LeadOverviewCounts(
      newLeads: provider.sales?.newLeads ?? 0,
      inProgressLeads:
          (provider.sales?.contactedLeads ?? 0) +
          (provider.sales?.qualifiedLeads ?? 0),
      wonLeads: provider.sales?.quotedLeads ?? 0,
      lostLeads: provider.sales?.lostLeads ?? 0,
    );
  }

  _LeadOverviewCounts _overviewCountsFromLeads() {
    int newLeads = 0;
    int inProgressLeads = 0;
    int wonLeads = 0;
    int lostLeads = 0;

    for (final lead in _overviewLeads) {
      final updatedAt = _leadUpdatedAt(lead);
      if (updatedAt == null || !_isWithinSelectedRange(updatedAt)) {
        continue;
      }

      switch (lead.status.trim().toLowerCase()) {
        case 'lost':
          lostLeads++;
          break;
        case 'quoted':
        case 'won':
          wonLeads++;
          break;
        case 'contacted':
        case 'qualified':
        case 'proposal':
        case 'nurture':
          inProgressLeads++;
          break;
        default:
          newLeads++;
          break;
      }
    }

    return _LeadOverviewCounts(
      newLeads: newLeads,
      inProgressLeads: inProgressLeads,
      wonLeads: wonLeads,
      lostLeads: lostLeads,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DashboardProvider>(context);
    final counts = _overviewLeadsLoaded
        ? _overviewCountsFromLeads()
        : _fallbackOverviewCounts(provider);
    final int newLeads = counts.newLeads;
    final int inProgressLeads = counts.inProgressLeads;
    final int wonLeads = counts.wonLeads;
    final int lostLeads = counts.lostLeads;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 70,
        automaticallyImplyLeading: false,
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
        titleSpacing: 18,
        title: const Row(
          children: [
            Icon(Icons.bolt, color: Colors.white, size: 22),
            SizedBox(width: 6),
            Text(
              'CRACKTECK',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notifications feature coming soon'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.notifications_none, color: Colors.white),
          ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(),
      body: RefreshIndicator(
        onRefresh: _loadDashboardForCurrentUser,
        child: Transform.translate(
          offset: const Offset(0, -18),
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: _buildBody(
              provider,
              newLeads,
              inProgressLeads,
              wonLeads,
              lostLeads,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return CrackteckBottomSwitcher(
      isMoreOpen: _isMoreOpen,
      currentIndex: _currentIndex,
      // Salesperson dashboard is only used for role 3 in current flow.
      roleId: 3,
      roleName: 'Salesperson',
      onHome: _onHomeTapped,
      onProfile: _onProfileTapped,
      onMore: _onMoreTapped,
      onLess: _onLessTapped,
      onLeads: _onLeadsTapped,
      onFollowUp: _onFollowUpTapped,
      onMeeting: _onMeetingTapped,
      onQuotation: _onQuotationTapped,
    );
  }

  void _onHomeTapped() {
    setState(() {
      _currentIndex = 0;
      _isMoreOpen = false;
    });
  }

  void _onMoreTapped() {
    setState(() {
      _isMoreOpen = true;
    });
  }

  void _onLessTapped() {
    setState(() {
      _isMoreOpen = false;
    });
  }

  void _onProfileTapped() {
    setState(() {
      _currentIndex = 2;
      _isMoreOpen = false;
    });
    Navigator.pushNamed(context, AppRoutes.salespersonProfile);
  }

  void _onLeadsTapped() {
    Navigator.pushNamed(context, AppRoutes.salespersonLeads);
  }

  void _onFollowUpTapped() {
    Navigator.pushNamed(context, AppRoutes.salespersonFollowUp);
  }

  void _onMeetingTapped() {
    setState(() {
      // Ensure we return to the main tab and close the "More" sheet.
      _currentIndex = 0;
      _isMoreOpen = false;
    });
    Navigator.pushNamed(context, AppRoutes.salespersonMeeting);
  }

  void _onQuotationTapped() {
    setState(() {
      // Ensure we return to the main tab and close the "More" sheet.
      _currentIndex = 0;
      _isMoreOpen = false;
    });
    Navigator.pushNamed(context, AppRoutes.salespersonQuotation);
  }

  Widget _buildBody(
    DashboardProvider provider,
    int newLeads,
    int inProgressLeads,
    int wonLeads,
    int lostLeads,
  ) {
    if (provider.error != null && !provider.loading) {
      return _buildErrorState();
    }

    if (provider.loading && provider.sales == null) {
      return _buildLoadingState();
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 30),
          _TodayTaskHeader(onViewAll: () {
            Navigator.pushNamed(context, AppRoutes.TaskViewAll);
          }),
          const SizedBox(height: 10),
          _TodayTaskList(tasks: provider.tasks, isLoading: provider.loading),
          const SizedBox(height: 16),
          SalesOverviewSection(
            reportValue: _reportValue,
            onReportChange: (v) => setState(() => _reportValue = v),
            newLeads: newLeads,
            inProgressLeads: inProgressLeads,
            wonLeads: wonLeads,
            lostLeads: lostLeads,
            onDetails: () {
              Navigator.pushNamed(context, AppRoutes.salesoverview);
            },
            isLoading: provider.loading || _overviewLeadsLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(darkGreen),
          ),
          SizedBox(height: 16),
          Text(
            'Loading dashboard...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final provider = Provider.of<DashboardProvider>(context, listen: false);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Failed to load dashboard',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              provider.error ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadDashboardForCurrentUser,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: darkGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeadOverviewCounts {
  final int newLeads;
  final int inProgressLeads;
  final int wonLeads;
  final int lostLeads;

  const _LeadOverviewCounts({
    required this.newLeads,
    required this.inProgressLeads,
    required this.wonLeads,
    required this.lostLeads,
  });
}

class _TodayTaskHeader extends StatelessWidget {
  final VoidCallback onViewAll;
  const _TodayTaskHeader({required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    const darkGreen = Color(0xFF145A00);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Todays Task',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        TextButton(
          onPressed: onViewAll,
          style: TextButton.styleFrom(
            backgroundColor: darkGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
          child: const Row(
            children: [
              Text('View All'),
              SizedBox(width: 6),
              Icon(Icons.chevron_right, size: 18),
            ],
          ),
        ),
      ],
    );
  }
}

class _TodayTaskList extends StatelessWidget {
  final List<TaskModel> tasks;
  final bool isLoading;

  const _TodayTaskList({required this.tasks, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    if (isLoading && tasks.isEmpty) {
      return const SizedBox(
        height: 155,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF145A00)),
          ),
        ),
      );
    }

    if (tasks.isEmpty) {
      return Container(
        height: 155,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.task_alt, size: 48, color: Colors.black26),
              SizedBox(height: 8),
              Text(
                'No tasks for today',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 155,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        primary: false,
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        itemCount: tasks.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final task = tasks[index];
          return _TaskCard(task: task);
        },
      ),
    );
  }
}

class SalesOverviewSection extends StatelessWidget {
  static const darkGreen = Color(0xFF145A00);
  static const newLeadsColor = Color(0xFF145A00);
  static const inProgressLeadsColor = Color(0xFFF4B400);
  static const wonLeadsColor = Color(0xFF1A73E8);
  static const lostLeadsColor = Color(0xFFD93025);

  final String reportValue;
  final ValueChanged<String> onReportChange;
  final int newLeads;
  final int inProgressLeads;
  final int wonLeads;
  final int lostLeads;

  final VoidCallback onDetails;
  final bool isLoading;

  const SalesOverviewSection({
    super.key,
    required this.reportValue,
    required this.onReportChange,
    required this.newLeads,
    required this.inProgressLeads,
    required this.wonLeads,
    required this.lostLeads,
    required this.onDetails,
    this.isLoading = false,
  });

  String _currentRangeLabel() {
    final now = DateTime.now();
    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${(d.year % 100).toString().padLeft(2, '0')}';

    if (reportValue == "Today's Sales Report") {
      return fmt(now);
    }

    if (reportValue == 'Monthly Sales Report') {
      final start = now.subtract(Duration(days: now.weekday - 1));
      final end = start.add(const Duration(days: 6));
      return '${fmt(start)} to ${fmt(end)}';
    }

    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0);
    return '${fmt(start)} to ${fmt(end)}';
  }

  @override
  Widget build(BuildContext context) {
    final totalLeads = newLeads + inProgressLeads + wonLeads + lostLeads;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sales Overview',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: reportValue,
                          isExpanded: true,
                          icon: Container(
                            width: 22,
                            height: 22,
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
                          items: const [
                            DropdownMenuItem(
                              value: "Today's Sales Report",
                              child: Text('Todays Sales Report'),
                            ),
                            DropdownMenuItem(
                              value: 'Monthly Sales Report',
                              child: Text('This Week'),
                            ),
                            DropdownMenuItem(
                              value: 'Yearly Sales Report',
                              child: Text('This Month'),
                            ),
                          ],
                          onChanged: (v) {
                            if (v != null) onReportChange(v);
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _LegendDot(
                        label: 'New ($newLeads)',
                        color: newLeadsColor,
                      ),
                      const SizedBox(height: 8),
                      _LegendDot(
                        label: 'In Progress ($inProgressLeads)',
                        color: inProgressLeadsColor,
                      ),
                      const SizedBox(height: 8),
                      _LegendDot(
                        label: 'Won ($wonLeads)',
                        color: wonLeadsColor,
                      ),
                      const SizedBox(height: 8),
                      _LegendDot(
                        label: 'Lost ($lostLeads)',
                        color: lostLeadsColor,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black12),
                ),
                child: Column(
                  children: [
                    Center(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final s = math.min(270.0, constraints.maxWidth);
                          return SizedBox(
                            width: s,
                            height: s,
                            child: _DonutChart(
                              newLeads: newLeads.toDouble(),
                              inProgressLeads: inProgressLeads.toDouble(),
                              wonLeads: wonLeads.toDouble(),
                              lostLeads: lostLeads.toDouble(),
                              totalLeads: totalLeads,
                              newLeadsColor: newLeadsColor,
                              inProgressLeadsColor: inProgressLeadsColor,
                              wonLeadsColor: wonLeadsColor,
                              lostLeadsColor: lostLeadsColor,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _currentRangeLabel(),
                      style: TextStyle(
                        color: darkGreen,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: onDetails,
            style: ElevatedButton.styleFrom(
              backgroundColor: darkGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            child: const Text('Details'),
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final String label;
  final Color color;
  const _LegendDot({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _DonutChart extends StatelessWidget {
  final double newLeads, inProgressLeads, wonLeads, lostLeads;
  final int totalLeads;
  final Color newLeadsColor, inProgressLeadsColor, wonLeadsColor, lostLeadsColor;

  const _DonutChart({
    required this.newLeads,
    required this.inProgressLeads,
    required this.wonLeads,
    required this.lostLeads,
    required this.totalLeads,
    required this.newLeadsColor,
    required this.inProgressLeadsColor,
    required this.wonLeadsColor,
    required this.lostLeadsColor,
  });

  @override
  Widget build(BuildContext context) {
    final total = math.max(
      1.0,
      newLeads + inProgressLeads + wonLeads + lostLeads,
    );

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        CustomPaint(
          painter: _DonutPainter(
            segments: <_DonutSegment>[
              _DonutSegment(value: newLeads / total, color: newLeadsColor),
              _DonutSegment(
                value: inProgressLeads / total,
                color: inProgressLeadsColor,
              ),
              _DonutSegment(value: wonLeads / total, color: wonLeadsColor),
              _DonutSegment(value: lostLeads / total, color: lostLeadsColor),
            ],
          ),
          size: const Size(double.infinity, double.infinity),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Total Leads',
              style: TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              totalLeads.toString(),
              style: const TextStyle(
                color: SalesOverviewSection.darkGreen,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DonutSegment {
  final double value;
  final Color color;

  const _DonutSegment({
    required this.value,
    required this.color,
  });
}

class _DonutPainter extends CustomPainter {
  final List<_DonutSegment> segments;

  _DonutPainter({
    required this.segments,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 54;

    const stroke = 34.0;

    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = Colors.black12;

    canvas.drawCircle(center, radius, bgPaint);

    var start = -math.pi / 2 + 0.35;
    for (final segment in segments) {
      if (segment.value <= 0) {
        continue;
      }

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt
        ..color = segment.color;
      final sweep = 2 * math.pi * segment.value.clamp(0.0, 1.0);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        false,
        paint,
      );
      start += sweep;
    }

    final holePaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, radius - 42, holePaint);
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.segments.length != segments.length ||
        oldDelegate.segments
            .asMap()
            .entries
            .any((entry) =>
                entry.key >= segments.length ||
                entry.value.color != segments[entry.key].color ||
                entry.value.value != segments[entry.key].value);
  }
}

class _TaskCard extends StatelessWidget {
  final TaskModel task;

  const _TaskCard({
    required this.task,
  });

  String get title {
    if (task.meet != null) return 'Meeting';
    if (task.followup != null) return 'Follow Up';
    return 'Task';
  }

  String get status => task.status;

  Color _getStatusColor() {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
      case 'in progress':
        return Colors.orange;
      case 'pending':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel() {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Completed';
      case 'in_progress':
      case 'in progress':
        return 'In Progress';
      case 'pending':
        return 'Pending';
      default:
        return status;
    }
  }

  String _valueOrFallback(String value, {String fallback = 'N/A'}) {
    final clean = value.trim();
    if (clean.isEmpty) return fallback;
    return clean;
  }

  List<MapEntry<String, String>> _details() {
    if (task.meet != null) {
      final meet = task.meet!;
      return <MapEntry<String, String>>[
        MapEntry('Lead ID', _valueOrFallback(task.leadId)),
        MapEntry('Meet Title', _valueOrFallback(meet.meetTitle)),
        MapEntry('Meeting Type', _valueOrFallback(meet.meetingType)),
        MapEntry('Start Time', _valueOrFallback(meet.startTime)),
      ];
    }

    if (task.followup != null) {
      final followup = task.followup!;
      return <MapEntry<String, String>>[
        MapEntry('Lead ID', _valueOrFallback(task.leadId)),
        MapEntry(
          'Follow-up Type',
          _valueOrFallback(followup.followupType),
        ),
        MapEntry('Follow-up Time', _valueOrFallback(followup.followupTime)),
        MapEntry('Remarks', _valueOrFallback(followup.remarks)),
      ];
    }

    return <MapEntry<String, String>>[
      MapEntry('Lead ID', _valueOrFallback(task.leadId)),
      MapEntry('Task ID', _valueOrFallback(task.id.toString())),
      MapEntry('Location', _valueOrFallback(task.location)),
      MapEntry('Status', _getStatusLabel()),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final details = _details();

    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _getStatusLabel(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...details.map((detail) => _kv(detail.key, detail.value)),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 86,
            child: Text(
              k,
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ),
          Expanded(
            child: Text(
              v,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
