import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/delivery_man_service.dart';

class PancardEditScreen extends StatefulWidget {
  const PancardEditScreen({super.key});

  @override
  State<PancardEditScreen> createState() => _PancardEditScreenState();
}

class _PancardEditScreenState extends State<PancardEditScreen> {
  static const Color darkGreen = Color(0xFF145A00);

  final _formKey = GlobalKey<FormState>();
  final _service = DeliveryManService.instance;
  final _picker = ImagePicker();

  final TextEditingController panCtrl = TextEditingController();

  XFile? _frontFile;
  XFile? _backFile;
  String? _frontLabel;
  String? _backLabel;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUpdate = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    panCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.fetchPanDetails();
      panCtrl.text = (data['pan_number'] ?? data['pan_no'] ?? '').toString();
      _frontLabel = (data['pan_card_front_path'] ?? data['pan_front'])?.toString();
      _backLabel = (data['pan_card_back_path'] ?? data['pan_back'])?.toString();
      _isUpdate = panCtrl.text.trim().isNotEmpty;
    } catch (_) {
      _isUpdate = false;
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showPickerOptions(bool isFront) async {
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
                    if (isFront) {
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
                    if (isFront) {
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
                    if (isFront) {
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

    setState(() => _isSaving = true);
    try {
      final response = await _service.savePanDetails(
        panNumber: panCtrl.text.trim(),
        frontFile: _frontFile,
        backFile: _backFile,
        isUpdate: _isUpdate,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message ?? 'PAN saved')),
      );
      if (response.success) {
        Navigator.pop(context);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Pan Card details',
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none, color: Colors.white),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Label('Pan no.'),
                    _InputField(
                      controller: panCtrl,
                      hint: 'Enter PAN number',
                    ),
                    const SizedBox(height: 20),
                    _UploadBox(
                      label: 'Pan Card Front Image',
                      fileName: _frontLabel,
                      onTap: () => _showPickerOptions(true),
                    ),
                    const SizedBox(height: 16),
                    _UploadBox(
                      label: 'Pan Card Back Image',
                      fileName: _backLabel,
                      onTap: () => _showPickerOptions(false),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: darkGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isSaving
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
            const SizedBox(height: 4),
            const Text(
              'PNG, PDF, JPG or JPEG',
              style: TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
