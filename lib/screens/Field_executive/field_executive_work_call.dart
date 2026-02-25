import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../services/api_service.dart';

class FieldExecutiveWorkCallScreen extends StatefulWidget {
  final int roleId;
  final String roleName;

  const FieldExecutiveWorkCallScreen({
    super.key,
    required this.roleId,
    required this.roleName,
  });

  @override
  State<FieldExecutiveWorkCallScreen> createState() =>
      _FieldExecutiveWorkCallScreenState();
}

class _FieldExecutiveWorkCallScreenState
    extends State<FieldExecutiveWorkCallScreen> {
  static const Color primaryGreen = Color(0xFF1E7C10);

  final List<_WorkCallTabConfig> tabs = const [
    _WorkCallTabConfig(
      label: 'Installations',
      icon: Icons.settings_outlined,
      tab: JobTab.installations,
    ),
    _WorkCallTabConfig(
      label: 'Repairs',
      icon: Icons.build_outlined,
      tab: JobTab.repairs,
    ),
    _WorkCallTabConfig(
      label: 'AMC',
      icon: Icons.print_outlined,
      tab: JobTab.amc,
    ),
    _WorkCallTabConfig(
      label: 'Quick Service',
      icon: Icons.bolt_outlined,
      tab: JobTab.quickService,
    ),
  ];

  int activeTabIndex = 0;
  List<JobItem> _jobs = <JobItem>[];
  bool _jobsLoading = true;
  String? _jobsError;

  @override
  void initState() {
    super.initState();
    _loadServiceRequests();
  }

  Future<void> _loadServiceRequests() async {
    setState(() {
      _jobsLoading = true;
      _jobsError = null;
    });

    try {
      final list = await ApiService.fetchServiceRequests(roleId: widget.roleId);
      if (!mounted) return;
      setState(() {
        _jobs = list.map(JobItem.fromApi).toList();
        _jobsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _jobsLoading = false;
        _jobsError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double tabFontSize = screenWidth < 360
        ? 11
        : screenWidth < 400
            ? 12
            : 14;
    final double tabIconSize = screenWidth < 360 ? 16 : 20;
    final double tabHorizontalPadding = screenWidth < 360 ? 8 : 12;

    final activeTab = tabs[activeTabIndex].tab;
    final visibleJobs = _jobs.where((job) => job.tab == activeTab).toList();

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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(tabs.length, (index) {
                    final bool isActive = activeTabIndex == index;
                    return Padding(
                      padding: EdgeInsets.only(
                        left: index == 0 ? 16 : 8,
                        right: index == tabs.length - 1 ? 16 : 0,
                      ),
                      child: GestureDetector(
                        onTap: () => setState(() => activeTabIndex = index),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: tabHorizontalPadding,
                            vertical: 8,
                          ),
                          constraints: const BoxConstraints(minWidth: 0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isActive
                                  ? Colors.grey.shade300
                                  : Colors.transparent,
                            ),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                tabs[index].icon,
                                size: tabIconSize,
                                color: isActive ? Colors.blue : Colors.grey,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  tabs[index].label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: tabFontSize,
                                    fontWeight: isActive
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isActive
                                        ? Colors.black
                                        : Colors.grey,
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
            Expanded(
              child: _jobsLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _jobsError != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Failed to load service requests',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.red,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _jobsError!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextButton(
                                  onPressed: _loadServiceRequests,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : visibleJobs.isEmpty
                          ? const Center(
                              child: Text(
                                'No service requests found',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              itemCount: visibleJobs.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final job = visibleJobs[index];
                                return _JobCard(
                                  job: job,
                                  roleId: widget.roleId,
                                  roleName: widget.roleName,
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

  const _JobCard({
    required this.job,
    required this.roleId,
    required this.roleName,
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
        Navigator.pushNamed(
          context,
          AppRoutes.FieldExecutiveInstallationDetailScreen,
          arguments: fieldexecutiveinstallationdetailArguments(
            roleId: roleId,
            roleName: roleName,
            title: job.title,
            serviceId: job.detailServiceId,
            location: job.location,
            priority: job.priority,
            jobType: job.jobType,
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
            Positioned(
              top: 0,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(4),
                  ),
                ),
                child: Text(
                  job.priority,
                  style: TextStyle(
                    color: priorityColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: job.imageUrl.isEmpty
                        ? const Icon(
                            Icons.desktop_windows_outlined,
                            color: Colors.grey,
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              job.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.desktop_windows_outlined,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          job.description,
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text(
                              'Service ID: ',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            Expanded(
                              child: Text(
                                job.serviceId,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Text(
                              'Location: ',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            Expanded(
                              child: Text(
                                job.location,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
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

class _WorkCallTabConfig {
  final String label;
  final IconData icon;
  final JobTab tab;

  const _WorkCallTabConfig({
    required this.label,
    required this.icon,
    required this.tab,
  });
}

enum JobTab { installations, repairs, amc, quickService }

class JobItem {
  final int? id;
  final String requestId;
  final String title;
  final String description;
  final String serviceId;
  final String location;
  final String priority;
  final JobTab tab;
  final String imageUrl;

  JobItem({
    required this.id,
    required this.requestId,
    required this.title,
    required this.description,
    required this.serviceId,
    required this.location,
    required this.priority,
    required this.tab,
    required this.imageUrl,
  });

  String get detailServiceId {
    if (id != null) return id!.toString();
    final normalized = requestId.trim().replaceFirst(RegExp(r'^#'), '');
    return normalized.isEmpty
        ? serviceId.replaceFirst(RegExp(r'^#'), '')
        : normalized;
  }

  String get jobType {
    switch (tab) {
      case JobTab.installations:
        return 'installations';
      case JobTab.repairs:
        return 'repairs';
      case JobTab.amc:
        return 'amc';
      case JobTab.quickService:
        return 'quick_service';
    }
  }

  factory JobItem.fromApi(Map<String, dynamic> json) {
    String readStr(List<String> keys, {String fallback = ''}) {
      for (final key in keys) {
        final value = json[key];
        if (value == null) continue;
        final str = value.toString().trim();
        if (str.isNotEmpty) return str;
      }
      return fallback;
    }

    int? readInt(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value == null) continue;
        if (value is int) return value;
        if (value is num) return value.toInt();
        final parsed = int.tryParse(value.toString().trim());
        if (parsed != null) return parsed;
      }
      return null;
    }

    final title = readStr(
      const ['title', 'service_name', 'service_title', 'name', 'issue', 'problem'],
      fallback: 'Service Request',
    );

    final description = readStr(
      const ['description', 'details', 'notes', 'remark', 'remarks'],
      fallback: 'Visit charge of Rs 159 waived in final bill; spare part/ repair cost extra',
    );

    final location = readStr(
      const ['location', 'address', 'city', 'area'],
      fallback: '-',
    );

    final id = readInt(const ['id', 'service_request_id']);

    final requestId = readStr(
      const ['request_id', 'requestId', 'service_id', 'serviceId', 'ticket_no'],
      fallback: '',
    );
    final serviceIdSource = requestId.isNotEmpty ? requestId : (id?.toString() ?? '-');
    final serviceId = serviceIdSource == '-' || serviceIdSource.isEmpty
        ? '-'
        : (serviceIdSource.startsWith('#') ? serviceIdSource : '#$serviceIdSource');

    final priority = readStr(
      const ['priority', 'priority_level', 'urgency'],
      fallback: 'Medium',
    );

    final tab = _tabFromServiceType(readStr(const ['service_type']));

    final imageUrl = readStr(
      const ['image_url', 'image', 'service_image', 'product_image'],
      fallback: '',
    );

    return JobItem(
      id: id,
      requestId: requestId,
      title: title,
      description: description,
      serviceId: serviceId,
      location: location,
      priority: _normalizePriority(priority),
      tab: tab,
      imageUrl: imageUrl,
    );
  }

  static String _normalizePriority(String raw) {
    final value = raw.trim().toLowerCase();
    if (value.contains('high') || value == '1' || value == 'urgent') {
      return 'High';
    }
    if (value.contains('low') || value == '3') {
      return 'Low';
    }
    return 'Medium';
  }

  static JobTab _tabFromServiceType(String rawServiceType) {
    final serviceType = rawServiceType.trim().toLowerCase();

    if (serviceType == '1') return JobTab.installations;
    if (serviceType == '2') return JobTab.repairs;
    if (serviceType == '3') return JobTab.amc;
    if (serviceType == '4') return JobTab.quickService;

    if (serviceType == 'installation' || serviceType == 'installations') {
      return JobTab.installations;
    }
    if (serviceType == 'repair' || serviceType == 'repairs') {
      return JobTab.repairs;
    }
    if (serviceType == 'amc') {
      return JobTab.amc;
    }
    if (serviceType == 'quick_service' ||
        serviceType == 'quick service' ||
        serviceType == 'quickservice') {
      return JobTab.quickService;
    }

    return JobTab.installations;
  }
}
