import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/delivery_person/delivery_documents_service.dart';

class DeliveryDocumentsProvider extends ChangeNotifier {
  DeliveryDocumentsProvider({DeliveryDocumentsService? service})
    : _service = service ?? DeliveryDocumentsService();

  final DeliveryDocumentsService _service;

  Map<String, dynamic> _aadhar = <String, dynamic>{};
  Map<String, dynamic> _pan = <String, dynamic>{};
  Map<String, dynamic> _vehicle = <String, dynamic>{};
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;
  bool _lastSaveSucceeded = false;

  Map<String, dynamic> get aadhar => _aadhar;
  Map<String, dynamic> get pan => _pan;
  Map<String, dynamic> get vehicle => _vehicle;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;
  bool get lastSaveSucceeded => _lastSaveSucceeded;

  Future<void> loadAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait<dynamic>(<Future<dynamic>>[
        _service.fetchAadharDetails(),
        _service.fetchPanDetails(),
        _service.fetchVehicleDetails(),
      ]);
      _aadhar = results[0] as Map<String, dynamic>;
      _pan = results[1] as Map<String, dynamic>;
      _vehicle = results[2] as Map<String, dynamic>;
    } catch (error) {
      _error = error.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAadhar() async {
    _isLoading = true;
    notifyListeners();
    try {
      _aadhar = await _service.fetchAadharDetails();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPan() async {
    _isLoading = true;
    notifyListeners();
    try {
      _pan = await _service.fetchPanDetails();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadVehicle() async {
    _isLoading = true;
    notifyListeners();
    try {
      _vehicle = await _service.fetchVehicleDetails();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> saveAadhar({
    required String number,
    XFile? frontFile,
    XFile? backFile,
    required bool isUpdate,
  }) async {
    _isSaving = true;
    _lastSaveSucceeded = false;
    notifyListeners();
    try {
      final response = await _service.saveAadharDetails(
        aadharNumber: number,
        frontFile: frontFile,
        backFile: backFile,
        isUpdate: isUpdate,
      );
      _lastSaveSucceeded = response.success;
      if (response.success) {
        await loadAadhar();
      }
      return response.message ?? 'Aadhaar saved';
    } catch (error) {
      return error.toString().replaceFirst('Exception: ', '');
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<String> savePan({
    required String number,
    XFile? frontFile,
    XFile? backFile,
    required bool isUpdate,
  }) async {
    _isSaving = true;
    _lastSaveSucceeded = false;
    notifyListeners();
    try {
      final response = await _service.savePanDetails(
        panNumber: number,
        frontFile: frontFile,
        backFile: backFile,
        isUpdate: isUpdate,
      );
      _lastSaveSucceeded = response.success;
      if (response.success) {
        await loadPan();
      }
      return response.message ?? 'PAN saved';
    } catch (error) {
      return error.toString().replaceFirst('Exception: ', '');
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<String> saveVehicle({
    required String vehicleType,
    required String vehicleNumber,
    required String drivingLicenseNo,
    XFile? frontFile,
    XFile? backFile,
  }) async {
    _isSaving = true;
    _lastSaveSucceeded = false;
    notifyListeners();
    try {
      final response = await _service.updateVehicleDetails(
        vehicleType: vehicleType,
        vehicleNumber: vehicleNumber,
        drivingLicenseNo: drivingLicenseNo,
        frontFile: frontFile,
        backFile: backFile,
      );
      _lastSaveSucceeded = response.success;
      if (response.success) {
        await loadVehicle();
      }
      return response.message ?? 'Vehicle details saved';
    } catch (error) {
      return error.toString().replaceFirst('Exception: ', '');
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
