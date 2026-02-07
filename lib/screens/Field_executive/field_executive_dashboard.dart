import 'package:flutter/material.dart';
import '../../widgets/delivery_man_bottom_navigation.dart';
import '../../widgets/placeholder.dart';
import 'field_executive_home_tab.dart';
import 'field_executive_profile_screen.dart';

class FieldExecutiveDashboard extends StatefulWidget {
  final int roleId;
  final String roleName;
  final int initialIndex;

  const FieldExecutiveDashboard({
    super.key,
    required this.roleId,
    required this.roleName,
    this.initialIndex = 0,
  });

  @override
  State<FieldExecutiveDashboard> createState() => _FieldExecutiveDashboardState();
}

class _FieldExecutiveDashboardState extends State<FieldExecutiveDashboard> {
  late int _currentIndex;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    _screens = [
      /// 🏠 HOME
      FieldExecutiveHomeTab(
        roleId: widget.roleId,
        roleName: widget.roleName,
      ),

      /// 💬 CHAT
      ComingSoonScreen(
        roleId: widget.roleId,
        roleName: widget.roleName,
      ),

      /// 👤 PROFILE
      CombinedProfileScreen(
        roleId: widget.roleId,
        roleName: widget.roleName,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: DeliveryBottomNavigation(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
      ),
    );
  }
}
