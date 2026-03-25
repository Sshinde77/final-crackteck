import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../model/Delivery_person/delivery_order_model.dart';
import '../../provider/delivery_person/delivery_attendance_provider.dart';
import '../../routes/app_routes.dart';

class DeliveryPersonAttendanceScreen extends StatefulWidget {
  final int roleId;
  final String roleName;

  const DeliveryPersonAttendanceScreen({
    super.key,
    required this.roleId,
    required this.roleName,
  });

  @override
  State<DeliveryPersonAttendanceScreen> createState() =>
      _DeliveryPersonAttendanceScreenState();
}

class _DeliveryPersonAttendanceScreenState
    extends State<DeliveryPersonAttendanceScreen> {
  static const Color midGreen = Color(0xFF1F8B00);
  static const Color darkGreen = Color(0xFF145A00);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<DeliveryAttendanceProvider>().load();
    });
  }

  Future<void> _action(bool login) async {
    final response = await context.read<DeliveryAttendanceProvider>().update(login);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(response)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DeliveryAttendanceProvider>();
    final loginTime = provider.attendance.loginAt == null
        ? '--'
        : DeliveryOrderModel.formatTime(provider.attendance.loginAt!);
    final logoutTime = provider.attendance.logoutAt == null
        ? '--'
        : DeliveryOrderModel.formatTime(provider.attendance.logoutAt!);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 72,
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
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Attendance',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(
                context,
                AppRoutes.DeliveryNotificationScreen,
                arguments: deliverynotificationArguments(
                  roleId: widget.roleId,
                  roleName: widget.roleName,
                ),
              );
            },
            icon: const Icon(Icons.notifications_none, color: Colors.white),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: provider.load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 42,
                backgroundColor: Color(0xFFEFF7EE),
                child: Icon(Icons.person, size: 42, color: midGreen),
              ),
              const SizedBox(height: 8),
              Text(
                widget.roleName,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: midGreen,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: provider.isUpdating ? null : () => _action(true),
                      child: Column(
                        children: [
                          const Text('Check In', style: TextStyle(fontSize: 12)),
                          const SizedBox(height: 6),
                          Text(
                            loginTime,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFEAEA),
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: provider.isUpdating ? null : () => _action(false),
                      child: Column(
                        children: [
                          const Text('Check Out', style: TextStyle(fontSize: 12)),
                          const SizedBox(height: 6),
                          Text(
                            logoutTime,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (provider.isLoading)
                const CircularProgressIndicator()
              else
                _attendanceCard(
                  title: 'Today',
                  login: loginTime,
                  logout: logoutTime,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _attendanceCard({
    required String title,
    required String login,
    required String logout,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Text('Login: $login'),
          const SizedBox(height: 6),
          Text('Logout: $logout'),
        ],
      ),
    );
  }
}
