import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';

class FieldExecutiveDeliveryScreen extends StatelessWidget {
  final int roleId;
  final String roleName;

  const FieldExecutiveDeliveryScreen({
    super.key,
    required this.roleId,
    required this.roleName,
  });

  static const Color _primaryGreen = Color(0xFF1F8B00);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      appBar: AppBar(
        backgroundColor: _primaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Delivery',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _DeliveryOptionCard(
              icon: Icons.assignment_return_outlined,
              title: 'Return Request',
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.RepairRequestScreen,
                  arguments: fieldexecutiveRepairRequestArguments(
                    roleId: roleId,
                    roleName: roleName,
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _DeliveryOptionCard(
              icon: Icons.local_shipping_outlined,
              title: 'Pickup Request',
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.PickupMaterialsScreen,
                  arguments: fieldexecutivePickupMaterialArguments(
                    roleId: roleId,
                    roleName: roleName,
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _DeliveryOptionCard(
              icon: Icons.handyman_outlined,
              title: 'Request Part',
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.FieldExecutiveAddProductScreen,
                  arguments: fieldexecutiveaddproductArguments(
                    roleId: roleId,
                    roleName: roleName,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliveryOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _DeliveryOptionCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF145A00)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 18,
              color: Color(0xFF145A00),
            ),
          ],
        ),
      ),
    );
  }
}
