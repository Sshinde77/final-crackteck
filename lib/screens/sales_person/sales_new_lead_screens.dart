import 'package:flutter/material.dart';

import '../../constants/api_constants.dart';
import '../../core/secure_storage_service.dart';
import '../../services/api_service.dart';
import '../../widgets/bottom_navigation.dart';

class NewLeadScreen extends StatefulWidget {
  final int roleId;
  final String roleName;

  const NewLeadScreen({Key? key, required this.roleId, required this.roleName})
    : super(key: key);

  @override
  State<NewLeadScreen> createState() => _NewLeadScreenState();
}

class _NewLeadScreenState extends State<NewLeadScreen> {
  static const Color midGreen = Color(0xFF1F8B00);
  // static const Color darkGreen = Color(0xFF145A00);

  bool _moreOpen = false;
  int _navIndex = 0;

  final _formKey = GlobalKey<FormState>();

  // Dropdown values
  String? source;
  String? urgency;
  String? requirementType;
  String? industryType;
  String? leadStatus;
  String? type;

  // Controllers
  final nameCtrl = TextEditingController();
  final companyCtrl = TextEditingController();
  final designationCtrl = TextEditingController();
  final numberCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final budgetCtrl = TextEditingController();

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
        title: const Text(
          'New Leads',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
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
              _input('Full Name', nameCtrl),
              _input('Company Name ( Optional )', companyCtrl),
              _input('Designation ( Optional )', designationCtrl),
              _input(
                'Number',
                numberCtrl,
                prefixIcon: const SizedBox(
                  width: 52,
                  child: Center(
                    child: Text(
                      '+91',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              _input('Email', emailCtrl),
              _input('Address', addressCtrl),
              _input('Budget Range', budgetCtrl),

              _dropdown(
                label: 'Source',
                value: source,
                items: ['Referral', 'Website', 'Walk-in'],
                onChanged: (v) => setState(() => source = v),
              ),

              _dropdown(
                label: 'Urgency',
                value: urgency,
                items: ['Low', 'Medium', 'High'],
                onChanged: (v) => setState(() => urgency = v),
              ),

              _dropdown(
                label: 'Requirement Type',
                value: requirementType,
                items: ['CCTV', 'Networking', 'Biometric'],
                onChanged: (v) => setState(() => requirementType = v),
              ),

              _dropdown(
                label: 'Industry Type',
                value: industryType,
                items: ['Pharma', 'School', 'Manufacturing'],
                onChanged: (v) => setState(() => industryType = v),
              ),

              _dropdown(
                label: 'Lead Status',
                value: leadStatus,
                items: ['Hold', 'Converted', 'Lost'],
                onChanged: (v) => setState(() => leadStatus = v),
              ),

              _dropdown(
                label: 'Type',
                value: type,
                items: ['AMC', 'Non AMC'],
                onChanged: (v) => setState(() => type = v),
              ),

              const SizedBox(height: 12),

              /// UPLOAD PHOTO
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 22),
                decoration: BoxDecoration(
                  border: Border.all(color: midGreen),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: const [
                    Icon(Icons.upload, color: midGreen),
                    SizedBox(height: 6),
                    Text(
                      'Click to upload',
                      style: TextStyle(
                        color: midGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Aadhar Card Image in PNG or JPG (max. 2Mb)',
                      style: TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

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

                      final body = <String, dynamic>{
                        'user_id': userId,
                        'name': nameCtrl.text.trim(),
                        'company_name': companyCtrl.text.trim(),
                        'designation': designationCtrl.text.trim(),
                        'phone': numberCtrl.text.trim(),
                        'email': emailCtrl.text.trim(),
                        'address': addressCtrl.text.trim(),
                        'budget_range': budgetCtrl.text.trim(),
                        'source': source ?? '',
                        'urgency': urgency ?? '',
                        'requirement_type': requirementType ?? '',
                        'industry_type': industryType ?? '',
                        // API uses `status` for lead status; default to "New" if none selected.
                        'status': leadStatus ?? 'New',
                      };

                      final response = await ApiService.post(
                        ApiConstants.new_lead,
                        body,
                        token: accessToken,
                      );

                      String message = 'Lead submitted';
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
                        // Optionally clear form fields after successful submission.
                        nameCtrl.clear();
                        companyCtrl.clear();
                        designationCtrl.clear();
                        numberCtrl.clear();
                        emailCtrl.clear();
                        addressCtrl.clear();
                        budgetCtrl.clear();
                        if (!mounted) return;
                        setState(() {
                          source = null;
                          urgency = null;
                          requirementType = null;
                          industryType = null;
                          leadStatus = null;
                          type = null;
                        });
                      }
                    } catch (e) {
                      if (!mounted) return;
                      messenger.showSnackBar(
                        SnackBar(content: Text('Failed to submit lead: $e')),
                      );
                    }
                  },
                  child: const Text(
                    'Submit',
                    style: TextStyle(
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
        onHome: () {},
        onProfile: () {},
        onMore: () => setState(() => _moreOpen = true),
        onLess: () => setState(() => _moreOpen = false),
        onLeads: () {},
        onFollowUp: () {},
        onMeeting: () {},
        onQuotation: () {},
      ),
    );
  }

  /// TEXT INPUT
  Widget _input(
    String label,
    TextEditingController controller, {
    Widget? prefixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: prefixIcon,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  /// DROPDOWN
  Widget _dropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.keyboard_arrow_down, color: midGreen),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
