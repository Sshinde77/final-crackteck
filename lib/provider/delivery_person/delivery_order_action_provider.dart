import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/delivery_person/delivery_orders_service.dart';

class DeliveryOrderActionProvider extends ChangeNotifier {
  DeliveryOrderActionProvider({
    required String orderId,
    DeliveryOrdersService? ordersService,
  })  : orderId = orderId.startsWith('#') ? orderId : '#$orderId',
        _ordersService = ordersService ?? DeliveryOrdersService();

  final String orderId;
  final DeliveryOrdersService _ordersService;

  bool _isUploadingSelfie = false;
  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;
  int _secondsRemaining = 80;
  Timer? _timer;
  bool _lastActionSucceeded = false;

  bool get isUploadingSelfie => _isUploadingSelfie;
  bool get isSendingOtp => _isSendingOtp;
  bool get isVerifyingOtp => _isVerifyingOtp;
  int get secondsRemaining => _secondsRemaining;
  bool get canResend => _secondsRemaining == 0;
  bool get lastActionSucceeded => _lastActionSucceeded;

  void startOtpTimer() {
    _timer?.cancel();
    _secondsRemaining = 80;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        _secondsRemaining--;
        notifyListeners();
      } else {
        timer.cancel();
      }
    });
    notifyListeners();
  }

  Future<String?> uploadSelfie(XFile photo) async {
    _isUploadingSelfie = true;
    notifyListeners();

    try {
      final response = await _ordersService.uploadOrderSelfie(
        orderId: orderId,
        profileImage: photo,
      );
      _lastActionSucceeded = response.success;
      return response.message ??
          (response.success ? 'Selfie uploaded' : 'Selfie upload failed');
    } catch (error) {
      _lastActionSucceeded = false;
      return error.toString().replaceFirst('Exception: ', '');
    } finally {
      _isUploadingSelfie = false;
      notifyListeners();
    }
  }

  Future<bool> sendOtp() async {
    _isSendingOtp = true;
    notifyListeners();

    try {
      final response = await _ordersService.sendOrderOtp(orderId);
      _lastActionSucceeded = response.success;
      if (response.success) {
        startOtpTimer();
      }
      return response.success;
    } catch (_) {
      _lastActionSucceeded = false;
      rethrow;
    } finally {
      _isSendingOtp = false;
      notifyListeners();
    }
  }

  Future<String> sendOtpMessage() async {
    try {
      final response = await _ordersService.sendOrderOtp(orderId);
      _lastActionSucceeded = response.success;
      if (response.success) {
        startOtpTimer();
      }
      return response.message ?? (response.success ? 'OTP sent' : 'Failed to send OTP');
    } catch (error) {
      _lastActionSucceeded = false;
      return error.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<String> verifyAndDeliver(String otp) async {
    _isVerifyingOtp = true;
    notifyListeners();

    try {
      final verifyResponse = await _ordersService.verifyOrderOtp(
        orderId: orderId,
        otp: otp,
      );
      if (!verifyResponse.success) {
        _lastActionSucceeded = false;
        return verifyResponse.message ?? 'OTP verification failed';
      }

      final deliveredResponse = await _ordersService.markOrderDelivered(orderId);
      _lastActionSucceeded = deliveredResponse.success;
      return deliveredResponse.message ?? 'Order delivered successfully.';
    } catch (error) {
      _lastActionSucceeded = false;
      return error.toString().replaceFirst('Exception: ', '');
    } finally {
      _isVerifyingOtp = false;
      notifyListeners();
    }
  }

  String formatTime() {
    final minutes = _secondsRemaining ~/ 60;
    final remainingSeconds = _secondsRemaining % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
