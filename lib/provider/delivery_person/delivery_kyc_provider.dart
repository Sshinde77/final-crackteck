import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../services/delivery_person/delivery_kyc_service.dart';

class DeliveryKycProvider extends ChangeNotifier {
  DeliveryKycProvider({DeliveryKycService? service})
    : _service = service ?? DeliveryKycService();

  final DeliveryKycService _service;

  Map<String, dynamic> _profile = <String, dynamic>{};
  Map<String, dynamic> _status = <String, dynamic>{};
  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _lastSubmitSucceeded = false;
  String? _error;

  Map<String, dynamic> get profile => _profile;
  Map<String, dynamic> get status => _status;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  bool get lastSubmitSucceeded => _lastSubmitSucceeded;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait<dynamic>([
        _service.fetchProfile(),
        _service.fetchKycStatus(),
      ]);
      _profile = results[0] as Map<String, dynamic>;
      _status = results[1] as Map<String, dynamic>;
    } catch (error) {
      _error = error.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> submit({
    required String name,
    required String email,
    required String phone,
    required String dob,
    required String documentType,
    required String documentNo,
    required File documentFile,
  }) async {
    _isSubmitting = true;
    _lastSubmitSucceeded = false;
    notifyListeners();
    try {
      final response = await _service.submitKyc(
        name: name,
        email: email,
        phone: phone,
        dob: dob,
        documentType: documentType,
        documentNo: documentNo,
        documentFile: documentFile,
      );
      _lastSubmitSucceeded = response.success;
      if (response.success) {
        await load();
      }
      return response.message ?? 'KYC submitted';
    } catch (error) {
      return error.toString().replaceFirst('Exception: ', '');
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
