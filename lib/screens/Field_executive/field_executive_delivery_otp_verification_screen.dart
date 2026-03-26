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
  static const int _fieldExecutiveRoleId = 1;
  final List<TextEditingController> _controllers =
      List.generate(_otpLength, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(_otpLength, (_) => FocusNode());

  Timer? _timer;
  int _secondsRemaining = 80;
  bool _isVerifying = false;
  bool _isLoadingDetail = false;
  bool _cashReceivedConfirmed = false;
  static const Color _primaryGreen = Color(0xFF1E7C10);
  Map<String, dynamic>? _detail;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _loadDeliveryDetail();
  }

  Future<void> _loadDeliveryDetail() async {
    if (widget.deliveryType.trim().isEmpty || widget.deliveryId.trim().isEmpty) {
      return;
    }

    setState(() {
      _isLoadingDetail = true;
    });

    try {
      final detail = await ApiService.fetchDeliveryRequestDetail(
        deliveryType: widget.deliveryType,
        deliveryId: widget.deliveryId,
        roleId: widget.roleId,
      );
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _isLoadingDetail = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingDetail = false;
      });
    }
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  String _readText(Map<String, dynamic>? source, List<String> keys) {
    if (source == null) return '';
    for (final key in keys) {
      final value = source[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return '';
  }

  String get _productName {
    final detail = _detail;
    final order = _asMap(detail?['order']);
    final orderOrDetail = order ?? detail;
    final orderItems = orderOrDetail?['order_items'];
    final firstOrderItem = orderItems is List && orderItems.isNotEmpty
        ? _asMap(orderItems.first)
        : null;
    final product = _asMap(detail?['products']) ?? _asMap(detail?['product']);
    final value = _readText(
      firstOrderItem ?? product ?? orderOrDetail,
      const ['product_name', 'name', 'title', 'service_name'],
    );
    return value.isEmpty ? '--' : value;
  }

  String get _quantity {
    final detail = _detail;
    final order = _asMap(detail?['order']);
    final orderOrDetail = order ?? detail;
    final orderItems = orderOrDetail?['order_items'];
    final firstOrderItem = orderItems is List && orderItems.isNotEmpty
        ? _asMap(orderItems.first)
        : null;
    final product = _asMap(detail?['products']) ?? _asMap(detail?['product']);
    final value = _readText(
      firstOrderItem ?? orderOrDetail,
      const ['requested_quantity', 'quantity', 'total_requested_quantity', 'qty'],
    );
    final fallback = _readText(
      product ?? orderOrDetail,
      const ['requested_quantity', 'quantity', 'total_requested_quantity', 'qty'],
    );
    final result = value.isNotEmpty ? value : fallback;
    return result.isEmpty ? '--' : result;
  }

  String get _installation {
    final detail = _detail;
    final order = _asMap(detail?['order']);
    final orderOrDetail = order ?? detail;
    final orderItems = orderOrDetail?['order_items'];
    final firstOrderItem = orderItems is List && orderItems.isNotEmpty
        ? _asMap(orderItems.first)
        : null;
    final product = _asMap(detail?['products']) ?? _asMap(detail?['product']);
    final value = _readText(
      firstOrderItem ?? orderOrDetail,
      const ['installation'],
    );
    final fallback = _readText(
      product ?? orderOrDetail,
      const ['installation'],
    );
    final result = value.isNotEmpty ? value : fallback;
    return result.isEmpty ? '--' : result;
  }

  String get _price {
    final detail = _detail;
    final order = _asMap(detail?['order']);
    final orderOrDetail = order ?? detail;
    final orderItems = orderOrDetail?['order_items'];
    final firstOrderItem = orderItems is List && orderItems.isNotEmpty
        ? _asMap(orderItems.first)
        : null;
    final product = _asMap(detail?['products']) ?? _asMap(detail?['product']);
    final value = _readText(
      firstOrderItem ?? orderOrDetail,
      const ['line_total', 'unit_price', 'final_price', 'price', 'amount'],
    );
    final fallback = _readText(
      product ?? orderOrDetail,
      const ['final_price', 'selling_price', 'price', 'amount'],
    );
    final result = value.isNotEmpty ? value : fallback;
    if (result.isEmpty) return '--';
    if (result.contains('\u20B9')) return result;
    return '\u20B9 $result';
  }

  String get _paymentStatus {
    final detail = _detail;
    final order = _asMap(detail?['order']);
    final orderOrDetail = order ?? detail;
    final value = _readText(
      orderOrDetail,
      const ['payment_status', 'paymentStatus', 'payment_state', 'payment'],
    );
    return value.isEmpty ? '--' : value;
  }

  String get _orderId {
    final detail = _detail;
    final order = _asMap(detail?['order']);
    final orderOrDetail = order ?? detail;
    final value = _readText(orderOrDetail, const ['id', 'order_id']);
    return value.isEmpty ? widget.deliveryId.trim() : value;
  }

  bool get _requiresCashConfirmation {
    return _paymentStatus.trim().toLowerCase() == 'pending';
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
    final isEnabled = !_requiresCashConfirmation || _cashReceivedConfirmed;
    return SizedBox(
      width: 60,
      height: 66,
      child: TextField(
        enabled: isEnabled,
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        maxLength: 1,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: isEnabled ? const Color(0xFF17321A) : const Color(0xFF9AA1A6),
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: isEnabled ? Colors.white : const Color(0xFFF1F3F4),
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFDCE8DE)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: _primaryGreen, width: 2),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF177A14),
            Color(0xFF0F5E10),
          ],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 34),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 6),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'OTP verification',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  'Secure delivery confirmation',
                  style: TextStyle(
                    color: Color(0xFFD6F0D8),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void onCashReceivedConfirmed() {
    if (_cashReceivedConfirmed) return;
    setState(() {
      _cashReceivedConfirmed = true;
    });
    _focusNodes.first.requestFocus();
  }

  Future<bool> _confirmCashReceived() async {
    final response = await ApiService.markCashReceived(
      orderId: _orderId,
      roleId: widget.roleId,
    );

    if (!mounted) return false;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          response.message ??
              (response.success
                  ? 'Cash received confirmed successfully'
                  : 'Failed to confirm cash received'),
        ),
        backgroundColor: response.success ? _primaryGreen : Colors.red,
      ),
    );

    if (!response.success) return false;

    onCashReceivedConfirmed();
    return true;
  }

  Widget _buildDetailCard() {
    if (_isLoadingDetail) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black12),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_detail == null) return const SizedBox.shrink();

    return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black12),
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Product Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          _detailRow('Product Name', _productName),
          const SizedBox(height: 10),
          _detailRow('Quantity', _quantity),
          const SizedBox(height: 10),
          _detailRow('Installation', _installation),
          const SizedBox(height: 10),
          _detailRow('Price', _price),
          const SizedBox(height: 10),
          _detailRow('Payment Status', _paymentStatus),
        ],
      ),
    );
  }

  Widget _buildOtpSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter code',
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF243027),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _requiresCashConfirmation && !_cashReceivedConfirmed
                ? 'Confirm cash received to enable OTP verification.'
                : 'Enter the 4-digit OTP shared for this delivery.',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF7A8580),
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_otpLength, _buildOtpField),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF79B36A),
                  Color(0xFF4D9854),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x2D4D9854),
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed:
                    ((_requiresCashConfirmation && !_cashReceivedConfirmed) ||
                            _isVerifying)
                        ? null
                        : _verifyOtp,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  backgroundColor: Colors.transparent,
                  disabledBackgroundColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
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
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Verify',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                          SizedBox(width: 10),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8F7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE7ECE7)),
            ),
            child: Row(
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
                          ? const Color(0xFF17321A)
                          : const Color(0xFF7A8580),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFE2E8E3)),
                  ),
                  child: Text(
                    '${_formatTime(_secondsRemaining)} left',
                    style: const TextStyle(
                      color: Color(0xFF7A8580),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
          ),
        ),
      ],
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

    final isFieldExecutiveFlow =
        widget.roleId == _fieldExecutiveRoleId ||
        widget.roleName.toLowerCase().contains('field');

    if (isFieldExecutiveFlow) {
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
      return;
    }

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.Deliverypersondashbord,
      (route) => false,
      arguments: deliverydasboardArguments(
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
      backgroundColor: const Color(0xFFF4F6F3),
      body: Column(
        children: [
          _buildHeroHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF5EA),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'We\'ve sent your verification code to',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.3,
                            color: Color(0xFF68806A),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.requestId.isNotEmpty
                              ? widget.requestId
                              : '+91 **** ** ****',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Color(0xFF17321A),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildDetailCard(),
                  if (_requiresCashConfirmation) ...[
                    const SizedBox(height: 16),
                    CashReceivedSlider(
                      onComplete: _confirmCashReceived,
                    ),
                  ],
                  const SizedBox(height: 20),
                  _buildOtpSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CashReceivedSlider extends StatefulWidget {
  const CashReceivedSlider({
    super.key,
    required this.onComplete,
  });

  final Future<bool> Function() onComplete;

  @override
  State<CashReceivedSlider> createState() => _CashReceivedSliderState();
}

class _CashReceivedSliderState extends State<CashReceivedSlider> {
  static const double _trackHeight = 60;
  static const double _thumbSize = 60;
  static const double _triggerThreshold = 0.84;

  double _dragFraction = 0;
  bool _isCompleted = false;
  bool _isSubmitting = false;

  void _onDragUpdate(DragUpdateDetails details, double maxTravel) {
    if (_isCompleted || _isSubmitting || maxTravel <= 0) return;
    setState(() {
      _dragFraction = (_dragFraction + (details.delta.dx / maxTravel)).clamp(0.0, 1.0);
    });
  }

  Future<void> _onDragEnd() async {
    if (_isCompleted || _isSubmitting) return;

    if (_dragFraction >= _triggerThreshold) {
      await HapticFeedback.mediumImpact();
      if (!mounted) return;
      setState(() {
        _isSubmitting = true;
      });
      final success = await widget.onComplete();
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _isCompleted = success;
        _dragFraction = success ? 1 : 0;
      });
      return;
    }

    setState(() {
      _dragFraction = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final maxTravel = (width - _thumbSize).clamp(0.0, double.infinity);
        final thumbOffset = maxTravel * _dragFraction;
        final fillWidth = (_thumbSize + thumbOffset).clamp(_thumbSize, width);

        return SizedBox(
          height: _trackHeight,
          width: double.infinity,
          child: Stack(
            children: [
              Container(
                height: _trackHeight,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                height: _trackHeight,
                width: fillWidth,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0xFF66BB6A),
                      Color(0xFF1E7C10),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              Positioned.fill(
                child: Center(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 180),
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: _dragFraction > 0.45
                          ? Colors.white
                          : const Color(0xFF243027),
                    ),
                    child: Text(
                      _isCompleted ? 'Cash Received ✓' : 'Cash Received',
                    ),
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                left: thumbOffset,
                top: 0,
                child: GestureDetector(
                  onHorizontalDragUpdate: (_isCompleted || _isSubmitting)
                      ? null
                      : (details) => _onDragUpdate(details, maxTravel),
                  onHorizontalDragEnd:
                      (_isCompleted || _isSubmitting) ? null : (_) => _onDragEnd(),
                  child: Container(
                    width: _thumbSize,
                    height: _thumbSize,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 14,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Color(0xFF1E7C10),
                            ),
                          )
                        : Icon(
                            _isCompleted
                                ? Icons.check
                                : Icons.arrow_forward_rounded,
                            color: const Color(0xFF1E7C10),
                            size: 26,
                          ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
