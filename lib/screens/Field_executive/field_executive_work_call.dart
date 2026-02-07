import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';

class FieldExecutiveWorkCallScreen extends StatefulWidget {
  final int roleId;
  final String roleName;

  const FieldExecutiveWorkCallScreen({
    super.key,
    required this.roleId,
    required this.roleName,
  });

  @override
  State<FieldExecutiveWorkCallScreen> createState() => _FieldExecutiveWorkCallScreenState();
}

class _FieldExecutiveWorkCallScreenState extends State<FieldExecutiveWorkCallScreen> {
  static const Color primaryGreen = Color(0xFF1E7C10);
  int activeTabIndex = 0; // 0: Installations, 1: Repairs, 2: AMC, 3: Quick Service

  final List<Map<String, dynamic>> tabs = [
    {'label': 'Installations', 'icon': Icons.settings_outlined},
    {'label': 'Repairs', 'icon': Icons.build_outlined},
    {'label': 'AMC', 'icon': Icons.print_outlined},
    {'label': 'Quick Service', 'icon': Icons.bolt_outlined},
  ];

  // Mock data for each tab
  final Map<int, List<JobItem>> tabData = {
    0: [
      JobItem(title: 'Desktop Installation', serviceId: '#LYCFF776567DS', location: 'Kandivali (West)', priority: 'High'),
      JobItem(title: 'Office CCTV Installation', serviceId: '#UORD898985DYU', location: 'Malad (East)', priority: 'High'),
      JobItem(title: 'Workstation Installation', serviceId: '#UOHLF756967EH', location: 'Borivali (West)', priority: 'Medium'),
      JobItem(title: 'Security CCTV Installation', serviceId: '#HWDSF776567DS', location: 'Borivali (West)', priority: 'Medium'),
      JobItem(title: 'Desktop Installation', serviceId: '#UOHLF756967EH', location: 'Borivali (West)', priority: 'Low'),
      JobItem(title: 'Laptop Installation', serviceId: '#PJFIF778985DYU', location: 'Borivali (West)', priority: 'Low'),
    ],
    1: [
      JobItem(title: 'Windows laptop repair', serviceId: '#HWDSF776567DS', location: 'Borivali (West)', priority: 'High'),
      JobItem(title: 'Mac laptop repair', serviceId: '#PJFIF778985DYU', location: 'Kandivali (West)', priority: 'High'),
      JobItem(title: 'Windows PC repair', serviceId: '#UOHLF756967EH', location: 'Malad (East)', priority: 'Medium'),
      JobItem(title: 'Mac PC repair', serviceId: '#HWDSF776567DS', location: 'Borivali (West)', priority: 'Medium'),
      JobItem(title: 'Windows softwear repair', serviceId: '#UOHLF756967EH', location: 'Borivali (West)', priority: 'Low'),
      JobItem(title: 'Mac softwear repair', serviceId: '#PJFIF778985DYU', location: 'Borivali (West)', priority: 'Low'),
    ],
    2: [
      JobItem(title: 'Service Check (Windows)', serviceId: '#HWDSF776567DS', location: 'Malad (East)', priority: 'High'),
      JobItem(title: 'Touch Pad (Windows)', serviceId: '#PJFIF778985DYU', location: 'Kandivali (West)', priority: 'High'),
      JobItem(title: 'Windows PC Service', serviceId: '#UOHLF756967EH', location: 'Borivali (West)', priority: 'Medium'),
      JobItem(title: 'Mac PC Service', serviceId: '#HWDSF776567DS', location: 'Borivali (West)', priority: 'Medium'),
      JobItem(title: 'Office CCTV Service', serviceId: '#UOHLF756967EH', location: 'Borivali (West)', priority: 'Low'),
      JobItem(title: 'Service Check (Windows)', serviceId: '#PJFIF778985DYU', location: 'Borivali (West)', priority: 'Low'),
    ],
    3: [
      JobItem(title: 'Quick Keyboard Fix', serviceId: '#QSKB112233AA', location: 'Borivali (West)', priority: 'High'),
      JobItem(title: 'Quick Wi-Fi Setup', serviceId: '#QSWF445566BB', location: 'Malad (East)', priority: 'High'),
      JobItem(title: 'Quick OS Tune-up', serviceId: '#QSOS778899CC', location: 'Kandivali (West)', priority: 'Medium'),
      JobItem(title: 'Quick Driver Update', serviceId: '#QSDR991122DD', location: 'Borivali (West)', priority: 'Medium'),
      JobItem(title: 'Quick Printer Fix', serviceId: '#QSPR334455EE', location: 'Borivali (West)', priority: 'Low'),
      JobItem(title: 'Quick Backup Setup', serviceId: '#QSBU667788FF', location: 'Kandivali (West)', priority: 'Low'),
    ],
  };

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double tabFontSize = screenWidth < 360 ? 11 : screenWidth < 400 ? 12 : 14;
    final double tabIconSize = screenWidth < 360 ? 16 : 20;
    final double tabHorizontalPadding = screenWidth < 360 ? 8 : 12;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Work Call',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
          // Custom Tab Bar
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(tabs.length, (index) {
                  final bool isActive = activeTabIndex == index;
                  return Padding(
                    padding: EdgeInsets.only(left: index == 0 ? 16 : 8, right: index == tabs.length - 1 ? 16 : 0),
                    child: GestureDetector(
                      onTap: () => setState(() => activeTabIndex = index),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: tabHorizontalPadding, vertical: 8),
                        constraints: const BoxConstraints(minWidth: 0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isActive ? Colors.grey.shade300 : Colors.transparent),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              tabs[index]['icon'],
                              size: tabIconSize,
                              color: isActive ? Colors.blue : Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                tabs[index]['label'],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: tabFontSize,
                                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                  color: isActive ? Colors.black : Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),

          // List of Jobs
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: tabData[activeTabIndex]!.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final job = tabData[activeTabIndex]![index];
                return _JobCard(
                  job: job,
                  roleId: widget.roleId,
                  roleName: widget.roleName,
                  activeTabIndex: activeTabIndex,
                );
              },
            ),
          ),
          ],
        ),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final JobItem job;
  final int roleId;
  final String roleName;
  final int activeTabIndex;

  const _JobCard({
    required this.job,
    required this.roleId,
    required this.roleName,
    required this.activeTabIndex,
  });

  @override
  Widget build(BuildContext context) {
    Color priorityColor;
    switch (job.priority.toLowerCase()) {
      case 'high':
        priorityColor = Colors.red;
        break;
      case 'medium':
        priorityColor = Colors.orange;
        break;
      case 'low':
        priorityColor = Colors.blue;
        break;
      default:
        priorityColor = Colors.grey;
    }

    return InkWell(
      onTap: () {
        // Determine job type string based on activeTabIndex
        final jobType = activeTabIndex == 0
            ? 'installations'
            : activeTabIndex == 1
                ? 'repairs'
                : activeTabIndex == 2
                    ? 'amc'
                    : 'quick_service';

        Navigator.pushNamed(
          context,
          AppRoutes.FieldExecutiveInstallationDetailScreen,
          arguments: fieldexecutiveinstallationdetailArguments(
            roleId: roleId,
            roleName: roleName,
            title: job.title,
            serviceId: job.serviceId,
            location: job.location,
            priority: job.priority,
            jobType: jobType,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Stack(
          children: [
            // Priority Badge
            Positioned(
              top: 0,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4)),
                ),
                child: Text(
                  job.priority,
                  style: TextStyle(color: priorityColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image Placeholder
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.desktop_windows_outlined, color: Colors.grey), // Simplified icon for now
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.title,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Visit charge of Rs 159 waived in final bill; spare part/ repair cost extra',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text('Service ID: ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Text(job.serviceId, style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Row(
                          children: [
                            const Text('Location: ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Text(job.location, style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class JobItem {
  final String title;
  final String serviceId;
  final String location;
  final String priority;

  JobItem({
    required this.title,
    required this.serviceId,
    required this.location,
    required this.priority,
  });
}
