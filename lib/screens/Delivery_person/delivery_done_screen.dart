import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';

class DeliveryDoneScreen extends StatelessWidget {
  final int roleId;
  final String roleName;

  const DeliveryDoneScreen({
    super.key,
    required this.roleId,
    required this.roleName,
  });

  static const Color darkGreen = Color(0xFF145A00);
  static const Color lightGreen = Color(0xFFD8E6D2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
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
                "Delivery Done!",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 8),

              // ✅ Delivery details link
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.DeliveryDetailScreen,
                    arguments: deliverydetailArguments(
                      roleId: roleId,
                      roleName: roleName,
                    ),
                  );
                },
                child: const Text(
                  "Delivery Details",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: darkGreen,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
