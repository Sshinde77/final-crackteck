import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../services/delivery_man_service.dart';

class DeliveryKycScreen extends StatefulWidget {
  const DeliveryKycScreen({
    super.key,
    required this.roleId,
    required this.roleName,
  });

  final int roleId;
  final String roleName;

  @override
  State<DeliveryKycScreen> createState() => _DeliveryKycScreenState();
}

class _DeliveryKycScreenState extends State<DeliveryKycScreen> {
  static const Color green = Color(0xFF1E7C10);

  final DeliveryManService _deliveryService = DeliveryManService.instance;
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _documentNoCtrl = TextEditingController();
  String? _documentType;
  Map<String, dynamic> _status = <String, dynamic>{};
  File? _selectedFile;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _dobCtrl.dispose();
    _documentNoCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });
    try {
      final results = await Future.wait<dynamic>([
        _deliveryService.fetchProfile(),
        _deliveryService.fetchKycStatus(),
      ]);
      final profile = results[0] as Map<String, dynamic>;
      final status = results[1] as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _nameCtrl.text =
            '${_read(profile, 'first_name')} ${_read(profile, 'last_name')}'
                .trim();
        if (_nameCtrl.text.isEmpty) {
          _nameCtrl.text = _read(profile, 'name');
        }
        _emailCtrl.text = _read(profile, 'email');
        _phoneCtrl.text = _read(profile, 'phone');
        _dobCtrl.text = _read(profile, 'dob');
        _status = status;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorText = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _read(Map<String, dynamic> source, String key) {
    final value = source[key];
    if (value == null) return '';
    return value.toString().trim();
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'pdf'],
    );
    if (result == null || result.files.isEmpty || result.files.single.path == null) {
      return;
    }
    setState(() => _selectedFile = File(result.files.single.path!));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFile == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a file')));
      return;
    }
    setState(() => _isSubmitting = true);
    final response = await _deliveryService.submitKyc(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      dob: _dobCtrl.text.trim(),
      documentType: (_documentType ?? '').trim(),
      documentNo: _documentNoCtrl.text.trim(),
      documentFile: _selectedFile!,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(response.message ?? 'KYC submitted')),
    );
    if (response.success) {
      _loadData();
    }
  }

  String get _statusText {
    return (_status['status'] ??
            _status['kyc_status'] ??
            _status['state'] ??
            'Not submitted')
        .toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: green,
        foregroundColor: Colors.white,
        title: const Text('KYC Log'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorText != null
              ? _KycError(message: _errorText!, onRetry: _loadData)
              : SafeArea(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F7F1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.verified_user_outlined, color: green),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Current status: $_statusText',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _field('Name', _nameCtrl),
                        _field('Email', _emailCtrl, keyboardType: TextInputType.emailAddress),
                        _field('Phone', _phoneCtrl, keyboardType: TextInputType.phone),
                        _field('DOB (YYYY-MM-DD)', _dobCtrl, keyboardType: TextInputType.datetime),
                        DropdownButtonFormField<String>(
                          initialValue: _documentType,
                          decoration: _decoration('Document Type'),
                          items: const ['Aadhar', 'PAN', 'Driving Licence', 'Passport']
                              .map(
                                (value) => DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                ),
                              )
                              .toList(),
                          validator: (value) =>
                              value == null || value.isEmpty ? 'Select document type' : null,
                          onChanged: (value) => setState(() => _documentType = value),
                        ),
                        const SizedBox(height: 12),
                        _field('Document Number', _documentNoCtrl),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _pickDocument,
                          icon: const Icon(Icons.upload_file),
                          label: Text(
                            _selectedFile == null
                                ? 'Upload Document'
                                : _selectedFile!.path.split(RegExp(r'[\\/]')).last,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: green,
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Submit KYC',
                                    style: TextStyle(color: Colors.white),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: (value) =>
            value == null || value.trim().isEmpty ? 'Required' : null,
        decoration: _decoration(label),
      ),
    );
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF4F6F8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}

class _KycError extends StatelessWidget {
  const _KycError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
