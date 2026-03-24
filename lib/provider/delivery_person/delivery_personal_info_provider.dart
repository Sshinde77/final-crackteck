import 'package:flutter/foundation.dart';

import '../../model/delivery_person/delivery_personal_info_model.dart';
import '../../services/delivery_person/delivery_profile_service.dart';

class DeliveryPersonalInfoProvider extends ChangeNotifier {
  DeliveryPersonalInfoProvider({DeliveryProfileService? service})
    : _service = service ?? DeliveryProfileService();

  final DeliveryProfileService _service;

  DeliveryPersonalInfoModel _info = DeliveryPersonalInfoModel.empty();
  bool _isLoading = false;
  bool _isSaving = false;
  bool _lastSaveSucceeded = false;
  String? _error;

  DeliveryPersonalInfoModel get info => _info;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get lastSaveSucceeded => _lastSaveSucceeded;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final profile = await _service.fetchProfile();
      _info = DeliveryPersonalInfoModel.fromJson(profile);
    } catch (error) {
      _error = error.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> save({
    required String firstName,
    required String lastName,
    required String dob,
    required String gender,
    required String maritalStatus,
    required String employmentType,
    required String joiningDate,
    required String assignedArea,
  }) async {
    _isSaving = true;
    _lastSaveSucceeded = false;
    notifyListeners();
    try {
      final response = await _service.updateProfile(
        fields: <String, dynamic>{
          'first_name': firstName,
          'last_name': lastName,
          'dob': dob,
          'gender': gender,
          'marital_status': maritalStatus,
          'employment_type': employmentType,
          'joining_date': joiningDate,
          'assigned_area': assignedArea,
        },
      );
      _lastSaveSucceeded = response.success;
      if (response.success) {
        await load();
      }
      return response.message ?? 'Profile updated';
    } catch (error) {
      return error.toString().replaceFirst('Exception: ', '');
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
