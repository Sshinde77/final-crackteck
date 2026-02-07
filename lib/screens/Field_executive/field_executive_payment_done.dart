import 'dart:async';
import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';

class FieldExecutivePaymentDoneScreen extends StatefulWidget {
  final int roleId;
  final String roleName;

  const FieldExecutivePaymentDoneScreen({
    super.key,
    required this.roleId,
    required this.roleName,
  });

  @override
  State<FieldExecutivePaymentDoneScreen> createState() => _FieldExecutivePaymentDoneScreenState();
}

class _FieldExecutivePaymentDoneScreenState extends State<FieldExecutivePaymentDoneScreen> {
  static const Color darkGreen = Color(0xFF145A00);
  static const Color lightGreen = Color(0xFFD8E6D2);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer(const Duration(seconds: 5), () {
      _navigateToDashboard();
    });
  }

  void _navigateToDashboard() {
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.FieldExecutiveDashboard,
        (route) => false,
        arguments: fieldexecutivedashboardArguments(
          roleId: widget.roleId,
          roleName: widget.roleName,
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: _navigateToDashboard, // Navigate on screen click
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ✅ Success Ring with Check
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer light ring
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: lightGreen,
                          width: 12,
                        ),
                      ),
                    ),

                    // Inner white circle
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),

                    // Check icon
                    const Icon(
                      Icons.check_rounded,
                      size: 40,
                      color: darkGreen,
                    ),
                  ],
                ),

                const SizedBox(height: 36),

                // ✅ Title
                const Text(
                  "Done!",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
