import 'package:final_crackteck/screens/Delivery_person/delivery_home_tab.dart';
import 'package:final_crackteck/screens/Delivery_person/delivery_profile_tab.dart';
import 'package:final_crackteck/widgets/delivery_man_bottom_navigation.dart';
import 'package:final_crackteck/widgets/placeholder.dart';
import 'package:flutter/material.dart';
class DeliveryDashboard extends StatefulWidget {
  final int roleId;
  final String roleName;
  final int initialIndex;

  const DeliveryDashboard({
    super.key,
    required this.roleId,
    required this.roleName,
    this.initialIndex = 0,
  });

  @override
  State<DeliveryDashboard> createState() => _DeliveryDashboardState();
}

class _DeliveryDashboardState extends State<DeliveryDashboard> {
  /// 0 = Home, 1 = Chat / Orders, 2 = Profile
  late int _currentIndex;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    _screens = [
      /// 🏠 HOME
      DeliveryPersonHomeTab(
        roleId: widget.roleId,
        roleName: widget.roleName,
      ),

      /// 💬 CHAT / ORDERS
      ComingSoonScreen(
        roleId: widget.roleId,
        roleName: widget.roleName,
      ),

      /// 👤 PROFILE (temporary)
      DeliveryProfileScreen(
        roleId: widget.roleId,
        roleName: widget.roleName,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],

      bottomNavigationBar: DeliveryBottomNavigation(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
      ),
    );
  }
}
