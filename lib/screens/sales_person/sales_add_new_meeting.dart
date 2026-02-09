import 'package:flutter/material.dart';

import '../../model/sales_person/lead_model.dart';
import '../../routes/app_routes.dart';
import '../../services/api_service.dart';
import '../../widgets/bottom_navigation.dart';

class NewMeetingScreen extends StatefulWidget {
  final int roleId;
  final String roleName;

  const NewMeetingScreen({
    Key? key,
    required this.roleId,
    required this.roleName,
  }) : super(key: key);

  @override
  State<NewMeetingScreen> createState() => _NewMeetingScreenState();
}

class _NewMeetingScreenState extends State<NewMeetingScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _moreOpen = false;
  int _navIndex = 0;

  // Controllers
  final clientNameCtrl = TextEditingController();
  final dateCtrl = TextEditingController();
  final timeCtrl = TextEditingController();
  final meetingTitleCtrl = TextEditingController();
  final meetingTypeCtrl = TextEditingController();
  final locationCtrl = TextEditingController();
  final agendaCtrl = TextEditingController();
  final followupTaskCtrl = TextEditingController();

  // Dropdown state
  String? statusValue;
  int? selectedLeadId;
  bool leadsLoading = false;
  String? leadLoadError;
  final List<LeadModel> leadOptions = [];
  final List<String> statusOptions = const ["Hold", "Converted", "Lost"];

  // Attachment UI state (UI-only here)
  String? attachmentName;

  static const Color midGreen = Color(0xFF1F8B00);
  static const Color darkGreen = Color(0xFF145A00);

  @override
  void initState() {
    super.initState();
    _loadLeadOptions();
  }

  @override
  void dispose() {
    clientNameCtrl.dispose();
    dateCtrl.dispose();
    timeCtrl.dispose();
    meetingTitleCtrl.dispose();
    meetingTypeCtrl.dispose();
    locationCtrl.dispose();
    agendaCtrl.dispose();
    followupTaskCtrl.dispose();
    super.dispose();
  }

  int _asInt(dynamic value, {int fallback = 1}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  Map<String, dynamic>? _extractLeadMap(Map<String, dynamic> payload) {
    final data = payload['data'];
    if (data is Map<String, dynamic>) return data;

    final lead = payload['lead'];
    if (lead is Map<String, dynamic>) return lead;

    if (payload.containsKey('id')) return payload;
    return null;
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
      clientNameCtrl.clear();
      return;
    }

    final localLead = leadOptions.where((lead) => lead.id == leadId).toList();
    if (localLead.isNotEmpty) {
      clientNameCtrl.text = localLead.first.name;
    }

    try {
      final detail = await ApiService.fetchLeadDetail(
        leadId.toString(),
        roleId: widget.roleId,
      );
      if (!mounted || selectedLeadId != leadId) return;

      final detailMap = _extractLeadMap(detail);
      if (detailMap == null) return;

      final detailLead = LeadModel.fromJson(detailMap);
      clientNameCtrl.text = detailLead.name;
    } catch (_) {
      // Keep locally selected lead values if detail call fails.
    }
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

  void _fakePickAttachment() {
    // UI only — replace with FilePicker later if needed.
    setState(() => attachmentName = "meeting_attachment.png");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Attachment selected (UI only)")),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Meeting Submitted")));
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
    String hint = "",
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: _decor(hint, suffixIcon: suffixIcon),
          validator: validator,
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _statusDropdown() {
    // Grey dropdown menu + items like screenshot
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label("Status"),
        DropdownButtonFormField<String>(
          value: statusValue,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: darkGreen,
          ), // we use custom suffix icon
          decoration: _decor(
            "Select",
            suffixIcon: const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.keyboard_arrow_down_rounded, color: darkGreen),
            ),
          ),
          hint: const Text(
            "Select",
            style: TextStyle(color: Colors.black38, fontSize: 13),
          ),
          dropdownColor: const Color(0xFFEFEFEF),
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
          onChanged: (v) => setState(() => statusValue = v),
          validator: (v) =>
              (v == null || v.isEmpty) ? "Please select status" : null,
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
          decoration: _decor(
            "Select lead",
            suffixIcon: const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.keyboard_arrow_down_rounded, color: darkGreen),
            ),
          ),
          hint: Text(
            leadsLoading ? "Loading leads..." : "Select lead",
            style: const TextStyle(color: Colors.black38, fontSize: 13),
          ),
          dropdownColor: const Color(0xFFEFEFEF),
          items: leadOptions.map((lead) {
            return DropdownMenuItem<int>(
              value: lead.id,
              child: Text(
                '${lead.id} - ${lead.name}',
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
                TextButton(onPressed: _loadLeadOptions, child: const Text("Retry")),
              ],
            ),
          ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _attachmentsBox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label("Attachments"),
        InkWell(
          onTap: _fakePickAttachment,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: darkGreen, width: 1.2),
                  ),
                  child: const Icon(
                    Icons.upload_file,
                    color: darkGreen,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Click to upload",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "PNG or JPG (max. 2MB)",
                  style: TextStyle(fontSize: 10, color: Colors.black45),
                ),
                if (attachmentName != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    attachmentName!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
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
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "New Meeting",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              // open notification screen if you have it
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
                  label: "Client / Lead Name",
                  controller: clientNameCtrl,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? "Enter name" : null,
                ),
                _textField(
                  label: "Date",
                  controller: dateCtrl,
                  readOnly: true,
                  onTap: _pickDate,
                  suffixIcon: const Icon(
                    Icons.calendar_month_outlined,
                    color: Colors.black45,
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? "Select date" : null,
                ),
                _textField(
                  label: "Time",
                  controller: timeCtrl,
                  readOnly: true,
                  onTap: _pickTime,
                  suffixIcon: const Icon(
                    Icons.access_time_rounded,
                    color: Colors.black45,
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? "Select time" : null,
                ),

                _statusDropdown(),

                _textField(
                  label: "Meeting Title",
                  controller: meetingTitleCtrl,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? "Enter meeting title"
                      : null,
                ),
                _textField(
                  label: "Meeting Type",
                  controller: meetingTypeCtrl,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? "Enter meeting type"
                      : null,
                ),
                _textField(
                  label: "Location / Meeting Link",
                  controller: locationCtrl,
                ),
                _textField(
                  label: "Meeting Agenda / Notes",
                  controller: agendaCtrl,
                  maxLines: 2,
                ),
                _textField(
                  label: "Follow-up Task",
                  controller: followupTaskCtrl,
                  maxLines: 2,
                ),

                _attachmentsBox(),

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
}
