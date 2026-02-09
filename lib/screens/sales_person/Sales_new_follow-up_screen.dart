import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../widgets/bottom_navigation.dart';
import '../../model/sales_person/lead_model.dart';
import '../../services/api_service.dart';


class NewFollowUpScreen extends StatefulWidget {
  final int roleId;
  final String roleName;

  const NewFollowUpScreen({
    Key? key,
    required this.roleId,
    required this.roleName,
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
  final dateCtrl = TextEditingController();
  final timeCtrl = TextEditingController();
  final clientNameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final remarksCtrl = TextEditingController();

  // State
  String? statusValue;
  int? selectedLeadId;
  bool leadsLoading = false;
  String? leadLoadError;
  final List<LeadModel> leadOptions = [];

  final List<String> statusOptions = const ["Hold", "Converted", "Lost"];

  // Theme-ish colors similar to your UI
  static const Color midGreen = Color(0xFF1F8B00);
  static const Color darkGreen = Color(0xFF145A00);

  @override
  void initState() {
    super.initState();
    _loadLeadOptions();
  }

  @override
  void dispose() {
    contactCtrl.dispose();
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
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2035, 12, 31),
    );
    if (picked != null) {
      final dd = picked.day.toString().padLeft(2, "0");
      final mm = picked.month.toString().padLeft(2, "0");
      final yyyy = picked.year.toString();
      setState(() => dateCtrl.text = "$dd/$mm/$yyyy");
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => timeCtrl.text = picked.format(context));
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    // Your submit logic here (API call etc.)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Submitted")),
    );
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

  Widget _statusDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label("Status"),
        DropdownButtonFormField<String>(
          value: statusValue,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: darkGreen),
          decoration: _decor(
            "Select",
            suffixIcon: const Padding(
              padding: EdgeInsets.only(right: 6),
              child: Icon(Icons.keyboard_arrow_down_rounded, color: darkGreen),
            ),
          ),
          hint: const Text(
            "Select",
            style: TextStyle(color: Colors.black38, fontSize: 13),
          ),
          items: statusOptions.map((s) {
            return DropdownMenuItem<String>(
              value: s,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  s,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            );
          }).toList(),
          dropdownColor: const Color(0xFFF2F2F2), // grey list like your screenshot
          onChanged: (val) => setState(() => statusValue = val),
          validator: (v) => (v == null || v.isEmpty) ? "Please select status" : null,
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _leadDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label("Lead"),
        DropdownButtonFormField<int>(
          value: selectedLeadId,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: darkGreen),
          decoration: _decor("Select lead"),
          hint: Text(
            leadsLoading ? "Loading leads..." : "Select lead",
            style: const TextStyle(color: Colors.black38, fontSize: 13),
          ),
          items: leadOptions.map((lead) {
            final displayText = '${lead.id} - ${lead.name}'.trim();
            return DropdownMenuItem<int>(
              value: lead.id,
              child: Text(
                displayText,
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
        title: const Text(
          "New Follow-Up",
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
                _leadDropdown(),

                _textField(
                  label: "Contact Number",
                  controller: contactCtrl,
                  hint: "",
                  keyboardType: TextInputType.phone,
                  prefixIcon: const SizedBox(
                    width: 52,
                    child: Center(
                      child: Text(
                        "+91",
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? "Enter contact number" : null,
                ),

                _textField(
                  label: "Date",
                  controller: dateCtrl,
                  readOnly: true,
                  onTap: _pickDate,
                  suffixIcon: const Icon(Icons.calendar_month_outlined, color: Colors.black45),
                  validator: (v) => (v == null || v.trim().isEmpty) ? "Select date" : null,
                ),

                _textField(
                  label: "Time",
                  controller: timeCtrl,
                  readOnly: true,
                  onTap: _pickTime,
                  suffixIcon: const Icon(Icons.access_time_rounded, color: Colors.black45),
                  validator: (v) => (v == null || v.trim().isEmpty) ? "Select time" : null,
                ),

                _statusDropdown(),

                _textField(
                  label: "Client Name",
                  controller: clientNameCtrl,
                  hint: "",
                  validator: (v) => (v == null || v.trim().isEmpty) ? "Enter client name" : null,
                ),

                _textField(
                  label: "Email",
                  controller: emailCtrl,
                  hint: "",
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    final value = (v ?? "").trim();
                    if (value.isEmpty) return "Enter email";
                    // simple email check
                    if (!value.contains("@") || !value.contains(".")) return "Enter valid email";
                    return null;
                  },
                ),

                _textField(
                  label: "Remarks",
                  controller: remarksCtrl,
                  hint: "",
                  maxLines: 2,
                ),

                const SizedBox(height: 14),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "Submit",
                      style: TextStyle(
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
