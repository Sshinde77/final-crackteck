import 'package:final_crackteck/routes/app_routes.dart';
import 'package:flutter/material.dart';

import 'constants/app_strings.dart';

class rolesccreen extends StatelessWidget {
  const rolesccreen({super.key});

  static const Color primaryGreen = Color(0xFF0F7A2A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // LOGO 107 x 109
                SizedBox(
                  width: 107,
                  height: 109,
                  child: Image.asset(
                    'assets/logo.png',   // <-- put your logo here
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 32),

                const Text(
                  'Select your\nservice role',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  "You need to identify the specific service role\nthat's needed for a particular task or application.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),

                _roleButton(
                  context,
                  icon: Icons.engineering,
                  title: 'Field Executive',
                  onTap: () {
                    _navigateToLogin(
                      context,
                      roleId: 1,
                      roleName: AppStrings.fieldExecutive,
                    );
                  },
                ),
                const SizedBox(height: 16),
                _roleButton(
                  context,
                  icon: Icons.local_shipping,
                  title: 'Delivery Man',
                  onTap: () {
                    _navigateToLogin(
                      context,
                      roleId: 2,
                      roleName: AppStrings.deliveryMan,
                    );
                  },
                ),
                const SizedBox(height: 16),
                _roleButton(
                  context,
                  icon: Icons.person_outline,
                  title: 'Sales Person',
                  onTap: () {
                    _navigateToLogin(
                      context,
                      roleId: 3,
                      roleName: AppStrings.salesPerson,
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 70,
      child: Material(
        color: primaryGreen,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white),
                  ),
                  child: Icon(icon, size: 22, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_forward, size: 18, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToLogin(
    BuildContext context, {
    required int roleId,
    required String roleName,
  }) {
    Navigator.pushNamed(
      context,
      AppRoutes.login,
      arguments: LoginArguments(roleId: roleId, roleName: roleName),
    );
  }
}
