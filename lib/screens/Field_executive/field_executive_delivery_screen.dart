import '../../constants/app_colors.dart';
import 'package:flutter/material.dart';

import '../../constants/api_constants.dart';
import '../../routes/app_routes.dart';

class FieldExecutiveDeliveryScreen extends StatelessWidget {
  final int roleId;
  final String roleName;
  final bool showBackButton;

  const FieldExecutiveDeliveryScreen({
    super.key,
    required this.roleId,
    required this.roleName,
    this.showBackButton = true,
  });

  static const Color _primaryGreen = AppColors.primary;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      appBar: AppBar(
        backgroundColor: _primaryGreen,
        elevation: 0,
        automaticallyImplyLeading: showBackButton,
        leading: showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text(
          'Delivery',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
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
                  AppRoutes.DeliveryRequestListScreen,
                  arguments: deliveryrequestlistArguments(
                    roleId: roleId,
                    roleName: roleName,
                    deliveryType: DeliveryRequestTypes.returnRequest,
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
                  AppRoutes.DeliveryRequestListScreen,
                  arguments: deliveryrequestlistArguments(
                    roleId: roleId,
                    roleName: roleName,
                    deliveryType: DeliveryRequestTypes.pickup,
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
                  AppRoutes.DeliveryRequestListScreen,
                  arguments: deliveryrequestlistArguments(
                    roleId: roleId,
                    roleName: roleName,
                    deliveryType: DeliveryRequestTypes.part,
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _DeliveryOptionCard(
              icon: Icons.inventory_2_outlined,
              title: 'Product Delivery',
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.DeliveryRequestListScreen,
                  arguments: deliveryrequestlistArguments(
                    roleId: roleId,
                    roleName: roleName,
                    deliveryType: DeliveryRequestTypes.productDelivery,
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
            Icon(icon, color: AppColors.primary),
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
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
