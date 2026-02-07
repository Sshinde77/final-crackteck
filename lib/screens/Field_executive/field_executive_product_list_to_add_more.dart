import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';

class ProductListScreen extends StatefulWidget {
  final int roleId;
  final String roleName;

  const ProductListScreen({
    super.key,
    required this.roleId,
    required this.roleName,
  });

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  static const Color primaryGreen = Color(0xFF1F8B00);

  final List<_ProductItem> _items = [
    _ProductItem(),
    _ProductItem(),
    _ProductItem(),
    _ProductItem(),
  ];

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
          'Product',
          style: TextStyle(color: Colors.white),
        ),
      ),

      body: SafeArea(
        child: Column(
          children: [
          // 🧾 Product List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                return _productCard(index);
              },
            ),
          ),

          // 🟢 Bottom Buttons
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
                // ➕ Add More
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.FieldExecutiveAddProductScreen,
                        arguments: fieldexecutiveaddproductArguments(
                          roleId: widget.roleId,
                          roleName: widget.roleName,
                        ),
                      );
                    },
                    icon: const Icon(Icons.add, color: primaryGreen),
                    label: const Text(
                      'Add More',
                      style: TextStyle(color: primaryGreen),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: primaryGreen),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // ✅ Submit
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: const Text(
                      'Submit',
                      style: TextStyle(fontSize: 16, color: Colors.white),
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

  /// 🧩 Product Card
  Widget _productCard(int index) {
    final item = _items[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🖼 Image
          Container(
            width: 64,
            height: 64,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Image.asset(
              'assets/products/intel_core_i3.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, color: Colors.grey),
            ),
          ),

          const SizedBox(width: 12),

          // 📦 Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Intel Core i3 12100F 12th Gen Desktop PC Processor',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  '₹ 62,990',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                // Qty Row
                Row(
                  children: [
                    const Text(
                      'Qty',
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(width: 10),

                    _qtyButton(
                      icon: Icons.remove,
                      onTap: () {
                        setState(() {
                          if (item.qty > 1) item.qty--;
                        });
                      },
                    ),

                    Container(
                      width: 36,
                      alignment: Alignment.center,
                      child: Text(
                        item.qty.toString(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    _qtyButton(
                      icon: Icons.add,
                      onTap: () {
                        setState(() {
                          item.qty++;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ➕➖ Qty Button
  Widget _qtyButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: primaryGreen,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }

  /// 📤 Submit Action
  void _submit() async {
    // 1. Show Full Screen Loading Overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  height: 100,
                  width: 100,
                  child: CircularProgressIndicator(
                    strokeWidth: 8,
                    valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
                    backgroundColor: Color(0xFFE0E8E0),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Processing your request',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // 2. Wait for 4 seconds (3-5 sec range)
    await Future.delayed(const Duration(seconds: 4));

    if (!mounted) return;
    Navigator.pop(context); // Close loading dialog

    // 3. Show Success Pop-up
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: primaryGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 20),
              const Text(
                'Request submitted\nsuccessfully',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // 4. Wait for 10 seconds
    await Future.delayed(const Duration(seconds: 10));

    // 5. Redirect to Home Tab (Field Executive Dashboard)
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.FieldExecutiveDashboard,
      (route) => false,
      arguments: fieldexecutivedashboardArguments(
        roleId: widget.roleId,
        roleName: widget.roleName,
        initialIndex: 0, // 0 usually corresponds to the Home Tab
      ),
    );
  }
}

/// 🔹 Product Model
class _ProductItem {
  int qty = 1;
}
