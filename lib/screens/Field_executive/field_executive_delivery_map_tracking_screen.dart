import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../services/api_service.dart';

class DeliveryMapTrackingScreen extends StatefulWidget {
  final int roleId;
  final String roleName;
  final String deliveryType;
  final String deliveryId;
  final String requestId;
  final String productName;
  final String customerName;
  final String customerPhone;
  final String customerAddress;

  const DeliveryMapTrackingScreen({
    super.key,
    required this.roleId,
    required this.roleName,
    required this.deliveryType,
    required this.deliveryId,
    required this.requestId,
    required this.productName,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
  });

  @override
  State<DeliveryMapTrackingScreen> createState() => _DeliveryMapTrackingScreenState();
}

class _DeliveryMapTrackingScreenState extends State<DeliveryMapTrackingScreen> {
  static const Color _primaryGreen = Color(0xFF1E7C10);
  bool _isSendingOtp = false;

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _sendOtp() async {
    if (_isSendingOtp) return;

    final deliveryId = widget.deliveryId.trim().replaceFirst(RegExp(r'^#'), '');
    if (deliveryId.isEmpty) {
      _showSnack('Unable to send OTP: delivery id is missing.');
      return;
    }

    setState(() {
      _isSendingOtp = true;
    });

    final response = await ApiService.sendDeliveryRequestOtp(
      deliveryType: widget.deliveryType,
      deliveryId: deliveryId,
      roleId: widget.roleId,
    );

    if (!mounted) return;

    setState(() {
      _isSendingOtp = false;
    });

    final responseMessage = (response.message ?? '').trim();
    final message = responseMessage.isNotEmpty
        ? responseMessage
        : (response.success ? 'OTP sent successfully' : 'Failed to send OTP');
    _showSnack(message);

    if (!response.success) return;

    Navigator.pushNamed(
      context,
      AppRoutes.DeliveryOtpVerificationScreen,
      arguments: deliveryotpverificationArguments(
        roleId: widget.roleId,
        roleName: widget.roleName,
        deliveryType: widget.deliveryType,
        deliveryId: deliveryId,
        requestId: widget.requestId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _primaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Delivery Tracking',
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF5E7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.location_on, color: _primaryGreen),
                    ),
                    const SizedBox(width: 10),
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
                            widget.customerAddress,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    'assets/images/map_placeholder.jpg',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) {
                      return Container(
                        color: Colors.grey.shade200,
                        alignment: Alignment.center,
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.map_outlined, size: 56, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Map preview unavailable', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      );
                    },
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
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 10,
                offset: const Offset(0, -2),
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
                  border: Border.all(color: Colors.black12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.grey.shade200,
                      child: Icon(Icons.person, color: Colors.grey.shade700),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.customerName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Request ID: ${widget.requestId}',
                            style: const TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _showSnack('Calling ${widget.customerPhone}'),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFEAF5E7),
                        padding: const EdgeInsets.all(12),
                      ),
                      icon: const Icon(Icons.call, color: _primaryGreen),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showSnack('Opening map (mocked)'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        side: const BorderSide(color: _primaryGreen, width: 1.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Open Map',
                        style: TextStyle(
                          color: _primaryGreen,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSendingOtp ? null : _sendOtp,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: _primaryGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isSendingOtp
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Send OTP',
                              style: TextStyle(
                                color: Colors.white,
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
