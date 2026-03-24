import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../provider/delivery_person/delivery_order_action_provider.dart';
import '../../routes/app_routes.dart';

class DeliveryOtpScreen extends StatefulWidget {
  final int roleId;
  final String roleName;
  final String orderId;

  const DeliveryOtpScreen({
    super.key,
    required this.roleId,
    required this.roleName,
    required this.orderId,
  });

  @override
  State<DeliveryOtpScreen> createState() => _DeliveryOtpScreenState();
}

class _DeliveryOtpScreenState extends State<DeliveryOtpScreen> {
  static const Color green = Color(0xFF1E7C10);

  Future<void> _sendOtp() async {
    final provider = context.read<DeliveryOrderActionProvider>();
    final message = await provider.sendOtpMessage();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    if (provider.lastActionSucceeded) {
      Navigator.pushNamed(
        context,
        AppRoutes.DeliveryOtpVerificationScreen,
        arguments: deliveryotpverificationArguments(
          roleId: widget.roleId,
          roleName: widget.roleName,
          orderId: widget.orderId,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DeliveryOrderActionProvider>();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: green,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Map',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(
                context,
                AppRoutes.DeliveryNotificationScreen,
                arguments: deliverynotificationArguments(
                  roleId: widget.roleId,
                  roleName: widget.roleName,
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.grey[200],
              alignment: Alignment.center,
              child: const Icon(Icons.map, size: 100, color: Colors.grey),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Order ${widget.orderId}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Send OTP to the customer before completing the delivery.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: provider.isSendingOtp ? null : _sendOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: provider.isSendingOtp
                          ? const SizedBox(
                              width: 22,
                              height: 22,
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
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
