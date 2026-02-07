import 'package:flutter/material.dart';

import 'package:final_crackteck/core/secure_storage_service.dart';
import 'package:final_crackteck/routes/app_routes.dart';
import 'package:final_crackteck/services/api_service.dart';

class VehicleScreen extends StatefulWidget {
  const VehicleScreen({super.key});

  @override
  State<VehicleScreen> createState() => _VehicleScreenState();
}

class _VehicleScreenState extends State<VehicleScreen> {
  final TextEditingController brandCtrl = TextEditingController();
  final TextEditingController modelCtrl = TextEditingController();
  final TextEditingController regCtrl = TextEditingController();
  String? selectedFuel;

  static const Color green = Color(0xFF2E7D32);

  final ApiService _apiService = ApiService.instance;
  bool _isSubmitting = false;

  @override
  void dispose() {
    brandCtrl.dispose();
    modelCtrl.dispose();
    regCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Vehicle',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 24),

              /// ✅ Bike Icon (same size & green color)
              Icon(Icons.two_wheeler, size: 90, color: green),

              const SizedBox(height: 30),

              _label('Brand'),
              _textField(controller: brandCtrl, hint: ''),

              const SizedBox(height: 16),

              _label('Model'),
              _textField(controller: modelCtrl, hint: ''),

              const SizedBox(height: 16),

              _label('Registration number'),
              _textField(controller: regCtrl, hint: ''),

              const SizedBox(height: 16),

              _label('Fuel type'),

              /// ✅ Fuel Type Dropdown (as per image)
              DropdownButtonFormField<String>(
                value: selectedFuel,
                icon: const Icon(Icons.keyboard_arrow_down, color: green),
                decoration: InputDecoration(
                  hintText: 'Select',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.black12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.black12),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'Petrol', child: Text('Petrol')),
                  DropdownMenuItem(value: 'Electric', child: Text('Electric')),
                  DropdownMenuItem(value: 'CNG', child: Text('CNG')),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedFuel = value;
                  });
                },
              ),

              const SizedBox(height: 32),

              /// ✅ Sign Up Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => _submitVehicleRegistration(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Sign Up',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitVehicleRegistration() async {
    final brand = brandCtrl.text.trim();
    final model = modelCtrl.text.trim();
    final regNumber = regCtrl.text.trim();
    final fuel = selectedFuel;

    if (brand.isEmpty || model.isEmpty || regNumber.isEmpty || fuel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final response = await _apiService.registerVehicle(
        roleId: 2,
        brand: brand,
        model: model,
        registrationNumber: regNumber,
        fuelType: fuel,
      );

      if (!mounted) return;

      if (response.success) {
        await SecureStorageService.markVehicleRegisteredForCurrentUser();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message ?? 'Vehicle registered.')),
        );

        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.Deliverypersondashbord,
          (_) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'Vehicle registration failed.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  /// ---------- Helpers ----------

  Widget _label(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(fontSize: 13, color: Colors.black54),
        ),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF7F7F7),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
