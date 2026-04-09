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

  Map<String, dynamic> _normalizeDocument(dynamic value) {
    final source = _mapFrom(value);
    if (source.isEmpty) {
      return const <String, dynamic>{};
    }

    final normalized = Map<String, dynamic>.from(source);
    for (final key in const <String>[
      'data',
      'document',
      'details',
      'vehicle',
      'vehicle_details',
      'aadhar',
      'aadhaar',
      'aadhar_details',
      'pan',
      'pan_card',
      'pan_card_details',
      'registration',
      'result',
      'item',
      'record',
      'documents',
      'files',
      'attributes',
    ]) {
      final nested = _normalizeDocument(source[key]);
      if (nested.isNotEmpty) {
        normalized.addAll(nested);
      }
    }

    _applyAliases(normalized);
    return normalized;
  }

  Map<String, dynamic> _mapFrom(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is List) {
      for (final item in value) {
        final mapped = _mapFrom(item);
        if (mapped.isNotEmpty) {
          return mapped;
        }
      }
    }
    return const <String, dynamic>{};
  }

  void _copyIfMissing(
    Map<String, dynamic> map,
    String targetKey,
    List<String> sourceKeys,
  ) {
    final existing = map[targetKey];
    if (existing != null && existing.toString().trim().isNotEmpty) {
      return;
    }
    for (final sourceKey in sourceKeys) {
      final value = map[sourceKey];
      if (value != null && value.toString().trim().isNotEmpty) {
        map[targetKey] = value;
        return;
      }
    }
  }

  void _applyAliases(Map<String, dynamic> map) {
    _copyIfMissing(map, 'aadhar_number', const [
      'aadhar_no',
      'aadhaar_number',
      'aadhaar_no',
      'aadharNumber',
      'aadhaarNumber',
      'document_no',
      'document_number',
    ]);
    _copyIfMissing(map, 'pan_number', const [
      'pan_no',
      'panNumber',
      'document_no',
      'document_number',
    ]);
    _copyIfMissing(map, 'vehicle_type', const [
      'vehicleType',
      'brand',
      'type',
    ]);
    _copyIfMissing(map, 'vehicle_number', const [
      'vehicleNumber',
      'registration_number',
      'registration_no',
      'vehicle_no',
    ]);
    _copyIfMissing(map, 'driving_license_no', const [
      'driving_licence_no',
      'drivingLicenseNo',
      'licence_no',
      'license_no',
      'license_number',
      'licence_number',
    ]);
    _copyIfMissing(map, 'aadhar_front_path', const [
      'aadhar_front',
      'aadhaar_front_path',
      'aadhaar_front',
      'front_path',
      'front_image',
      'document_file',
      'document_path',
      'document_url',
      'file',
      'file_path',
    ]);
    _copyIfMissing(map, 'aadhar_back_path', const [
      'aadhar_back',
      'aadhaar_back_path',
      'aadhaar_back',
      'back_path',
      'back_image',
    ]);
    _copyIfMissing(map, 'pan_card_front_path', const [
      'pan_front',
      'pan_front_path',
      'front_path',
      'front_image',
      'document_file',
      'document_path',
      'document_url',
      'file',
      'file_path',
    ]);
    _copyIfMissing(map, 'pan_card_back_path', const [
      'pan_back',
      'pan_back_path',
      'back_path',
      'back_image',
    ]);
    _copyIfMissing(map, 'driving_license_front_path', const [
      'driving_licence_front_path',
      'drivingLicenseFrontPath',
      'licence_front_image',
      'license_front_image',
      'licence_front_path',
      'license_front_path',
      'front_path',
      'front_image',
      'document_file',
      'document_path',
      'document_url',
      'file',
      'file_path',
    ]);
    _copyIfMissing(map, 'driving_license_back_path', const [
      'driving_licence_back_path',
      'drivingLicenseBackPath',
      'licence_back_image',
      'license_back_image',
      'licence_back_path',
      'license_back_path',
      'back_path',
      'back_image',
    ]);
  }

  Future<void> loadAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    final errors = <String>[];

    try {
      _aadhar = _normalizeDocument(await _service.fetchAadharDetails());
    } catch (error) {
      errors.add(error.toString().replaceFirst('Exception: ', ''));
    }

    try {
      _pan = _normalizeDocument(await _service.fetchPanDetails());
    } catch (error) {
      errors.add(error.toString().replaceFirst('Exception: ', ''));
    }

    try {
      _vehicle = _normalizeDocument(await _service.fetchVehicleDetails());
    } catch (error) {
      errors.add(error.toString().replaceFirst('Exception: ', ''));
    }

    _error = errors.isEmpty ? null : errors.join('\n');
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadAadhar() async {
    _isLoading = true;
    notifyListeners();
    try {
      _aadhar = _normalizeDocument(await _service.fetchAadharDetails());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPan() async {
    _isLoading = true;
    notifyListeners();
    try {
      _pan = _normalizeDocument(await _service.fetchPanDetails());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadVehicle() async {
    _isLoading = true;
    notifyListeners();
    try {
      _vehicle = _normalizeDocument(await _service.fetchVehicleDetails());
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
