import 'package:flutter/foundation.dart';

import '../../model/delivery_person/delivery_profile_model.dart';
import '../../services/delivery_person/delivery_profile_service.dart';

class DeliveryProfileProvider extends ChangeNotifier {
  DeliveryProfileProvider({DeliveryProfileService? service})
    : _service = service ?? DeliveryProfileService();

  final DeliveryProfileService _service;

  DeliveryProfileModel _profile = DeliveryProfileModel.empty();
  bool _isLoading = false;
  String? _error;

  DeliveryProfileModel get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final rawProfile = await _service.fetchProfile();
      _profile = DeliveryProfileModel.fromJson(rawProfile);
    } catch (error) {
      _error = error.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
