import 'package:flutter/material.dart';
import '../../model/field executive/field_executive_product_service.dart';
import '../../routes/app_routes.dart';

class FieldExecutiveProductItemDetailScreen extends StatelessWidget {
  final int roleId;
  final String roleName;
  final String title;
  final String serviceId;
  final String location;
  final String priority;
  final FieldExecutiveProductItemDetailFlow flow;
  final FieldExecutiveProductServicesController controller;

  const FieldExecutiveProductItemDetailScreen({
    super.key,
    required this.roleId,
    required this.roleName,
    required this.title,
    required this.serviceId,
    required this.location,
    required this.priority,
    required this.flow,
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
          'Product Detail',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Product Image
            Container(
              height: 250,
              width: double.infinity,
              color: Colors.grey.shade100,
              child: Center(
                child: Image.network(
                  'https://via.placeholder.com/200',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          priority,
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Service ID: $serviceId',
                    style: const TextStyle(color: primaryGreen, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  _buildDetailItem('Type', 'Desktop Computer'),
                  _buildDetailItem('Model No', 'X-THRILL-2024-V2'),
                  _buildDetailItem('Purchase Date', '12 Jan 2024'),
                  _buildDetailItem('Brand', 'TechGear Pro'),
                  const SizedBox(height: 24),
                  const Text(
                    'Issue Description',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: const Text(
                      'The system is experiencing intermittent power-offs during high-performance tasks. Suspected issue with the power supply unit or cooling system. Needs a thorough hardware inspection and potential replacement of thermal paste.',
                      style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: flow == FieldExecutiveProductItemDetailFlow.afterOtpVerification
          ? SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      // Use named route so route_generator is used consistently across app
                      Navigator.pushNamed(
                        context,
                        AppRoutes.FieldExecutiveUploadBeforeImagesScreen,
                        arguments: fieldexecutiveuploadbeforeimagesArguments(
                          roleId: roleId,
                          roleName: roleName,
                          serviceId: serviceId,
                          flow: flow,
                          controller: controller,
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
                      'Start Service',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),
          ),
          const Text(':  ', style: TextStyle(color: Colors.black54)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
