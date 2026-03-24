import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:final_crackteck/core/secure_storage_service.dart';
import 'package:final_crackteck/routes/app_routes.dart';
import 'package:final_crackteck/services/delivery_man_service.dart';

class VehicleScreen extends StatefulWidget {
  const VehicleScreen({super.key});

  @override
  State<VehicleScreen> createState() => _VehicleScreenState();
}

class _VehicleScreenState extends State<VehicleScreen> {
  final TextEditingController vehicleTypeCtrl = TextEditingController();
  final TextEditingController vehicleNumberCtrl = TextEditingController();
  final TextEditingController licenceCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final DeliveryManService _service = DeliveryManService.instance;

  static const Color green = Color(0xFF2E7D32);

  XFile? _frontFile;
  XFile? _backFile;
  String? _frontLabel;
  String? _backLabel;
  bool _isSubmitting = false;

  @override
  void dispose() {
    vehicleTypeCtrl.dispose();
    vehicleNumberCtrl.dispose();
    licenceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile(bool front) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () async {
                Navigator.pop(context);
                final file = await _picker.pickImage(source: ImageSource.camera);
                if (file != null && mounted) {
                  setState(() {
                    if (front) {
                      _frontFile = file;
                      _frontLabel = file.name;
                    } else {
                      _backFile = file;
                      _backLabel = file.name;
                    }
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final file = await _picker.pickImage(source: ImageSource.gallery);
                if (file != null && mounted) {
                  setState(() {
                    if (front) {
                      _frontFile = file;
                      _frontLabel = file.name;
                    } else {
                      _backFile = file;
                      _backLabel = file.name;
                    }
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file),
              title: const Text('File'),
              onTap: () async {
                Navigator.pop(context);
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
                );
                final path = result?.files.single.path;
                if (path != null && mounted) {
                  final file = XFile(path);
                  setState(() {
                    if (front) {
                      _frontFile = file;
                      _frontLabel = result!.files.single.name;
                    } else {
                      _backFile = file;
                      _backLabel = result!.files.single.name;
                    }
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitVehicleRegistration() async {
    final vehicleType = vehicleTypeCtrl.text.trim();
    final vehicleNumber = vehicleNumberCtrl.text.trim();
    final licenceNo = licenceCtrl.text.trim();

    if (vehicleType.isEmpty ||
        vehicleNumber.isEmpty ||
        licenceNo.isEmpty ||
        _frontFile == null ||
        _backFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all vehicle fields.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final response = await _service.registerVehicleDetails(
        vehicleType: vehicleType,
        vehicleNumber: vehicleNumber,
        drivingLicenseNo: licenceNo,
        frontFile: _frontFile!,
        backFile: _backFile!,
      );
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message ?? 'Vehicle registered.')),
      );

      if (response.success) {
        await SecureStorageService.markVehicleRegisteredForCurrentUser();
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.Deliverypersondashbord,
          (_) => false,
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

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
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _uploadCard({
    required String title,
    required String? fileName,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12),
        ),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            const Icon(Icons.upload_file, color: green, size: 30),
            const SizedBox(height: 8),
            Text(
              fileName ?? 'Tap to upload',
              textAlign: TextAlign.center,
              style: const TextStyle(color: green, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
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
          'Vehicle Registration',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 24),
              const Icon(Icons.two_wheeler, size: 90, color: green),
              const SizedBox(height: 30),
              _label('Vehicle type'),
              _textField(controller: vehicleTypeCtrl, hint: 'Bike / Car'),
              const SizedBox(height: 16),
              _label('Vehicle number'),
              _textField(controller: vehicleNumberCtrl, hint: 'MH00AB1234'),
              const SizedBox(height: 16),
              _label('Driving license no.'),
              _textField(controller: licenceCtrl, hint: 'Enter license number'),
              const SizedBox(height: 16),
              _uploadCard(
                title: 'Driving license front',
                fileName: _frontLabel,
                onTap: () => _pickFile(true),
              ),
              const SizedBox(height: 16),
              _uploadCard(
                title: 'Driving license back',
                fileName: _backLabel,
                onTap: () => _pickFile(false),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitVehicleRegistration,
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
                          'Continue',
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
}
