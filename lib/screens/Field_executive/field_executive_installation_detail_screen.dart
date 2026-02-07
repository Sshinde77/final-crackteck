import 'package:flutter/material.dart';
import '../../model/field executive/field_executive_product_service.dart';
import '../../routes/app_routes.dart';

enum CaseTransferStatus { none, pending }

class FieldExecutiveInstallationDetailScreen extends StatefulWidget {
  final int roleId;
  final String roleName;
  final String title;
  final String serviceId;
  final String location;
  final String priority;
  final String jobType; // 'installations' | 'repairs' | 'amc'

  const FieldExecutiveInstallationDetailScreen({
    super.key,
    required this.roleId,
    required this.roleName,
    required this.title,
    required this.serviceId,
    required this.location,
    required this.priority,
    this.jobType = 'installations',
  });

  @override
  State<FieldExecutiveInstallationDetailScreen> createState() => _FieldExecutiveInstallationDetailScreenState();
}

class _FieldExecutiveInstallationDetailScreenState extends State<FieldExecutiveInstallationDetailScreen> {
  bool isAccepted = false;
  DateTime? selectedDate;
  CaseTransferStatus caseTransferStatus = CaseTransferStatus.none;
  static const primaryGreen = Color(0xFF1E7C10);

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryGreen,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: primaryGreen,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(String title, String desc, String serviceId, String location, String priority) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.desktop_windows, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(fontSize: 12, color: Colors.black54), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(serviceId, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              Text(location, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageThumb(String url) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(url, width: 100, height: 100, fit: BoxFit.cover),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.jobType == 'repairs'
              ? 'Repair service details'
              : widget.jobType == 'amc'
                  ? 'AMC service details'
                  : 'Installation service details',
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                Center(
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Image.network(
                      'https://via.placeholder.com/300x200', // Placeholder for Desktop Image
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Title and Description
                Text(
                  widget.title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.jobType == 'repairs'
                      ? 'Visit charge of Rs 159 waived in final bill; spare part / repair cost extra. Technician will diagnose and provide repair estimate.'
                      : 'Visit charge of Rs 159 waived in final bill; spare part / repair cost extra',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 16),
                const Divider(),

                // Customer Details
                _buildDetailRow('Customer Name', 'Jenny Doe'),
                _buildDetailRow('Customer Number', '+91 **** ** ****'),
                _buildDetailRow(
                  'Schedule',
                  selectedDate == null
                      ? '07 April / 10:00 AM'
                      : '${selectedDate!.day.toString().padLeft(2, '0')} ${_getMonthName(selectedDate!.month)} / 10:00 AM',
                ),
                _buildDetailRow('Service Type', widget.title),
                _buildDetailRow('Service ID', widget.serviceId),
                const Divider(),

                // Product Section with View All
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Product',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.FieldExecutiveAllProductsScreen,
                          arguments: fieldexecutiveallproductsArguments(
                            roleId: widget.roleId,
                            roleName: widget.roleName,
                            controller: FieldExecutiveProductServicesController.withDefaults(),
                          ),
                        );
                      },
                      label: const Text('View all product', style: TextStyle(color: primaryGreen)),
                      icon: const Icon(Icons.arrow_forward, color: primaryGreen, size: 16),
                      iconAlignment: IconAlignment.end,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildProductCard(
                  'Desktop Installation',
                  'Visit charge of Rs 159 waived in final bill; spare part/ repair cost extra',
                  '#LYCFF776567DS',
                  'Kandivali (West)',
                  'High',
                ),
                const SizedBox(height: 16),
                const Divider(),

                // Photo's & Video
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Photo\'s & Video',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    TextButton.icon(
                      onPressed: () {},
                      label: const Text('View All', style: TextStyle(color: primaryGreen)),
                      icon: const Icon(Icons.arrow_forward, color: primaryGreen, size: 16),
                      iconAlignment: IconAlignment.end,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildImageThumb('https://via.placeholder.com/100'),
                      _buildImageThumb('https://via.placeholder.com/100'),
                      _buildImageThumb('https://via.placeholder.com/100'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),

                // Location
                const Text(
                  'Location',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Shop No 5, MPS MART, Mahatma Gandhi Rd, near SVC Co Op Bank, Kandivali, Manek Nagar, Kandivali (W, Mumbai, Maharashtra 400067',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 16),

                // Go to location button (same for all job types)
                if (isAccepted) ...[
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.FieldExecutiveMapTrackingScreen,
                        arguments: fieldexecutivemaptrackingArguments(
                          roleId: widget.roleId,
                          roleName: widget.roleName,
                          serviceId: widget.serviceId,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.near_me_outlined, color: Colors.white),
                    label: const Text('Go to location', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                  const SizedBox(height: 16),
                ],

                // Map Placeholder
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/map_placeholder.jpg', // Placeholder for map
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, -2),
              )
            ],
          ),
          // same accept / reschedule / case-transfer actions for all job types
          child: isAccepted
              ? (
                  // If pending, show only the pending container (no buttons)
                  caseTransferStatus == CaseTransferStatus.pending
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange.shade200),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Case transfer is pending. You will be notified once it is accepted by another executive.',
                                      style: const TextStyle(fontSize: 14, color: Colors.orange),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _selectDate(context),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: selectedDate == null ? Colors.grey.shade100 : primaryGreen,
                                      minimumSize: const Size(double.infinity, 50),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      elevation: 0,
                                    ),
                                    child: Text(
                                      'Rescheduled',
                                      style: TextStyle(
                                        color: selectedDate == null ? primaryGreen : Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      // Navigate to Case Transfer screen and await result
                                      final result = await Navigator.pushNamed(
                                        context,
                                        AppRoutes.FieldExecutiveCaseTransferScreen,
                                        arguments: fieldexecutivecasetransferArguments(
                                          roleId: widget.roleId,
                                          roleName: widget.roleName,
                                        ),
                                      );

                                      // If the case transfer screen returned true, mark as pending
                                      if (result == true) {
                                        setState(() {
                                          caseTransferStatus = CaseTransferStatus.pending;
                                        });
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryGreen,
                                      minimumSize: const Size(double.infinity, 50),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: const Text(
                                      'Case Transfer',
                                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                )
              : ElevatedButton(
                  onPressed: () {
                    setState(() {
                      isAccepted = true;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text(
                    'Accept',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                ),
              ),
            );
  }
}
