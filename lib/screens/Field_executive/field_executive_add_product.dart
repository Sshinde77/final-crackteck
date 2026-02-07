import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';

class AddProductScreen extends StatelessWidget {
  final int roleId;
  final String roleName;

  const AddProductScreen({
    super.key,
    required this.roleId,
    required this.roleName,
  });

  static const Color primaryGreen = Color(0xFF1F8B00);

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
          'Add products',
          style: TextStyle(color: Colors.white),
        ),
      ),

      body: SafeArea(
        child: Column(
          children: [
          const SizedBox(height: 12),

          // 🔍 Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: () {
                // TODO: Search action
              },
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search, color: Colors.black54),
                    SizedBox(width: 8),
                    Text(
                      'Search',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 🛒 Product Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _products.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.68,
              ),
              itemBuilder: (context, index) {
                final product = _products[index];
                return _ProductCard(
                  product: product,
                  roleId: roleId,
                  roleName: roleName,
                );
              },
            ),
          ),
          ],
        ),
      ),
    );
  }
}

/// 🔹 Product Card Widget
class _ProductCard extends StatelessWidget {
  final _Product product;
  final int roleId;
  final String roleName;

  const _ProductCard({
    required this.product,
    required this.roleId,
    required this.roleName,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.FieldExecutiveRequestedProductDetailScreen,
          arguments: fieldexecutiverequestedproductlistArguments(
            roleId: roleId,
            roleName: roleName,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🖼 Image
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Image.asset(
                  product.image,
                  fit: BoxFit.contain,
                  width: double.infinity,
                ),
              ),
            ),

            // 💰 Price
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                product.price,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),

            const SizedBox(height: 4),

            // 📦 Name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ),

            const SizedBox(height: 8),

            // 🟢 Request Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: SizedBox(
                width: double.infinity,
                height: 36,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.FieldExecutiveRequestedProductDetailScreen,
                      arguments: fieldexecutiverequestedproductlistArguments(
                        roleId: roleId,
                        roleName: roleName,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AddProductScreen.primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Request Part',
                    style: TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// 🔹 Product Model
class _Product {
  final String name;
  final String price;
  final String image;

  const _Product({
    required this.name,
    required this.price,
    required this.image,
  });
}

/// 🔹 Static Product Data (as shown in image)
const List<_Product> _products = [
  _Product(
    name: 'Apple MacBook Air M1 chip',
    price: '₹ 62,990',
    image: 'assets/products/macbook.png',
  ),
  _Product(
    name: 'ASUS ROG Strix G13CHR 2024',
    price: '₹ 1,29,990',
    image: 'assets/products/asus_cpu.png',
  ),
  _Product(
    name: 'HP All-in-One PC, Windows 11 Home',
    price: '₹ 31,490',
    image: 'assets/products/hp_allinone.png',
  ),
  _Product(
    name: 'Samsung Galaxy Book3 Pro Intel 13th',
    price: '₹ 97,150',
    image: 'assets/products/samsung_laptop.png',
  ),
  _Product(
    name: 'Zebronics Security Camera',
    price: '₹ 2,699',
    image: 'assets/products/camera.png',
  ),
  _Product(
    name: 'Mini PC',
    price: '₹ 50,990',
    image: 'assets/products/mini_pc.png',
  ),
];
