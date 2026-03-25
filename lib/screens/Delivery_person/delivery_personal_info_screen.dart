import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../provider/delivery_person/delivery_personal_info_provider.dart';

class DeliveryPersonalInfoScreen extends StatefulWidget {
  const DeliveryPersonalInfoScreen({
    super.key,
    required this.roleId,
    required this.roleName,
  });

  final int roleId;
  final String roleName;

  @override
  State<DeliveryPersonalInfoScreen> createState() =>
      _DeliveryPersonalInfoScreenState();
}

class _DeliveryPersonalInfoScreenState extends State<DeliveryPersonalInfoScreen> {
  static const Color green = Color(0xFF1E7C10);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<DeliveryPersonalInfoProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DeliveryPersonalInfoProvider>();
    final info = provider.info;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: green,
        foregroundColor: Colors.white,
        title: const Text('Personal info'),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
              ? _ErrorState(message: provider.error!, onRetry: provider.load)
              : SafeArea(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _InfoCard(
                        label: 'First Name',
                        value: info.firstName,
                      ),
                      _InfoCard(
                        label: 'Last Name',
                        value: info.lastName,
                      ),
                      _InfoCard(
                        label: 'DOB',
                        value: info.dob,
                      ),
                      _InfoCard(
                        label: 'Gender',
                        value: _formatGender(info.gender),
                      ),
                      _InfoCard(
                        label: 'Marital Status',
                        value: info.maritalStatus,
                      ),
                      _InfoCard(
                        label: 'Employment Type',
                        value: info.employmentType,
                      ),
                      _InfoCard(
                        label: 'Joining Date',
                        value: info.joiningDate,
                      ),
                      _InfoCard(
                        label: 'Assigned Area',
                        value: info.assignedArea,
                      ),
                    ],
                  ),
                ),
    );
  }

  String _formatGender(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '--';
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final displayValue = value.trim().isEmpty ? '--' : value.trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            displayValue,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
