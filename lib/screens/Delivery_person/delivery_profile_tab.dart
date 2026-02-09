import 'package:flutter/material.dart';
import '../../core/secure_storage_service.dart';
import '../../routes/app_routes.dart';
import '../../services/api_service.dart';
import '../../widgets/placeholder.dart';


class DeliveryProfileScreen extends StatefulWidget {
  final int roleId;
  final String roleName;
  final int currentIndex; // which tab is active in bottom nav

  const DeliveryProfileScreen({
    super.key,
    required this.roleId,
    required this.roleName,
    this.currentIndex = 0,
  });

  @override
  State<DeliveryProfileScreen> createState() => _DeliveryProfileScreenState();
}

class _DeliveryProfileScreenState extends State<DeliveryProfileScreen> {
  static const Color green = Color(0xFF1E7C10);
  bool _isLoggingOut = false;

  Future<void> _handleLogout() async {
    if (_isLoggingOut) return;

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Log out'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Log out'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true || !mounted) return;

    setState(() => _isLoggingOut = true);

    try {
      final response = await ApiService.instance.logout(roleId: widget.roleId);
      if (!mounted) return;

      if (!response.success) {
        setState(() => _isLoggingOut = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.message ?? 'Logout failed. Please try again.',
            ),
          ),
        );
        return;
      }

      await SecureStorageService.clearTokens();
      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.roleSelection,
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoggingOut = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong during logout. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ✅ AppBar
      appBar: AppBar(
        backgroundColor: green,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Personal Information",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(
              //     builder: (context) => DeliveryNotificationScreen(
              //       roleId: roleId,
              //       roleName: roleName,
              //     ),
              //   ),
              // );
            },
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        child: Column(
          children: [
            // ---------------- PROFILE HEADER ----------------
            const CircleAvatar(
              radius: 48,
              backgroundImage: NetworkImage(
                "https://images.unsplash.com/photo-1527980965255-d3b416303d12",
              ),
            ),
            const SizedBox(height: 12),

            const Text(
              "Denil Rao",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),

            const Text(
              "12334",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 6),

            // ⭐ Rating
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.star, color: Colors.amber, size: 18),
                Icon(Icons.star, color: Colors.amber, size: 18),
                Icon(Icons.star, color: Colors.amber, size: 18),
                Icon(Icons.star_border, color: Colors.grey, size: 18),
                Icon(Icons.star_border, color: Colors.grey, size: 18),
              ],
            ),

            const SizedBox(height: 20),

            // ---------------- MENU LIST ----------------
            _ProfileTile(
              icon: Icons.person_outline,
              label: "Personal info",
              onTap: () {},
            ),
            _ProfileTile(
              icon: Icons.credit_card,
              label: "Documents",
              onTap: () {
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(builder: (context) => const DocumentsScreen()),
                // );
              },
            ),
            _ProfileTile(
              icon: Icons.fact_check_outlined,
              label: "Attendence",
              onTap: () {
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //     builder: (context) => DeliveryPersonAttendanceScreen(
                //       roleId: roleId,
                //       roleName: roleName,
                //     ),
                //   ),
                // );
              },
            ),
            _ProfileTile(
              icon: Icons.account_balance_wallet_outlined,
              label: "Wallet",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ComingSoonScreen(
                      roleId: widget.roleId,
                      roleName: widget.roleName,
                    ),
                  ),
                );
              },
            ),
            _ProfileTile(
              icon: Icons.verified_user_outlined,
              label: "KYC Log",
              onTap: () {},
            ),
            _ProfileTile(
              icon: Icons.location_on_outlined,
              label: "Track Your Work",
              onTap: () {
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //     builder: (context) => TotalDeliveryScreen(
                //       roleId: roleId,
                //       roleName: roleName,
                //     ),
                //   ),
                // );
              },
            ),
            _ProfileTile(
              icon: Icons.feedback_outlined,
              label: "Feedback's",
              onTap: () 
              {
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(builder: (context) => const FeedbackScreen()),
                // );
              },
            ),

            const SizedBox(height: 16),

            _ProfileTile(
              icon: Icons.description_outlined,
              label: "Terms Of service",
              onTap: () {
                // Navigator.pushNamed(
                //   context,
                //   AppRoutes.DeliveryTermsConditionScreen,
                //   arguments: deliverytermsArguments(
                //     roleId: roleId,
                //     roleName: roleName,
                //   ),
                // );
              },
            ),
            _ProfileTile(
              icon: Icons.privacy_tip_outlined,
              label: "Privacy policy",
              onTap: () {
                // Navigator.pushNamed(
                //   context,
                //   AppRoutes.DeliveryPrivacyPolicyScreen,
                //   arguments: deliverypolicyArguments(
                //     roleId: roleId,
                //     roleName: roleName,
                //   ),
                // );
              },
            ),
            _ProfileTile(
              icon: Icons.headset_mic_outlined,
              label: "Help & Support",
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.chat_bubble_outline, color: green, size: 18),
                  SizedBox(width: 6),
                  Icon(Icons.call_outlined, color: green, size: 18),
                ],
              ),
              onTap: () {},
            ),
            _ProfileTile(
              icon: Icons.logout,
              label: _isLoggingOut ? "Logging out..." : "Log out",
              iconColor: Colors.redAccent,
              textColor: Colors.redAccent,
              trailing: _isLoggingOut
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.redAccent,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Colors.redAccent,
                    ),
              onTap: _isLoggingOut ? () {} : _handleLogout,
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------------- PROFILE TILE ----------------

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;
  final Color iconColor;
  final Color textColor;

  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.iconColor = green,
    this.textColor = Colors.black,
  });

  static const Color green = Color(0xFF1E7C10);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x11000000),
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
              trailing ??
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: green,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
