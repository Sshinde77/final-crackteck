import 'package:flutter/material.dart';
import '../../model/field executive/field_executive_product_service.dart';
import '../../model/field executive/field_executive_service_request_detail.dart';
import '../../routes/app_routes.dart';
import '../../constants/api_constants.dart';
import '../../services/api_service.dart';

enum CaseTransferStatus { none, pending }

class FieldExecutiveInstallationDetailScreen extends StatefulWidget {
  final int roleId;
  final String roleName;
  final String title;
  final String serviceId;
  final String location;
  final String priority;
  final String jobType; // 'installations' | 'repairs' | 'amc'

  const FieldExecutiveInstallationDetailScreen({
    super.key,
    required this.roleId,
    required this.roleName,
    required this.title,
    required this.serviceId,
    required this.location,
    required this.priority,
    this.jobType = 'installations',
  });

  @override
  State<FieldExecutiveInstallationDetailScreen> createState() => _FieldExecutiveInstallationDetailScreenState();
}

class _FieldExecutiveInstallationDetailScreenState extends State<FieldExecutiveInstallationDetailScreen> {
  bool isAccepted = false;
  bool _isAccepting = false;
  bool _isRescheduling = false;
  String _serviceRequestStatus = '';
  DateTime? selectedDate;
  CaseTransferStatus caseTransferStatus = CaseTransferStatus.none;
  bool _isLoadingDetail = true;
  String? _detailError;
  Map<String, dynamic>? _detailData;
  static const primaryGreen = Color(0xFF1E7C10);

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoadingDetail = true;
      _detailError = null;
    });

    try {
      final detail = await ApiService.fetchServiceRequestDetail(
        widget.serviceId,
        roleId: widget.roleId,
      );
      if (!mounted) return;
      final status = _extractServiceRequestStatus(detail);
      setState(() {
        _detailData = detail;
        _serviceRequestStatus = status;
        isAccepted = isAccepted || _isEngineerApprovedStatus(status);
        _isLoadingDetail = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _detailError = e.toString();
        _isLoadingDetail = false;
      });
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _serviceRequestDbIdForApi() {
    final fromDetail = _readFromMap(
      _detailData,
      const ['id', 'service_request_id'],
    );
    if (fromDetail.isNotEmpty) {
      return fromDetail.replaceFirst(RegExp(r'^#'), '').trim();
    }
    return widget.serviceId.replaceFirst(RegExp(r'^#'), '').trim();
  }

  Future<void> _acceptServiceRequest() async {
    if (_isAccepting) return;

    final serviceRequestId = _serviceRequestDbIdForApi();
    if (int.tryParse(serviceRequestId) == null) {
      _snack('Service request id is invalid for accept API');
      return;
    }

    setState(() {
      _isAccepting = true;
    });

    final response = await ApiService.acceptServiceRequest(
      serviceRequestId,
      roleId: widget.roleId,
    );

    if (!mounted) return;
    setState(() {
      _isAccepting = false;
      if (response.success) {
        isAccepted = true;
      }
    });

    _snack(
      response.message ??
          (response.success
              ? 'Service request accepted'
              : 'Failed to accept service request'),
    );
  }

  String _extractServiceRequestStatus(Map<String, dynamic>? raw) {
    if (raw == null) return '';

    final rootStatus = _readFromMap(raw, const ['status']);
    if (rootStatus.isNotEmpty) return rootStatus;

    final requestMap = _asMap(raw['service_request']) ??
        _asMap(raw['request']) ??
        _asMap(raw['service']);
    return _readFromMap(requestMap, const ['status']);
  }

  bool _isEngineerApprovedStatus(String status) {
    return status.trim().toLowerCase() == 'engineer_approved';
  }

  bool get _isRequestAccepted =>
      isAccepted || _isEngineerApprovedStatus(_serviceRequestStatus);

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  String _readFromMap(
    Map<String, dynamic>? source,
    List<String> keys, {
    String fallback = '',
  }) {
    if (source == null) return fallback;
    for (final key in keys) {
      final value = source[key];
      if (value == null) continue;
      if (value is Map || value is List) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return fallback;
  }

  String _field(List<String> keys, {String fallback = ''}) {
    final direct = _readFromMap(_detailData, keys);
    if (direct.isNotEmpty) return direct;

    final customer = _asMap(_detailData?['customer']) ??
        _asMap(_detailData?['customer_details']) ??
        _asMap(_detailData?['user']);
    final customerValue = _readFromMap(customer, keys);
    if (customerValue.isNotEmpty) return customerValue;

    final product =
        _asMap(_detailData?['product']) ?? _asMap(_detailData?['service']);
    final productValue = _readFromMap(product, keys);
    if (productValue.isNotEmpty) return productValue;

    return fallback;
  }

  String _normalizeServiceId(String raw) {
    final cleaned = raw.trim();
    if (cleaned.isEmpty || cleaned == '-') return '-';
    return cleaned.startsWith('#') ? cleaned : '#$cleaned';
  }

  String _normalizePriority(String raw) {
    final value = raw.trim().toLowerCase();
    if (value.contains('high') || value == '1' || value == 'urgent') {
      return 'High';
    }
    if (value.contains('low') || value == '3') {
      return 'Low';
    }
    return 'Medium';
  }

  String _normalizeServiceType(String raw) {
    final value = raw.trim().toLowerCase();
    if (value.isEmpty) return '';
    if (value == '1' ||
        value == 'installation' ||
        value == 'installations') {
      return 'Installation';
    }
    if (value == '2' || value == 'repair' || value == 'repairs') {
      return 'Repair';
    }
    if (value == '3' || value == 'amc') {
      return 'AMC';
    }
    if (value == '4' ||
        value == 'quick_service' ||
        value == 'quick service' ||
        value == 'quickservice') {
      return 'Quick Service';
    }
    return raw.trim();
  }

  String _maskPhoneNumber(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty || raw.trim() == '-') return '-';
    if (digits.length <= 4) return '****';
    final maskedLength = digits.length - 4;
    return '${'*' * maskedLength}${digits.substring(maskedLength)}';
  }

  void _addUrl(List<String> urls, dynamic value) {
    if (value == null) return;
    if (value is String) {
      final normalized = _normalizeImageSource(value);
      if (normalized.isEmpty) return;
      if (!urls.contains(normalized)) urls.add(normalized);
      return;
    }
    if (value is List) {
      for (final item in value) {
        _addUrl(urls, item);
      }
      return;
    }
    final map = _asMap(value);
    if (map == null) return;
    for (final key in const [
      'url',
      'image',
      'image_url',
      'path',
      'file',
      'src',
      'thumbnail',
      'thumb',
    ]) {
      _addUrl(urls, map[key]);
    }
  }

  bool _looksLikeHtml(String raw) {
    final value = raw.trimLeft().toLowerCase();
    return value.startsWith('<!doctype html') || value.startsWith('<html');
  }

  String _normalizeImageSource(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return '';
    if (value.toLowerCase() == 'null') return '';
    if (_looksLikeHtml(value)) return '';
    if (value.startsWith('data:image/')) return value;
    if (value.contains('<') && value.contains('>')) return '';

    final parsed = Uri.tryParse(value);
    if (parsed != null && parsed.hasScheme) {
      final scheme = parsed.scheme.toLowerCase();
      if (scheme == 'http' || scheme == 'https') return parsed.toString();
      return '';
    }

    final base = Uri.parse(ApiConstants.baseUrl);
    final origin = Uri(
      scheme: base.scheme,
      host: base.host,
      port: base.hasPort ? base.port : null,
    );

    final relative = value.startsWith('//')
        ? Uri.parse('https:$value')
        : value.startsWith('/')
            ? Uri.parse(value)
            : Uri.parse('/$value');

    return origin.resolveUri(relative).toString();
  }

  Widget _buildImageFallback({
    IconData icon = Icons.image_not_supported,
    double iconSize = 40,
  }) {
    return Container(
      color: Colors.grey.shade100,
      alignment: Alignment.center,
      child: Icon(icon, color: Colors.grey.shade500, size: iconSize),
    );
  }

  List<Map<String, dynamic>> get _productMaps {
    final products = <Map<String, dynamic>>[];

    void collectProducts(dynamic node) {
      if (node == null) return;
      final map = _asMap(node);
      if (map != null) {
        products.add(map);
        return;
      }
      if (node is List) {
        for (final item in node) {
          collectProducts(item);
        }
      }
    }

    for (final key in const [
      'products',
      'product',
      'product_detail',
      'product_details',
      'service_products',
      'service_product',
      'items',
      'item',
      'service',
    ]) {
      collectProducts(_detailData?[key]);
    }

    final unique = <String>{};
    final deduped = <Map<String, dynamic>>[];
    for (final product in products) {
      final identity =
          '${product['id']}-${product['product_id']}-${product['product_code']}-${product['sku']}-${product['name']}-${product['product_name']}';
      if (unique.add(identity)) {
        deduped.add(product);
      }
    }
    return deduped;
  }

  Map<String, dynamic>? get _customerMap =>
      _asMap(_detailData?['customer']) ??
      _asMap(_detailData?['customer_details']) ??
      _asMap(_detailData?['user']) ??
      _asMap(_detailData?['lead_details']);

  Map<String, dynamic>? get _productMap => _productMaps.isEmpty ? null : _productMaps.first;

  String _readProductField(List<String> keys, {String fallback = ''}) {
    final productValue = _readFromMap(_productMap, keys);
    if (productValue.isNotEmpty) return productValue;
    return _field(keys, fallback: fallback);
  }

  String _formatDateMaybe(String raw) {
    if (raw.trim().isEmpty) return '';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return '${parsed.day.toString().padLeft(2, '0')} ${_getMonthName(parsed.month)}';
  }

  String get _title => _field(
        const ['title', 'service_name', 'service_title', 'name', 'issue', 'problem'],
        fallback: widget.title,
      );
  String get _description => _field(
        const ['description', 'details', 'notes', 'remark', 'remarks'],
        fallback: widget.jobType == 'repairs'
            ? 'Visit charge of Rs 159 waived in final bill; spare part / repair cost extra. Technician will diagnose and provide repair estimate.'
            : 'Visit charge of Rs 159 waived in final bill; spare part / repair cost extra',
      );
  String get _requestId => _field(
        const ['request_id', 'requestId', 'service_id', 'serviceId', 'ticket_no', 'id'],
        fallback: widget.serviceId,
      );
  String get _serviceId => _normalizeServiceId(
        _field(
          const ['service_id', 'serviceId', 'request_id', 'id', 'ticket_no'],
          fallback: widget.serviceId,
        ),
      );
  String get _location =>
      _field(const ['location', 'city', 'area'], fallback: widget.location);
  FieldExecutiveServiceRequestDetail? get _detailModel {
    final detail = _detailData;
    if (detail == null) return null;
    return FieldExecutiveServiceRequestDetail.fromJson(detail);
  }

  String get _formattedCustomerAddress {
    final detailModel = _detailModel;
    final addressId = detailModel?.customerAddressId ?? '';
    if (addressId.trim().isEmpty) {
      return 'Address Not Available';
    }

    final address = detailModel?.customerAddress;
    if (address == null || !address.hasData) {
      return 'Address Not Available';
    }

    final formatted = address.formattedMultiline.trim();
    if (formatted.isEmpty) {
      return 'Address Not Available';
    }

    return formatted;
  }

  String get _priority => _normalizePriority(
        _field(
          const ['priority', 'priority_level', 'urgency'],
          fallback: widget.priority,
        ),
      );
  String get _imageUrl => _field(
        const ['image_url', 'image', 'service_image', 'product_image'],
        fallback: '',
      );
  String get _customerName {
    final firstName = _readFromMap(
      _customerMap,
      const ['first_name', 'firstName', 'firstname'],
    );
    final lastName = _readFromMap(
      _customerMap,
      const ['last_name', 'lastName', 'lastname'],
    );

    final fullName = [firstName, lastName]
        .where((part) => part.trim().isNotEmpty)
        .join(' ')
        .trim();
    if (fullName.isNotEmpty) return fullName;

    final rootFirstName = _readFromMap(
      _detailData,
      const ['first_name', 'firstName', 'firstname'],
    );
    final rootLastName = _readFromMap(
      _detailData,
      const ['last_name', 'lastName', 'lastname'],
    );
    final rootFullName = [rootFirstName, rootLastName]
        .where((part) => part.trim().isNotEmpty)
        .join(' ')
        .trim();
    if (rootFullName.isNotEmpty) return rootFullName;

    final fallback = _field(
      const ['customer_name', 'full_name', 'name'],
      fallback: '-',
    );
    return fallback.trim().isEmpty ? '-' : fallback;
  }
  String get _customerNumber => _field(
        const ['customer_phone', 'customer_number', 'phone', 'mobile', 'phone_number', 'contact_number'],
        fallback: '-',
      );
  String get _customerNumberForDisplay =>
      _isRequestAccepted ? _customerNumber : _maskPhoneNumber(_customerNumber);
  String get _serviceType =>
      _normalizeServiceType(
        _field(
          const ['service_type', 'serviceType', 'service_type_name', 'type'],
          fallback: widget.jobType,
        ),
      );
  String get _productTitle => _readProductField(
        const ['product_name', 'name', 'title', 'service_name'],
        fallback: _title,
      );
  String get _productBrand =>
      _readProductField(const ['brand', 'brand_name', 'company', 'make']);
  String get _productModel =>
      _readProductField(const ['model', 'model_name', 'variant']);
  String get _productCode => _readProductField(
        const ['product_code', 'sku', 'serial_number', 'product_id', 'id'],
      );
  String get _productLocation =>
      _readProductField(const ['location', 'city', 'area'], fallback: _location);
  bool get _hasMultipleProducts => _productMaps.length > 1;
  List<String> get _productImageUrls {
    final urls = <String>[];

    for (final product in _productMaps) {
      for (final key in const [
        'images',
        'product_images',
        'gallery',
        'photos',
        'media',
        'attachments',
        'product_image',
        'image_url',
        'image',
        'thumbnail',
      ]) {
        _addUrl(urls, product[key]);
      }
    }

    return urls.take(20).toList();
  }

  List<String> get _attachmentMediaUrls {
    final urls = <String>[];
    for (final key in const [
      'images',
      'photos',
      'media',
      'attachments',
      'before_images',
      'after_images',
      'videos',
    ]) {
      _addUrl(urls, _detailData?[key]);
    }
    return urls.take(20).toList();
  }

  String get _heroImageUrl {
    if (_productImageUrls.isNotEmpty) return _productImageUrls.first;
    final normalizedImage = _normalizeImageSource(_imageUrl);
    if (normalizedImage.isNotEmpty) return normalizedImage;
    return '';
  }

  String get _productImage {
    if (_productImageUrls.isNotEmpty) return _productImageUrls.first;
    return _normalizeImageSource(
      _readProductField(
      const ['product_image', 'image_url', 'image', 'thumbnail'],
      fallback: _imageUrl,
      ),
    );
  }
  String get _productDetailText {
    final parts = <String>[
      if (_productBrand.isNotEmpty) _productBrand,
      if (_productModel.isNotEmpty) _productModel,
      if (_productCode.isNotEmpty) 'Code: $_productCode',
    ];
    if (parts.isNotEmpty) return parts.join(' | ');
    return _readProductField(
      const ['description', 'details', 'product_description'],
      fallback: _description,
    );
  }

  String get _schedule {
    final raw = _field(
      const ['schedule', 'scheduled_at', 'appointment', 'appointment_date_time'],
      fallback: '',
    );
    if (raw.isNotEmpty) return raw;
    final date = _field(
      const ['schedule_date', 'scheduled_date', 'date', 'visit_date'],
      fallback: '',
    );
    final time = _field(
      const ['schedule_time', 'scheduled_time', 'time', 'visit_time'],
      fallback: '',
    );
    final dateText = _formatDateMaybe(date);
    if (dateText.isEmpty && time.isEmpty) return 'Not scheduled';
    if (dateText.isEmpty) return time;
    if (time.isEmpty) return dateText;
    return '$dateText / $time';
  }

  List<String> get _mediaUrls {
    final productImages = _productImageUrls;
    if (productImages.length > 1) {
      return productImages.skip(1).toList();
    }
    if (productImages.length == 1) {
      return const [];
    }
    return _attachmentMediaUrls;
  }

  bool get _showMediaSection => _mediaUrls.isNotEmpty;

  Future<void> _selectDate(BuildContext context) async {
    if (_isRescheduling) return;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryGreen,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: primaryGreen,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedDate) {
      await _submitRescheduleDate(picked);
    }
  }

  Future<void> _submitRescheduleDate(DateTime pickedDate) async {
    final serviceRequestId = _serviceRequestDbIdForApi();
    if (int.tryParse(serviceRequestId) == null) {
      _snack('Service request id is invalid for reschedule API');
      return;
    }

    final formattedDate =
        '${pickedDate.year.toString().padLeft(4, '0')}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}';

    setState(() {
      _isRescheduling = true;
    });

    final response = await ApiService.rescheduleServiceRequest(
      serviceRequestId,
      roleId: widget.roleId,
      engineerReason: 'Not available',
      rescheduleDate: formattedDate,
    );

    if (!mounted) return;

    setState(() {
      _isRescheduling = false;
      if (response.success) {
        selectedDate = pickedDate;
      }
    });

    _snack(
      response.message ??
          (response.success
              ? 'Service request rescheduled successfully.'
              : 'Failed to reschedule request'),
    );

    if (response.success) {
      // Refresh detail so status/timeline stays in sync after reschedule.
      _loadDetail();
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(
    String title,
    String desc,
    String codeOrId,
    String location,
    String imageUrl,
  ) {
    final normalizedImage = _normalizeImageSource(imageUrl);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
            child: normalizedImage.isEmpty
                ? _buildImageFallback(icon: Icons.desktop_windows, iconSize: 26)
                : ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      normalizedImage,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _buildImageFallback(icon: Icons.desktop_windows, iconSize: 26),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(fontSize: 12, color: Colors.black54), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(codeOrId, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              Text(location, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageThumb(String url) {
    final normalized = _normalizeImageSource(url);
    if (normalized.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 100,
            height: 100,
            child: _buildImageFallback(iconSize: 28),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          normalized,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => SizedBox(
            width: 100,
            height: 100,
            child: _buildImageFallback(iconSize: 28),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroImage() {
    if (_heroImageUrl.isEmpty) {
      return _buildImageFallback();
    }

    return Image.network(
      _heroImageUrl,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => _buildImageFallback(),
    );
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
        title: Text(
          _serviceType.isEmpty ? 'Service details' : _serviceType,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: _isLoadingDetail
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                if (_detailError != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade100),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 18,
                          color: Colors.red.shade700,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Could not load latest details. Showing fallback data.',
                            style: TextStyle(fontSize: 12, color: Colors.black87),
                          ),
                        ),
                        TextButton(
                          onPressed: _loadDetail,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                // Product Image
                Center(
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: _buildHeroImage(),
                  ),
                ),
                const SizedBox(height: 20),

                // Title and Description
                Text(
                  _serviceType.isEmpty ? _title : _serviceType,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Request ID: $_requestId',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 16),
                const Divider(),

                // Customer Details
                _buildDetailRow('Customer Name', _customerName),
                _buildDetailRow('Customer Number', _customerNumberForDisplay),
                _buildDetailRow(
                  'Schedule',
                  selectedDate == null
                      ? _schedule
                      : '${selectedDate!.day.toString().padLeft(2, '0')} ${_getMonthName(selectedDate!.month)} / 10:00 AM',
                ),
                _buildDetailRow('Service Type', _serviceType),
                _buildDetailRow('Service ID', _serviceId),
                const Divider(),

                // Product Section with View All
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Product',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    if (_hasMultipleProducts)
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.FieldExecutiveAllProductsScreen,
                            arguments: fieldexecutiveallproductsArguments(
                              roleId: widget.roleId,
                              roleName: widget.roleName,
                              controller: FieldExecutiveProductServicesController.withDefaults(),
                            ),
                          );
                        },
                        label: const Text('View all product', style: TextStyle(color: primaryGreen)),
                        icon: const Icon(Icons.arrow_forward, color: primaryGreen, size: 16),
                        iconAlignment: IconAlignment.end,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildProductCard(
                  _productTitle,
                  _productDetailText,
                  _productCode.isEmpty ? _serviceId : _productCode,
                  _productLocation,
                  _productImage,
                ),
                const SizedBox(height: 16),
                const Divider(),

                // Photo's & Video
                if (_showMediaSection) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Photo\'s & Video',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        onPressed: () {},
                        label: const Text('View All', style: TextStyle(color: primaryGreen)),
                        icon: const Icon(Icons.arrow_forward, color: primaryGreen, size: 16),
                        iconAlignment: IconAlignment.end,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 100,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _mediaUrls.map(_buildImageThumb).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                ],

                // Location
                const Text(
                  'Location',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (_location.trim().isNotEmpty && _location.trim() != '-')
                  Text(
                    _location,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                const SizedBox(height: 4),
                Text(
                  _formattedCustomerAddress,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),

                // Go to location button (same for all job types)
                if (_isRequestAccepted) ...[
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.FieldExecutiveMapTrackingScreen,
                        arguments: fieldexecutivemaptrackingArguments(
                          roleId: widget.roleId,
                          roleName: widget.roleName,
                          serviceId: _serviceRequestDbIdForApi(),
                          customerName: _customerName == '-' ? '' : _customerName,
                          customerAddress:
                              _formattedCustomerAddress == 'Address Not Available'
                                  ? ''
                                  : _formattedCustomerAddress,
                          customerPhone: _customerNumber == '-' ? '' : _customerNumber,
                          displayServiceId: _serviceId,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.near_me_outlined, color: Colors.white),
                    label: const Text('Go to location', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                  const SizedBox(height: 16),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, -2),
              )
            ],
          ),
          // same accept / reschedule / case-transfer actions for all job types
          child: _isRequestAccepted
              ? (
                  // If pending, show only the pending container (no buttons)
                  caseTransferStatus == CaseTransferStatus.pending
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange.shade200),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Case transfer is pending. You will be notified once it is accepted by another executive.',
                                      style: const TextStyle(fontSize: 14, color: Colors.orange),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _isRescheduling ? null : () => _selectDate(context),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: selectedDate == null ? Colors.grey.shade100 : primaryGreen,
                                      minimumSize: const Size(double.infinity, 50),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      elevation: 0,
                                    ),
                                    child: _isRescheduling
                                        ? SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              color: selectedDate == null ? primaryGreen : Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Text(
                                            'Rescheduled',
                                            style: TextStyle(
                                              color: selectedDate == null ? primaryGreen : Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      // Navigate to Case Transfer screen and await result
                                      final result = await Navigator.pushNamed(
                                        context,
                                        AppRoutes.FieldExecutiveCaseTransferScreen,
                                        arguments: fieldexecutivecasetransferArguments(
                                          roleId: widget.roleId,
                                          roleName: widget.roleName,
                                          serviceId: _serviceRequestDbIdForApi(),
                                        ),
                                      );

                                      // If the case transfer screen returned true, mark as pending
                                      if (result == true) {
                                        setState(() {
                                          caseTransferStatus = CaseTransferStatus.pending;
                                        });
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryGreen,
                                      minimumSize: const Size(double.infinity, 50),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: const Text(
                                      'Case Transfer',
                                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                )
              : ElevatedButton(
                  onPressed: _isAccepting ? null : _acceptServiceRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isAccepting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Accept',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
                ),
              ),
            );
  }
}
