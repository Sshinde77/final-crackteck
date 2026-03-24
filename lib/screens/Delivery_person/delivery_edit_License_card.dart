import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../provider/delivery_person/delivery_documents_provider.dart';

class LicenseEditScreen extends StatefulWidget {
  const LicenseEditScreen({super.key});

  @override
  State<LicenseEditScreen> createState() => _LicenseEditScreenState();
}

class _LicenseEditScreenState extends State<LicenseEditScreen> {
  static const Color darkGreen = Color(0xFF145A00);

  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  final TextEditingController licenceCtrl = TextEditingController();

  XFile? _frontFile;
  XFile? _backFile;
  String? _frontLabel;
  String? _backLabel;
  String _vehicleType = '';
  String _vehicleNumber = '';
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
    licenceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pick(bool front) async {
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
                  allowedExtensions: ['jpg', 'jpeg', 'pdf', 'png'],
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<DeliveryDocumentsProvider>();
    final message = await provider.saveVehicle(
      vehicleType: _vehicleType,
      vehicleNumber: _vehicleNumber,
      drivingLicenseNo: licenceCtrl.text.trim(),
      frontFile: _frontFile,
      backFile: _backFile,
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
    if (!provider.isLoading && licenceCtrl.text.isEmpty) {
      licenceCtrl.text =
          (vehicle['driving_license_no'] ?? vehicle['licence_no'] ?? '').toString();
      _vehicleType = (vehicle['vehicle_type'] ?? vehicle['brand'] ?? 'Bike').toString();
      _vehicleNumber =
          (vehicle['vehicle_number'] ?? vehicle['registration_number'] ?? '').toString();
      _frontLabel ??=
          (vehicle['driving_license_front_path'] ?? vehicle['licence_front_image'])?.toString();
      _backLabel ??=
          (vehicle['driving_license_back_path'] ?? vehicle['licence_back_image'])?.toString();
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
          'Driving License details',
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
        ),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Label('Driving license no.'),
                    _InputField(
                      controller: licenceCtrl,
                      hint: 'Enter license number',
                    ),
                    const SizedBox(height: 20),
                    _UploadBox(
                      label: 'Driving License Front Image',
                      fileName: _frontLabel,
                      onTap: () => _pick(true),
                    ),
                    const SizedBox(height: 16),
                    _UploadBox(
                      label: 'Driving License Back Image',
                      fileName: _backLabel,
                      onTap: () => _pick(false),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: provider.isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: darkGreen,
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
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
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
                  ],
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
        border: const UnderlineInputBorder(),
        isDense: true,
      ),
      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
    );
  }
}

class _UploadBox extends StatelessWidget {
  const _UploadBox({
    required this.label,
    required this.onTap,
    this.fileName,
  });

  final String label;
  final VoidCallback onTap;
  final String? fileName;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 110,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black26),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.upload_outlined, color: Colors.green),
                SizedBox(width: 12),
                Icon(Icons.camera_alt_outlined, color: Colors.green),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              fileName?.isNotEmpty == true
                  ? fileName!.split('/').last
                  : 'Click to upload or take a photo',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
