import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../provider/delivery_person/delivery_documents_provider.dart';

class VehicleDetailsScreen extends StatefulWidget {
  const VehicleDetailsScreen({super.key});

  @override
  State<VehicleDetailsScreen> createState() => _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends State<VehicleDetailsScreen> {
  static const Color darkGreen = Color(0xFF145A00);

  final _formKey = GlobalKey<FormState>();
  final TextEditingController vehicleTypeCtrl = TextEditingController();
  final TextEditingController vehicleNumberCtrl = TextEditingController();
  final TextEditingController licenceCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<DeliveryDocumentsProvider>().loadVehicle();
    });
  }

  @override
  void dispose() {
    vehicleTypeCtrl.dispose();
    vehicleNumberCtrl.dispose();
    licenceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<DeliveryDocumentsProvider>();
    final message = await provider.saveVehicle(
      vehicleType: vehicleTypeCtrl.text.trim(),
      vehicleNumber: vehicleNumberCtrl.text.trim(),
      drivingLicenseNo: licenceCtrl.text.trim(),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    if (provider.lastSaveSucceeded) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DeliveryDocumentsProvider>();
    final vehicle = provider.vehicle;
    if (!provider.isLoading && vehicleTypeCtrl.text.isEmpty) {
      vehicleTypeCtrl.text = (vehicle['vehicle_type'] ?? vehicle['brand'] ?? '').toString();
      vehicleNumberCtrl.text =
          (vehicle['vehicle_number'] ?? vehicle['registration_number'] ?? '').toString();
      licenceCtrl.text =
          (vehicle['driving_license_no'] ?? vehicle['licence_no'] ?? '').toString();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: darkGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Vehicle Details',
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
        ),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Label('Vehicle Type'),
                    _InputField(controller: vehicleTypeCtrl, hint: 'Bike / Car'),
                    const SizedBox(height: 16),
                    const _Label('Vehicle Number'),
                    _InputField(
                      controller: vehicleNumberCtrl,
                      hint: 'Enter vehicle number',
                    ),
                    const SizedBox(height: 16),
                    const _Label('Driving License No.'),
                    _InputField(
                      controller: licenceCtrl,
                      hint: 'Enter license number',
                    ),
                  ],
                ),
              ),
            ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        color: Colors.white,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: provider.isSaving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: darkGreen,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: provider.isSaving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 12, color: Colors.black54),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.hint,
  });

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.black12),
        ),
      ),
      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
    );
  }
}
