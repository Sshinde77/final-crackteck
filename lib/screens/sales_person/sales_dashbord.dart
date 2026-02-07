import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:final_crackteck/core/secure_storage_service.dart';
import 'package:final_crackteck/model/sales_person/dashboard_provider.dart';
import 'package:final_crackteck/model/sales_person/task_model.dart';
import 'package:final_crackteck/routes/app_routes.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardForCurrentUser();
    });
  }

  Future<void> _loadDashboardForCurrentUser() async {
    final userId = await SecureStorageService.getUserId();
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
    await provider.loadDashboard(userId.toString());
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DashboardProvider>(context);
    final double targetVal = provider.sales?.target ?? 0;
    final double achievedVal = provider.sales?.achieved ?? 0;
    final double pendingVal = provider.sales?.pending ?? 0;

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
            child: _buildBody(provider, targetVal, achievedVal, pendingVal),
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
    double targetVal,
    double achievedVal,
    double pendingVal,
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
            target: targetVal,
            achieved: achievedVal,
            pending: pendingVal,
            onDetails: () {
              Navigator.pushNamed(context, AppRoutes.salesoverview);
            },
            isLoading: provider.loading,
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
          return _TaskCard(
            title: task.title,
            leadId: task.leadId,
            followUpId: task.followUpId,
            number: task.phone,
            location: task.location,
            status: task.status,
          );
        },
      ),
    );
  }
}

class SalesOverviewSection extends StatelessWidget {
  static const darkGreen = Color(0xFF145A00);
  static const lightGreen = Color(0xFFB9D9B0);

  final String reportValue;
  final ValueChanged<String> onReportChange;

  final double target;
  final double achieved;
  final double pending;

  final VoidCallback onDetails;
  final bool isLoading;

  const SalesOverviewSection({
    super.key,
    required this.reportValue,
    required this.onReportChange,
    required this.target,
    required this.achieved,
    required this.pending,
    required this.onDetails,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
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
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _LegendDot(label: 'Achivement', color: darkGreen),
                      SizedBox(height: 8),
                      _LegendDot(label: 'Target Pending', color: lightGreen),
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
                              target: target,
                              achieved: achieved,
                              pending: pending,
                              achievedColor: darkGreen,
                              pendingColor: lightGreen,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '28-06-25',
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
  final double target, achieved, pending;
  final Color achievedColor, pendingColor;

  const _DonutChart({
    required this.target,
    required this.achieved,
    required this.pending,
    required this.achievedColor,
    required this.pendingColor,
  });

  @override
  Widget build(BuildContext context) {
    final safeTarget = target <= 0 ? 1 : target;
    final achievedPct = (achieved / safeTarget).clamp(0.0, 1.0);
    final pendingPct = (pending / safeTarget).clamp(0.0, 1.0);

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        CustomPaint(
          painter: _DonutPainter(
            achievedPct: achievedPct,
            pendingPct: pendingPct,
            achievedColor: achievedColor,
            pendingColor: pendingColor,
          ),
          size: const Size(double.infinity, double.infinity),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Target',
              style: TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              target.toStringAsFixed(0),
              style: TextStyle(
                color: achievedColor,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ],
        ),
        Positioned(
          left: 0,
          bottom: 54,
          child: _ValueLabel(
            value: achieved,
            percent: achievedPct,
            alignLeft: true,
          ),
        ),
        Positioned(
          right: 0,
          bottom: 48,
          child: _ValueLabel(
            value: pending,
            percent: pendingPct,
            alignLeft: false,
          ),
        ),
      ],
    );
  }
}

class _ValueLabel extends StatelessWidget {
  final double value, percent;
  final bool alignLeft;
  const _ValueLabel({
    required this.value,
    required this.percent,
    required this.alignLeft,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignLeft
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      children: [
        Text(
          value.toStringAsFixed(0),
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
        ),
        const Text(
          '%',
          style: TextStyle(
            color: Colors.black54,
            fontWeight: FontWeight.w700,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final double achievedPct, pendingPct;
  final Color achievedColor, pendingColor;

  _DonutPainter({
    required this.achievedPct,
    required this.pendingPct,
    required this.achievedColor,
    required this.pendingColor,
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

    final achievedPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt
      ..color = achievedColor;

    final pendingPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt
      ..color = pendingColor;

    canvas.drawCircle(center, radius, bgPaint);

    final start = -math.pi / 2 + 0.35;

    final achievedSweep = 2 * math.pi * achievedPct;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      achievedSweep,
      false,
      achievedPaint,
    );

    final pendingSweep = 2 * math.pi * pendingPct;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start + achievedSweep,
      pendingSweep,
      false,
      pendingPaint,
    );

    final holePaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, radius - 42, holePaint);
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.achievedPct != achievedPct ||
        oldDelegate.pendingPct != pendingPct ||
        oldDelegate.achievedColor != achievedColor ||
        oldDelegate.pendingColor != pendingColor;
  }
}

class _TaskCard extends StatelessWidget {
  final String title, leadId, followUpId, number, location, status;

  const _TaskCard({
    required this.title,
    required this.leadId,
    required this.followUpId,
    required this.number,
    required this.location,
    required this.status,
  });

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

  @override
  Widget build(BuildContext context) {
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
          _kv('Lead ID', leadId),
          _kv('Follow up ID', followUpId),
          _kv('Number', number),
          _kv('Location', location),
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
