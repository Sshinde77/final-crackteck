import 'package:flutter/material.dart';
import '../../constants/app_strings.dart';
import '../../routes/app_routes.dart';

class ProductRequestedDetailScreen extends StatefulWidget {
  final int roleId;
  final String roleName;

  const ProductRequestedDetailScreen({
    super.key,
    required this.roleId,
    required this.roleName,
  });

  @override
  State<ProductRequestedDetailScreen> createState() => _ProductRequestedDetailScreenState();
}

class _ProductRequestedDetailScreenState extends State<ProductRequestedDetailScreen> {
  static const Color primaryGreen = Color(0xFF1F8B00);
  int qty = 1;

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
          style: TextStyle(color: Colors.white),
        ),
      ),

      body: SafeArea(
        child: Column(
          children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🖼 Product Image
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Image.asset(
                      'assets/products/motherboard.png',
                      height: 220,
                      fit: BoxFit.contain,
                      width: double.infinity,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 📦 Product Name
                  const Text(
                    'AURA EDITION Yoga Slim 7 Intel, 35.56cms - Core Ultra 5 (Luna Grey)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 💰 Price
                  const Row(
                    children: [
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
                          fontSize: 12,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  const Text(
                    AppStrings.inclTaxes,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),

                  const SizedBox(height: 20),

                  // 📋 Specs
                  _sectionTitle(AppStrings.systemSpecs),
                  _spec(AppStrings.processor,
                      'Intel® Core™ Ultra 5 228V Processor (LP E-cores up to 3.50 GHz, P-cores up to 4.50 GHz / 32 GB MOP)'),
                  _spec(AppStrings.os,
                      'Windows 11 Home Single Language 64'),
                  _spec(AppStrings.graphicCard,
                      'Integrated Intel® Arc™ Graphics 130V'),
                  _spec(AppStrings.memory,
                      '32 GB LPDDR5X-8533 MHz (Memory on Package)'),
                  _spec(AppStrings.storage,
                      '1 TB SSD M.2 2242 PCIe Gen4 TLC'),
                  _spec(AppStrings.display,
                      '35.56cms (14") WUXGA (1920x1200), OLED, Glossy, Non-touch'),
                  _spec(AppStrings.camera,
                      '5MP IR with Privacy Shutter'),
                  _spec(AppStrings.audio,
                      '4 Speakers, Dolby Atmos'),
                  _spec(AppStrings.pointingDevice, 'ClickPad'),
                  _spec(AppStrings.keyboard, 'Backlit, Luna Grey - English (US)'),
                  _spec(AppStrings.wifi,
                      'Wi-Fi 7, 802.11be 2x2 & Bluetooth® 5.4'),
                  _spec(AppStrings.warranty, '1 Year PremiumCare'),
                  _spec(AppStrings.color, 'Luna Grey'),
                  _spec(AppStrings.brand, 'Lenovo YOGA'),
                  _spec(AppStrings.screenResolution, '1920 x 1200'),
                  _spec(
                      AppStrings.softwarePreload,
                      'Office Home 2024 + Lenovo AI Now'),
                  _spec(
                      AppStrings.services,
                      '1Yr Accidental Damage Protection'),
                ],
              ),
            ),
          ),

          // 🟢 Bottom Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Qty
                Row(
                  children: [
                    _qtyButton(Icons.remove, () {
                      if (qty > 1) {
                        setState(() => qty--);
                      }
                    }),
                    Container(
                      width: 40,
                      alignment: Alignment.center,
                      child: Text(
                        qty.toString(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    _qtyButton(Icons.add, () {
                      setState(() => qty++);
                    }),
                  ],
                ),

                const SizedBox(width: 16),

                // Add Button
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.FieldExecutiveProductListToAddMoreScreen,
                          arguments: fieldexecutiveproductlisttoaddmoreArguments(
                            roleId: widget.roleId,
                            roleName: widget.roleName,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        AppStrings.addButton,
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }

  // 🔹 Section Title
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // 🔹 Spec Row
  Widget _spec(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
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
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
          const Divider(height: 16),
        ],
      ),
    );
  }

  // 🔹 Qty Button
  Widget _qtyButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: primaryGreen,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}
