import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../widgets/bottom_navigation.dart';

class SalesOverviewScreen extends StatefulWidget {
  final int roleId;
  final String roleName;

  const SalesOverviewScreen({
    Key? key,
    required this.roleId,
    required this.roleName,
  }) : super(key: key);

  @override
  State<SalesOverviewScreen> createState() => _SalesOverviewScreenState();
}

class _SalesOverviewScreenState extends State<SalesOverviewScreen> {
  static const Color midGreen = Color(0xFF1F8B00);
  static const Color darkGreen = Color(0xFF145A00);

  // ✅ required for bottom switcher
  bool _moreOpen = false;
  int _navIndex = 0; // 0=Home, 2=Profile

  @override
  Widget build(BuildContext context) {
    final cards = <_SalesMetric>[
      _SalesMetric(
        title: "Leads Generated",
        value: "120",
        delta: "10.6%",
        subtitle: "From last week",
      ),
      _SalesMetric(
        title: "Qualified Leads",
        value: "180",
        delta: "10.6%",
        subtitle: "From last week",
      ),
      _SalesMetric(
        title: "Deals Closed",
        value: "55",
        delta: "10.6%",
        subtitle: "From last week",
      ),
      _SalesMetric(
        title: "Total Revenue",
        value: "₹ 78,570",
        delta: "10.6%",
        subtitle: "From last week",
      ),
      _SalesMetric(
        title: "Conversation Rate",
        value: "120",
        delta: "10.6%",
        subtitle: "From last week",
      ),
      _SalesMetric(
        title: "Average Deal Time",
        value: "120",
        delta: "10.6%",
        subtitle: "From last week",
      ),
    ];

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
          "Sales Overview",
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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: GridView.builder(
            itemCount: cards.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.22,
            ),
            itemBuilder: (context, i) {
              final m = cards[i];
              return _MetricCard(
                metric: m,
                onTap: () {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("${m.title} clicked")));
                },
              );
            },
          ),
        ),
      ),

      // ✅ now works (because setState + variables exist)
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

// =======================
// UI CARD
// =======================
class _MetricCard extends StatelessWidget {
  final _SalesMetric metric;
  final VoidCallback onTap;

  const _MetricCard({required this.metric, required this.onTap});

  static const Color darkGreen = Color(0xFF145A00);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    metric.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.north_east, size: 16, color: darkGreen),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              metric.value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: darkGreen,
                height: 1.0,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                const Icon(Icons.show_chart, size: 14, color: darkGreen),
                const SizedBox(width: 4),
                Text(
                  metric.delta,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: darkGreen,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    metric.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =======================
// MODEL
// =======================
class _SalesMetric {
  final String title;
  final String value;
  final String delta;
  final String subtitle;

  const _SalesMetric({
    required this.title,
    required this.value,
    required this.delta,
    required this.subtitle,
  });
}
