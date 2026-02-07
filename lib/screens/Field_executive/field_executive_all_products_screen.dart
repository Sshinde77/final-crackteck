import 'package:flutter/material.dart';
import '../../model/field executive/field_executive_product_service.dart';
import '../../routes/app_routes.dart';

class FieldExecutiveAllProductsScreen extends StatelessWidget {
  final int roleId;
  final String roleName;
  final FieldExecutiveProductItemDetailFlow flow;
  final FieldExecutiveProductServicesController controller;

  const FieldExecutiveAllProductsScreen({
    super.key,
    required this.roleId,
    required this.roleName,
    this.flow = FieldExecutiveProductItemDetailFlow.normalBrowsing,
    required this.controller,
  });

  static const primaryGreen = Color(0xFF1E7C10);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'All Products',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final items = controller.items;
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final subtitle = item.title == 'Monitor Setup'
                    ? 'Standard installation for LED/LCD monitors'
                    : item.title == 'UPS Installation'
                        ? 'Battery backup configuration and testing'
                        : item.title == 'Keyboard and Mouse'
                            ? 'Wired/Wireless setup and driver installation'
                            : 'Visit charge of Rs 159 waived in final bill; spare part/ repair cost extra';
                return Padding(
                  padding: EdgeInsets.only(bottom: index == items.length - 1 ? 0 : 12),
                  child: _buildProductCard(
                    context,
                    item,
                    subtitle,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildProductCard(
    BuildContext context,
    FieldExecutiveProductService item,
    String subtitle,
  ) {
    final isCompleted = item.isCompleted;
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.FieldExecutiveProductItemDetailScreen,
          arguments: fieldexecutiveproductitemdetailArguments(
            roleId: roleId,
            roleName: roleName,
            title: item.title,
            serviceId: item.serviceId,
            location: item.location,
            priority: item.priority,
            flow: flow,
            controller: controller,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Image.network(
                        'https://via.placeholder.com/60',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(fontSize: 10, color: Colors.black54),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const SizedBox(
                              width: 70,
                              child: Text('Service ID:', style: TextStyle(fontSize: 12, color: Colors.black54)),
                            ),
                            Text(item.serviceId, style: const TextStyle(fontSize: 12, color: primaryGreen, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const SizedBox(
                              width: 70,
                              child: Text('Location:', style: TextStyle(fontSize: 12, color: Colors.black54)),
                            ),
                            Text(item.location, style: const TextStyle(fontSize: 12, color: primaryGreen, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isCompleted ? Colors.green.shade50 : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isCompleted ? Colors.green.shade200 : Colors.red.shade200,
                            ),
                          ),
                          child: Text(
                            isCompleted ? 'Completed' : 'Incomplete',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isCompleted ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Priority Tag
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12)),
                ),
                child: Text(
                  item.priority,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
