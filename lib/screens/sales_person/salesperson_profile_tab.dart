import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../routes/app_routes.dart';
import '../../widgets/bottom_navigation.dart';
import '../../model/sales_person/profile_provider.dart';
import '../../services/api_service.dart';
import '../../core/secure_storage_service.dart';

class SalesPersonMoreScreen extends StatefulWidget {
  final String userName;
  final int roleId;
  final String roleName;

  const SalesPersonMoreScreen({
    super.key,
    this.userName = "Jenny Doe",
    required this.roleId,
    required this.roleName,
  });

  @override
  State<SalesPersonMoreScreen> createState() => _SalesPersonMoreScreenState();
}

class _SalesPersonMoreScreenState extends State<SalesPersonMoreScreen> {
  static const Color midGreen = Color(0xFF1F8B00);
  static const Color darkGreen = Color(0xFF145A00);
  bool _moreOpen = false;
  int _navIndex = 2; // 0=Home, 2=Profile
  bool _isLoggingOut = false;

  // ✅ State values (you can update these later from API)
  String loginTime = "00:00 AM";
  String logoutTime = "00:00 PM";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = Provider.of<ProfileProvider>(context, listen: false);
      provider.loadProfile();
    });
  }

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
    final profileProvider = Provider.of<ProfileProvider>(context);
    final profile = profileProvider.profile;
    final loading = profileProvider.loading;
    final error = profileProvider.error;

    final String displayName;
    if (profile != null && profile.fullName.trim().isNotEmpty) {
      displayName = profile.fullName;
    } else {
      displayName = widget.userName;
    }

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
          "Hi, $displayName",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              // Navigator.pushNamed(
              //   context,
              //   AppRoutes.NotificationScreen,
              //   arguments: NotificationArguments(
              //     roleId: widget.roleId,
              //     roleName: widget.roleName,
              //   ),
              // );
            },
            icon: const Icon(Icons.notifications_none, color: Colors.white),
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => Provider.of<ProfileProvider>(
            context,
            listen: false,
          ).refreshProfile(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              children: [
                if (loading && profile == null)
                  const SizedBox(
                    height: 140,
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(darkGreen),
                      ),
                    ),
                  ),
                if (!loading && error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 32,
                          color: Colors.redAccent,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () {
                            Provider.of<ProfileProvider>(
                              context,
                              listen: false,
                            ).loadProfile();
                          },
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),

                //   // Login / Logout cards
                //   Container(
                //     padding: const EdgeInsets.all(12),
                //     decoration: BoxDecoration(
                //       color: Colors.white,
                //       border: Border.all(color: Colors.black12),
                //       borderRadius: BorderRadius.circular(12),
                //     ),
                //     child: Row(
                //       children: [
                //         // Expanded(
                //         //   child: _TimeCard(
                //         //     title: "Login",
                //         //     time: loginTime,
                //         //     bg: const Color(0xFFE9FFE6),
                //         //     iconBg: const Color(0xFF2E7D32),
                //         //     icon: Icons.access_time,
                //         //     titleColor: const Color(0xFF2E7D32),
                //         //     onTap: () {
                //         //       // ✅ example: update state
                //         //       setState(() {
                //         //         loginTime = "09:30 AM";
                //         //       });
                //         //     },
                //         //   ),
                //         // ),
                //         // const SizedBox(width: 12),
                //         // Expanded(
                //         //   child: _TimeCard(
                //         //     title: "Logout",
                //         //     time: logoutTime,
                //         //     bg: const Color(0xFFFFE9E9),
                //         //     iconBg: const Color(0xFFD32F2F),
                //         //     icon: Icons.access_time,
                //         //     titleColor: const Color(0xFFD32F2F),
                //         //     onTap: () {
                //         //       // ✅ example: update state
                //         //       setState(() {
                //         //         logoutTime = "06:45 PM";
                //         //       });
                //         //     },
                //         //   ),
                //         // ),
                //       ],
                //     ),
                //   ),
                const SizedBox(height: 16),

                _OptionTile(
                  icon: Icons.info_outline,
                  label: "Personal info",
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.SalesPersonPersonalInfoScreen,
                    );
                  },
                ),
                const SizedBox(height: 12),

                _OptionTile(
                  icon: Icons.fact_check_outlined,
                  label: "Attendance",
                  onTap: () {
                    //   Navigator.pushNamed(
                    //   context,
                    //   AppRoutes.SalesPersonAttendanceScreen,
                    //   arguments: SalesattendanceArguments(roleId:  widget.roleId, roleName: widget.roleName),
                    // );
                  },
                ),
                const SizedBox(height: 12),

                _OptionTile(
                  icon: Icons.verified_user_outlined,
                  label: "KYC Log",
                  onTap: () {
                    // TODO: navigate
                  },
                ),
                const SizedBox(height: 12),

                _OptionTile(
                  icon: Icons.support_agent_outlined,
                  label: "Help & Support",
                  onTap: () {
                    // TODO: navigate
                  },
                ),
                const SizedBox(height: 12),

                _OptionTile(
                  icon: Icons.privacy_tip_outlined,
                  label: "Privacy policy",
                  onTap: () {
                    //    Navigator.pushNamed(
                    //   context,
                    //   AppRoutes.PrivacyPolicyScreen,
                    //   arguments: SalespolicyArguments(roleId:  widget.roleId, roleName: widget.roleName),
                    // );
                  },
                ),
                const SizedBox(height: 12),

                _OptionTile(
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
                          Icons.arrow_forward,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                  onTap: _isLoggingOut ? () {} : _handleLogout,
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: CrackteckBottomSwitcher(
        isMoreOpen: _moreOpen,
        currentIndex: _navIndex,
        roleId: widget.roleId,
        roleName: widget.roleName,

        onHome: () {
          setState(() {
            _navIndex = 0;
            _moreOpen = false;
          });
          Navigator.pop(context);
        },
        onProfile: () {
          setState(() {
            _navIndex = 2;
            _moreOpen = false;
          });
          // Already on profile; no navigation.
        },
        onMore: () => setState(() => _moreOpen = true),
        onLess: () => setState(() => _moreOpen = false),

        onLeads: () {
          Navigator.pushNamed(context, AppRoutes.salespersonLeads);
        },
        onFollowUp: () {
          Navigator.pushNamed(context, AppRoutes.salespersonFollowUp);
        },
        onMeeting: () {
          Navigator.pushNamed(context, AppRoutes.salespersonMeeting);
        },
        onQuotation: () {
          Navigator.pushNamed(context, AppRoutes.salespersonQuotation);
        },
      ),
    );
  }
}

// class SalespersonalinfoArguments {
//    final int roleId;
//   final String roleName;

//   SalespersonalinfoArguments({required this.roleId, required this.roleName});
// }


class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;
  final Color iconColor;
  final Color textColor;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.iconColor = Colors.black54,
    this.textColor = Colors.black54,
  });

  static const Color darkGreen = Color(0xFF145A00);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ),
            trailing ??
                const Icon(Icons.arrow_forward, color: darkGreen, size: 20),
          ],
        ),
      ),
    );
  }
}
