import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../routes/app_routes.dart';
import '../../services/api_service.dart';

class DeliveryOtpVerificationScreen extends StatefulWidget {
  final int roleId;
  final String roleName;
  final String deliveryType;
  final String deliveryId;
  final String requestId;

  const DeliveryOtpVerificationScreen({
    super.key,
    required this.roleId,
    required this.roleName,
    required this.deliveryType,
    required this.deliveryId,
    required this.requestId,
  });

  @override
  State<DeliveryOtpVerificationScreen> createState() => _DeliveryOtpVerificationScreenState();
}

class _DeliveryOtpVerificationScreenState extends State<DeliveryOtpVerificationScreen> {
  static const int _otpLength = 4;
  final List<TextEditingController> _controllers =
      List.generate(_otpLength, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(_otpLength, (_) => FocusNode());

  Timer? _timer;
  int _secondsRemaining = 80;
  bool _isVerifying = false;
  static const Color _primaryGreen = Color(0xFF1E7C10);

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 0) {
        timer.cancel();
        return;
      }
      if (!mounted) return;
      setState(() {
        _secondsRemaining--;
      });
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Widget _buildOtpField(int index) {
    return SizedBox(
      width: 58,
      height: 132,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        maxLength: 1,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: const Color(0xFFE8E8E8),
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: _primaryGreen, width: 2),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < _otpLength - 1) {
            _focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Container(
      color: _primaryGreen,
      padding: const EdgeInsets.fromLTRB(8, 18, 8, 26),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 34),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 6),
            const Text(
              'OTP verification',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _verifyOtp() async {
    if (_isVerifying) return;

    final otp = _controllers.map((c) => c.text.trim()).join();
    if (otp.length != _otpLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a 4-digit OTP'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    final response = await ApiService.verifyDeliveryRequestOtp(
      deliveryType: widget.deliveryType,
      deliveryId: widget.deliveryId,
      otp: otp,
      roleId: widget.roleId,
    );

    if (!mounted) return;
    setState(() {
      _isVerifying = false;
    });

    final responseMessage = (response.message ?? '').trim();
    final message = responseMessage.isNotEmpty
        ? responseMessage
        : (response.success
            ? 'Delivery confirmed successfully'
            : 'Failed to verify OTP');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: response.success ? _primaryGreen : Colors.red,
      ),
    );

    if (!response.success) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.FieldExecutiveDashboard,
      (route) => false,
      arguments: fieldexecutivedashboardArguments(
        roleId: widget.roleId,
        roleName: widget.roleName,
        initialIndex: 0,
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      body: Column(
        children: [
          _buildHeroHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(32, 34, 32, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'We\'ve sent your verification code to',
                    style: TextStyle(
                      fontSize: 18,
                      height: 1.3,
                      color: Color(0xFFA7A7A7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    widget.requestId.isNotEmpty
                        ? widget.requestId
                        : '+91 **** ** ****',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Color(0xFFA7A7A7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 36),
                  const Text(
                    'Enter code',
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFF5C5C5C),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(_otpLength, _buildOtpField),
                  ),
                  const SizedBox(height: 90),
                  SizedBox(
                    width: double.infinity,
                    height: 76,
                    child: ElevatedButton(
                      onPressed: _isVerifying ? null : _verifyOtp,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: _primaryGreen,
                        disabledBackgroundColor: _primaryGreen.withValues(alpha: 0.65),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: _isVerifying
                          ? const SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.4,
                              ),
                            )
                          : const Text(
                              'Verify',
                              style: TextStyle(
                                fontSize: 24,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 34),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: _secondsRemaining == 0
                            ? () {
                                setState(() {
                                  _secondsRemaining = 80;
                                });
                                _startTimer();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('OTP resent (mock)'),
                                    backgroundColor: Colors.black87,
                                  ),
                                );
                              }
                            : null,
                        child: Text(
                          'Resend code',
                          style: TextStyle(
                            color: _secondsRemaining == 0
                                ? Colors.black
                                : Colors.black.withValues(alpha: 0.9),
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        '${_formatTime(_secondsRemaining)} left',
                        style: const TextStyle(
                          color: Color(0xFF8B8B8B),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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
