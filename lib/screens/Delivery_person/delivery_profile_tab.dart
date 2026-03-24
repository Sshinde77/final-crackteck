import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../provider/delivery_person/delivery_attendance_provider.dart';
import '../../provider/delivery_person/delivery_documents_provider.dart';
import '../../provider/delivery_person/delivery_kyc_provider.dart';
import '../../provider/delivery_person/delivery_personal_info_provider.dart';
import '../../provider/delivery_person/delivery_profile_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/placeholder.dart';
import 'delivery_feedback.dart';
import 'delivery_kyc_screen.dart';
import 'delivery_notification.dart';
import 'delivery_person_attendance.dart';
import 'delivery_person_documents.dart';
import 'delivery_personal_info_screen.dart';
import 'delivery_track_order.dart';

class DeliveryProfileScreen extends StatefulWidget {
  final int roleId;
  final String roleName;
  final int currentIndex;

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<DeliveryProfileProvider>().loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DeliveryProfileProvider>();
    final profile = provider.profile;
    final ImageProvider? avatar = profile.avatarUrl.isEmpty
        ? null
        : NetworkImage(profile.avatarUrl);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: green,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Personal Information',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DeliveryNotificationScreen(
                    roleId: widget.roleId,
                    roleName: widget.roleName,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: provider.loadProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          child: Column(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: const Color(0xFFEFF7EE),
                backgroundImage: avatar,
                child: avatar == null
                    ? const Icon(Icons.person, size: 48, color: green)
                    : null,
              ),
              const SizedBox(height: 12),
              Text(
                profile.name,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                profile.code,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 6),
              _RatingRow(rating: profile.rating),
              const SizedBox(height: 20),
              if (provider.isLoading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: CircularProgressIndicator(),
                ),
              if (provider.error != null)
                _ErrorBanner(message: provider.error!, onRetry: provider.loadProfile),
              _ProfileTile(
                icon: Icons.person_outline,
                label: 'Personal info',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ChangeNotifierProvider<DeliveryPersonalInfoProvider>(
                            create: (_) => DeliveryPersonalInfoProvider(),
                            child: DeliveryPersonalInfoScreen(
                              roleId: widget.roleId,
                              roleName: widget.roleName,
                            ),
                          ),
                    ),
                  ).then((_) => provider.loadProfile());
                },
              ),
              _ProfileTile(
                icon: Icons.credit_card,
                label: 'Documents',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ChangeNotifierProvider<DeliveryDocumentsProvider>(
                            create: (_) => DeliveryDocumentsProvider(),
                            child: const DocumentsScreen(),
                          ),
                    ),
                  );
                },
              ),
              _ProfileTile(
                icon: Icons.fact_check_outlined,
                label: 'Attendance',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ChangeNotifierProvider<DeliveryAttendanceProvider>(
                            create: (_) => DeliveryAttendanceProvider(),
                            child: DeliveryPersonAttendanceScreen(
                              roleId: widget.roleId,
                              roleName: widget.roleName,
                            ),
                          ),
                    ),
                  );
                },
              ),
              _ProfileTile(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Wallet',
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
                label: 'KYC Log',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ChangeNotifierProvider<DeliveryKycProvider>(
                            create: (_) => DeliveryKycProvider(),
                            child: DeliveryKycScreen(
                              roleId: widget.roleId,
                              roleName: widget.roleName,
                            ),
                          ),
                    ),
                  );
                },
              ),
              _ProfileTile(
                icon: Icons.location_on_outlined,
                label: 'Track Your Work',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TotalDeliveryScreen(
                        roleId: widget.roleId,
                        roleName: widget.roleName,
                      ),
                    ),
                  );
                },
              ),
              _ProfileTile(
                icon: Icons.feedback_outlined,
                label: "Feedback's",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FeedbackScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _ProfileTile(
                icon: Icons.description_outlined,
                label: 'Terms Of service',
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.DeliveryTermsConditionScreen,
                    arguments: deliverytermsArguments(
                      roleId: widget.roleId,
                      roleName: widget.roleName,
                    ),
                  );
                },
              ),
              _ProfileTile(
                icon: Icons.privacy_tip_outlined,
                label: 'Privacy policy',
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.DeliveryPrivacyPolicyScreen,
                    arguments: deliverypolicyArguments(
                      roleId: widget.roleId,
                      roleName: widget.roleName,
                    ),
                  );
                },
              ),
              _ProfileTile(
                icon: Icons.headset_mic_outlined,
                label: 'Help & Support',
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
            ],
          ),
        ),
      ),
    );
  }
}

class _RatingRow extends StatelessWidget {
  const _RatingRow({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    final rounded = rating.clamp(0, 5).round();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(5, (index) {
        final filled = index < rounded;
        return Icon(
          filled ? Icons.star : Icons.star_border,
          color: filled ? Colors.amber : Colors.grey,
          size: 18,
        );
      }),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4F4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD5D5)),
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;

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
              Icon(icon, color: green, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              trailing ??
                  const Icon(Icons.arrow_forward_ios, size: 14, color: green),
            ],
          ),
        ),
      ),
    );
  }
}
