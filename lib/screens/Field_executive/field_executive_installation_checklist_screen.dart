import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../model/field executive/field_executive_product_service.dart';
import '../../routes/app_routes.dart';
import 'field_executive_add_product.dart';
import 'field_executive_upload_after_images_screen.dart';

class FieldExecutiveInstallationChecklistScreen extends StatefulWidget {
  final int roleId;
  final String roleName;
  final String serviceId;
  final FieldExecutiveProductItemDetailFlow flow;
  final FieldExecutiveProductServicesController controller;

  const FieldExecutiveInstallationChecklistScreen({
    super.key,
    required this.roleId,
    required this.roleName,
    required this.serviceId,
    required this.flow,
    required this.controller,
  });

  @override
  State<FieldExecutiveInstallationChecklistScreen> createState() =>
      _FieldExecutiveInstallationChecklistScreenState();
}

class _FieldExecutiveInstallationChecklistScreenState
    extends State<FieldExecutiveInstallationChecklistScreen> {
  static const primaryGreen = Color(0xFF1E7C10);
  final ImagePicker _picker = ImagePicker();

  // Track which items are expanded
  final Map<String, bool> _expandedItems = {};

  // Track status of each item (Working / Not Working)
  final Map<String, String?> _itemStatus = {};

  Future<void> _pickImage() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 50,
      );
      if (photo != null) {
        debugPrint("Photo picked: ${photo.path}");
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

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
          'COMPUTER (Desktop / Laptop)',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Pre-Installation'),
              _buildChecklistItem('Site Readiness check'),
              _buildChecklistItem('Power and network availability check'),
              const SizedBox(height: 16),
              _buildSectionHeader('Installation'),
              _buildChecklistItem('Unpack and inspect'),
              _buildChecklistItem('Connect power, monitor, keyboard, mouse'),
              _buildChecklistItem('Install Os and drivers'),
              const SizedBox(height: 16),
              _buildSectionHeader('Final Steps'),
              _buildChecklistItem('Test device boot and shutdown'),
              _buildChecklistItem('Customer demo and feedback'),
              const SizedBox(height: 24),
              _buildLargeButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FieldExecutiveUploadAfterImagesScreen(
                        roleId: widget.roleId,
                        roleName: widget.roleName,
                      ),
                    ),
                  );
                },
                icon: Icons.cloud_upload,
                label: 'Upload after photos',
              ),
              const SizedBox(height: 12),
              _buildLargeButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.FieldExecutiveWriteReportScreen,
                    arguments: fieldexecutivewritereportArguments(
                      roleId: widget.roleId,
                      roleName: widget.roleName,
                      serviceId: widget.serviceId,
                      flow: widget.flow,
                      controller: widget.controller,
                    ),
                  );
                },
                label: 'Write Report',
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          color: primaryGreen,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showStatusDetailsDialog(String title, String status) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Write problems and solutions',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  maxLines: 5,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.camera_alt, color: primaryGreen),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Photo',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Icon(Icons.arrow_forward, color: primaryGreen),
                      ],
                    ),
                  ),
                ),
                if (status == 'Not Working') ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Add To Pick-Up',
                            style: TextStyle(color: Colors.black87),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddProductScreen(
                                  roleId: widget.roleId,
                                  roleName: widget.roleName,
                                ),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Request Part',
                            style: TextStyle(color: primaryGreen),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _itemStatus[title] = status;
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChecklistItem(String title) {
    bool isExpanded = _expandedItems[title] ?? false;
    String? status = _itemStatus[title];

    Color circleColor = Colors.grey.shade200;
    Widget? circleIcon;

    if (status == 'Working') {
      circleColor = primaryGreen;
      circleIcon = const Icon(Icons.check, size: 16, color: Colors.white);
    } else if (status == 'Not Working') {
      circleColor = Colors.red;
      circleIcon = const Icon(Icons.close, size: 16, color: Colors.white);
    }

    return Column(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _expandedItems[title] = !isExpanded;
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: circleColor,
                  ),
                  child: circleIcon,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: primaryGreen.withOpacity(0.7),
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showStatusDetailsDialog(title, 'Not Working'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: status == 'Not Working'
                            ? Colors.red.shade50
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: status == 'Not Working'
                              ? Colors.red
                              : Colors.grey.shade200,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Not Working',
                        style: TextStyle(
                          color: status == 'Not Working'
                              ? Colors.red
                              : Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showStatusDetailsDialog(title, 'Working'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: status == 'Working'
                            ? Colors.green.shade50
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: status == 'Working'
                              ? primaryGreen
                              : Colors.grey.shade200,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Working',
                        style: TextStyle(
                          color: status == 'Working'
                              ? primaryGreen
                              : Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildLargeButton({
    required VoidCallback onPressed,
    required String label,
    IconData? icon,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
