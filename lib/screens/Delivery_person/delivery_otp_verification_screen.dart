import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../provider/delivery_person/delivery_order_action_provider.dart';
import '../../routes/app_routes.dart';

class DeliveryOtpVerificationScreen extends StatefulWidget {
  final int roleId;
  final String roleName;
  final String orderId;

  const DeliveryOtpVerificationScreen({
    super.key,
    required this.roleId,
    required this.roleName,
    required this.orderId,
  });

  @override
  State<DeliveryOtpVerificationScreen> createState() =>
      _DeliveryOtpVerificationScreenState();
}

class _DeliveryOtpVerificationScreenState
    extends State<DeliveryOtpVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  static const Color green = Color(0xFF1E7C10);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<DeliveryOrderActionProvider>().startOtpTimer();
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_otpController.text.trim().isEmpty) return;

    final provider = context.read<DeliveryOrderActionProvider>();
    final message = await provider.verifyAndDeliver(_otpController.text.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    if (provider.lastActionSucceeded) {
      Navigator.pushNamed(
        context,
        AppRoutes.DeliveryDoneScreen,
        arguments: deliverydoneArguments(
          roleId: widget.roleId,
          roleName: widget.roleName,
        ),
      );
    }
  }

  Future<void> _resend() async {
    final provider = context.read<DeliveryOrderActionProvider>();
    final message = await provider.sendOtpMessage();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DeliveryOrderActionProvider>();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black),
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Text(
                'Please provide the OTP to proceed with the delivery.',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "We've sent your verification code to\n+91 **** ** ****",
                style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
              ),
              const SizedBox(height: 60),
              const Text(
                'Enter code',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
                decoration: const InputDecoration(
                  hintText: '8888',
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black12),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: green),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: provider.canResend ? _resend : null,
                  child: Text(
                    'Resend code',
                    style: TextStyle(
                      color: provider.canResend ? green : Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: provider.isVerifyingOtp ? null : _verify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: provider.isVerifyingOtp
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
                          'Verify',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  '${provider.formatTime()} left',
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
