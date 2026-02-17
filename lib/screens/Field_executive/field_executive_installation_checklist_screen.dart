import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../model/field executive/field_executive_product_service.dart';
import '../../routes/app_routes.dart';
import '../../services/api_service.dart';
import 'field_executive_add_product.dart';

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
  final ImagePicker _picker = ImagePicker();
  File? _beforeImage;
  bool _isPickingBeforeImage = false;
  File? _afterImage;
  bool _isPickingAfterImage = false;
  bool _isLoadingDiagnosis = false;
  String? _diagnosisError;
  List<String> _diagnosisItems = const <String>[];

  // Track which items are expanded
  final Map<String, bool> _expandedItems = {};

  // Track status of each item (Working / Not Working)
  final Map<String, String?> _itemStatus = {};

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

  void _syncChecklistStateForDiagnosis(List<String> diagnosisItems) {
    final keys = diagnosisItems.toSet();
    _expandedItems.removeWhere((key, _) => !keys.contains(key));
    _itemStatus.removeWhere((key, _) => !keys.contains(key));
  }

  Future<void> _loadDiagnosisList() async {
    final serviceRequestId = _serviceRequestIdForApi();
    final productId = _productIdForApi();

    if (serviceRequestId.isEmpty || productId.isEmpty) {
      setState(() {
        _diagnosisItems = const <String>[];
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

  Future<void> _pickImage() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 50,
      );
      if (photo != null) {
        debugPrint("Photo picked: ${photo.path}");
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
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
              _buildLargeButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.FieldExecutiveWriteReportScreen,
                    arguments: fieldexecutivewritereportArguments(
                      roleId: widget.roleId,
                      roleName: widget.roleName,
                      serviceId: widget.serviceId,
                      flow: widget.flow,
                      controller: widget.controller,
                    ),
                  );
                },
                label: 'Write Report',
              ),
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

  List<String> get _effectiveDiagnosisItems {
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

  void _showStatusDetailsDialog(String title, String status) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Write problems and solutions',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  maxLines: 5,
                  decoration: InputDecoration(
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
                  onTap: _pickImage,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                if (status == 'Not Working') ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Add To Pick-Up',
                            style: TextStyle(color: Colors.black87),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddProductScreen(
                                  roleId: widget.roleId,
                                  roleName: widget.roleName,
                                ),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Request Part',
                            style: TextStyle(color: primaryGreen),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _itemStatus[title] = status;
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
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
        );
      },
    );
  }

  Widget _buildChecklistItem(String title) {
    bool isExpanded = _expandedItems[title] ?? false;
    String? status = _itemStatus[title];

    Color circleColor = Colors.grey.shade200;
    Widget? circleIcon;

    if (status == 'Working') {
      circleColor = primaryGreen;
      circleIcon = const Icon(Icons.check, size: 16, color: Colors.white);
    } else if (status == 'Not Working') {
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
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
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
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showStatusDetailsDialog(title, 'Not Working'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: status == 'Not Working'
                            ? Colors.red.shade50
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: status == 'Not Working'
                              ? Colors.red
                              : Colors.grey.shade200,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Not Working',
                        style: TextStyle(
                          color: status == 'Not Working'
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
                    onTap: () => _showStatusDetailsDialog(title, 'Working'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: status == 'Working'
                            ? Colors.green.shade50
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: status == 'Working'
                              ? primaryGreen
                              : Colors.grey.shade200,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Working',
                        style: TextStyle(
                          color: status == 'Working'
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
          ),
      ],
    );
  }

  Widget _buildLargeButton({
    required VoidCallback onPressed,
    required String label,
    IconData? icon,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
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
