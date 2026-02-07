import 'package:flutter/material.dart';
import '../../constants/app_strings.dart';
import '../../routes/app_routes.dart';

class ProductDetailScreen extends StatelessWidget {
  final int roleId;
  final String roleName;

  const ProductDetailScreen({
    super.key,
    required this.roleId,
    required this.roleName,
  });

  static const Color primaryGreen = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ✅ AppBar
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          AppStrings.productTitle,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ✅ Body
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Product Image
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset(
                  'assets/products/motherboard.png',
                  height: 160,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Product Name
            const Text(
              'AURA EDITION Yoga Slim 7\nIntel, 35.56cms - Core Ultra 5 (Luna Grey)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),

            const SizedBox(height: 10),

            // Price Row
            Row(
              children: const [
                Text(
                  '₹1,09,990',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  '28% off',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            const Text(
              AppStrings.inclTaxes,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 16),
            const Divider(),

            // Specs Section
            const Text(
              AppStrings.systemSpecs,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),

            _specItem(
              AppStrings.processor,
              'Intel® Core™ Ultra 5 125H Processor (LP-E cores up to 3.6GHz)',
            ),
            _specItem(
              AppStrings.os,
              'Windows 11 Home Single Language 64',
            ),
            _specItem(
              AppStrings.graphicCard,
              'Integrated Intel® Arc™ Graphics',
            ),
            _specItem(
              AppStrings.memory,
              '32 GB LPDDR5X-8533MHz (Memory on Package)',
            ),
            _specItem(
              AppStrings.storage,
              '1 TB SSD M.2 2242 PCIe Gen4 TLC',
            ),
            _specItem(
              AppStrings.display,
              '35.56cms (14") WUXGA (1920×1200) OLED',
            ),
            _specItem(
              'AC Adapter / Power Supply',
              '65W',
            ),
            _specItem(
              AppStrings.pointingDevice,
              'ClickPad',
            ),
            _specItem(
              AppStrings.keyboard,
              'Backlit, Luna Grey – English (US)',
            ),
            _specItem(
              AppStrings.wifi,
              'Wi-Fi 7 + Bluetooth® 5.4',
            ),
            _specItem(
              AppStrings.warranty,
              '1 Year PremiumCare',
            ),
            _specItem(
              AppStrings.color,
              'Luna Grey',
            ),
            _specItem(
              AppStrings.brand,
              'Lenovo',
            ),
            _specItem(
              AppStrings.screenResolution,
              '1920 x 1200',
            ),
            _specItem(
              AppStrings.softwarePreload,
              'Office Home 2024 + Lenovo® AI Now',
            ),
            _specItem(
              AppStrings.services,
              '1YR Accidental Damage Protection',
            ),
            ],
          ),
        ),
      ),

      // ✅ Bottom Button
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.FieldExecutiveProductPaymentScreen,
                  arguments: fieldexecutiveproductpaymentArguments(
                    roleId: roleId,
                    roleName: roleName,
                  ),
                );
              },
              child: const Text(
                'Use in repair',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 🔹 Spec Row Widget
  static Widget _specItem(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
