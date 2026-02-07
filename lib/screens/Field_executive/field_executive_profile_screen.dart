import 'package:flutter/material.dart';
import 'field_excutive_attendance.dart';
import 'field_executive_feedback.dart';
import 'field_executive_payment.dart';
import 'field_executive_personal_info.dart';
import 'field_executive_pickup_product.dart';
import 'field_executive_privacy_policy.dart';
import 'field_executive_repair_request_part.dart';
import 'field_executive_stock_in_hand.dart';
import 'field_executive_work.dart';

class CombinedProfileScreen extends StatefulWidget {
  final String userName;
  final int roleId;
  final String roleName;

  const CombinedProfileScreen({
    super.key,
    this.userName = 'Jenny Doe',
    required this.roleId,
    required this.roleName,
  });

  @override
  State<CombinedProfileScreen> createState() => _CombinedProfileScreenState();
}

class _CombinedProfileScreenState extends State<CombinedProfileScreen> {
  static const Color midGreen = Color(0xFF1F8B00);
  static const Color darkGreen = Color(0xFF145A00);

  String loginTime = "00:00 AM";
  String logoutTime = "00:00 PM";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 76,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
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
        title: Text(
          "Hi, ${widget.userName}",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              // intentionally left empty — navigation disabled per request
            },
            icon: const Icon(Icons.notifications_none, color: Colors.white),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Attendance header cards (compact)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _TimeCard(
                        title: "Login",
                        time: loginTime,
                        bg: const Color(0xFFE9FFE6),
                        iconBg: const Color(0xFF2E7D32),
                        icon: Icons.login,
                        titleColor: const Color(0xFF2E7D32),
                        onTap: () => setState(() => loginTime = "09:00 AM"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TimeCard(
                        title: "Logout",
                        time: logoutTime,
                        bg: const Color(0xFFFFE9E9),
                        iconBg: const Color(0xFFD32F2F),
                        icon: Icons.logout,
                        titleColor: const Color(0xFFD32F2F),
                        onTap: () => setState(() => logoutTime = "06:00 PM"),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // All options (combined from both screenshots)
              _OptionTile(
                icon: Icons.person,
                label: "Personal Information",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FieldExecutivePersonalInfo( roleId: 0, roleName: '', ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _OptionTile(icon: Icons.event_available, label: "Attendance", onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const field_executive_attendance( roleId: 0, roleName: '', ),
                  ),
                );
              },),
              const SizedBox(height: 12),
              _OptionTile(icon: Icons.local_shipping, label: "Pick up request", onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PickupMaterialsScreen( roleId: 0, roleName: '', ),
                  ),
                );
              },),
              const SizedBox(height: 12),
              _OptionTile(icon: Icons.handyman, label: "Repair part request", onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RepairRequestScreen( roleId: 0, roleName: '', ),
                  ),
                );
              },),
              const SizedBox(height: 12),
              _OptionTile(icon: Icons.payment_rounded, label: "Payment", onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentsScreen ( roleId: 0, roleName: '', ),
                  ),
                );
              },),
              const SizedBox(height: 12),
              _OptionTile(icon: Icons.playlist_add, label: "Add new AMC", onTap: () {}),
              const SizedBox(height: 12),
              _OptionTile(icon: Icons.support_agent, label: "Work calls", onTap: ()  {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WorksScreen ( roleId: 0, roleName: '', ),
                  ),
                );
              },),
              const SizedBox(height: 12),
              _OptionTile(icon: Icons.warehouse, label: "Stock in Hand", onTap: ()  {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StockInHandScreen ( roleId: 0, roleName: '', ),
                  ),
                );
              },),
              const SizedBox(height: 12),
              _OptionTile(icon: Icons.privacy_tip_outlined, label: "Privacy policy", onTap: ()  {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => fieldexecutivePrivacyPolicyScreen ( roleId: 0, roleName: '', ),
                  ),
                );
              },),
              const SizedBox(height: 12),
              _OptionTile(icon: Icons.privacy_tip_outlined, label: "Feedbacks ", onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => fieldexecutiveFeedbackScreen ( roleId: 0, roleName: '', ),
                  ),
                );
              },),
              const SizedBox(height: 12),
              _OptionTile(icon: Icons.privacy_tip_outlined, label: "Help & Support", onTap: () {}),
            ],
          ),
        ),
      ),
      // bottom navigation removed as requested — screen is static and will not navigate
    );
  }
}

class _TimeCard extends StatelessWidget {
  final String title;
  final String time;
  final Color bg;
  final Color iconBg;
  final IconData icon;
  final Color titleColor;
  final VoidCallback onTap;

  const _TimeCard({
    required this.title,
    required this.time,
    required this.bg,
    required this.iconBg,
    required this.icon,
    required this.titleColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 74,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.black12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(6)),
                  child: Icon(icon, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 8),
                Text(title, style: TextStyle(color: titleColor, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
            const Spacer(),
            Text(time, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OptionTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.black12),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF145A00)),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
            const Icon(Icons.arrow_forward, color: Color(0xFF145A00)),
          ],
        ),
      ),
    );
  }
}
