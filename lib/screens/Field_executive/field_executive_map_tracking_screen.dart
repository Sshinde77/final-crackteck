import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
  bool _isSendingOtp = false;

  late final String _customerName;
  late final String _customerAddress;
  late final String _customerPhone;
  late final String _displayServiceId;
  late final String _destinationText;

  @override
  void initState() {
    super.initState();
    _customerName = widget.customerName.trim();
    _customerAddress = widget.customerAddress.trim();
    _customerPhone = widget.customerPhone.trim();
    _displayServiceId = widget.displayServiceId.trim();
    _destinationText = _buildDestinationText(_customerAddress);
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _buildDestinationText(String fullAddress) {
    final raw = fullAddress.trim();
    if (raw.isEmpty) return '';
    if (raw.toLowerCase() == 'address not available') return '';

    final lines = raw
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (lines.isEmpty) return '';

    final branchName = lines.isNotEmpty ? lines[0] : '';
    final addressLine = lines.length > 1 ? lines[1] : '';
    final citySource = lines.length > 2 ? lines[2] : '';
    final city = citySource.split(',').first.split('-').first.trim();

    final parts = <String>[
      if (branchName.isNotEmpty) branchName,
      if (addressLine.isNotEmpty) addressLine,
      if (city.isNotEmpty) city,
    ];

    return parts.join(', ').trim();
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

  Future<void> _startInstallation() async {
    if (_isSendingOtp) return;
    debugPrint('Start Installation clicked');

    final serviceRequestId = widget.serviceId
        .trim()
        .replaceFirst(RegExp(r'^#'), '');

    if (mounted) {
      setState(() {
        _isSendingOtp = true;
      });
    } else {
      _isSendingOtp = true;
    }

    late final response;
    try {
      debugPrint(
        'Calling sendServiceRequestOtp for ID: $serviceRequestId with roleId: ${widget.roleId}',
      );
      response = await ApiService.sendServiceRequestOtp(
        serviceRequestId,
        roleId: widget.roleId,
      );
      debugPrint(
        'sendServiceRequestOtp response: success=${response.success}, message=${response.message}',
      );
    } catch (e) {
      debugPrint('sendServiceRequestOtp exception: $e');
      if (mounted) {
        _snack('Failed to send OTP');
      }
      return;
    } finally {
      if (mounted) {
        setState(() {
          _isSendingOtp = false;
        });
      } else {
        _isSendingOtp = false;
      }
    }

    if (!mounted) return;

    if (!response.success) {
      _snack(response.message ?? 'Failed to send OTP');
      return;
    }

    _snack(response.message ?? 'OTP sent successfully');

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
    final customerName = _customerName.isEmpty ? 'Customer' : _customerName;
    final serviceId = _displayServiceId.isEmpty ? widget.serviceId : _displayServiceId;

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
            if (_destinationText.isNotEmpty)
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
                              _destinationText,
                              maxLines: 2,
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
                    ],
                  ),
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _openGoogleMaps(_customerAddress),
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
                      onPressed: _isSendingOtp
                          ? null
                          : () {
                              debugPrint('Start Installation button tapped');
                              _startInstallation();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSendingOtp
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
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
