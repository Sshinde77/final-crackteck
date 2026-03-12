import 'package:flutter/material.dart';

import '../../constants/api_constants.dart';
import '../../routes/app_routes.dart';
import '../../services/api_service.dart';
import 'field_executive_delivery_flow_helpers.dart';

class FieldExecutiveDeliverySendOtpScreen extends StatefulWidget {
  final int roleId;
  final String roleName;
  final int? userId;
  final String deliveryType;
  final String requestId;

  const FieldExecutiveDeliverySendOtpScreen({
    super.key,
    required this.roleId,
    required this.roleName,
    this.userId,
    required this.deliveryType,
    required this.requestId,
  });

  @override
  State<FieldExecutiveDeliverySendOtpScreen> createState() =>
      _FieldExecutiveDeliverySendOtpScreenState();
}

class _FieldExecutiveDeliverySendOtpScreenState
    extends State<FieldExecutiveDeliverySendOtpScreen> {
  static const Color primaryGreen = Color(0xFF1E7C10);

  bool _isSending = false;
  String? _error;

  String get _displayRequestId {
    final id = widget.requestId.trim().replaceFirst(RegExp(r'^#'), '');
    return id.isEmpty ? '-' : '#$id';
  }

  String get _apiDeliveryType {
    switch (FieldExecutiveDeliveryTypes.normalize(widget.deliveryType)) {
      case FieldExecutiveDeliveryTypes.pickupRequest:
        return DeliveryRequestTypes.pickup;
      case FieldExecutiveDeliveryTypes.requestPart:
        return DeliveryRequestTypes.part;
      case FieldExecutiveDeliveryTypes.returnRequest:
      default:
        return DeliveryRequestTypes.returnRequest;
    }
  }

  Future<void> _sendOtp() async {
    if (_isSending) return;

    setState(() {
      _isSending = true;
      _error = null;
    });

    final response = await ApiService.sendDeliveryRequestOtp(
      deliveryType: _apiDeliveryType,
      deliveryId: widget.requestId,
      roleId: widget.roleId,
    );

    if (!mounted) return;

    setState(() {
      _isSending = false;
      _error = response.success ? null : response.message;
    });

    if (!response.success) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(response.message ?? 'OTP sent successfully')),
    );

    Navigator.pushReplacementNamed(
      context,
      AppRoutes.DeliveryOtpVerificationScreen,
      arguments: deliveryotpverificationArguments(
        roleId: widget.roleId,
        roleName: widget.roleName,
        deliveryType: _apiDeliveryType,
        deliveryId: widget.requestId.trim().replaceFirst(RegExp(r'^#'), ''),
        requestId: widget.requestId.trim().replaceFirst(RegExp(r'^#'), ''),
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
        title: const Text(
          'Send Delivery OTP',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF5E7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      FieldExecutiveDeliveryTypes.label(widget.deliveryType),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Request ID: $_displayRequestId',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Send OTP to continue delivery verification.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade100),
                  ),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSending ? null : _sendOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Send OTP',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
