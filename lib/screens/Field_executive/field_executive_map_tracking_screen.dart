import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../model/field executive/field_executive_service_request_detail.dart';
import '../../routes/app_routes.dart';
import '../../services/api_service.dart';

class FieldExecutiveMapTrackingScreen extends StatefulWidget {
  final int roleId;
  final String roleName;
  final String serviceId;
  final String customerName;
  final String customerAddress;
  final String customerPhone;
  final String displayServiceId;

  const FieldExecutiveMapTrackingScreen({
    super.key,
    required this.roleId,
    required this.roleName,
    required this.serviceId,
    this.customerName = '',
    this.customerAddress = '',
    this.customerPhone = '',
    this.displayServiceId = '',
  });

  @override
  State<FieldExecutiveMapTrackingScreen> createState() =>
      _FieldExecutiveMapTrackingScreenState();
}

class _FieldExecutiveMapTrackingScreenState
    extends State<FieldExecutiveMapTrackingScreen> {
  static const primaryGreen = Color(0xFF1E7C10);

  bool _loading = false;
  String _customerName = '';
  String _customerAddress = '';
  String _customerPhone = '';
  String _displayServiceId = '';
  String _destinationLabel = '';

  @override
  void initState() {
    super.initState();
    _customerName = widget.customerName.trim();
    _customerAddress = widget.customerAddress.trim();
    _customerPhone = widget.customerPhone.trim();
    _displayServiceId = widget.displayServiceId.trim();
    _destinationLabel = _computeDestinationLabel(_customerAddress);

    if (_customerName.isEmpty || _customerAddress.isEmpty || _customerPhone.isEmpty) {
      _loadServiceRequestDetail();
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  String _readFromMap(Map<String, dynamic>? map, List<String> keys) {
    if (map == null) return '';
    for (final key in keys) {
      final value = map[key];
      if (value == null) continue;
      if (value is Map || value is List) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null') {
        return text;
      }
    }
    return '';
  }

  String _buildAddressFromModel(FieldExecutiveServiceRequestDetail model) {
    final addr = model.customerAddress;
    if (addr != null) {
      final formatted = addr.formattedMultiline.trim();
      if (formatted.isNotEmpty) return formatted;
    }

    final raw = model.raw;
    final customer = _asMap(raw['customer']) ??
        _asMap(raw['customer_details']) ??
        _asMap(raw['user']);
    final request = _asMap(raw['service_request']) ??
        _asMap(raw['request']) ??
        _asMap(raw['service']);

    final fallback = _readFromMap(
      request,
      const ['address', 'full_address', 'service_address', 'location'],
    );
    if (fallback.isNotEmpty) return fallback;

    return _readFromMap(
      customer,
      const ['address', 'full_address', 'address1', 'address_line_1'],
    );
  }

  String _computeDestinationLabel(String address) {
    if (address.trim().isEmpty) return 'Destination unavailable';
    final lines = address.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (lines.isEmpty) return 'Destination unavailable';

    final last = lines.last;
    final withoutPincode = last.split('-').first.trim();
    if (withoutPincode.isNotEmpty) return withoutPincode;
    return lines.first;
  }

  Future<void> _loadServiceRequestDetail() async {
    setState(() => _loading = true);
    try {
      final detail = await ApiService.fetchServiceRequestDetail(
        widget.serviceId,
        roleId: widget.roleId,
      );
      final model = FieldExecutiveServiceRequestDetail.fromJson(detail);
      final customer = _asMap(detail['customer']) ??
          _asMap(detail['customer_details']) ??
          _asMap(detail['user']);

      final firstName = _readFromMap(
        customer,
        const ['first_name', 'firstName', 'firstname'],
      );
      final lastName = _readFromMap(
        customer,
        const ['last_name', 'lastName', 'lastname'],
      );
      final fullName = [firstName, lastName]
          .where((part) => part.trim().isNotEmpty)
          .join(' ')
          .trim();

      final name = fullName.isNotEmpty
          ? fullName
          : _readFromMap(detail, const ['customer_name', 'full_name', 'name']);

      final phone = _readFromMap(
        detail,
        const ['customer_phone', 'customer_number', 'phone', 'mobile', 'phone_number', 'contact_number'],
      );

      final displayId = _readFromMap(
        detail,
        const ['request_id', 'requestId', 'service_id', 'serviceId', 'ticket_no'],
      );

      final address = _buildAddressFromModel(model);

      if (!mounted) return;
      setState(() {
        if (_customerName.isEmpty) _customerName = name;
        if (_customerPhone.isEmpty) _customerPhone = phone;
        if (_displayServiceId.isEmpty) _displayServiceId = displayId;
        if (_customerAddress.isEmpty) _customerAddress = address;
        _destinationLabel = _computeDestinationLabel(_customerAddress);
      });
    } catch (_) {
      // Keep existing passed data. UI has fallbacks.
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _openGoogleMaps(String address) async {
    final trimmed = address.trim();
    if (trimmed.isEmpty) {
      _snack('Customer address not available');
      return;
    }

    final encodedAddress = Uri.encodeComponent(trimmed.replaceAll('\n', ', '));
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$encodedAddress',
    );

    final launched = await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      _snack('Unable to open Google Maps');
    }
  }

  void _startInstallation() {
    Navigator.pushNamed(
      context,
      AppRoutes.FieldExecutiveOtpVerificationScreen,
      arguments: fieldexecutiveotpverificationArguments(
        roleId: widget.roleId,
        roleName: widget.roleName,
        serviceId: widget.serviceId,
      ),
    );
  }

  Future<void> _callCustomer() async {
    final raw = _customerPhone.trim();
    if (raw.isEmpty || raw == '-') {
      _snack('Customer phone number not available');
      return;
    }

    final digits = raw.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$digits');
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      _snack('Unable to open dialer');
    }
  }

  @override
  Widget build(BuildContext context) {
    final customerName =
        _customerName.isEmpty ? 'Customer' : _customerName;
    final serviceId = _displayServiceId.isEmpty
        ? widget.serviceId
        : _displayServiceId;

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
          'Tracking',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_loading) const LinearProgressIndicator(minHeight: 2),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF5E7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: primaryGreen,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Destination',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _destinationLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 28,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Time',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '15 min',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: double.infinity,
                    child: Image.asset(
                      'assets/images/map_placeholder.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return Container(
                          color: Colors.grey.shade200,
                          alignment: Alignment.center,
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.map_outlined,
                                color: Colors.grey,
                                size: 56,
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Map preview unavailable',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.grey.shade200,
                      child: Icon(
                        Icons.person,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Service ID: $serviceId',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _callCustomer,
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFEAF5E7),
                        padding: const EdgeInsets.all(12),
                      ),
                      icon: const Icon(Icons.call, color: primaryGreen),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _openGoogleMaps(_customerAddress),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                        side: const BorderSide(color: primaryGreen, width: 1.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Colors.white,
                      ),
                      child: const Text(
                        'Navigate',
                        style: TextStyle(
                          color: primaryGreen,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _startInstallation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Start Installation',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
