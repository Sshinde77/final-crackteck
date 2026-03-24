import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../provider/delivery_person/delivery_personal_info_provider.dart';

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

  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _maritalStatusCtrl = TextEditingController();
  final _employmentTypeCtrl = TextEditingController();
  final _joiningDateCtrl = TextEditingController();
  final _assignedAreaCtrl = TextEditingController();
  String? _gender;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<DeliveryPersonalInfoProvider>().load();
    });
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

  String? _emptyToNull(String value) => value.isEmpty ? null : value;

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<DeliveryPersonalInfoProvider>();
    final response = await provider.save(
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      dob: _dobCtrl.text.trim(),
      gender: (_gender ?? '').trim(),
      maritalStatus: _maritalStatusCtrl.text.trim(),
      employmentType: _employmentTypeCtrl.text.trim(),
      joiningDate: _joiningDateCtrl.text.trim(),
      assignedArea: _assignedAreaCtrl.text.trim(),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(response)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DeliveryPersonalInfoProvider>();
    final info = provider.info;
    if (!provider.isLoading && _firstNameCtrl.text.isEmpty && info.raw.isNotEmpty) {
      _firstNameCtrl.text = info.firstName;
      _lastNameCtrl.text = info.lastName;
      _dobCtrl.text = info.dob;
      _gender ??= _emptyToNull(info.gender ?? '');
      _maritalStatusCtrl.text = info.maritalStatus;
      _employmentTypeCtrl.text = info.employmentType;
      _joiningDateCtrl.text = info.joiningDate;
      _assignedAreaCtrl.text = info.assignedArea;
    }
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: green,
        foregroundColor: Colors.white,
        title: const Text('Personal info'),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
              ? _ErrorState(message: provider.error!, onRetry: provider.load)
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
                            onPressed: provider.isSaving ? null : _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: green,
                            ),
                            child: provider.isSaving
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
