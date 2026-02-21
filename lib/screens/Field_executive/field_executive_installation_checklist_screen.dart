import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../model/field executive/diagnosis_item.dart';
import '../../model/field executive/field_executive_product_service.dart';
import '../../model/field executive/selected_stock_item.dart';
import '../../routes/app_routes.dart';
import '../../services/api_service.dart';

class _NotWorkingDialogResult {
  final String selectedOption;
  final String notes;
  final File? selectedImage;

  const _NotWorkingDialogResult({
    required this.selectedOption,
    required this.notes,
    required this.selectedImage,
  });
}

class FieldExecutiveInstallationChecklistScreen extends StatefulWidget {
  final int roleId;
  final String roleName;
  final String serviceId;
  final String serviceRequestId;
  final String serviceRequestDbId;
  final String productDbId;
  final Map<String, dynamic>? selectedProduct;
  final FieldExecutiveProductItemDetailFlow flow;
  final FieldExecutiveProductServicesController controller;

  const FieldExecutiveInstallationChecklistScreen({
    super.key,
    required this.roleId,
    required this.roleName,
    required this.serviceId,
    this.serviceRequestId = '',
    this.serviceRequestDbId = '',
    this.productDbId = '',
    this.selectedProduct,
    required this.flow,
    required this.controller,
  });

  @override
  State<FieldExecutiveInstallationChecklistScreen> createState() =>
      _FieldExecutiveInstallationChecklistScreenState();
}

class _FieldExecutiveInstallationChecklistScreenState
    extends State<FieldExecutiveInstallationChecklistScreen> {
  static const primaryGreen = Color(0xFF1E7C10);
  static const List<String> _notWorkingOptions = <String>[
    'Not Working',
    'Add to Pickup',
    'Use Stock in Hand',
    'Request a Part',
  ];

  final ImagePicker _picker = ImagePicker();
  File? _beforeImage;
  bool _isPickingBeforeImage = false;
  File? _afterImage;
  bool _isPickingAfterImage = false;
  bool _isLoadingDiagnosis = false;
  String? _diagnosisError;
  List<DiagnosisItem> _diagnosisItems = const <DiagnosisItem>[];

  // Track which items are expanded
  final Map<String, bool> _expandedItems = {};

  // Track status of each item (Working or selected non-working action)
  final Map<String, String?> _itemStatus = {};
  final Map<String, String> _itemSelectedAction = {};
  final Map<String, String> _itemProblemSolution = {};
  final Map<String, File> _itemIssueImage = {};
  final Map<String, List<SelectedStockItem>> _itemSelectedStockItems = {};
  final Map<String, bool> _itemPartUsed = {};
  String _writtenReportText = '';
  bool _isSubmittingDiagnosis = false;

  @override
  void initState() {
    super.initState();
    _loadDiagnosisList();
  }

  @override
  void didUpdateWidget(
    covariant FieldExecutiveInstallationChecklistScreen oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.serviceRequestId != widget.serviceRequestId ||
        oldWidget.serviceRequestDbId != widget.serviceRequestDbId ||
        oldWidget.productDbId != widget.productDbId ||
        oldWidget.serviceId != widget.serviceId ||
        oldWidget.selectedProduct != widget.selectedProduct) {
      _loadDiagnosisList();
    }
  }

  String _normalizeId(String raw) {
    return raw.trim().replaceFirst(RegExp(r'^#'), '');
  }

  String _readFromMap(Map<String, dynamic>? source, List<String> keys) {
    if (source == null) return '';
    for (final key in keys) {
      final value = source[key];
      if (value == null || value is Map || value is List) {
        continue;
      }
      final text = _normalizeId(value.toString());
      if (text.isNotEmpty && text.toLowerCase() != 'null') {
        return text;
      }
    }
    return '';
  }

  String _firstResolvedId(List<String> candidates) {
    for (final candidate in candidates) {
      final normalized = _normalizeId(candidate);
      if (normalized.isNotEmpty && int.tryParse(normalized) != null) {
        return normalized;
      }
    }
    for (final candidate in candidates) {
      final normalized = _normalizeId(candidate);
      if (normalized.isNotEmpty) {
        return normalized;
      }
    }
    return '';
  }

  String _serviceRequestIdForApi() {
    return _firstResolvedId([
      widget.serviceRequestDbId,
      _readFromMap(
        widget.selectedProduct,
        const [
          'service_requests_id',
          'service_request_id',
          'serviceRequestId',
          'request_service_id',
        ],
      ),
      widget.serviceRequestId,
    ]);
  }

  String _productIdForApi() {
    return _firstResolvedId([
      widget.productDbId,
      _readFromMap(
        widget.selectedProduct,
        const ['id', 'product_id', 'productId', 'item_code_id', 'itemCodeId'],
      ),
      widget.serviceId,
    ]);
  }

  void _syncChecklistStateForDiagnosis(List<DiagnosisItem> diagnosisItems) {
    final keys = diagnosisItems.map((item) => item.name).toSet();
    _expandedItems.removeWhere((key, _) => !keys.contains(key));
    _itemStatus.removeWhere((key, _) => !keys.contains(key));
    _itemSelectedAction.removeWhere((key, _) => !keys.contains(key));
    _itemProblemSolution.removeWhere((key, _) => !keys.contains(key));
    _itemIssueImage.removeWhere((key, _) => !keys.contains(key));
    _itemSelectedStockItems.removeWhere((key, _) => !keys.contains(key));
    _itemPartUsed.removeWhere((key, _) => !keys.contains(key));
    for (final item in diagnosisItems) {
      if (_normalizePartStatus(item.partStatus) == 'customer_approved') {
        // Rehydrated API state should always wait for an explicit local click.
        _itemPartUsed[item.name] = false;
      } else {
        _itemPartUsed.remove(item.name);
      }
    }
    _clearSelectedStockForNonUseStatuses(diagnosisItems);
  }

  Future<void> _loadDiagnosisList() async {
    final serviceRequestId = _serviceRequestIdForApi();
    final productId = _productIdForApi();

    if (serviceRequestId.isEmpty || productId.isEmpty) {
      setState(() {
        _diagnosisItems = const <DiagnosisItem>[];
        _diagnosisError =
            'Diagnosis API parameters are missing. Please open this screen from product detail.';
        _isLoadingDiagnosis = false;
      });
      return;
    }

    setState(() {
      _isLoadingDiagnosis = true;
      _diagnosisError = null;
    });

    try {
      final list = await ApiService.fetchServiceRequestDiagnosisList(
        serviceRequestId: serviceRequestId,
        productId: productId,
        roleId: widget.roleId,
      );
      if (!mounted) return;
      setState(() {
        _syncChecklistStateForDiagnosis(list);
        _diagnosisItems = list;
        _isLoadingDiagnosis = false;
        _diagnosisError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingDiagnosis = false;
        _diagnosisError = e
            .toString()
            .replaceFirst(RegExp(r'^Exception:\s*'), '')
            .trim();
      });
    }
  }

  Future<void> _pickBeforeImage(ImageSource source) async {
    if (_isPickingBeforeImage) return;

    setState(() {
      _isPickingBeforeImage = true;
    });

    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 70,
      );
      if (picked != null && mounted) {
        setState(() {
          _beforeImage = File(picked.path);
        });
      }
    } catch (e) {
      debugPrint("Error picking before image: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isPickingBeforeImage = false;
        });
      }
    }
  }

  void _showBeforeImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.upload_file, color: primaryGreen),
                title: const Text('Upload file'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickBeforeImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: primaryGreen),
                title: const Text('Open camera'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickBeforeImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAfterImage(ImageSource source) async {
    if (_isPickingAfterImage) return;

    setState(() {
      _isPickingAfterImage = true;
    });

    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 70,
      );
      if (picked != null && mounted) {
        setState(() {
          _afterImage = File(picked.path);
        });
      }
    } catch (e) {
      debugPrint("Error picking after image: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isPickingAfterImage = false;
        });
      }
    }
  }

  void _showAfterImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.upload_file, color: primaryGreen),
                title: const Text('Upload file'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickAfterImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: primaryGreen),
                title: const Text('Open camera'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickAfterImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _normalizeStatusLabel(String? status) {
    final normalized = (status ?? '')
        .trim()
        .toLowerCase()
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .replaceAll(RegExp(r'\s+'), ' ');

    switch (normalized) {
      case 'working':
        return 'Working';
      case 'not working':
        return 'Not Working';
      case 'picking':
      case 'add to pickup':
        return 'Add to Pickup';
      case 'stock in hand':
      case 'use stock in hand':
        return 'Use Stock in Hand';
      case 'request part':
      case 'request a part':
        return 'Request a Part';
      default:
        return '';
    }
  }

  String _normalizePartStatus(String? status) {
    final normalized = (status ?? '')
        .trim()
        .toLowerCase()
        .replaceAll('-', '_')
        .replaceAll(' ', '_')
        .replaceAll(RegExp(r'_+'), '_');

    switch (normalized) {
      case 'waiting_for_approval':
      case 'customer_approved':
      case 'used':
        return normalized;
      default:
        return '';
    }
  }

  bool _isWorkingStatus(String? status) {
    return _normalizeStatusLabel(status) == 'Working';
  }

  bool _isNonWorkingStatus(String? status) {
    final normalized = _normalizeStatusLabel(status);
    return normalized.isNotEmpty && normalized != 'Working';
  }

  bool _isUseStockInHandStatus(String? status) {
    return _normalizeStatusLabel(status) == 'Use Stock in Hand';
  }

  DiagnosisItem? _findDiagnosisByName(String name) {
    for (final item in _effectiveDiagnosisItems) {
      if (item.name == name) return item;
    }
    return null;
  }

  void _clearSelectedStockForNonUseStatuses(
    List<DiagnosisItem> diagnosisItems,
  ) {
    final Map<String, DiagnosisItem> diagnosisByName = {
      for (final item in diagnosisItems) item.name: item,
    };

    for (final key in _itemSelectedStockItems.keys.toList()) {
      final List<SelectedStockItem> sanitizedItems = _sanitizeSelectedStockItems(
        _itemSelectedStockItems[key] ?? const <SelectedStockItem>[],
      );
      if (sanitizedItems.isEmpty) {
        _itemSelectedStockItems.remove(key);
        continue;
      }
      _itemSelectedStockItems[key] = sanitizedItems;

      final localStatus = _normalizeStatusLabel(_itemStatus[key]);
      if (localStatus.isNotEmpty) {
        if (!_isUseStockInHandStatus(localStatus)) {
          _itemSelectedStockItems.remove(key);
        }
        continue;
      }

      final apiStatus = _normalizeStatusLabel(diagnosisByName[key]?.statusLabel);
      if (apiStatus.isNotEmpty && !_isUseStockInHandStatus(apiStatus)) {
        _itemSelectedStockItems.remove(key);
      }
    }
  }

  void _showMessageSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _stockItemKey(SelectedStockItem item) {
    final String normalizedProductId = _normalizeId(item.productId);
    if (normalizedProductId.isNotEmpty) {
      return 'id:$normalizedProductId';
    }
    final String normalizedName = item.productName.trim().toLowerCase();
    if (normalizedName.isNotEmpty) {
      return 'name:$normalizedName';
    }
    return '';
  }

  List<SelectedStockItem> _sanitizeSelectedStockItems(
    List<SelectedStockItem> items,
  ) {
    final Map<String, SelectedStockItem> uniqueItems =
        <String, SelectedStockItem>{};

    for (final item in items) {
      final String normalizedProductId = _normalizeId(item.productId);
      final int? numericPartId = int.tryParse(normalizedProductId);
      if (numericPartId == null) {
        debugPrint(
          '[Checklist] Dropping stock item due to invalid part_id '
          '(productId=${item.productId}, name=${item.productName})',
        );
        continue;
      }
      final int safeQuantity = item.quantity <= 0 ? 1 : item.quantity;
      if (item.quantity <= 0) {
        debugPrint(
          '[Checklist] quantity<=0 fallback applied '
          '(part_id=$numericPartId, original=${item.quantity}, normalized=$safeQuantity)',
        );
      }

      final SelectedStockItem normalizedItem = item.copyWith(
        productId: numericPartId.toString(),
        quantity: safeQuantity,
      );
      final String key = _stockItemKey(normalizedItem);
      if (key.isEmpty) {
        continue;
      }
      uniqueItems[key] = normalizedItem;
    }

    return uniqueItems.values.toList(growable: false);
  }

  List<SelectedStockItem> _mergeSelectedStockItems({
    required List<SelectedStockItem> existingItems,
    required List<SelectedStockItem> incomingItems,
  }) {
    final Map<String, SelectedStockItem> merged = <String, SelectedStockItem>{};

    for (final item in _sanitizeSelectedStockItems(existingItems)) {
      merged[_stockItemKey(item)] = item;
    }

    for (final item in _sanitizeSelectedStockItems(incomingItems)) {
      merged[_stockItemKey(item)] = item;
    }

    return merged.values.toList(growable: false);
  }

  bool _hasSelectedStockItems(String diagnosisName) {
    final List<SelectedStockItem> items = _sanitizeSelectedStockItems(
      _itemSelectedStockItems[diagnosisName] ?? const <SelectedStockItem>[],
    );
    return items.isNotEmpty;
  }

  void _changeInlineStockQuantity({
    required String diagnosisName,
    required SelectedStockItem item,
    required int delta,
  }) {
    if (delta == 0) return;

    final List<SelectedStockItem> currentItems = List<SelectedStockItem>.from(
      _itemSelectedStockItems[diagnosisName] ?? const <SelectedStockItem>[],
    );
    final String targetKey = _stockItemKey(item);
    final int index = currentItems.indexWhere(
      (element) => _stockItemKey(element) == targetKey,
    );
    if (index < 0) return;

    final SelectedStockItem targetItem = currentItems[index];
    final int nextQuantity = targetItem.quantity + delta;

    setState(() {
      if (nextQuantity <= 0) {
        currentItems.removeAt(index);
      } else {
        currentItems[index] = targetItem.copyWith(quantity: nextQuantity);
      }

      if (currentItems.isEmpty) {
        _itemSelectedStockItems.remove(diagnosisName);
      } else {
        _itemSelectedStockItems[diagnosisName] = currentItems;
      }
    });
  }

  Future<void> _onAddMoreProductsPressed(String diagnosisName) async {
    final List<SelectedStockItem>? selectedFromStockScreen =
        await _openStockInHandSelection(diagnosisName);
    if (!mounted || selectedFromStockScreen == null) {
      return;
    }

    final List<SelectedStockItem> mergedItems = _mergeSelectedStockItems(
      existingItems: _itemSelectedStockItems[diagnosisName] ??
          const <SelectedStockItem>[],
      incomingItems: selectedFromStockScreen,
    );

    if (mergedItems.isEmpty) {
      _showMessageSnackBar('At least one stock item is required');
      return;
    }

    setState(() {
      _itemSelectedStockItems[diagnosisName] = mergedItems;
    });
  }

  String? _firstDiagnosisWithoutStockItems() {
    final Set<String> diagnosisNames = _effectiveDiagnosisItems
        .map((item) => item.name)
        .toSet();

    for (final diagnosis in _effectiveDiagnosisItems) {
      final bool isApprovedAndMarkedUsed =
          _normalizePartStatus(diagnosis.partStatus) == 'customer_approved' &&
          (_itemPartUsed[diagnosis.name] ?? false);
      if (isApprovedAndMarkedUsed) {
        continue;
      }
      if (!_isUseStockInHandStatus(_resolvedStatusLabel(diagnosis))) {
        continue;
      }
      final items = _sanitizeSelectedStockItems(
        _itemSelectedStockItems[diagnosis.name] ?? const <SelectedStockItem>[],
      );
      if (items.isEmpty) {
        return diagnosis.name;
      }
    }

    for (final entry in _itemStatus.entries) {
      if (!_isUseStockInHandStatus(entry.value)) {
        continue;
      }
      if (diagnosisNames.contains(entry.key)) {
        continue;
      }
      final items = _sanitizeSelectedStockItems(
        _itemSelectedStockItems[entry.key] ?? const <SelectedStockItem>[],
      );
      if (items.isEmpty) {
        return entry.key;
      }
    }

    return null;
  }

  String? _firstMarkedUsedDiagnosisMissingApiPartData() {
    for (final diagnosis in _effectiveDiagnosisItems) {
      final bool isApprovedAndMarkedUsed =
          _normalizePartStatus(diagnosis.partStatus) == 'customer_approved' &&
          (_itemPartUsed[diagnosis.name] ?? false);
      if (!isApprovedAndMarkedUsed) {
        continue;
      }
      final int? approvedPartId = int.tryParse(
        _normalizeId(diagnosis.productIdFromApi),
      );
      final int? approvedQuantity = int.tryParse(
        diagnosis.quantityFromApi.trim(),
      );
      if (approvedPartId == null ||
          approvedQuantity == null ||
          approvedQuantity <= 0) {
        return diagnosis.name;
      }
    }
    return null;
  }

  String _resolvedStatusLabel(DiagnosisItem diagnosis) {
    final localStatus = _normalizeStatusLabel(_itemStatus[diagnosis.name]);
    if (localStatus.isNotEmpty) return localStatus;
    return _normalizeStatusLabel(diagnosis.statusLabel);
  }

  String? _resolvedReportText(DiagnosisItem diagnosis) {
    final localText = (_itemProblemSolution[diagnosis.name] ?? '').trim();
    if (localText.isNotEmpty) return localText;
    final apiText = (diagnosis.report ?? '').trim();
    if (apiText.isEmpty) return null;
    return apiText;
  }

  Future<ImageSource?> _showImageSourcePickerBottomSheet(
    BuildContext context,
  ) async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.upload_file, color: primaryGreen),
                title: const Text('Upload file'),
                onTap: () {
                  Navigator.pop(sheetContext, ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: primaryGreen),
                title: const Text('Open camera'),
                onTap: () {
                  Navigator.pop(sheetContext, ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  List<SelectedStockItem> _parseSelectedStockItems(dynamic raw) {
    debugPrint(
      '[Checklist] _parseSelectedStockItems rawType=${raw.runtimeType}',
    );
    if (raw is! List) {
      return const <SelectedStockItem>[];
    }

    final List<SelectedStockItem> parsed = <SelectedStockItem>[];
    for (int i = 0; i < raw.length; i++) {
      final dynamic item = raw[i];
      SelectedStockItem? candidate;
      if (item is SelectedStockItem) {
        candidate = item;
      } else if (item is Map<String, dynamic>) {
        candidate = SelectedStockItem.fromMap(item);
      } else if (item is Map) {
        candidate = SelectedStockItem.fromMap(Map<String, dynamic>.from(item));
      }

      if (candidate == null) {
        debugPrint(
          '[Checklist][PARSE][$i] Unsupported item type=${item.runtimeType}',
        );
        continue;
      }

      // Keep checklist state valid for submit payload:
      // productId is required for part_id, and quantity must be positive.
      final String normalizedProductId = _normalizeId(candidate.productId);
      if (normalizedProductId.isEmpty) {
        debugPrint(
          '[Checklist][PARSE][$i] Dropped item with missing productId '
          '(name=${candidate.productName}, quantity=${candidate.quantity})',
        );
        continue;
      }

      final int normalizedQuantity = candidate.quantity <= 0
          ? 1
          : candidate.quantity;
      if (candidate.quantity <= 0) {
        debugPrint(
          '[Checklist][PARSE][$i] quantity<=0 fallback applied '
          '(productId=$normalizedProductId, original=${candidate.quantity}, normalized=1)',
        );
      }

      final SelectedStockItem normalizedItem = candidate.copyWith(
        productId: normalizedProductId,
        quantity: normalizedQuantity,
      );
      parsed.add(normalizedItem);
      debugPrint(
        '[Checklist][PARSE][$i] '
        'productId=${normalizedItem.productId}, '
        'productName=${normalizedItem.productName}, '
        'quantity=${normalizedItem.quantity}',
      );
    }
    return parsed;
  }

  Future<List<SelectedStockItem>?> _openStockInHandSelection(
    String diagnosisName,
  ) async {
    final dynamic result = await Navigator.pushNamed(
      context,
      AppRoutes.FieldExecutiveStockInHandScreen,
      arguments: fieldexecutivestockinhandArguments(
        roleId: widget.roleId,
        roleName: widget.roleName,
        selectionMode: true,
        diagnosisName: diagnosisName,
        initialSelectedItems: _sanitizeSelectedStockItems(
          _itemSelectedStockItems[diagnosisName] ??
              const <SelectedStockItem>[],
        ),
      ),
    );
    if (result == null) return null;
    debugPrint(
      '[Checklist] _openStockInHandSelection resultType=${result.runtimeType}',
    );
    if (result is List) {
      for (int i = 0; i < result.length; i++) {
        final dynamic item = result[i];
        if (item is SelectedStockItem) {
          debugPrint(
            '[Checklist][NAV-RESULT][$i] '
            'productId=${item.productId}, '
            'productName=${item.productName}, '
            'quantity=${item.quantity}',
          );
        } else if (item is Map<String, dynamic>) {
          final SelectedStockItem parsed = SelectedStockItem.fromMap(item);
          debugPrint(
            '[Checklist][NAV-RESULT][$i] '
            'productId=${parsed.productId}, '
            'productName=${parsed.productName}, '
            'quantity=${parsed.quantity}',
          );
        } else if (item is Map) {
          final SelectedStockItem parsed = SelectedStockItem.fromMap(
            Map<String, dynamic>.from(item),
          );
          debugPrint(
            '[Checklist][NAV-RESULT][$i] '
            'productId=${parsed.productId}, '
            'productName=${parsed.productName}, '
            'quantity=${parsed.quantity}',
          );
        } else {
          debugPrint(
            '[Checklist][NAV-RESULT][$i] unsupportedType=${item.runtimeType}',
          );
        }
      }
    }

    final List<SelectedStockItem> parsedResult = _parseSelectedStockItems(
      result,
    );
    debugPrint(
      '[Checklist] _openStockInHandSelection parsedCount=${parsedResult.length}',
    );
    return parsedResult;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'COMPUTER (Desktop / Laptop)',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _isLoadingDiagnosis ? null : _loadDiagnosisList,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBeforeImageUploadSection(),
              const SizedBox(height: 16),
              _buildSectionHeader('Diagnosis List'),
              ..._effectiveDiagnosisItems.map(_buildChecklistItem),
              if (!_isLoadingDiagnosis &&
                  _diagnosisError == null &&
                  _diagnosisItems.isEmpty)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Text(
                    'No diagnosis list found for this product.',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),
              if (_isLoadingDiagnosis)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: LinearProgressIndicator(color: primaryGreen),
                ),
              if (_diagnosisError != null && _diagnosisError!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _diagnosisError!,
                            style: TextStyle(
                              color: Colors.orange.shade900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _loadDiagnosisList,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              _buildAfterImageUploadSection(),
              const SizedBox(height: 12),
              _buildReportSection(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBeforeImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLargeButton(
          onPressed: _showBeforeImagePickerOptions,
          icon: Icons.add_a_photo_outlined,
          label:
              _beforeImage == null ? 'Upload before image' : 'Re-upload before image',
        ),
        if (_beforeImage != null) ...[
          const SizedBox(height: 10),
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: 170,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                  image: DecorationImage(
                    image: FileImage(_beforeImage!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: ElevatedButton(
                  onPressed: _showBeforeImagePickerOptions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: primaryGreen,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'Re-upload',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
        if (_isPickingBeforeImage)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: LinearProgressIndicator(color: primaryGreen),
          ),
      ],
    );
  }

  List<DiagnosisItem> get _effectiveDiagnosisItems {
    return _diagnosisItems;
  }

  Widget _buildAfterImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLargeButton(
          onPressed: _showAfterImagePickerOptions,
          icon: Icons.cloud_upload,
          label: _afterImage == null ? 'Upload after photos' : 'Re-upload after photos',
        ),
        if (_afterImage != null) ...[
          const SizedBox(height: 10),
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: 170,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                  image: DecorationImage(
                    image: FileImage(_afterImage!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: ElevatedButton(
                  onPressed: _showAfterImagePickerOptions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: primaryGreen,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'Re-upload',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
        if (_isPickingAfterImage)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: LinearProgressIndicator(color: primaryGreen),
          ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          color: primaryGreen,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildReportSection() {
    final bool hasReport = _writtenReportText.trim().isNotEmpty;
    if (!hasReport) {
      return _buildLargeButton(
        onPressed: _showWriteReportDialog,
        label: 'Write Report',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Report',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: primaryGreen,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _writtenReportText,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildLargeButton(
          onPressed: _isSubmittingDiagnosis ? null : _onFinalSubmitPressed,
          label: _isSubmittingDiagnosis ? 'Submitting...' : 'Submit',
        ),
      ],
    );
  }

  Future<void> _showWriteReportDialog() async {
    String reportText = _writtenReportText;

    final String? submittedReport = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final bool canSubmit = reportText.trim().isNotEmpty;
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      initialValue: reportText,
                      onChanged: (value) {
                        setDialogState(() {
                          reportText = value;
                        });
                      },
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Write report',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: canSubmit
                          ? () {
                              Navigator.of(
                                dialogContext,
                              ).pop(reportText.trim());
                              
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        disabledBackgroundColor: Colors.grey.shade300,
                        disabledForegroundColor: Colors.grey.shade600,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Submit',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted || submittedReport == null) return;
    final normalizedReport = submittedReport.trim();
    if (normalizedReport.isEmpty) return;

    setState(() {
      _writtenReportText = normalizedReport;
    });
  }

  void _onFinalSubmitPressed() {
    _submitDiagnosisReport();
  }

  String _statusToApiValue(String? status) {
    final normalized = _normalizeStatusLabel(status).toLowerCase();
    switch (normalized) {
      case 'working':
        return 'working';
      case 'not working':
        return 'not_working';
      case 'add to pickup':
        return 'picking';
      case 'use stock in hand':
        return 'stock_in_hand';
      case 'request a part':
        return 'request_part';
      default:
        return 'working';
    }
  }

  List<Map<String, dynamic>> _buildDiagnosisSubmitPayload() {
    final Map<String, DiagnosisItem> diagnosisByName = {
      for (final item in _effectiveDiagnosisItems) item.name: item,
    };
    final List<String> items = _effectiveDiagnosisItems.isNotEmpty
        ? _effectiveDiagnosisItems.map((item) => item.name).toList()
        : _itemStatus.keys.toList();

    return List<Map<String, dynamic>>.generate(items.length, (index) {
      final String name = items[index];
      final DiagnosisItem? diagnosis = diagnosisByName[name];
      final String selectedStatus = _normalizeStatusLabel(
        _itemStatus[name] ?? diagnosis?.statusLabel,
      );
      final String apiStatus = _statusToApiValue(
        selectedStatus.isEmpty ? 'Working' : selectedStatus,
      );
      final String partStatus = _normalizePartStatus(diagnosis?.partStatus);
      final bool markPartUsedOnSubmit =
          partStatus == 'customer_approved' && (_itemPartUsed[name] ?? false);
      final int? approvedPartId = int.tryParse(
        _normalizeId(diagnosis?.productIdFromApi ?? ''),
      );
      final int? approvedQuantity = int.tryParse(
        (diagnosis?.quantityFromApi ?? '').trim(),
      );
      final String report =
          (_itemProblemSolution[name] ?? diagnosis?.report ?? '').trim();
      final File? issueImage = _itemIssueImage[name];
      final List<SelectedStockItem> selectedStockItems =
          _sanitizeSelectedStockItems(
        _itemSelectedStockItems[name] ?? const <SelectedStockItem>[],
      );
      final SelectedStockItem? selectedStockItem = selectedStockItems.isNotEmpty
          ? selectedStockItems.first
          : null;
      final int? selectedPartId = selectedStockItem == null
          ? null
          : int.tryParse(_normalizeId(selectedStockItem.productId));
      final int? selectedQuantity = selectedStockItem == null
          ? null
          : (selectedStockItem.quantity > 0 ? selectedStockItem.quantity : null);
      final int? rehydratedPartId = int.tryParse(_normalizeId(diagnosis?.partId ?? ''));
      final int? rehydratedQuantity = int.tryParse((diagnosis?.quantity ?? '').trim());
      final int? resolvedPartId = selectedPartId ?? rehydratedPartId;
      final int? resolvedQuantity =
          selectedQuantity ?? ((rehydratedQuantity ?? 0) > 0 ? rehydratedQuantity : null);

      if (markPartUsedOnSubmit) {
        final Map<String, dynamic> payload = <String, dynamic>{
          'name': name,
          'status': 'working',
          'part_status': 'used',
        };
        if (approvedPartId != null &&
            approvedQuantity != null &&
            approvedQuantity > 0) {
          payload['part_id'] = approvedPartId.toString();
          payload['quantity'] = approvedQuantity.toString();
        }
        return payload;
      }

      final Map<String, dynamic> payload = <String, dynamic>{
        'name': name,
        'status': apiStatus,
        if (report.isNotEmpty) 'report': report,
        if (issueImage != null) 'images': <File>[issueImage],
      };

      if (apiStatus == 'stock_in_hand') {
        if (resolvedPartId != null && resolvedQuantity != null) {
          payload['part_id'] = resolvedPartId.toString();
          payload['quantity'] = resolvedQuantity.toString();
        }
      }

      return payload;
    });
  }

  Future<void> _submitDiagnosisReport() async {
    if (_isSubmittingDiagnosis) return;

    final serviceRequestId = _serviceRequestIdForApi();
    final productId = _productIdForApi();
    final report = _writtenReportText.trim();

    if (serviceRequestId.isEmpty || productId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Missing service request/product id. Please reopen from product detail.',
          ),
        ),
      );
      return;
    }

    if (report.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write report before submitting.')),
      );
      return;
    }

    final String? invalidApprovedPartData =
        _firstMarkedUsedDiagnosisMissingApiPartData();
    if (invalidApprovedPartData != null) {
      _showMessageSnackBar(
        'Approved part data missing from API for "$invalidApprovedPartData". Please refresh and try again.',
      );
      return;
    }

    final String? invalidDiagnosis = _firstDiagnosisWithoutStockItems();
    if (invalidDiagnosis != null) {
      setState(() {
        _expandedItems[invalidDiagnosis] = true;
      });
      _showMessageSnackBar('At least one stock item is required');
      return;
    }

    final diagnosisPayload = _buildDiagnosisSubmitPayload();
    if (diagnosisPayload.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No diagnosis items to submit.')),
      );
      return;
    }

    setState(() {
      _isSubmittingDiagnosis = true;
    });

    try {
      final response = await ApiService.submitServiceRequestDiagnosis(
        serviceRequestId: serviceRequestId,
        productId: productId,
        roleId: widget.roleId,
        diagnosisList: diagnosisPayload,
        defaultReport: report,
        beforePhoto: _beforeImage,
        afterPhoto: _afterImage,
      );

      if (!mounted) return;

      final String message =
          response.message?.trim().isNotEmpty == true
          ? response.message!.trim()
          : (response.success
                ? 'Diagnosis submitted successfully.'
                : 'Failed to submit diagnosis.');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: response.success ? primaryGreen : Colors.red,
        ),
      );

      if (response.success) {
        _itemPartUsed.clear();
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.FieldExecutiveAllProductsScreen,
          (route) => false,
          arguments: fieldexecutiveallproductsArguments(
            roleId: widget.roleId,
            roleName: widget.roleName,
            flow: widget.flow,
            controller: widget.controller,
            serviceRequestId: _serviceRequestIdForApi(),
          ),
        );
        return;
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit diagnosis: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingDiagnosis = false;
        });
      } else {
        _isSubmittingDiagnosis = false;
      }
    }
  }

  Future<void> _showNotWorkingDialog(String title) async {
    final DiagnosisItem? diagnosis = _findDiagnosisByName(title);
    String notes = _itemProblemSolution[title] ?? diagnosis?.report ?? '';
    final String initialStatus = _normalizeStatusLabel(
      _itemSelectedAction[title] ?? _itemStatus[title] ?? diagnosis?.statusLabel,
    );
    String? selectedOption = _isNonWorkingStatus(initialStatus)
        ? initialStatus
        : null;
    File? selectedImage = _itemIssueImage[title];
    bool isPickingImage = false;

    final _NotWorkingDialogResult? result =
        await showDialog<_NotWorkingDialogResult>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickIssueImage(ImageSource source) async {
              if (isPickingImage) return;
              setDialogState(() {
                isPickingImage = true;
              });
              try {
                final XFile? picked = await _picker.pickImage(
                  source: source,
                  imageQuality: 70,
                );
                if (picked != null && dialogContext.mounted) {
                  setDialogState(() {
                    selectedImage = File(picked.path);
                  });
                }
              } catch (e) {
                debugPrint('Error picking issue image: $e');
              } finally {
                if (dialogContext.mounted) {
                  setDialogState(() {
                    isPickingImage = false;
                  });
                }
              }
            }

            Future<void> showIssueImagePicker() async {
              final ImageSource? source = await _showImageSourcePickerBottomSheet(
                dialogContext,
              );
              if (source != null) {
                await pickIssueImage(source);
              }
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Write problem and solution',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: notes,
                        onChanged: (value) {
                          notes = value;
                        },
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: 'Write problem and solution',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: showIssueImagePicker,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.camera_alt, color: primaryGreen),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Photo',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Icon(Icons.arrow_forward, color: primaryGreen),
                            ],
                          ),
                        ),
                      ),
                      if (selectedImage != null) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            selectedImage!,
                            width: 110,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                      if (isPickingImage)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: LinearProgressIndicator(color: primaryGreen),
                        ),
                      const SizedBox(height: 16),
                      ..._notWorkingOptions.map(
                        (option) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildActionOptionTile(
                            label: option,
                            isSelected: selectedOption == option,
                            onTap: () {
                              setDialogState(() {
                                selectedOption = option;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: selectedOption == null
                            ? null
                            : () {
                                Navigator.pop(
                                  dialogContext,
                                  _NotWorkingDialogResult(
                                    selectedOption: selectedOption!,
                                    notes: notes.trim(),
                                    selectedImage: selectedImage,
                                  ),
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          disabledBackgroundColor: Colors.grey.shade300,
                          disabledForegroundColor: Colors.grey.shade600,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Continue',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted || result == null) return;

    final bool hadExistingStock = _hasSelectedStockItems(title);
    List<SelectedStockItem>? selectedStockItems;
    if (result.selectedOption == 'Use Stock in Hand') {
      selectedStockItems = await _openStockInHandSelection(title);
      if (!mounted) return;
      if (selectedStockItems == null) {
        return;
      }
      final List<SelectedStockItem> mergedItems = _mergeSelectedStockItems(
        existingItems: _itemSelectedStockItems[title] ??
            const <SelectedStockItem>[],
        incomingItems: selectedStockItems,
      );
      if (mergedItems.isEmpty) {
        _showMessageSnackBar('At least one stock item is required');
        return;
      }
      selectedStockItems = mergedItems;
    }
    final List<SelectedStockItem> selectedStockItemsValue =
        selectedStockItems ?? const <SelectedStockItem>[];
    final bool shouldAutoClearStock =
        result.selectedOption != 'Use Stock in Hand' && hadExistingStock;

    setState(() {
      _itemStatus[title] = result.selectedOption;
      _itemSelectedAction[title] = result.selectedOption;
      if (result.notes.isEmpty) {
        _itemProblemSolution.remove(title);
      } else {
        _itemProblemSolution[title] = result.notes;
      }
      if (result.selectedImage == null) {
        _itemIssueImage.remove(title);
      } else {
        _itemIssueImage[title] = result.selectedImage!;
      }
      if (result.selectedOption == 'Use Stock in Hand') {
        if (selectedStockItemsValue.isEmpty) {
          _itemSelectedStockItems.remove(title);
        } else {
          _itemSelectedStockItems[title] = selectedStockItemsValue;
        }
      } else {
        _itemSelectedStockItems.remove(title);
      }
      _expandedItems[title] = false;
    });

    if (shouldAutoClearStock) {
      _showMessageSnackBar('Stock selection cleared due to status change');
    }
  }

  Widget _buildActionOptionTile({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    const Color activeColor = Colors.red;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.red.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeColor : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? activeColor : Colors.grey.shade500,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? activeColor : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInlineQuantityButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: primaryGreen,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(
            icon,
            size: 18,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildInlineStockItemsEditor({
    required String diagnosisName,
    required List<SelectedStockItem> items,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selected Stock Items',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: primaryGreen,
            ),
          ),
          const SizedBox(height: 6),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'No stock items selected.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
            )
          else
            ...items.map(
              (item) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade100),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.productName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildInlineQuantityButton(
                      icon: Icons.remove,
                      onTap: () {
                        _changeInlineStockQuantity(
                          diagnosisName: diagnosisName,
                          item: item,
                          delta: -1,
                        );
                      },
                    ),
                    Container(
                      width: 30,
                      alignment: Alignment.center,
                      child: Text(
                        item.quantity.toString(),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _buildInlineQuantityButton(
                      icon: Icons.add,
                      onTap: () {
                        _changeInlineStockQuantity(
                          diagnosisName: diagnosisName,
                          item: item,
                          delta: 1,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _onAddMoreProductsPressed(diagnosisName),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryGreen,
                side: BorderSide(color: Colors.green.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              icon: const Icon(Icons.add_shopping_cart_outlined, size: 18),
              label: const Text(
                'Add more products',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String statusLabel, {required bool isWorking}) {
    final Color color = isWorking ? primaryGreen : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        statusLabel,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPartStatusBadge(String partStatus) {
    late final Color color;
    late final String label;

    switch (partStatus) {
      case 'waiting_for_approval':
        color = Colors.orange;
        label = 'Waiting for approval';
        break;
      case 'used':
        color = primaryGreen;
        label = 'Part Used';
        break;
      case 'customer_approved':
        color = primaryGreen;
        label = 'Customer Approved';
        break;
      default:
        color = Colors.blueGrey;
        label = partStatus;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildChecklistItem(DiagnosisItem diagnosis) {
    final String title = diagnosis.name;
    final bool isExpanded = _expandedItems[title] ?? false;
    final String statusLabel = _resolvedStatusLabel(diagnosis);
    final String partStatus = _normalizePartStatus(diagnosis.partStatus);
    final bool isMarkedPartUsed = _itemPartUsed[title] == true;
    final bool hasStatus = statusLabel.isNotEmpty;
    final bool isWorking = _isWorkingStatus(statusLabel);
    final bool isNonWorking = _isNonWorkingStatus(statusLabel);
    final bool isUseStockInHand = _isUseStockInHandStatus(statusLabel);
    final bool isWaitingForApproval = partStatus == 'waiting_for_approval';
    final bool isCustomerApproved = partStatus == 'customer_approved';
    final bool isPartUsed = partStatus == 'used';
    final bool isLockedForStatusChange =
        isWaitingForApproval || isPartUsed || isMarkedPartUsed;
    final bool canMarkAsUsed =
        isCustomerApproved && !isMarkedPartUsed;
    final String? reportText = _resolvedReportText(diagnosis);
    final File? issueImage = _itemIssueImage[title];
    final List<SelectedStockItem> selectedStockItems =
        _sanitizeSelectedStockItems(
      _itemSelectedStockItems[title] ?? const <SelectedStockItem>[],
    );

    Color circleColor = Colors.grey.shade200;
    Widget? circleIcon;

    if (isWorking) {
      circleColor = primaryGreen;
      circleIcon = const Icon(Icons.check, size: 16, color: Colors.white);
    } else if (isNonWorking) {
      circleColor = Colors.red;
      circleIcon = const Icon(Icons.close, size: 16, color: Colors.white);
    }

    return Column(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _expandedItems[title] = !isExpanded;
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: circleColor,
                  ),
                  child: circleIcon,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (reportText != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            reportText,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      if (isUseStockInHand ||
                          isWaitingForApproval ||
                          isCustomerApproved ||
                          isPartUsed ||
                          isMarkedPartUsed)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (isUseStockInHand)
                                _buildStatusBadge(
                                  statusLabel.isEmpty
                                      ? 'Use Stock in Hand'
                                      : statusLabel,
                                  isWorking: true,
                                ),
                              if (isWaitingForApproval ||
                                  isCustomerApproved ||
                                  isPartUsed)
                                _buildPartStatusBadge(partStatus),
                              if (canMarkAsUsed)
                                OutlinedButton(
                                  onPressed: () {
                                    setState(() {
                                      _itemPartUsed[title] = true;
                                      debugPrint('MARK USED -> $title = ${_itemPartUsed[title]}');
                                    });
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: primaryGreen,
                                    side: BorderSide(color: Colors.green.shade300),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  child: const Text(
                                    'Mark as Used',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ),
                                
                              if (isMarkedPartUsed)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(color: Colors.green.shade200),
                                  ),
                                  child: Text(
                                    'Part will be marked as used on submit',
                                    style: TextStyle(
                                      color: Colors.green.shade800,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      if (isUseStockInHand &&
                          !isLockedForStatusChange &&
                          !isCustomerApproved)
                        _buildInlineStockItemsEditor(
                          diagnosisName: title,
                          items: selectedStockItems,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (hasStatus && !isUseStockInHand) ...[
                  _buildStatusBadge(
                    statusLabel,
                    isWorking: isWorking,
                  ),
                  const SizedBox(width: 8),
                ],
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: primaryGreen.withOpacity(0.7),
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
            child: Column(
              children: [
                if (!isLockedForStatusChange) ...[
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _showNotWorkingDialog(title),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isNonWorking
                                  ? Colors.red.shade50
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isNonWorking
                                    ? Colors.red
                                    : Colors.grey.shade200,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              isNonWorking ? statusLabel : 'Not Working',
                              style: TextStyle(
                                color: isNonWorking
                                    ? Colors.red
                                    : Colors.grey.shade500,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            final bool hadStockSelection = _hasSelectedStockItems(
                              title,
                            );
                            setState(() {
                              _itemStatus[title] = 'Working';
                              _itemSelectedAction.remove(title);
                              _itemProblemSolution.remove(title);
                              _itemIssueImage.remove(title);
                              _itemSelectedStockItems.remove(title);
                              _expandedItems[title] = false;
                            });
                            if (hadStockSelection) {
                              _showMessageSnackBar(
                                'Stock selection cleared due to status change',
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isWorking
                                  ? Colors.green.shade50
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isWorking
                                    ? primaryGreen
                                    : Colors.grey.shade200,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Working',
                              style: TextStyle(
                                color: isWorking
                                    ? primaryGreen
                                    : Colors.grey.shade500,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        if (issueImage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(
                issueImage,
                width: 110,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLargeButton({
    required VoidCallback? onPressed,
    required String label,
    IconData? icon,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey.shade300,
        disabledForegroundColor: Colors.grey.shade600,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

