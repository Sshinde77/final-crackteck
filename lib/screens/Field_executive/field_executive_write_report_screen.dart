import 'package:flutter/material.dart';
import '../../model/field executive/field_executive_product_service.dart';
import '../../routes/app_routes.dart';

class FieldExecutiveWriteReportScreen extends StatefulWidget {
  final int roleId;
  final String roleName;
  final String serviceId;
  final FieldExecutiveProductItemDetailFlow flow;
  final FieldExecutiveProductServicesController controller;

  const FieldExecutiveWriteReportScreen({
    super.key,
    required this.roleId,
    required this.roleName,
    required this.serviceId,
    required this.flow,
    required this.controller,
  });

  @override
  State<FieldExecutiveWriteReportScreen> createState() =>
      _FieldExecutiveWriteReportScreenState();
}

class _FieldExecutiveWriteReportScreenState
    extends State<FieldExecutiveWriteReportScreen> {
  static const primaryGreen = Color(0xFF1E7C10);
  final TextEditingController _reportController = TextEditingController();

  @override
  void dispose() {
    _reportController.dispose();
    super.dispose();
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
          'Write report',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
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
              Expanded(
                child: TextField(
                  controller: _reportController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    hintText: '',
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
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  widget.controller.markCompleted(widget.serviceId);

                  if (widget.controller.hasIncomplete) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.FieldExecutiveAllProductsScreen,
                      (route) => false,
                      arguments: fieldexecutiveallproductsArguments(
                        roleId: widget.roleId,
                        roleName: widget.roleName,
                        flow: widget.flow,
                        controller: widget.controller,
                      ),
                    );
                    return;
                  }

                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.FieldExecutiveDashboard,
                    (route) => false,
                    arguments: fieldexecutivedashboardArguments(
                      roleId: widget.roleId,
                      roleName: widget.roleName,
                      initialIndex: 0,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Submit',
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
      ),
    );
  }
}
