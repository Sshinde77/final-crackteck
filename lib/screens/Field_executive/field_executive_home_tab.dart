import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../services/api_service.dart';

class FieldExecutiveHomeTab extends StatefulWidget {
  final int roleId;
  final String roleName;

  const FieldExecutiveHomeTab({
    super.key,
    required this.roleId,
    required this.roleName,
  });

  @override
  State<FieldExecutiveHomeTab> createState() => _FieldExecutiveHomeTabState();
}

class _FieldExecutiveHomeTabState extends State<FieldExecutiveHomeTab> {
  final TextEditingController _searchCtrl = TextEditingController();
  JobTab _activeTab = JobTab.installations;
  List<JobItem> _jobs = [];
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
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF1E7C10);
    
    // Filtering logic for search and tabs
    final visibleJobs = _jobs.where((j) {
      final matchesTab = j.tab == _activeTab;
      final query = _searchCtrl.text.toLowerCase();
      if (query.isEmpty) return matchesTab;
      
      final matchesSearch = j.title.toLowerCase().contains(query) ||
                            j.serviceId.toLowerCase().contains(query) ||
                            j.location.toLowerCase().contains(query);
                            
      return matchesTab && matchesSearch;
    }).toList();

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth <= 320;
    final horizontalPadding = isSmall ? 10.0 : 16.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header & Search
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: isSmall ? 100 : 120,
                    width: double.infinity,
                    decoration: const BoxDecoration(color: green),
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 15),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'crackteck',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isSmall ? 20 : 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.FieldExecutiveNotificationScreen,
                              arguments: fieldexecutivenotificationArguments(
                                roleId: widget.roleId,
                                roleName: widget.roleName,
                              ),
                            );
                          },
                          child: Icon(
                            Icons.notifications_none,
                            color: Colors.white,
                            size: isSmall ? 24 : 28,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: horizontalPadding,
                    right: horizontalPadding,
                    bottom: -20,
                    child: Container(
                      height: isSmall ? 44 : 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (value) => setState(() {}),
                        style: TextStyle(fontSize: isSmall ? 14 : 16),
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.search, color: Colors.grey, size: isSmall ? 20 : 24),
                          hintText: "Search",
                          hintStyle: TextStyle(fontSize: isSmall ? 13 : 15),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: isSmall ? 8 : 12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: isSmall ? 35 : 45),

              // Stat Cards
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.FieldExecutiveStockInHandScreen,
                            arguments: fieldexecutivestockinhandArguments(
                              roleId: widget.roleId,
                              roleName: widget.roleName,
                            ),
                          );
                        },
                        child: _StatCard(
                          title: 'Stock\nin hand',
                          icon: Icons.inventory_2,
                          iconColor: Colors.orange,
                          isSmall: isSmall,
                        ),
                      ),
                    ),
                    SizedBox(width: isSmall ? 6 : 10),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.FieldExecutiveWorkCallScreen,
                            arguments: fieldexecutiveworkcallArguments(
                              roleId: widget.roleId,
                              roleName: widget.roleName,
                            ),
                          );
                        },
                        child: _StatCard(
                          title: 'Work\ncall',
                          icon: Icons.home_repair_service,
                          iconColor: Colors.blue,
                          isSmall: isSmall,
                        ),
                      ),
                    ),
                    SizedBox(width: isSmall ? 6 : 10),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.FieldExecutiveDeliveryScreen,
                            arguments: fieldexecutivedeliveryArguments(
                              roleId: widget.roleId,
                              roleName: widget.roleName,
                            ),
                          );
                        },
                        child: _StatCard(
                          title: 'Delivery',
                          icon: Icons.local_shipping,
                          iconColor: Colors.green,
                          isSmall: isSmall,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Text(
                  'New job assign',
                  style: TextStyle(
                    fontSize: isSmall ? 16 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Tabs
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Row(
                  children: [
                    _JobTabButton(
                      label: isSmall ? 'Install' : 'Installations',
                      icon: Icons.settings,
                      isActive: _activeTab == JobTab.installations,
                      isSmall: isSmall,
                      onTap: () => setState(() => _activeTab = JobTab.installations),
                    ),
                    SizedBox(width: isSmall ? 6 : 12),
                    _JobTabButton(
                      label: 'Repairs',
                      icon: Icons.build,
                      isActive: _activeTab == JobTab.repairs,
                      isSmall: isSmall,
                      onTap: () => setState(() => _activeTab = JobTab.repairs),
                    ),
                    SizedBox(width: isSmall ? 6 : 12),
                    _JobTabButton(
                      label: 'AMC',
                      icon: Icons.print,
                      isActive: _activeTab == JobTab.amc,
                      isSmall: isSmall,
                      onTap: () => setState(() => _activeTab = JobTab.amc),
                    ),
                    SizedBox(width: isSmall ? 6 : 12),
                    _JobTabButton(
                      label: isSmall ? 'Quick' : 'Quick Service',
                      icon: Icons.bolt,
                      isActive: _activeTab == JobTab.quickService,
                      isSmall: isSmall,
                      onTap: () => setState(() => _activeTab = JobTab.quickService),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (_jobsLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_jobsError != null)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Failed to load service requests',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.red.shade700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _jobsError!,
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _loadServiceRequests,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (visibleJobs.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 24),
                  child: const Center(
                    child: Text(
                      'No service requests found',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 10),
                  itemCount: visibleJobs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final job = visibleJobs[index];
                    // Make all job types navigable; pass jobType so detail screen can render accordingly
                    String jobTypeStr = job.tab == JobTab.installations
                        ? 'installations'
                        : job.tab == JobTab.repairs
                            ? 'repairs'
                            : job.tab == JobTab.amc
                                ? 'amc'
                                : 'quick_service';

                    return InkWell(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.FieldExecutiveInstallationDetailScreen,
                          arguments: fieldexecutiveinstallationdetailArguments(
                            roleId: widget.roleId,
                            roleName: widget.roleName,
                            title: job.title,
                            serviceId: job.detailServiceId,
                            location: job.location,
                            priority: job.priority,
                            jobType: jobTypeStr,
                          ),
                        );
                      },
                      child: _JobCard(
                        job: job,
                        isSmall: isSmall,
                      ),
                    );
                  },
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final bool isSmall;

  const _StatCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.isSmall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: isSmall ? 4 : 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: isSmall ? 20 : 24),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isSmall ? 9 : 11,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _JobTabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  final bool isSmall;

  const _JobTabButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
    required this.isSmall,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: isSmall ? 8 : 10),
          decoration: BoxDecoration(
            color: isActive ? Colors.grey.shade100 : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive ? Colors.grey.shade300 : Colors.grey.shade100,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: isSmall ? 14 : 16, color: isActive ? Colors.blue : Colors.grey),
              SizedBox(width: isSmall ? 4 : 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isSmall ? 9 : 12,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    color: isActive ? Colors.black : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final JobItem job;
  final bool isSmall;

  const _JobCard({
    required this.job,
    required this.isSmall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isSmall ? 10 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: isSmall ? 60 : 80,
                height: isSmall ? 60 : 80,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: job.imageUrl.isEmpty
                    ? const Icon(Icons.build_circle_outlined, color: Colors.grey)
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          job.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.build_circle_outlined, color: Colors.grey),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            job.title,
                            style: TextStyle(
                              fontSize: isSmall ? 14 : 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          job.priority,
                          style: TextStyle(
                            fontSize: isSmall ? 10 : 12,
                            fontWeight: FontWeight.bold,
                            color: job.priority == 'High' ? Colors.red : Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      job.description,
                      style: TextStyle(
                        fontSize: isSmall ? 9 : 10,
                        color: Colors.black54,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Service ID',
                      style: TextStyle(fontSize: isSmall ? 9 : 10, color: Colors.grey),
                    ),
                    Text(
                      job.serviceId,
                      style: TextStyle(
                        fontSize: isSmall ? 10 : 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Location',
                      style: TextStyle(fontSize: isSmall ? 9 : 10, color: Colors.grey),
                    ),
                    Text(
                      job.location,
                      style: TextStyle(
                        fontSize: isSmall ? 10 : 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
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
    return normalized.isEmpty ? serviceId.replaceFirst(RegExp(r'^#'), '') : normalized;
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

    // Numeric mappings, if backend sends enum codes.
    if (serviceType == '1') return JobTab.installations;
    if (serviceType == '2') return JobTab.repairs;
    if (serviceType == '3') return JobTab.amc;
    if (serviceType == '4') return JobTab.quickService;

    // String mappings from API.
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

    // Unknown/missing service_type defaults to Installations tab.
    return JobTab.installations;
  }
}
