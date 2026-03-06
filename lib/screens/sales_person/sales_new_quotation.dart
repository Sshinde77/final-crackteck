import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/secure_storage_service.dart';
import '../../model/sales_person/lead_model.dart';
import '../../routes/app_routes.dart';
import '../../services/api_service.dart';
import '../../widgets/bottom_navigation.dart';

class NewQuotationScreen extends StatefulWidget {
  final int roleId;
  final String roleName;

  const NewQuotationScreen({
    super.key,
    required this.roleId,
    required this.roleName,
  });

  @override
  State<NewQuotationScreen> createState() => _NewQuotationScreenState();
}

class _NewQuotationScreenState extends State<NewQuotationScreen> {
  static const Color midGreen = Color(0xFF1F8B00);
  static const Color darkGreen = Color(0xFF145A00);

  final _formKey = GlobalKey<FormState>();

  bool _moreOpen = false;
  int _navIndex = 0;
  bool _submitting = false;
  bool _showValidationErrors = false;
  bool _leadsLoading = false;
  bool _amcLoading = false;
  String? _leadLoadError;
  String? _amcLoadError;

  int? _selectedLeadId;
  int? _selectedAmcPlanId;
  File? _selectedProductImage;

  final List<LeadModel> _leadOptions = <LeadModel>[];
  final List<Map<String, dynamic>> _amcPlans = <Map<String, dynamic>>[];

  final TextEditingController _quotationDateCtrl = TextEditingController();
  final TextEditingController _expiryDateCtrl = TextEditingController();
  final TextEditingController _productNameCtrl = TextEditingController();
  final TextEditingController _productTypeCtrl = TextEditingController();
  final TextEditingController _modelNoCtrl = TextEditingController();
  final TextEditingController _hsnCtrl = TextEditingController();
  final TextEditingController _purchaseDateCtrl = TextEditingController();
  final TextEditingController _brandCtrl = TextEditingController();
  final TextEditingController _descriptionCtrl = TextEditingController();
  final TextEditingController _skuCtrl = TextEditingController();
  final TextEditingController _quantityCtrl = TextEditingController();
  final TextEditingController _planStartDateCtrl = TextEditingController();
  final TextEditingController _additionalNotesCtrl = TextEditingController();

  DateTime? _quotationDate;
  DateTime? _expiryDate;
  DateTime? _purchaseDate;
  DateTime? _planStartDate;
  String? _priorityLevel;

  static const List<String> _priorityOptions = <String>[
    'low',
    'medium',
    'high',
    'critical',
  ];

  @override
  void initState() {
    super.initState();
    _loadLeadOptions();
    _loadAmcPlans();
  }

  @override
  void dispose() {
    _quotationDateCtrl.dispose();
    _expiryDateCtrl.dispose();
    _productNameCtrl.dispose();
    _productTypeCtrl.dispose();
    _modelNoCtrl.dispose();
    _hsnCtrl.dispose();
    _purchaseDateCtrl.dispose();
    _brandCtrl.dispose();
    _descriptionCtrl.dispose();
    _skuCtrl.dispose();
    _quantityCtrl.dispose();
    _planStartDateCtrl.dispose();
    _additionalNotesCtrl.dispose();
    super.dispose();
  }

  int _asInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  double _asDouble(dynamic value, {double fallback = 0}) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  Map<String, dynamic>? _selectedAmcPlan() {
    for (final plan in _amcPlans) {
      if (_asInt(plan['id']) == _selectedAmcPlanId) {
        return plan;
      }
    }
    return null;
  }

  DateTime _calculatePlanEndDate(DateTime startDate, int durationInMonths) {
    if (durationInMonths <= 0) {
      return startDate;
    }

    final targetMonth = startDate.month + durationInMonths;
    final normalizedYear = startDate.year + ((targetMonth - 1) ~/ 12);
    final normalizedMonth = ((targetMonth - 1) % 12) + 1;
    final firstDayOfFollowingMonth = normalizedMonth == 12
        ? DateTime(normalizedYear + 1, 1, 1)
        : DateTime(normalizedYear, normalizedMonth + 1, 1);
    final lastDayOfTargetMonth =
        firstDayOfFollowingMonth.subtract(const Duration(days: 1)).day;
    final normalizedDay = startDate.day.clamp(1, lastDayOfTargetMonth);

    return DateTime(normalizedYear, normalizedMonth, normalizedDay)
        .subtract(const Duration(days: 1));
  }

  Future<void> _loadLeadOptions() async {
    setState(() {
      _leadsLoading = true;
      _leadLoadError = null;
    });

    try {
      final List<LeadModel> allLeads = <LeadModel>[];
      int page = 1;
      int lastPage = 1;

      do {
        final result = await ApiService.fetchLeads('', widget.roleId, page: page);
        final data = result['data'];
        if (data is List) {
          for (final item in data) {
            if (item is Map<String, dynamic>) {
              allLeads.add(LeadModel.fromJson(item));
            }
          }
        }

        final meta = result['meta'];
        if (meta is Map<String, dynamic>) {
          lastPage = _asInt(meta['last_page'], fallback: page);
        } else {
          lastPage = page;
        }
        page++;
      } while (page <= lastPage);

      if (!mounted) return;
      setState(() {
        _leadOptions
          ..clear()
          ..addAll(allLeads);
        _leadsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _leadsLoading = false;
        _leadLoadError = e.toString();
      });
    }
  }

  Future<void> _loadAmcPlans() async {
    setState(() {
      _amcLoading = true;
      _amcLoadError = null;
    });

    try {
      final plans = await ApiService.fetchAmcPlans();
      if (!mounted) return;
      setState(() {
        _amcPlans
          ..clear()
          ..addAll(plans);
        _amcLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _amcLoading = false;
        _amcLoadError = e.toString();
      });
    }
  }

  String _formatDisplayDate(DateTime value) {
    final dd = value.day.toString().padLeft(2, '0');
    final mm = value.month.toString().padLeft(2, '0');
    final yyyy = value.year.toString();
    return '$dd/$mm/$yyyy';
  }

  String _formatApiDate(DateTime value) {
    final yyyy = value.year.toString().padLeft(4, '0');
    final mm = value.month.toString().padLeft(2, '0');
    final dd = value.day.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd';
  }

  Future<void> _pickDate({
    required TextEditingController controller,
    required ValueChanged<DateTime> onSelected,
    DateTime? initialDate,
  }) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? now,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2035, 12, 31),
    );

    if (picked == null) return;

    controller.text = _formatDisplayDate(picked);
    onSelected(picked);
  }

  Future<void> _pickProductImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    final path = result?.files.single.path;
    if (path == null || path.trim().isEmpty) return;

    setState(() {
      _selectedProductImage = File(path);
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;

    FocusScope.of(context).unfocus();
    debugPrint('Quotation submit tapped');

    final formState = _formKey.currentState;
    if (formState == null) {
      debugPrint('Quotation form state is null');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Form is not ready. Please try again.')),
      );
      return;
    }

    if (!formState.validate()) {
      debugPrint('Quotation form validation failed');
      if (!_showValidationErrors && mounted) {
        setState(() => _showValidationErrors = true);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields.')),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final userId = await SecureStorageService.getUserId();
    if (userId == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Authentication error. Please log in again.')),
      );
      return;
    }

    if (_selectedLeadId == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please select lead ID.')),
      );
      return;
    }

    if (_selectedAmcPlanId == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please select AMC plan.')),
      );
      return;
    }

    if (_quotationDate == null ||
        _expiryDate == null ||
        _purchaseDate == null ||
        _planStartDate == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please select all required dates.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final selectedPlan = _selectedAmcPlan();
      final planDurationMonths = _asInt(selectedPlan?['duration']);
      final planEndDate = _calculatePlanEndDate(_planStartDate!, planDurationMonths);
      final totalAmount = _asDouble(
        selectedPlan?['total_cost'] ?? selectedPlan?['total_amount'],
      );

      final fields = <String, String>{
        'user_id': userId.toString(),
        'lead_id': _selectedLeadId.toString(),
        'quote_date': _formatApiDate(_quotationDate!),
        'expiry_date': _formatApiDate(_expiryDate!),
        'products[0][name]': _productNameCtrl.text.trim(),
        'products[0][product_name]': _productNameCtrl.text.trim(),
        'products[0][type]': _productTypeCtrl.text.trim(),
        'products[0][model_no]': _modelNoCtrl.text.trim(),
        'products[0][hsn]': _hsnCtrl.text.trim(),
        'products[0][hsn_code]': _hsnCtrl.text.trim(),
        'products[0][purchase_date]': _formatApiDate(_purchaseDate!),
        'products[0][brand]': _brandCtrl.text.trim(),
        'products[0][description]': _descriptionCtrl.text.trim(),
        'products[0][sku]': _skuCtrl.text.trim(),
        'products[0][quantity]': _quantityCtrl.text.trim(),
        'amc_plan_id': _selectedAmcPlanId.toString(),
        'plan_start_date': _formatApiDate(_planStartDate!),
        'plan_end_date': _formatApiDate(planEndDate),
        'total_amount': totalAmount.toStringAsFixed(2),
        'priority_level': _priorityLevel ?? '',
        'additional_notes': _additionalNotesCtrl.text.trim(),
      };

      final response = await ApiService.createQuotation(
        fields: fields,
        productImage: _selectedProductImage,
      );

      debugPrint(
        'Quotation submit response: success=${response.success}, message=${response.message}',
      );

      messenger.showSnackBar(
        SnackBar(
          content: Text(response.message ?? 'Quotation submitted'),
        ),
      );

      if (response.success && mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to submit quotation: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.black54,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  InputDecoration _decor(String hint, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.blue, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red, width: 1.6),
      ),
      suffixIcon: suffixIcon,
    );
  }

  Widget _textField({
    required String label,
    required TextEditingController controller,
    String hint = '',
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          decoration: _decor(hint, suffixIcon: suffixIcon),
          validator: validator,
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _leadDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Lead ID'),
        DropdownButtonFormField<int>(
          value: _selectedLeadId,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: darkGreen),
          decoration: _decor('Select lead ID'),
          hint: Text(
            _leadsLoading ? 'Loading lead IDs...' : 'Select lead ID',
            style: const TextStyle(color: Colors.black38, fontSize: 13),
          ),
          items: _leadOptions.map((lead) {
            final leadIdText = lead.leadNumber.trim().isEmpty
                ? lead.id.toString()
                : lead.leadNumber.trim();
            return DropdownMenuItem<int>(
              value: lead.id,
              child: Text(
                leadIdText,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            );
          }).toList(),
          onChanged: _leadsLoading ? null : (value) => setState(() => _selectedLeadId = value),
          validator: (v) => v == null ? 'Please select lead' : null,
        ),
        if (_leadsLoading)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        if (!_leadsLoading && _leadLoadError != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                const Icon(Icons.error_outline, size: 16, color: Colors.red),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Failed to load leads',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(onPressed: _loadLeadOptions, child: const Text('Retry')),
              ],
            ),
          ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _amcPlanDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('AMC Plan'),
        DropdownButtonFormField<int>(
          value: _selectedAmcPlanId,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: darkGreen),
          decoration: _decor('Select AMC plan'),
          hint: Text(
            _amcLoading ? 'Loading AMC plans...' : 'Select AMC plan',
            style: const TextStyle(color: Colors.black38, fontSize: 13),
          ),
          items: _amcPlans.map((plan) {
            final id = _asInt(plan['id']);
            final label = (plan['plan_name'] ?? '').toString().trim();
            return DropdownMenuItem<int>(
              value: id,
              child: Text(
                label.isEmpty ? 'Plan $id' : label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            );
          }).toList(),
          onChanged: _amcLoading ? null : (value) => setState(() => _selectedAmcPlanId = value),
          validator: (v) => v == null ? 'Please select AMC plan' : null,
        ),
        if (_amcLoading)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        if (!_amcLoading && _amcLoadError != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                const Icon(Icons.error_outline, size: 16, color: Colors.red),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Failed to load AMC plans',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(onPressed: _loadAmcPlans, child: const Text('Retry')),
              ],
            ),
          ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _priorityDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Priority Level'),
        DropdownButtonFormField<String>(
          value: _priorityLevel,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: darkGreen),
          decoration: _decor('Select priority'),
          items: _priorityOptions.map((priority) {
            return DropdownMenuItem<String>(
              value: priority,
              child: Text(
                priority,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            );
          }).toList(),
          onChanged: (value) => setState(() => _priorityLevel = value),
          validator: (v) => (v == null || v.trim().isEmpty)
              ? 'Please select priority'
              : null,
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: midGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'New Quotation',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none, color: Colors.white),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
           child: Form(
             key: _formKey,
             autovalidateMode: _showValidationErrors
                 ? AutovalidateMode.onUserInteraction
                 : AutovalidateMode.disabled,
             child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('Quotation Details'),
                _leadDropdown(),
                _textField(
                  label: 'Quotation Date',
                  controller: _quotationDateCtrl,
                  readOnly: true,
                  onTap: () => _pickDate(
                    controller: _quotationDateCtrl,
                    initialDate: _quotationDate,
                    onSelected: (value) => _quotationDate = value,
                  ),
                  suffixIcon: const Icon(Icons.calendar_month_outlined),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Select quotation date' : null,
                ),
                _textField(
                  label: 'Expiry Date',
                  controller: _expiryDateCtrl,
                  readOnly: true,
                  onTap: () => _pickDate(
                    controller: _expiryDateCtrl,
                    initialDate: _expiryDate,
                    onSelected: (value) => _expiryDate = value,
                  ),
                  suffixIcon: const Icon(Icons.calendar_month_outlined),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Select expiry date' : null,
                ),
                const SizedBox(height: 8),
                _sectionTitle('Product Details'),
                _textField(
                  label: 'Product Name',
                  controller: _productNameCtrl,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Enter product name' : null,
                ),
                _textField(
                  label: 'Product Type',
                  controller: _productTypeCtrl,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Enter product type' : null,
                ),
                _textField(
                  label: 'Model No',
                  controller: _modelNoCtrl,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Enter model number' : null,
                ),
                _textField(
                  label: 'HSN',
                  controller: _hsnCtrl,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Enter HSN' : null,
                ),
                _textField(
                  label: 'Purchase Date',
                  controller: _purchaseDateCtrl,
                  readOnly: true,
                  onTap: () => _pickDate(
                    controller: _purchaseDateCtrl,
                    initialDate: _purchaseDate,
                    onSelected: (value) => _purchaseDate = value,
                  ),
                  suffixIcon: const Icon(Icons.calendar_month_outlined),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Select purchase date' : null,
                ),
                _textField(
                  label: 'Brand',
                  controller: _brandCtrl,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Enter brand' : null,
                ),
                _textField(
                  label: 'Description',
                  controller: _descriptionCtrl,
                  maxLines: 3,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Enter description' : null,
                ),
                _textField(
                  label: 'SKU',
                  controller: _skuCtrl,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Enter SKU' : null,
                ),
                _textField(
                  label: 'Quantity',
                  controller: _quantityCtrl,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final value = (v ?? '').trim();
                    if (value.isEmpty) return 'Enter quantity';
                    final qty = int.tryParse(value);
                    if (qty == null || qty <= 0) return 'Enter valid quantity';
                    return null;
                  },
                ),
                _label('Product Image'),
                InkWell(
                  onTap: _pickProductImage,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.upload_file, color: darkGreen),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _selectedProductImage == null
                                ? 'Select product image'
                                : _selectedProductImage!.path.split(Platform.pathSeparator).last,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const SizedBox(height: 8),
                _sectionTitle('AMC Details'),
                _amcPlanDropdown(),
                _textField(
                  label: 'Plan Start Date',
                  controller: _planStartDateCtrl,
                  readOnly: true,
                  onTap: () => _pickDate(
                    controller: _planStartDateCtrl,
                    initialDate: _planStartDate,
                    onSelected: (value) => _planStartDate = value,
                  ),
                  suffixIcon: const Icon(Icons.calendar_month_outlined),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Select plan start date' : null,
                ),
                _priorityDropdown(),
                _textField(
                  label: 'Additional Notes',
                  controller: _additionalNotesCtrl,
                  maxLines: 4,
                ),
                const SizedBox(height: 12),
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
                    onPressed: _submitting ? null : _submit,
                    child: Text(
                      _submitting ? 'Submitting...' : 'Submit',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: CrackteckBottomSwitcher(
        isMoreOpen: _moreOpen,
        currentIndex: _navIndex,
        roleId: widget.roleId,
        roleName: widget.roleName,
        onHome: () {
          Navigator.pushNamed(context, AppRoutes.salespersonDashboard);
        },
        onProfile: () {
          Navigator.pushNamed(context, AppRoutes.salespersonProfile);
        },
        onMore: () => setState(() => _moreOpen = true),
        onLess: () => setState(() => _moreOpen = false),
        onLeads: () {
          Navigator.pushNamed(context, AppRoutes.salespersonLeads);
        },
        onFollowUp: () {
          Navigator.pushNamed(context, AppRoutes.salespersonFollowUp);
        },
        onMeeting: () {
          Navigator.pushNamed(context, AppRoutes.salespersonMeeting);
        },
        onQuotation: () {
          Navigator.pushNamed(context, AppRoutes.salespersonQuotation);
        },
      ),
    );
  }
}
