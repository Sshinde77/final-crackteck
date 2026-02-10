import 'package:flutter/material.dart';

import '../../constants/api_constants.dart';
import '../../core/secure_storage_service.dart';
import '../../model/sales_person/lead_model.dart';
import '../../routes/app_routes.dart';
import '../../services/api_service.dart';
import '../../widgets/bottom_navigation.dart';

class NewMeetingScreen extends StatefulWidget {
  final int roleId;
  final String roleName;
  final int? initialLeadId;
  final String? initialClientLeadName;
  final String? initialMeetingTitle;
  final String? initialMeetingType;
  final String? initialStartDate;
  final String? initialStartTime;
  final String? initialEndTime;
  final String? initialAgenda;
  final String? initialFollowUpTask;
  final String? initialLocation;
  final String? initialStatus;
  final String? initialMeetingNotes;
  final List<String>? initialAttendees;
  final bool lockPrimaryFields;

  const NewMeetingScreen({
    Key? key,
    required this.roleId,
    required this.roleName,
    this.initialLeadId,
    this.initialClientLeadName,
    this.initialMeetingTitle,
    this.initialMeetingType,
    this.initialStartDate,
    this.initialStartTime,
    this.initialEndTime,
    this.initialAgenda,
    this.initialFollowUpTask,
    this.initialLocation,
    this.initialStatus,
    this.initialMeetingNotes,
    this.initialAttendees,
    this.lockPrimaryFields = false,
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
  final startTimeCtrl = TextEditingController();
  final endTimeCtrl = TextEditingController();
  final meetingTitleCtrl = TextEditingController();
  final locationCtrl = TextEditingController();
  final agendaCtrl = TextEditingController();
  final followupTaskCtrl = TextEditingController();
  final meetingNotesCtrl = TextEditingController();
  final attendeeNameCtrl = TextEditingController();

  // Dropdown state
  String? statusValue;
  String? meetingTypeValue;
  int? selectedLeadId;
  bool leadsLoading = false;
  bool submitLoading = false;
  String? leadLoadError;
  DateTime? _selectedMeetingDate;
  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedEndTime;
  final List<String> attendees = <String>[];
  final List<LeadModel> leadOptions = [];
  final List<String> meetingTypeOptions = const [
    "Onsite Demo",
    "Virtual Meeting",
    "Technical Visit",
    "Business Meeting",
    "Other",
  ];
  final Map<String, String> meetingTypeApiValues = const {
    "Onsite Demo": "onsite_demo",
    "Virtual Meeting": "virtual_meeting",
    "Technical Visit": "technical_visit",
    "Business Meeting": "business_meeting",
    "Other": "other",
  };
  final List<String> statusOptions = const [
    "Scheduled",
    "Confirmed",
    "Completed",
    "Cancelled",
    "Rescheduled",
  ];

  static const Color midGreen = Color(0xFF1F8B00);
  static const Color darkGreen = Color(0xFF145A00);

  @override
  void initState() {
    super.initState();
    _applyInitialValues();
    _loadLeadOptions();
  }

  @override
  void dispose() {
    clientNameCtrl.dispose();
    dateCtrl.dispose();
    startTimeCtrl.dispose();
    endTimeCtrl.dispose();
    meetingTitleCtrl.dispose();
    locationCtrl.dispose();
    agendaCtrl.dispose();
    followupTaskCtrl.dispose();
    meetingNotesCtrl.dispose();
    attendeeNameCtrl.dispose();
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

  bool get _isPrimaryLocked => widget.lockPrimaryFields;

  DateTime? _parseDateInput(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return null;

    final iso = DateTime.tryParse(value);
    if (iso != null) return DateTime(iso.year, iso.month, iso.day);

    final slash = value.split('/');
    if (slash.length == 3) {
      final dd = int.tryParse(slash[0]);
      final mm = int.tryParse(slash[1]);
      final yy = int.tryParse(slash[2]);
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

  String _displayDate(DateTime value) {
    final dd = value.day.toString().padLeft(2, "0");
    final mm = value.month.toString().padLeft(2, "0");
    final yyyy = value.year.toString();
    return "$dd/$mm/$yyyy";
  }

  String _displayTime(TimeOfDay value) {
    final hh = value.hour.toString().padLeft(2, '0');
    final mm = value.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  String _meetingTypeLabelFromApi(String? value) {
    const apiToLabel = <String, String>{
      'onsite_demo': 'Onsite Demo',
      'virtual_meeting': 'Virtual Meeting',
      'technical_visit': 'Technical Visit',
      'business_meeting': 'Business Meeting',
      'other': 'Other',
    };
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return '';
    if (apiToLabel.containsKey(raw)) return apiToLabel[raw]!;
    return raw;
  }

  String _statusLabelFromApi(String? value) {
    const apiToLabel = <String, String>{
      'scheduled': 'Scheduled',
      'confirmed': 'Confirmed',
      'completed': 'Completed',
      'cancelled': 'Cancelled',
      'canceled': 'Cancelled',
      'rescheduled': 'Rescheduled',
    };
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return '';
    final lower = raw.toLowerCase();
    if (apiToLabel.containsKey(lower)) return apiToLabel[lower]!;
    return raw;
  }

  void _applyInitialValues() {
    selectedLeadId = widget.initialLeadId;
    clientNameCtrl.text = (widget.initialClientLeadName ?? '').trim();
    meetingTitleCtrl.text = (widget.initialMeetingTitle ?? '').trim();

    final parsedType = _meetingTypeLabelFromApi(widget.initialMeetingType);
    if (parsedType.isNotEmpty && meetingTypeOptions.contains(parsedType)) {
      meetingTypeValue = parsedType;
    }

    final parsedDate = _parseDateInput(widget.initialStartDate);
    if (parsedDate != null) {
      _selectedMeetingDate = parsedDate;
      dateCtrl.text = _displayDate(parsedDate);
    }

    final parsedStart = _parseTimeInput(widget.initialStartTime);
    if (parsedStart != null) {
      _selectedStartTime = parsedStart;
      startTimeCtrl.text = _displayTime(parsedStart);
    }

    final parsedEnd = _parseTimeInput(widget.initialEndTime);
    if (parsedEnd != null) {
      _selectedEndTime = parsedEnd;
      endTimeCtrl.text = _displayTime(parsedEnd);
    }

    agendaCtrl.text = (widget.initialAgenda ?? '').trim();
    followupTaskCtrl.text = (widget.initialFollowUpTask ?? '').trim();
    locationCtrl.text = (widget.initialLocation ?? '').trim();
    meetingNotesCtrl.text = (widget.initialMeetingNotes ?? '').trim();
    final parsedStatus = _statusLabelFromApi(widget.initialStatus);
    if (parsedStatus.isNotEmpty && statusOptions.contains(parsedStatus)) {
      statusValue = parsedStatus;
    }
    attendees
      ..clear()
      ..addAll(
        (widget.initialAttendees ?? const <String>[])
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty),
      );
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
      initialDate: _selectedMeetingDate ?? DateTime.now(),
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2035, 12, 31),
    );
    if (picked != null) {
      final dd = picked.day.toString().padLeft(2, "0");
      final mm = picked.month.toString().padLeft(2, "0");
      final yyyy = picked.year.toString();
      setState(() {
        _selectedMeetingDate = picked;
        dateCtrl.text = "$dd/$mm/$yyyy";
      });
    }
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedStartTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedStartTime = picked;
        startTimeCtrl.text = _displayTime(picked);
      });
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedEndTime ?? _selectedStartTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedEndTime = picked;
        endTimeCtrl.text = _displayTime(picked);
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

  void _addAttendee() {
    final value = attendeeNameCtrl.text.trim();
    if (value.isEmpty) return;
    if (attendees.contains(value)) {
      attendeeNameCtrl.clear();
      return;
    }
    setState(() {
      attendees.add(value);
      attendeeNameCtrl.clear();
    });
  }

  void _removeAttendee(String name) {
    setState(() => attendees.remove(name));
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
    if (selectedLeadId == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Please select lead ID.")),
      );
      return;
    }
    if (_selectedMeetingDate == null || _selectedStartTime == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Please select start date and start time.")),
      );
      return;
    }
    if (meetingNotesCtrl.text.trim().isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Please enter meeting notes.")),
      );
      return;
    }

    final body = <String, dynamic>{
      "user_id": userId,
      "lead_id": selectedLeadId,
      "meet_title": meetingTitleCtrl.text.trim(),
      "meeting_type": meetingTypeApiValues[meetingTypeValue] ?? "other",
      "date": _toApiDate(_selectedMeetingDate!),
      "time": _toApiTime(_selectedStartTime!),
      "location": locationCtrl.text.trim(),
      // Attachment picker is not in this form currently; send empty value.
      "attachment": "",
      "meetAgenda": agendaCtrl.text.trim(),
      "followUp": followupTaskCtrl.text.trim(),
      "status": statusValue,
      "meeting_notes": meetingNotesCtrl.text.trim(),
      "attendees": attendees,
      if (_selectedEndTime != null) "end_time": _toApiTime(_selectedEndTime!),
    };

    setState(() => submitLoading = true);
    try {
      final response = await ApiService.post(
        ApiConstants.new_meet,
        body,
        token: accessToken,
      );

      String message = "Meeting submitted";
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
        SnackBar(content: Text("Failed to submit meeting: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => submitLoading = false);
      }
    }
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

  Widget _dropdownField({
    required String label,
    required String hint,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
    required String validatorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: darkGreen),
          decoration: _decor(
            hint,
            suffixIcon: const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.keyboard_arrow_down_rounded, color: darkGreen),
            ),
          ),
          hint: Text(
            hint,
            style: const TextStyle(color: Colors.black38, fontSize: 13),
          ),
          dropdownColor: const Color(0xFFEFEFEF),
          items: options.map((option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(
                option,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
          validator: (v) => (v == null || v.isEmpty) ? validatorText : null,
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _meetingTypeDropdown() {
    return _dropdownField(
      label: "Meeting Type",
      hint: "Select meeting type",
      value: meetingTypeValue,
      options: meetingTypeOptions,
      onChanged: (v) => setState(() => meetingTypeValue = v),
      validatorText: "Please select meeting type",
    );
  }

  Widget _statusDropdown() {
    return _dropdownField(
      label: "Status",
      hint: "-- Select Status --",
      value: statusValue,
      options: statusOptions,
      onChanged: (v) => setState(() => statusValue = v),
      validatorText: "Please select status",
    );
  }

  Widget _leadDropdown() {
    final items = leadOptions.map((lead) {
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
    }).toList();

    final hasSelected = selectedLeadId != null &&
        items.any((item) => item.value == selectedLeadId);
    if (selectedLeadId != null && !hasSelected) {
      final name = clientNameCtrl.text.trim().isEmpty
          ? "Lead"
          : clientNameCtrl.text.trim();
      items.add(
        DropdownMenuItem<int>(
          value: selectedLeadId,
          child: Text(
            '${selectedLeadId!} - $name',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label("Lead ID *"),
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
          items: items,
          onChanged: (leadsLoading || _isPrimaryLocked) ? null : _onLeadSelected,
          validator: (v) {
            if (_isPrimaryLocked) return null;
            return v == null ? "Please select lead" : null;
          },
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

  Widget _attendeesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label("Attendees"),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: attendeeNameCtrl,
                decoration: _decor("Add attendee name"),
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _addAttendee(),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: _addAttendee,
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Add",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
        if (attendees.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: attendees.map((name) {
              return Chip(
                label: Text(name),
                onDeleted: () => _removeAttendee(name),
                deleteIconColor: Colors.red,
              );
            }).toList(),
          ),
        ],
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
                  label: "Client / Lead Name *",
                  controller: clientNameCtrl,
                  readOnly: _isPrimaryLocked,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? "Enter name" : null,
                ),
                _textField(
                  label: "Meeting Title",
                  controller: meetingTitleCtrl,
                  readOnly: _isPrimaryLocked,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? "Enter meeting title"
                      : null,
                ),
                _textField(
                  label: "Start Date",
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
                  label: "Start Time",
                  controller: startTimeCtrl,
                  readOnly: true,
                  onTap: _pickStartTime,
                  suffixIcon: const Icon(
                    Icons.access_time_rounded,
                    color: Colors.black45,
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? "Select start time" : null,
                ),
                _textField(
                  label: "End Time",
                  controller: endTimeCtrl,
                  readOnly: true,
                  onTap: _pickEndTime,
                  suffixIcon: const Icon(
                    Icons.access_time_rounded,
                    color: Colors.black45,
                  ),
                ),
                _meetingTypeDropdown(),
                _textField(
                  label: "Meeting Agenda *",
                  controller: agendaCtrl,
                  maxLines: 2,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? "Enter meeting agenda"
                      : null,
                ),
                _textField(
                  label: "Follow-up Task *",
                  controller: followupTaskCtrl,
                  maxLines: 2,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? "Enter follow-up task"
                      : null,
                ),
                _textField(
                  label: "Location / Meeting Link",
                  controller: locationCtrl,
                ),
                _statusDropdown(),
                _textField(
                  label: "Meeting Notes *",
                  controller: meetingNotesCtrl,
                  maxLines: 3,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? "Enter meeting notes"
                      : null,
                ),
                _attendeesField(),

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
                    child: submitLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
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
