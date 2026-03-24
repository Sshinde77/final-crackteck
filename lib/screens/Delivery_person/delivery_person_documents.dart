import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../provider/delivery_person/delivery_documents_provider.dart';
import 'delivery_edit_License_card.dart';
import 'delivery_edit_adhar_card.dart';
import 'delivery_edit_pan_card.dart';
import 'delivery_vehilcle_details.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  static const Color darkGreen = Color(0xFF145A00);

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<DeliveryDocumentsProvider>().loadAll();
    });
  }

  String _masked(dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) return '--';
    if (text.length <= 3) return text;
    final mask = List<String>.filled(text.length - 3, '*').join();
    return '$mask${text.substring(text.length - 3)}';
  }

  String _pick(Map<String, dynamic> source, List<String> keys, {String fallback = '--'}) {
    for (final key in keys) {
      final value = source[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DeliveryDocumentsProvider>();
    final aadhar = provider.aadhar;
    final pan = provider.pan;
    final vehicle = provider.vehicle;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: DocumentsScreen.darkGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Documents',
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none, color: Colors.white),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: provider.loadAll,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (provider.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: CircularProgressIndicator(),
                  ),
                ),
              if (provider.error != null)
                _ErrorCard(message: provider.error!, onRetry: provider.loadAll),
              const _Label('Aadhar no.'),
              _MaskedField(value: _masked(aadhar['aadhar_number'] ?? aadhar['aadhar_no'])),
              const SizedBox(height: 10),
              _DocImageRow(
                leftLabel: _pick(aadhar, const ['aadhar_front_path', 'aadhar_front']),
                rightLabel: _pick(aadhar, const ['aadhar_back_path', 'aadhar_back']),
                onEdit: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChangeNotifierProvider.value(
                        value: provider,
                        child: const AadhaarEditScreen(),
                      ),
                    ),
                  );
                  provider.loadAll();
                },
              ),
              const SizedBox(height: 20),
              const _Label('PAN no.'),
              _MaskedField(value: _masked(pan['pan_number'] ?? pan['pan_no'])),
              const SizedBox(height: 10),
              _DocImageRow(
                leftLabel: _pick(pan, const ['pan_card_front_path', 'pan_front']),
                rightLabel: _pick(pan, const ['pan_card_back_path', 'pan_back']),
                onEdit: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChangeNotifierProvider.value(
                        value: provider,
                        child: const PancardEditScreen(),
                      ),
                    ),
                  );
                  provider.loadAll();
                },
              ),
              const SizedBox(height: 20),
              const _Label('Licenses No.'),
              _MaskedField(
                value: _masked(
                  vehicle['driving_license_no'] ?? vehicle['licence_no'],
                ),
              ),
              const SizedBox(height: 10),
              _DocImageRow(
                leftLabel: _pick(
                  vehicle,
                  const ['driving_license_front_path', 'licence_front_image'],
                ),
                rightLabel: _pick(
                  vehicle,
                  const ['driving_license_back_path', 'licence_back_image'],
                ),
                onEdit: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChangeNotifierProvider.value(
                        value: provider,
                        child: const LicenseEditScreen(),
                      ),
                    ),
                  );
                  provider.loadAll();
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Vehicle Details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              const _Label('Type'),
              _InputBox(
                value: _pick(
                  vehicle,
                  const ['vehicle_type', 'brand'],
                ),
              ),
              const SizedBox(height: 12),
              const _Label('Vehicle Number'),
              _InputBox(
                value: _pick(
                  vehicle,
                  const ['vehicle_number', 'registration_number'],
                ),
              ),
              const SizedBox(height: 12),
              const _Label('Driving License No.'),
              _InputBox(
                value: _pick(
                  vehicle,
                  const ['driving_license_no', 'licence_no'],
                ),
              ),
              const SizedBox(height: 12),
              const _Label('Fuel type'),
              _InputBox(value: _pick(vehicle, const ['fuel_type'])),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChangeNotifierProvider.value(
                          value: provider,
                          child: const VehicleDetailsScreen(),
                        ),
                      ),
                    );
                    provider.loadAll();
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'Edit',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.edit, size: 14, color: Colors.red),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const _BottomNav(),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4F4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFD7D7)),
      ),
      child: Column(
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 12, color: Colors.black54),
    );
  }
}

class _MaskedField extends StatelessWidget {
  const _MaskedField({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black12),
      ),
      child: Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _InputBox extends StatelessWidget {
  const _InputBox({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black12),
      ),
      child: Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _DocImageRow extends StatelessWidget {
  const _DocImageRow({
    required this.leftLabel,
    required this.rightLabel,
    required this.onEdit,
  });

  final String leftLabel;
  final String rightLabel;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          children: [
            Expanded(child: _DocImageBox(label: leftLabel)),
            const SizedBox(width: 12),
            Expanded(child: _DocImageBox(label: rightLabel)),
          ],
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onEdit,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'Edit',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700),
              ),
              SizedBox(width: 4),
              Icon(Icons.edit, size: 14, color: Colors.red),
            ],
          ),
        ),
      ],
    );
  }
}

class _DocImageBox extends StatelessWidget {
  const _DocImageBox({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(8),
      child: Text(
        label == '--' ? 'IMAGE' : label.split('/').last,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.black54),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: const [
          _NavItem(icon: Icons.home_outlined, label: 'Home'),
          _NavItem(icon: Icons.chat_bubble_outline, label: 'Chat'),
          _NavItem(icon: Icons.person, label: 'Profile', selected: true),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? DocumentsScreen.darkGreen : Colors.black54;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
