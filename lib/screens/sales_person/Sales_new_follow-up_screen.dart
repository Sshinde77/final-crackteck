import 'package:flutter/material.dart';

import '../../constants/api_constants.dart';
import '../../core/secure_storage_service.dart';
import '../../routes/app_routes.dart';
import '../../widgets/bottom_navigation.dart';
import '../../model/sales_person/lead_model.dart';
import '../../services/api_service.dart';


class NewFollowUpScreen extends StatefulWidget {
  final int roleId;
  final String roleName;
  final bool isEdit;
  final String? followUpId;
  final int? initialLeadId;
  final String? initialLeadIdDisplay;
  final String? initialClientName;
  final String? initialPhone;
  final String? initialEmail;
  final String? initialFollowUpDate;
  final String? initialFollowUpTime;
  final String? initialRemarks;
  final String? initialFollowUpStatus;

  const NewFollowUpScreen({
    Key? key,
    required this.roleId,
    required this.roleName,
    this.isEdit = false,
    this.followUpId,
    this.initialLeadId,
    this.initialLeadIdDisplay,
    this.initialClientName,
    this.initialPhone,
    this.initialEmail,
    this.initialFollowUpDate,
    this.initialFollowUpTime,
    this.initialRemarks,
    this.initialFollowUpStatus,
  }) : super(key: key);
  @override
  State<NewFollowUpScreen> createState() => _NewFollowUpScreenState();
}

class _NewFollowUpScreenState extends State<NewFollowUpScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _moreOpen = false;
  int _navIndex = 0;

  // Controllers
  final contactCtrl = TextEditingController();
  final leadIdCtrl = TextEditingController();
  final dateCtrl = TextEditingController();
  final timeCtrl = TextEditingController();
  final clientNameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final remarksCtrl = TextEditingController();

  // State
  int? selectedLeadId;
  bool leadsLoading = false;
  bool submitLoading = false;
  String? leadLoadError;
  final List<LeadModel> leadOptions = [];

  DateTime? _selectedFollowUpDate;
  TimeOfDay? _selectedFollowUpTime;

  // Theme-ish colors similar to your UI
  static const Color midGreen = Color(0xFF1F8B00);
  static const Color darkGreen = Color(0xFF145A00);

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _applyInitialEditValues();
      if (selectedLeadId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _onLeadSelected(selectedLeadId);
        });
      }
    } else {
      _loadLeadOptions();
    }
  }

  @override
  void dispose() {
    contactCtrl.dispose();
    leadIdCtrl.dispose();
    dateCtrl.dispose();
    timeCtrl.dispose();
    clientNameCtrl.dispose();
    emailCtrl.dispose();
    remarksCtrl.dispose();
    super.dispose();
  }

  int _asInt(dynamic value, {int fallback = 1}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }
    return fallback;
  }

  bool get _isEditMode => widget.isEdit;

  String _displayDate(DateTime value) {
    final dd = value.day.toString().padLeft(2, "0");
    final mm = value.month.toString().padLeft(2, "0");
    final yyyy = value.year.toString();
    return "$dd/$mm/$yyyy";
  }

  DateTime? _parseDateInput(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return null;

    final isoParsed = DateTime.tryParse(value);
    if (isoParsed != null) return isoParsed;

    final parts = value.split('/');
    if (parts.length == 3) {
      final dd = int.tryParse(parts[0]);
      final mm = int.tryParse(parts[1]);
      final yy = int.tryParse(parts[2]);
      if (dd != null && mm != null && yy != null) {
        return DateTime(yy, mm, dd);
      }
    }
    return null;
  }

  TimeOfDay? _parseTimeInput(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return null;

    final match = RegExp(r'^(\d{1,2}):(\d{2})(?::\d{2})?$').firstMatch(value);
    if (match != null) {
      final hh = int.tryParse(match.group(1)!);
      final mm = int.tryParse(match.group(2)!);
      if (hh != null &&
          mm != null &&
          hh >= 0 &&
          hh <= 23 &&
          mm >= 0 &&
          mm <= 59) {
        return TimeOfDay(hour: hh, minute: mm);
      }
    }
    return null;
  }

  String _displayTime(TimeOfDay value) {
    final hh = value.hour.toString().padLeft(2, '0');
    final mm = value.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  void _applyInitialEditValues() {
    selectedLeadId = widget.initialLeadId;
    leadIdCtrl.text =
        (widget.initialLeadIdDisplay ?? widget.initialLeadId?.toString() ?? '')
            .trim();
    clientNameCtrl.text = (widget.initialClientName ?? '').trim();
    contactCtrl.text = _sanitizePhone(widget.initialPhone ?? '');
    emailCtrl.text = (widget.initialEmail ?? '').trim();
    remarksCtrl.text = (widget.initialRemarks ?? '').trim();

    final parsedDate = _parseDateInput(widget.initialFollowUpDate);
    if (parsedDate != null) {
      _selectedFollowUpDate = parsedDate;
      dateCtrl.text = _displayDate(parsedDate);
    }

    final parsedTime = _parseTimeInput(widget.initialFollowUpTime);
    if (parsedTime != null) {
      _selectedFollowUpTime = parsedTime;
      timeCtrl.text = _displayTime(parsedTime);
    }
  }

  Future<void> _loadLeadOptions() async {
    setState(() {
      leadsLoading = true;
      leadLoadError = null;
    });

    try {
      final List<LeadModel> allLeads = [];
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
        leadOptions
          ..clear()
          ..addAll(allLeads);
        leadsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        leadsLoading = false;
        leadLoadError = e.toString();
      });
    }
  }

  Future<void> _onLeadSelected(int? leadId) async {
    setState(() => selectedLeadId = leadId);
    if (leadId == null) {
      contactCtrl.clear();
      clientNameCtrl.clear();
      emailCtrl.clear();
      return;
    }

    final localLead = leadOptions.where((lead) => lead.id == leadId).toList();
    if (localLead.isNotEmpty) {
      final lead = localLead.first;
      clientNameCtrl.text = lead.name;
      emailCtrl.text = lead.email;
      contactCtrl.text = _sanitizePhone(lead.phone);
    }

    try {
      final leadDetail = await ApiService.fetchLeadDetail(
        leadId.toString(),
        roleId: widget.roleId,
      );
      if (!mounted || selectedLeadId != leadId) return;

      final detailMap = _extractLeadMap(leadDetail);
      if (detailMap == null) return;

      final detailLead = LeadModel.fromJson(detailMap);
      clientNameCtrl.text = detailLead.name;
      emailCtrl.text = detailLead.email;
      contactCtrl.text = _sanitizePhone(detailLead.phone);
    } catch (_) {
      // Keep already-filled local lead values if detail API fails.
    }
  }

  Map<String, dynamic>? _extractLeadMap(Map<String, dynamic> payload) {
    final data = payload['data'];
    if (data is Map<String, dynamic>) return data;

    final lead = payload['lead'];
    if (lead is Map<String, dynamic>) return lead;

    if (payload.containsKey('id')) return payload;
    return null;
  }

  String _sanitizePhone(String value) {
    return value
        .replaceAll('+91', '')
        .replaceAll('+', '')
        .trim();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedFollowUpDate ?? now,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2035, 12, 31),
    );
    if (picked != null) {
      final dd = picked.day.toString().padLeft(2, "0");
      final mm = picked.month.toString().padLeft(2, "0");
      final yyyy = picked.year.toString();
      setState(() {
        _selectedFollowUpDate = picked;
        dateCtrl.text = "$dd/$mm/$yyyy";
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedFollowUpTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedFollowUpTime = picked;
        timeCtrl.text = _displayTime(picked);
      });
    }
  }

  String _toApiDate(DateTime value) {
    final yyyy = value.year.toString().padLeft(4, '0');
    final mm = value.month.toString().padLeft(2, '0');
    final dd = value.day.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd';
  }

  String _toApiTime(TimeOfDay value) {
    final hh = value.hour.toString().padLeft(2, '0');
    final mm = value.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (submitLoading) return;

    final messenger = ScaffoldMessenger.of(context);
    final userId = await SecureStorageService.getUserId();
    final accessToken = await SecureStorageService.getAccessToken();

    if (userId == null || accessToken == null || accessToken.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Authentication error. Please log in again.")),
      );
      return;
    }

    if (_selectedFollowUpDate == null || _selectedFollowUpTime == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Please select follow-up date and time.")),
      );
      return;
    }
    if (selectedLeadId == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Lead ID is missing.")),
      );
      return;
    }

    setState(() => submitLoading = true);
    try {
      final endpoint = _isEditMode
          ? Uri.parse(
              ApiConstants.edit_follow_up.replaceFirst(
                '{follow_up_id}',
                widget.followUpId ?? '',
              ),
            ).replace(
              queryParameters: {'user_id': userId.toString()},
            )
          : Uri.parse(ApiConstants.new_follow_up).replace(
              queryParameters: {'user_id': userId.toString()},
            );

      if (_isEditMode && (widget.followUpId == null || widget.followUpId!.trim().isEmpty)) {
        messenger.showSnackBar(
          const SnackBar(content: Text("Follow-up ID is missing for edit.")),
        );
        return;
      }

      final body = <String, dynamic>{
        'user_id': userId,
        'lead_id': selectedLeadId,
        'followup_date': _toApiDate(_selectedFollowUpDate!),
        'followup_time': _toApiTime(_selectedFollowUpTime!),
        'remarks': remarksCtrl.text.trim(),
        'status': 'pending',
      };

      final response = _isEditMode
          ? await ApiService.put(
              endpoint.toString(),
              body,
              token: accessToken,
            )
          : await ApiService.post(
              endpoint.toString(),
              body,
              token: accessToken,
            );

      String message = _isEditMode
          ? "Follow-up updated successfully"
          : "Follow-up submitted";
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

      if (success && mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text("Failed to submit follow-up: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => submitLoading = false);
      }
    }
  }

  InputDecoration _decor(String hint, {Widget? suffixIcon, Widget? prefixIcon}) {
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
      prefixIcon: prefixIcon,
      prefixIconConstraints: const BoxConstraints(minWidth: 52),
      suffixIcon: suffixIcon,
    );
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

  Widget _textField({
    required String label,
    required TextEditingController controller,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
    Widget? prefixIcon,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          maxLines: maxLines,
          decoration: _decor(hint ?? "", suffixIcon: suffixIcon, prefixIcon: prefixIcon),
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
        _label("Lead ID"),
        DropdownButtonFormField<int>(
          value: selectedLeadId,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: darkGreen),
          decoration: _decor("Select lead ID"),
          hint: Text(
            leadsLoading ? "Loading lead IDs..." : "Select lead ID",
            style: const TextStyle(color: Colors.black38, fontSize: 13),
          ),
          items: leadOptions.map((lead) {
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
          onChanged: leadsLoading ? null : _onLeadSelected,
          validator: (v) => v == null ? "Please select lead" : null,
        ),
        if (leadsLoading)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        if (!leadsLoading && leadLoadError != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                const Icon(Icons.error_outline, size: 16, color: Colors.red),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "Failed to load leads",
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _loadLeadOptions,
                  child: const Text("Retry"),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 70,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [midGreen, darkGreen],
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditMode ? "Edit Follow-Up" : "New Follow-Up",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            onPressed: (){
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

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                if (_isEditMode)
                  _textField(
                    label: "Lead ID",
                    controller: leadIdCtrl,
                    readOnly: true,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? "Lead ID missing" : null,
                  )
                else
                  _leadDropdown(),

                _textField(
                  label: "Client Name",
                  controller: clientNameCtrl,
                  hint: "",
                  readOnly: true,
                  validator: (v) => (v == null || v.trim().isEmpty) ? "Select lead ID first" : null,
                ),

                _textField(
                  label: "Contact Number",
                  controller: contactCtrl,
                  hint: "",
                  keyboardType: TextInputType.phone,
                  readOnly: true,
                  prefixIcon: const SizedBox(
                    width: 52,
                    child: Center(
                      child: Text(
                        "+91",
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? "Select lead ID first" : null,
                ),

                _textField(
                  label: "Email ID",
                  controller: emailCtrl,
                  hint: "",
                  keyboardType: TextInputType.emailAddress,
                  readOnly: true,
                  validator: (v) {
                    final value = (v ?? "").trim();
                    if (value.isEmpty) return "Select lead ID first";
                    if (!value.contains("@") || !value.contains(".")) return "Invalid email in lead data";
                    return null;
                  },
                ),

                _textField(
                  label: "Follow Up Date",
                  controller: dateCtrl,
                  readOnly: true,
                  onTap: _pickDate,
                  suffixIcon: const Icon(Icons.calendar_month_outlined, color: Colors.black45),
                  validator: (v) => (v == null || v.trim().isEmpty) ? "Select date" : null,
                ),

                _textField(
                  label: "Follow Up Time",
                  controller: timeCtrl,
                  readOnly: true,
                  onTap: _pickTime,
                  suffixIcon: const Icon(Icons.access_time_rounded, color: Colors.black45),
                  validator: (v) => (v == null || v.trim().isEmpty) ? "Select time" : null,
                ),

                _textField(
                  label: "Remark",
                  controller: remarksCtrl,
                  hint: "",
                  maxLines: 2,
                ),

                const SizedBox(height: 14),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: submitLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      submitLoading
                          ? "Submitting..."
                          : (_isEditMode ? "Update" : "Submit"),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
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
