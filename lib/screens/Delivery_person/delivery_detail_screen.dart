import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';

class DeliveryDetailsScreen extends StatelessWidget {
  final int? roleId;
  final String? roleName;

  const DeliveryDetailsScreen({
    super.key,
    this.roleId,
    this.roleName,
  });

  static const Color darkGreen = Color(0xFF145A00);

  /// ✅ SAFE navigation (no pop, no empty stack)
  void _goToDashboard(BuildContext context) {
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.DeliveryDashboard,
      arguments: deliverydasboardArguments(
        roleId: roleId ?? 0,
        roleName: roleName ?? "",
        initialIndex: 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ✅ AppBar WITHOUT back pop
      appBar: AppBar(
        automaticallyImplyLeading: false, // 🔑 IMPORTANT
        backgroundColor: darkGreen,
        title: const Text(
          "Delivery Details",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            tooltip: "Go to Dashboard",
            icon: const Icon(Icons.home_rounded, color: Colors.white),
            onPressed: () => _goToDashboard(context),
          ),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 Details Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Column(
                  children: [
                    _DetailRow(label: "Name", value: "Denil rao"),
                    _DetailRow(label: "Number", value: "+91 **** ****"),
                    _DetailRow(label: "Email", value: "cracktech@mail.com"),
                    _DetailRow(label: "From", value: "Vasai Warehouse"),
                    _DetailRow(
                      label: "To",
                      value:
                      "Office No 501, 5th Floor,\n"
                          "Ghanshyam Enclave, New Link Rd,\n"
                          "Kandivali, Kandivali West,\n"
                          "Mumbai, Maharashtra 400067",
                      multiline: true,
                    ),
                  ],
                ),
              ),
        
              const SizedBox(height: 20),
        
              const Text(
                "Delivered Products",
                style: TextStyle(
                  color: darkGreen,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
        
              const SizedBox(height: 12),
        
              const _ProductTile(
                title:
                "AURA EDITION Yoga Slim 7 Intel, 35.56cms - Core Ultra 5 (Luna Grey)",
              ),
              const _ProductTile(
                title: "Intel Core i3 12100F 12th Gen Desktop PC Processor",
              ),
              const _ProductTile(
                title:
                "AURA EDITION Yoga Slim 7 Intel, 35.56cms - Core Ultra 5 (Luna Grey)",
              ),
              const _ProductTile(
                title:
                "AURA EDITION Yoga Slim 7 Intel, 35.56cms - Core Ultra 5 (Luna Grey)",
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// =======================
/// DETAIL ROW
/// =======================
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool multiline;

  const _DetailRow({
    required this.label,
    required this.value,
    this.multiline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment:
        multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// =======================
/// PRODUCT TILE
/// =======================
class _ProductTile extends StatelessWidget {
  final String title;

  const _ProductTile({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: const Text(
              "IMG",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
