import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';

class StockInHandScreen extends StatelessWidget {
  final int roleId;
  final String roleName;

  const StockInHandScreen({
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
          'Stock in hand',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ✅ Body
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                children: [
                InkWell(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.FieldExecutiveProductDetailScreen,
                      arguments: fieldexecutiveproductdetailArguments(
                        roleId: roleId,
                        roleName: roleName,
                      ),
                    );
                  },
                  child: const StockItemCard(image: 'assets/products/cpu.png'),
                ),
                InkWell(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.FieldExecutiveProductDetailScreen,
                      arguments: fieldexecutiveproductdetailArguments(
                        roleId: roleId,
                        roleName: roleName,
                      ),
                    );
                  },
                  child: const StockItemCard(image: 'assets/products/motherboard.png'),
                ),
                InkWell(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.FieldExecutiveProductDetailScreen,
                      arguments: fieldexecutiveproductdetailArguments(
                        roleId: roleId,
                        roleName: roleName,
                      ),
                    );
                  },
                  child: const StockItemCard(image: 'assets/products/psu.png'),
                ),
                InkWell(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.FieldExecutiveProductDetailScreen,
                      arguments: fieldexecutiveproductdetailArguments(
                        roleId: roleId,
                        roleName: roleName,
                      ),
                    );
                  },
                  child: const StockItemCard(image: 'assets/products/gpu.png'),
                ),
                InkWell(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.FieldExecutiveProductDetailScreen,
                      arguments: fieldexecutiveproductdetailArguments(
                        roleId: roleId,
                        roleName: roleName,
                      ),
                    );
                  },
                  child: const StockItemCard(image: 'assets/products/motherboard.png'),
                ),
                InkWell(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.FieldExecutiveProductDetailScreen,
                      arguments: fieldexecutiveproductdetailArguments(
                        roleId: roleId,
                        roleName: roleName,
                      ),
                    );
                  },
                  child: const StockItemCard(image: 'assets/products/ram.png'),
                ),
                ],
              ),
            ),
          ],
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
                  AppRoutes.FieldExecutiveAddProductScreen,
                  arguments: fieldexecutiveaddproductArguments(
                    roleId: roleId,
                    roleName: roleName,
                  ),
                );
              },
              child: const Text(
                'Request more product',
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
}

/// 🧾 Stock Item Card
class StockItemCard extends StatelessWidget {
  final String image;

  const StockItemCard({
    super.key,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          Container(
            width: 60,
            height: 60,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Image.asset(
              image,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, color: Colors.grey),
            ),
          ),

          const SizedBox(width: 12),

          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Intel Core i3 12100F 12th\nGen Desktop PC Processor',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  '₹ 62,990',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Quantity
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const [
              Text(
                'Qty',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '2',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
