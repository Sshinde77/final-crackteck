import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:country_state_city_picker/model/select_status_model.dart'
    as csc_picker;

import '../../constants/api_constants.dart';
import '../../core/secure_storage_service.dart';
import '../../routes/app_routes.dart';
import '../../services/api_service.dart';
import '../../widgets/bottom_navigation.dart';

class NewLeadScreen extends StatefulWidget {
  final int roleId;
  final String roleName;
  final String? leadId;
  final bool isEdit;

  const NewLeadScreen({
    Key? key,
    required this.roleId,
    required this.roleName,
    this.leadId,
    this.isEdit = false,
  }) : super(key: key);

  @override
  State<NewLeadScreen> createState() => _NewLeadScreenState();
}

class _NewLeadScreenState extends State<NewLeadScreen> {
  static const Color midGreen = Color(0xFF1F8B00);
  // static const Color darkGreen = Color(0xFF145A00);

  bool _moreOpen = false;
  int _navIndex = 0;

  final _formKey = GlobalKey<FormState>();

  // Controllers
  final firstNameCtrl = TextEditingController();
  final lastNameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final address1Ctrl = TextEditingController();
  final address2Ctrl = TextEditingController();
  final cityCtrl = TextEditingController();
  final stateCtrl = TextEditingController();
  final countryCtrl = TextEditingController(text: 'India');
  final pincodeCtrl = TextEditingController();
  final requirementTypeCtrl = TextEditingController();
  final budgetRangeCtrl = TextEditingController();
  final notesCtrl = TextEditingController();
  static const List<String> _urgencyOptions = <String>[
    'Low',
    'Medium',
    'High',
    'Critical',
  ];

  List<csc_picker.StatusModel> _countries = <csc_picker.StatusModel>[];
  List<csc_picker.State> _states = <csc_picker.State>[];
  List<csc_picker.City> _cities = <csc_picker.City>[];

  String? _selectedCountry;
  String? _selectedState;
  String? _selectedCity;
  String? _selectedUrgency;
  bool _locationLoading = true;
  bool _leadLoading = false;

  bool get _isEditMode =>
      widget.isEdit && (widget.leadId != null && widget.leadId!.isNotEmpty);

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _locationLoading = false;
      _loadLeadForEdit();
    } else {
      _initLocationPicker();
    }
  }

  @override
  void dispose() {
    firstNameCtrl.dispose();
    lastNameCtrl.dispose();
    phoneCtrl.dispose();
    emailCtrl.dispose();
    address1Ctrl.dispose();
    address2Ctrl.dispose();
    cityCtrl.dispose();
    stateCtrl.dispose();
    countryCtrl.dispose();
    pincodeCtrl.dispose();
    requirementTypeCtrl.dispose();
    budgetRangeCtrl.dispose();
    notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _initLocationPicker() async {
    const assetPath =
        'packages/country_state_city_picker/lib/assets/country.json';
    try {
      final raw = await rootBundle.loadString(assetPath);
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        throw Exception('Invalid location dataset');
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

  Map<String, dynamic> _extractLeadMap(Map<String, dynamic> payload) {
    final data = payload['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is List && data.isNotEmpty && data.first is Map<String, dynamic>) {
      return Map<String, dynamic>.from(data.first as Map<String, dynamic>);
    }
    final lead = payload['lead'];
    if (lead is Map<String, dynamic>) return lead;
    return payload;
  }

  String _s(dynamic value) {
    if (value == null) return '';
    final t = value.toString().trim();
    return t.toLowerCase() == 'null' ? '' : t;
  }

  String _pick(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = _s(source[key]);
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  Map<String, dynamic> _firstMapFrom(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is List) {
      final maps = value
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      if (maps.isEmpty) return <String, dynamic>{};

      final primary = maps.where((m) {
        final flag = _s(m['is_primary']);
        return flag == '1' || flag.toLowerCase() == 'true';
      }).toList();
      if (primary.isNotEmpty) return primary.first;
      return maps.first;
    }
    return <String, dynamic>{};
  }

  String _pickFromMaps(List<Map<String, dynamic>> maps, List<String> keys) {
    for (final map in maps) {
      final value = _pick(map, keys);
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  String? _normalizeUrgency(String value) {
    final v = value.trim().toLowerCase();
    for (final option in _urgencyOptions) {
      if (option.toLowerCase() == v) return option;
    }
    return null;
  }

  Future<void> _loadLeadForEdit() async {
    if (!_isEditMode) return;
    setState(() => _leadLoading = true);
    try {
      final payload = await ApiService.fetchLeadDetail(
        widget.leadId!,
        roleId: widget.roleId,
      );
      final leadMap = _extractLeadMap(payload);
      if (!mounted) return;
      setState(() {
        final customerMap = _asMap(leadMap['customer']);
        final nestedAddress = _firstMapFrom(leadMap['customer_address']);
        final customerAddress = _firstMapFrom(customerMap['customer_address']);
        final branches = _firstMapFrom(customerMap['branches']);
        final addresses = _firstMapFrom(customerMap['addresses']);

        final sourceMaps = <Map<String, dynamic>>[
          nestedAddress,
          customerAddress,
          branches,
          addresses,
          customerMap,
          leadMap,
          payload,
        ];

        final fullAddress = _pickFromMaps(sourceMaps, [
          'address',
          'current_address',
          'full_address',
          'addr',
        ]);
        String address1 = _pickFromMaps(sourceMaps, [
          'address1',
          'address_1',
          'line1',
          'address_line_1',
          'street',
          'address',
          'current_address',
        ]);
        String address2 = _pickFromMaps(sourceMaps, [
          'address2',
          'address_2',
          'line2',
          'address_line_2',
          'landmark',
        ]);

        if (address1.isEmpty && fullAddress.isNotEmpty) {
          final parts = fullAddress
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
          if (parts.isNotEmpty) {
            address1 = parts.first;
            if (parts.length > 1 && address2.isEmpty) {
              address2 = parts.sublist(1).join(', ');
            }
          }
        }

        firstNameCtrl.text = _pick(leadMap, ['first_name']);
        if (firstNameCtrl.text.isEmpty) {
          final fullName = _pick(leadMap, ['name', 'full_name']);
          if (fullName.isNotEmpty) {
            final parts = fullName.split(RegExp(r'\s+'));
            firstNameCtrl.text = parts.first;
            if (parts.length > 1) {
              lastNameCtrl.text = parts.sublist(1).join(' ');
            }
          }
        }
        if (lastNameCtrl.text.isEmpty) {
          lastNameCtrl.text = _pick(leadMap, ['last_name']);
        }
        phoneCtrl.text = _pick(leadMap, ['phone', 'mobile']);
        emailCtrl.text = _pick(leadMap, ['email']);
        address1Ctrl.text = address1;
        address2Ctrl.text = address2;
        cityCtrl.text = _pickFromMaps(sourceMaps, ['city', 'city_name']);
        stateCtrl.text = _pickFromMaps(sourceMaps, ['state', 'state_name']);
        countryCtrl.text = _pickFromMaps(sourceMaps, ['country', 'country_name']);
        if (countryCtrl.text.isEmpty) {
          countryCtrl.text = 'India';
        }
        pincodeCtrl.text = _pickFromMaps(sourceMaps, ['pincode', 'zip', 'zipcode']);
        requirementTypeCtrl.text = _pick(leadMap, ['requirement_type']);
        budgetRangeCtrl.text = _pick(leadMap, ['budget_range']);
        notesCtrl.text = _pick(leadMap, ['notes']);
        _selectedUrgency = _normalizeUrgency(_pick(leadMap, ['urgency']));
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load lead details for editing')),
      );
    } finally {
      if (mounted) {
        setState(() => _leadLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      /// APP BAR
      appBar: AppBar(
        elevation: 0,
        backgroundColor: midGreen,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditMode ? 'Edit Lead' : 'New Leads',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              // Navigator.pushNamed(
              //   context,
              //   AppRoutes.NotificationScreen,
              //   arguments: NotificationArguments(
              //     roleId: widget.roleId,
              //     roleName: widget.roleName,
              //   ),
              // );
            },
            icon: const Icon(Icons.notifications_none, color: Colors.white),
          ),
          const SizedBox(width: 8),
        ],
      ),

      /// BODY
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _input(
                'First Name',
                firstNameCtrl,
                readOnly: _isEditMode,
                validator: _isEditMode
                    ? null
                    : (v) => (v == null || v.trim().isEmpty)
                          ? 'Enter first name'
                          : null,
              ),
              _input('Last Name', lastNameCtrl, readOnly: _isEditMode),
              _input(
                'Phone',
                phoneCtrl,
                readOnly: _isEditMode,
                prefixIcon: const SizedBox(
                  width: 52,
                  child: Center(
                    child: Text(
                      '+91',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                keyboardType: TextInputType.phone,
                validator: _isEditMode
                    ? null
                    : (v) {
                        if (v == null || v.trim().isEmpty) return 'Enter phone';
                        final digits = v.replaceAll(RegExp(r'\D'), '');
                        if (digits.length < 10) return 'Enter valid phone';
                        return null;
                      },
              ),
              _input(
                'Email',
                emailCtrl,
                readOnly: _isEditMode,
                keyboardType: TextInputType.emailAddress,
                validator: _isEditMode
                    ? null
                    : (v) {
                        if (v == null || v.trim().isEmpty) return 'Enter email';
                        final ok = RegExp(
                          r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                        ).hasMatch(v.trim());
                        return ok ? null : 'Enter valid email';
                      },
              ),
              if (!_isEditMode) ...[
                _input('Address1', address1Ctrl),
                _input('Address2', address2Ctrl),
                _locationPicker(),
                _input(
                  'Pincode',
                  pincodeCtrl,
                  keyboardType: TextInputType.number,
                ),
              ],
              _input('Requirement Type', requirementTypeCtrl),
              _input('Budget Range', budgetRangeCtrl),
              _urgencyDropdown(),
              _input('Notes', notesCtrl, maxLines: 4, readOnly: _isEditMode),

              const SizedBox(height: 12),
              const SizedBox(height: 8),

              /// SUBMIT BUTTON
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: midGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    if (_leadLoading) return;
                    final messenger = ScaffoldMessenger.of(context);
                    if (!_formKey.currentState!.validate()) {
                      return;
                    }

                    try {
                      final userId = await SecureStorageService.getUserId();
                      final accessToken =
                          await SecureStorageService.getAccessToken();

                      if (userId == null ||
                          accessToken == null ||
                          accessToken.isEmpty) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Authentication error. Please log in again.',
                            ),
                          ),
                        );
                        return;
                      }

                      final isEdit = _isEditMode;
                      final body = <String, dynamic>{
                        'user_id': userId,
                        'requirement_type': requirementTypeCtrl.text.trim(),
                        'budget_range': budgetRangeCtrl.text.trim(),
                        'urgency': _selectedUrgency ?? '',
                        'status': 'New',
                      };

                      if (!isEdit) {
                        body.addAll({
                          'first_name': firstNameCtrl.text.trim(),
                          'last_name': lastNameCtrl.text.trim(),
                          'name':
                              '${firstNameCtrl.text.trim()} ${lastNameCtrl.text.trim()}'
                                  .trim(),
                          'phone': phoneCtrl.text.trim(),
                          'email': emailCtrl.text.trim(),
                          'address1': address1Ctrl.text.trim(),
                          'address2': address2Ctrl.text.trim(),
                          'address':
                              '${address1Ctrl.text.trim()} ${address2Ctrl.text.trim()}'
                                  .trim(),
                          'city': cityCtrl.text.trim(),
                          'state': stateCtrl.text.trim(),
                          'country': countryCtrl.text.trim().isEmpty
                              ? 'India'
                              : countryCtrl.text.trim(),
                          'pincode': pincodeCtrl.text.trim(),
                          'industry_type': '',
                          'notes': notesCtrl.text.trim(),
                        });
                      }

                      final dynamic response;
                      if (isEdit) {
                        final endpoint = ApiConstants.edit_lead.replaceFirst(
                          '{lead_id}',
                          widget.leadId!,
                        );
                        final uri = Uri.parse(endpoint).replace(
                          queryParameters: {
                            'user_id': userId.toString(),
                            'role_id': widget.roleId.toString(),
                          },
                        );
                        response = await ApiService.put(
                          uri.toString(),
                          body,
                          token: accessToken,
                        );
                      } else {
                        response = await ApiService.post(
                          ApiConstants.new_lead,
                          body,
                          token: accessToken,
                        );
                      }

                      String message = isEdit
                          ? 'Lead updated successfully'
                          : 'Lead submitted';
                      bool success = true;
                      if (response is Map<String, dynamic>) {
                        if (response['message'] != null) {
                          message = response['message'].toString();
                        }
                        if (response['success'] is bool) {
                          success = response['success'] as bool;
                        } else if (response['status'] is bool) {
                          success = response['status'] as bool;
                        }
                      }

                      messenger.showSnackBar(SnackBar(content: Text(message)));

                      if (success) {
                        if (!mounted) return;
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context, true);
                        } else {
                          Navigator.pushReplacementNamed(
                            context,
                            AppRoutes.salespersonLeads,
                          );
                        }
                      }
                    } catch (e) {
                      if (!mounted) return;
                      messenger.showSnackBar(
                        SnackBar(content: Text('Failed to submit lead: $e')),
                      );
                    }
                  },
                  child: Text(
                    _isEditMode ? 'Update' : 'Submit',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      bottomNavigationBar: CrackteckBottomSwitcher(
        isMoreOpen: _moreOpen,
        currentIndex: _navIndex,
        roleId: widget.roleId,
        roleName: widget.roleName,
        onHome: () { Navigator.pushNamed(context, AppRoutes.salespersonDashboard);},
        onProfile: () { Navigator.pushNamed(context, AppRoutes.salespersonProfile);},
        onMore: () => setState(() => _moreOpen = true),
        onLess: () => setState(() => _moreOpen = false),
        onLeads: () { Navigator.pushNamed(context, AppRoutes.salespersonLeads);},
        onFollowUp: () { Navigator.pushNamed(context, AppRoutes.salespersonFollowUp);},
        onMeeting: () { Navigator.pushNamed(context, AppRoutes.salespersonMeeting);},
        onQuotation: () { Navigator.pushNamed(context, AppRoutes.salespersonQuotation);},
      ),
    );
  }

  /// TEXT INPUT
  Widget _input(
    String label,
    TextEditingController controller, {
    Widget? prefixIcon,
    bool readOnly = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboardType,
        validator: validator,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: prefixIcon,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _urgencyDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: _selectedUrgency,
        decoration: InputDecoration(
          labelText: 'Urgency',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        items: _urgencyOptions
            .map((e) => DropdownMenuItem<String>(value: e, child: Text(e)))
            .toList(),
        onChanged: _leadLoading
            ? null
            : (value) => setState(() => _selectedUrgency = value),
        validator: (v) =>
            (v == null || v.trim().isEmpty) ? 'Select urgency' : null,
      ),
    );
  }

  Widget _locationPicker() {
    if (_locationLoading) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            isExpanded: true,
            value: _selectedCountry,
            decoration: InputDecoration(
              labelText: 'Country',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: _countries
                .where((e) => (e.name ?? '').trim().isNotEmpty)
                .map(
                  (e) => DropdownMenuItem<String>(
                    value: e.name!,
                    child: Text(e.name!),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null || value.trim().isEmpty) return;
              setState(() {
                _selectedCountry = value;
                countryCtrl.text = value;
                _syncStatesAndCities();
              });
            },
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Select country' : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            isExpanded: true,
            value: _selectedState,
            decoration: InputDecoration(
              labelText: 'State',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: _states
                .where((e) => (e.name ?? '').trim().isNotEmpty)
                .map(
                  (e) => DropdownMenuItem<String>(
                    value: e.name!,
                    child: Text(e.name!),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null || value.trim().isEmpty) return;
              setState(() {
                _selectedState = value;
                stateCtrl.text = value;
                _syncCitiesOnly();
              });
            },
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Select state' : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            isExpanded: true,
            value: _selectedCity,
            decoration: InputDecoration(
              labelText: 'City',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: _cities
                .where((e) => (e.name ?? '').trim().isNotEmpty)
                .map(
                  (e) => DropdownMenuItem<String>(
                    value: e.name!,
                    child: Text(e.name!),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null || value.trim().isEmpty) return;
              setState(() {
                _selectedCity = value;
                cityCtrl.text = value;
              });
            },
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Select city' : null,
          ),
        ],
      ),
    );
  }
}
