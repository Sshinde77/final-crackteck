import 'dart:convert';
import 'dart:io';

import 'package:country_state_city_picker/model/select_status_model.dart'
    as csc_picker;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'constants/app_colors.dart';
import 'constants/app_spacing.dart';
import 'constants/app_strings.dart';
import 'routes/app_routes.dart';
import 'services/api_service.dart';

enum _DocumentType {
  aadharFront,
  aadharBack,
  panFront,
  panBack,
  licenceFront,
  licenceBack,
}

class SignupScreen extends StatefulWidget {
  final SignUpArguments arg;
  const SignupScreen({super.key, required this.arg});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _personalFormKey = GlobalKey<FormState>();
  final _documentFormKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService.instance;

  final firstNameCtrl = TextEditingController();
  final lastNameCtrl = TextEditingController();
  final numberCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final addressLine1Ctrl = TextEditingController();
  final addressLine2Ctrl = TextEditingController();
  final countryCtrl = TextEditingController(text: 'India');
  final stateCtrl = TextEditingController();
  final cityCtrl = TextEditingController();
  final pincodeCtrl = TextEditingController();
  final aadharCtrl = TextEditingController();
  final panCtrl = TextEditingController();
  final licenceNumberCtrl = TextEditingController();

  File? aadharFrontFile;
  File? aadharBackFile;
  File? panFrontFile;
  File? panBackFile;
  File? licenceFrontFile;
  File? licenceBackFile;

  List<csc_picker.StatusModel> _countries = <csc_picker.StatusModel>[];
  List<csc_picker.State> _states = <csc_picker.State>[];
  List<csc_picker.City> _cities = <csc_picker.City>[];
  String? _selectedCountry;
  String? _selectedState;
  String? _selectedCity;
  bool _locationLoading = true;

  int _currentStep = 0;
  bool agree = false;
  bool loading = false;

  bool get _isDeliveryPerson => widget.arg.roleId == 2;

  @override
  void initState() {
    super.initState();
    _initLocationPicker();
  }

  @override
  void dispose() {
    firstNameCtrl.dispose();
    lastNameCtrl.dispose();
    numberCtrl.dispose();
    emailCtrl.dispose();
    addressLine1Ctrl.dispose();
    addressLine2Ctrl.dispose();
    countryCtrl.dispose();
    stateCtrl.dispose();
    cityCtrl.dispose();
    pincodeCtrl.dispose();
    aadharCtrl.dispose();
    panCtrl.dispose();
    licenceNumberCtrl.dispose();
    super.dispose();
  }

  Future<void> _initLocationPicker() async {
    const assetPath =
        'packages/country_state_city_picker/lib/assets/country.json';

    try {
      final raw = await rootBundle.loadString(assetPath);
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        throw Exception('Invalid country-state-city dataset');
      }

      final parsed = decoded
          .whereType<Map>()
          .map(
            (e) => csc_picker.StatusModel.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList();

      if (!mounted) return;
      setState(() {
        _countries = parsed;
        _selectedCountry = _countries
            .firstWhere(
              (e) => (e.name ?? '').toLowerCase() == 'india',
              orElse: () => _countries.isNotEmpty
                  ? _countries.first
                  : csc_picker.StatusModel(name: 'India'),
            )
            .name;
        countryCtrl.text = _selectedCountry ?? 'India';
        _syncStatesAndCities();
        _locationLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _selectedCountry = 'India';
        countryCtrl.text = 'India';
        _states = <csc_picker.State>[];
        _cities = <csc_picker.City>[];
        _selectedState = null;
        _selectedCity = null;
        stateCtrl.clear();
        cityCtrl.clear();
        _locationLoading = false;
      });
    }
  }

  void _syncStatesAndCities() {
    final country = _countries.firstWhere(
      (e) => (e.name ?? '') == (_selectedCountry ?? ''),
      orElse: () => csc_picker.StatusModel(state: <csc_picker.State>[]),
    );

    _states = country.state ?? <csc_picker.State>[];
    _selectedState = _states.isNotEmpty ? _states.first.name : null;
    stateCtrl.text = _selectedState ?? '';

    final state = _states.firstWhere(
      (e) => (e.name ?? '') == (_selectedState ?? ''),
      orElse: () => csc_picker.State(city: <csc_picker.City>[]),
    );
    _cities = state.city ?? <csc_picker.City>[];
    _selectedCity = _cities.isNotEmpty ? _cities.first.name : null;
    cityCtrl.text = _selectedCity ?? '';
  }

  void _syncCitiesOnly() {
    final state = _states.firstWhere(
      (e) => (e.name ?? '') == (_selectedState ?? ''),
      orElse: () => csc_picker.State(city: <csc_picker.City>[]),
    );
    _cities = state.city ?? <csc_picker.City>[];
    _selectedCity = _cities.isNotEmpty ? _cities.first.name : null;
    cityCtrl.text = _selectedCity ?? '';
  }

  Future<void> _pickFile(_DocumentType type) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'pdf'],
      withData: false,
    );

    if (result == null || result.files.isEmpty) return;

    final picked = result.files.single;
    final fileName = picked.name.toLowerCase();
    final isSupportedExtension =
        fileName.endsWith('.png') ||
        fileName.endsWith('.jpg') ||
        fileName.endsWith('.jpeg') ||
        fileName.endsWith('.pdf');

    if (!isSupportedExtension) {
      _snack('Please select a PNG, JPG, JPEG, or PDF file');
      return;
    }

    if (picked.size > 2 * 1024 * 1024) {
      _snack('File size must be less than 2MB');
      return;
    }

    if (picked.path == null) {
      _snack('This platform does not provide a local file path for uploads.');
      return;
    }

    final file = File(picked.path!);
    setState(() {
      switch (type) {
        case _DocumentType.aadharFront:
          aadharFrontFile = file;
          break;
        case _DocumentType.aadharBack:
          aadharBackFile = file;
          break;
        case _DocumentType.panFront:
          panFrontFile = file;
          break;
        case _DocumentType.panBack:
          panBackFile = file;
          break;
        case _DocumentType.licenceFront:
          licenceFrontFile = file;
          break;
        case _DocumentType.licenceBack:
          licenceBackFile = file;
          break;
      }
    });
  }

  Future<void> _goToDocumentsStep() async {
    if (_locationLoading) {
      _snack('Location data is still loading. Please wait.');
      return;
    }
    if (!_personalFormKey.currentState!.validate()) return;

    setState(() {
      _currentStep = 1;
    });
  }

  void _goToPersonalStep() {
    setState(() {
      _currentStep = 0;
    });
  }

  Future<void> signup() async {
    final isDelivery = _isDeliveryPerson;
    if (!_documentFormKey.currentState!.validate()) return;

    if (!agree) {
      _snack('Please accept terms and conditions');
      return;
    }

    if (aadharFrontFile == null || aadharBackFile == null) {
      _snack('Please upload Aadhar front and back images');
      return;
    }
    if (panFrontFile == null || panBackFile == null) {
      _snack('Please upload PAN front and back images');
      return;
    }
    if (isDelivery && (licenceFrontFile == null || licenceBackFile == null)) {
      _snack('Please upload licence front and back files');
      return;
    }

    final fullName =
        '${firstNameCtrl.text.trim()} ${lastNameCtrl.text.trim()}'.trim();
    final fullAddress = <String>[
      addressLine1Ctrl.text.trim(),
      addressLine2Ctrl.text.trim(),
      cityCtrl.text.trim(),
      stateCtrl.text.trim(),
      countryCtrl.text.trim(),
      pincodeCtrl.text.trim(),
    ].where((e) => e.isNotEmpty).join(', ');

    setState(() => loading = true);

    final res = await _apiService.signup(
      name: fullName,
      phone: numberCtrl.text.trim(),
      email: emailCtrl.text.trim(),
      address: fullAddress,
      aadhar: aadharCtrl.text.trim(),
      pan: panCtrl.text.trim(),
      aadharFile: aadharFrontFile!,
      panFile: panFrontFile!,
      firstName: firstNameCtrl.text.trim(),
      lastName: lastNameCtrl.text.trim(),
      addressLine1: addressLine1Ctrl.text.trim(),
      addressLine2: addressLine2Ctrl.text.trim(),
      country: countryCtrl.text.trim(),
      state: stateCtrl.text.trim(),
      city: cityCtrl.text.trim(),
      pincode: pincodeCtrl.text.trim(),
      aadharBackFile: aadharBackFile,
      panBackFile: panBackFile,
      drivingLicenceNumber: isDelivery ? licenceNumberCtrl.text.trim() : null,
      licenceFrontFile: isDelivery ? licenceFrontFile : null,
      licenceBackFile: isDelivery ? licenceBackFile : null,
    );

    if (!mounted) return;
    setState(() => loading = false);

    if (res.success) {
      _snack('Signup successful');
      Navigator.pop(context);
    } else {
      _snack(res.message ?? 'Signup failed');
    }
  }

  bool _isValidEmail(String value) {
    final v = value.trim();
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return regex.hasMatch(v);
  }

  String _fileLabel(File? file) {
    if (file == null) return 'Click to upload';
    final parts = file.path.split(RegExp(r'[\\/]'));
    final name = parts.isEmpty ? file.path : parts.last;
    return name.isEmpty ? 'File selected' : name;
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _navigateToLogin() {
    Navigator.pushNamed(
      context,
      AppRoutes.login,
      arguments: LoginArguments(
        roleId: widget.arg.roleId,
        roleName: widget.arg.roleName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roleName = widget.arg.roleName;
    final isDelivery = _isDeliveryPerson;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.horizontalPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                'Hi, Welcome\n$roleName!',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                getSignUpSubtitle(roleName),
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 18),
              _buildStepHeader(),
              const SizedBox(height: 16),
              if (_currentStep == 0)
                _buildPersonalDetailsForm()
              else
                _buildDocumentsForm(isDelivery),
              const SizedBox(height: 15),
              Center(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black),
                    children: [
                      const TextSpan(text: 'Have an account? '),
                      TextSpan(
                        text: 'Login',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = _navigateToLogin,
                      ),
                    ],
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

  Widget _buildStepHeader() {
    return Row(
      children: [
        Expanded(
          child: _stepChip(
            title: '1. Personal Details',
            isActive: _currentStep == 0,
            isCompleted: _currentStep > 0,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _stepChip(
            title: '2. Documents',
            isActive: _currentStep == 1,
            isCompleted: false,
          ),
        ),
      ],
    );
  }

  Widget _stepChip({
    required String title,
    required bool isActive,
    required bool isCompleted,
  }) {
    Color borderColor = Colors.grey.shade300;
    Color textColor = Colors.black54;
    Color bgColor = Colors.white;

    if (isCompleted) {
      borderColor = AppColors.primary;
      textColor = AppColors.primary;
      bgColor = AppColors.primary.withValues(alpha: 0.08);
    } else if (isActive) {
      borderColor = AppColors.primary;
      textColor = AppColors.primary;
      bgColor = AppColors.primary.withValues(alpha: 0.05);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildPersonalDetailsForm() {
    return Form(
      key: _personalFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _input(
            'First Name',
            firstNameCtrl,
            textCapitalization: TextCapitalization.words,
          ),
          _input(
            'Last Name',
            lastNameCtrl,
            textCapitalization: TextCapitalization.words,
          ),
          _input(
            'Phone',
            numberCtrl,
            keyboard: TextInputType.phone,
            prefix: '+91 ',
            maxLength: 10,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (v) {
              final value = (v ?? '').trim();
              if (value.isEmpty) return 'Required';
              if (value.length != 10) return 'Enter valid 10 digit phone';
              return null;
            },
          ),
          _input(
            'Email',
            emailCtrl,
            keyboard: TextInputType.emailAddress,
            validator: (v) {
              final value = (v ?? '').trim();
              if (value.isEmpty) return 'Required';
              if (!_isValidEmail(value)) return 'Enter valid email';
              return null;
            },
          ),
          _input(
            'Address Line 1',
            addressLine1Ctrl,
            textCapitalization: TextCapitalization.sentences,
          ),
          _input(
            'Address Line 2',
            addressLine2Ctrl,
            textCapitalization: TextCapitalization.sentences,
          ),
          _buildLocationPicker(),
          _input(
            'Pincode',
            pincodeCtrl,
            keyboard: TextInputType.number,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (v) {
              final value = (v ?? '').trim();
              if (value.isEmpty) return 'Required';
              if (value.length != 6) return 'Enter valid 6 digit pincode';
              return null;
            },
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _goToDocumentsStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Next',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationPicker() {
    if (_locationLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          children: [
            SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Loading country/state/city...',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ),
          ],
        ),
      );
    }

    final countries = _countries
        .map((e) => (e.name ?? '').trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final states = _states
        .map((e) => (e.name ?? '').trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final cities = _cities
        .map((e) => (e.name ?? '').trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return Column(
      children: [
        _dropdown(
          hint: 'Country',
          value: _selectedCountry,
          items: countries,
          onChanged: (value) {
            setState(() {
              _selectedCountry = value;
              countryCtrl.text = value ?? '';
              _syncStatesAndCities();
            });
          },
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Select country' : null,
        ),
        _dropdown(
          hint: 'State',
          value: _selectedState,
          items: states,
          onChanged: (value) {
            setState(() {
              _selectedState = value;
              stateCtrl.text = value ?? '';
              _syncCitiesOnly();
            });
          },
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Select state' : null,
        ),
        _dropdown(
          hint: 'City',
          value: _selectedCity,
          items: cities,
          onChanged: (value) {
            setState(() {
              _selectedCity = value;
              cityCtrl.text = value ?? '';
            });
          },
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Select city' : null,
        ),
      ],
    );
  }

  Widget _dropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    final normalizedValue =
        (value != null && items.contains(value)) ? value : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: normalizedValue,
        isExpanded: true,
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
        items: items
            .map(
              (item) => DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDocumentsForm(bool isDelivery) {
    return Form(
      key: _documentFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _input(
            'Aadhar no.',
            aadharCtrl,
            keyboard: TextInputType.number,
            maxLength: 12,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (v) {
              final value = (v ?? '').trim();
              if (value.isEmpty) return 'Required';
              if (value.length != 12) return 'Enter valid 12 digit Aadhar';
              return null;
            },
          ),
          _uploadBox(
            title: 'Aadhar Card Front Image',
            subtitle: 'PNG, JPG, JPEG, or PDF (max. 2MB)',
            file: aadharFrontFile,
            onTap: () => _pickFile(_DocumentType.aadharFront),
          ),
          const SizedBox(height: 10),
          _uploadBox(
            title: 'Aadhar Card Back Image',
            subtitle: 'PNG, JPG, JPEG, or PDF (max. 2MB)',
            file: aadharBackFile,
            onTap: () => _pickFile(_DocumentType.aadharBack),
          ),
          const SizedBox(height: 10),
          _input(
            'PAN no.',
            panCtrl,
            textCapitalization: TextCapitalization.characters,
            maxLength: 10,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9]'))],
            validator: (v) {
              final value = (v ?? '').trim().toUpperCase();
              if (value.isEmpty) return 'Required';
              if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(value)) {
                return 'Enter valid PAN';
              }
              panCtrl.value = panCtrl.value.copyWith(
                text: value,
                selection: TextSelection.collapsed(offset: value.length),
              );
              return null;
            },
          ),
          _uploadBox(
            title: 'PAN Card Front Image',
            subtitle: 'PNG, JPG, JPEG, or PDF (max. 2MB)',
            file: panFrontFile,
            onTap: () => _pickFile(_DocumentType.panFront),
          ),
          const SizedBox(height: 10),
          _uploadBox(
            title: 'PAN Card Back Image',
            subtitle: 'PNG, JPG, JPEG, or PDF (max. 2MB)',
            file: panBackFile,
            onTap: () => _pickFile(_DocumentType.panBack),
          ),
          if (isDelivery) ...[
            const SizedBox(height: 10),
            _input('Driving Licence Number', licenceNumberCtrl),
            _uploadBox(
              title: 'Licence Front Image',
              subtitle: 'PNG, JPG, JPEG, or PDF (max. 2MB)',
              file: licenceFrontFile,
              onTap: () => _pickFile(_DocumentType.licenceFront),
            ),
            const SizedBox(height: 10),
            _uploadBox(
              title: 'Licence Back Image',
              subtitle: 'PNG, JPG, JPEG, or PDF (max. 2MB)',
              file: licenceBackFile,
              onTap: () => _pickFile(_DocumentType.licenceBack),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Checkbox(
                value: agree,
                onChanged: (v) => setState(() => agree = v ?? false),
                activeColor: AppColors.primary,
              ),
              const Expanded(
                child: Text(
                  'I agree to the terms and conditions',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: loading ? null : _goToPersonalStep,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Back',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: loading ? null : signup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Submit',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _input(
    String hint,
    TextEditingController ctrl, {
    TextInputType keyboard = TextInputType.text,
    String? prefix,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboard,
        maxLength: maxLength,
        inputFormatters: inputFormatters,
        textCapitalization: textCapitalization,
        validator: validator ?? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
        decoration: InputDecoration(
          hintText: hint,
          prefixText: prefix,
          counterText: '',
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _uploadBox({
    required String title,
    required String subtitle,
    required File? file,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onTap,
            child: Container(
              height: 45,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _fileLabel(file),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
