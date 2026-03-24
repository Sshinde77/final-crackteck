import 'package:flutter/material.dart';

import '../../services/delivery_man_service.dart';

class DeliveryPersonalInfoScreen extends StatefulWidget {
  const DeliveryPersonalInfoScreen({
    super.key,
    required this.roleId,
    required this.roleName,
  });

  final int roleId;
  final String roleName;

  @override
  State<DeliveryPersonalInfoScreen> createState() =>
      _DeliveryPersonalInfoScreenState();
}

class _DeliveryPersonalInfoScreenState extends State<DeliveryPersonalInfoScreen> {
  static const Color green = Color(0xFF1E7C10);

  final DeliveryManService _deliveryService = DeliveryManService.instance;
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _maritalStatusCtrl = TextEditingController();
  final _employmentTypeCtrl = TextEditingController();
  final _joiningDateCtrl = TextEditingController();
  final _assignedAreaCtrl = TextEditingController();
  String? _gender;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _dobCtrl.dispose();
    _maritalStatusCtrl.dispose();
    _employmentTypeCtrl.dispose();
    _joiningDateCtrl.dispose();
    _assignedAreaCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });
    try {
      final profile = await _deliveryService.fetchProfile();
      if (!mounted) return;
      setState(() {
        _firstNameCtrl.text = _read(profile, 'first_name');
        _lastNameCtrl.text = _read(profile, 'last_name');
        _dobCtrl.text = _read(profile, 'dob');
        _gender = _emptyToNull(_read(profile, 'gender'));
        _maritalStatusCtrl.text = _read(profile, 'marital_status');
        _employmentTypeCtrl.text = _read(profile, 'employment_type');
        _joiningDateCtrl.text = _read(profile, 'joining_date');
        _assignedAreaCtrl.text = _read(profile, 'assigned_area');
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

  String? _emptyToNull(String value) => value.isEmpty ? null : value;

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final response = await _deliveryService.updateProfile(
      fields: <String, dynamic>{
        'first_name': _firstNameCtrl.text.trim(),
        'last_name': _lastNameCtrl.text.trim(),
        'dob': _dobCtrl.text.trim(),
        'gender': (_gender ?? '').trim(),
        'marital_status': _maritalStatusCtrl.text.trim(),
        'employment_type': _employmentTypeCtrl.text.trim(),
        'joining_date': _joiningDateCtrl.text.trim(),
        'assigned_area': _assignedAreaCtrl.text.trim(),
      },
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(response.message ?? 'Profile updated')),
    );
    if (response.success) {
      _loadProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: green,
        foregroundColor: Colors.white,
        title: const Text('Personal info'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorText != null
              ? _ErrorState(message: _errorText!, onRetry: _loadProfile)
              : SafeArea(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _field('First Name', _firstNameCtrl),
                        _field('Last Name', _lastNameCtrl),
                        _field(
                          'DOB (YYYY-MM-DD)',
                          _dobCtrl,
                          keyboardType: TextInputType.datetime,
                        ),
                        DropdownButtonFormField<String>(
                          initialValue: _gender,
                          decoration: _decoration('Gender'),
                          items: const ['Male', 'Female', 'Other']
                              .map(
                                (value) => DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                ),
                              )
                              .toList(),
                          onChanged: (value) => setState(() => _gender = value),
                        ),
                        const SizedBox(height: 12),
                        _field('Marital Status', _maritalStatusCtrl),
                        _field('Employment Type', _employmentTypeCtrl),
                        _field(
                          'Joining Date (YYYY-MM-DD)',
                          _joiningDateCtrl,
                          keyboardType: TextInputType.datetime,
                        ),
                        _field('Assigned Area', _assignedAreaCtrl),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: green,
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Save',
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

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

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
