import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:final_crackteck/model/sales_person/profile_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/bottom_navigation.dart';

class SalesPersonPersonalInfoScreen extends StatefulWidget {
  final int roleId;
  final String roleName;

  const SalesPersonPersonalInfoScreen({
    Key? key,
    required this.roleId,
    required this.roleName,
  }) : super(key: key);

  @override
  State<SalesPersonPersonalInfoScreen> createState() =>
      _SalesPersonPersonalInfoScreenState();
}

class _SalesPersonPersonalInfoScreenState
    extends State<SalesPersonPersonalInfoScreen> {
  static const Color midGreen = Color(0xFF1F8B00);
  static const Color darkGreen = Color(0xFF145A00);

  /// ✅ STATE VARIABLES
  bool _moreOpen = false;
  int _navIndex = 2; // Profile tab selected

  @override
  void initState() {
    super.initState();
    // Load profile data once the widget is mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = Provider.of<ProfileProvider>(context, listen: false);
      provider.loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);
    final profile = profileProvider.profile;

    final String headerName =
        (profile != null && profile.fullName.trim().isNotEmpty)
        ? profile.fullName
        : 'Sales Person';

    final String nameValue =
        (profile != null && profile.fullName.trim().isNotEmpty)
        ? profile.fullName
        : 'Jenny Doe';

    final String numberValue =
        (profile != null && profile.phone.trim().isNotEmpty)
        ? profile.phone
        : '+91 **** ** ****';

    final String emailValue =
        (profile != null && profile.email.trim().isNotEmpty)
        ? profile.email
        : 'jennydoe@mail.com';

    String addressValue;
    if (profile != null &&
        (profile.currentAddress.trim().isNotEmpty ||
            profile.city.trim().isNotEmpty ||
            profile.state.trim().isNotEmpty ||
            profile.country.trim().isNotEmpty ||
            profile.pincode.trim().isNotEmpty)) {
      final parts = <String>[
        profile.currentAddress.trim(),
        profile.city.trim(),
        profile.state.trim(),
        profile.country.trim(),
        profile.pincode.trim(),
      ]..removeWhere((e) => e.isEmpty);
      addressValue = parts.join(', ');
    } else {
      addressValue = '1213 B wing goregaon';
    }

    final String aadharValue =
        (profile != null && profile.idNo.trim().isNotEmpty)
        ? profile.idNo
        : '**********';

    // PAN is not provided by the profile API example; keep placeholder
    const String panValue = '********';

    return Scaffold(
      backgroundColor: Colors.white,

      /// APP BAR
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
          'Personal info',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16,
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
          const SizedBox(width: 6),
        ],
      ),

      /// BODY
      body: Column(
        children: [
          const SizedBox(height: 18),

          /// PROFILE IMAGE
          const CircleAvatar(
            radius: 46,
            backgroundColor: Colors.black12,
            backgroundImage: AssetImage('assets/profile.jpg'),
          ),

          const SizedBox(height: 12),

          Text(
            headerName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),

          const SizedBox(height: 24),

          /// INFO LIST (values sourced from profile API where available)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _InfoTile(label: 'Name', value: nameValue),
                _InfoTile(label: 'Number', value: numberValue),
                _InfoTile(label: 'Email ID', value: emailValue),
                _InfoTile(label: 'Current Address', value: addressValue),
                _InfoTile(label: 'Aadhar no.', value: aadharValue),
                const _InfoTile(
                  label: 'PAN no.',
                  value: panValue,
                  showDivider: false,
                ),
              ],
            ),
          ),

          /// EDIT BUTTON
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 20, 16),
            child: Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: () {
                  // TODO: Edit action
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'Edit',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.edit, size: 16, color: Colors.red),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      /// BOTTOM NAVIGATION
      bottomNavigationBar: CrackteckBottomSwitcher(
        isMoreOpen: _moreOpen,
        currentIndex: _navIndex,
        roleId: widget.roleId,
        roleName: widget.roleName,

               onHome: () { Navigator.pushNamed(context, AppRoutes.salespersonDashboard);},
        onProfile: () { Navigator.pushNamed(context, AppRoutes.salespersonProfile);},
        onMore: () => setState(() => _moreOpen = true),
        onLess: () => setState(() => _moreOpen = false),
        onLeads: () { Navigator.pushNamed(context, AppRoutes.salespersonLeads);},
        onFollowUp: () { Navigator.pushNamed(context, AppRoutes.salespersonFollowUp);},
        onMeeting: () { Navigator.pushNamed(context, AppRoutes.salespersonMeeting);},
        onQuotation: () { Navigator.pushNamed(context, AppRoutes.salespersonQuotation);},
      ),
    );
  }
}

/// SINGLE INFO ROW
class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final bool showDivider;

  const _InfoTile({
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        if (showDivider) const Divider(height: 1, thickness: 1),
        const SizedBox(height: 16),
      ],
    );
  }
}
