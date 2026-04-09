import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/api_service.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({
    super.key,
    required this.roleId,
    required this.roleName,
    this.title = 'Wallet',
  });

  final int roleId;
  final String roleName;
  final String title;

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  static const Color _primaryGreen = Color(0xFF1F8B00);
  static const Color _darkGreen = Color(0xFF145A00);

  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _entries = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _loadWalletEntries();
  }

  Future<void> _loadWalletEntries() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final entries = await ApiService.fetchCashReceivedList(roleId: widget.roleId);
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    final text = value.toString().replaceAll(RegExp(r'[^0-9.\-]'), '').trim();
    return double.tryParse(text) ?? 0;
  }

  String _readString(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value == null) continue;
      if (value is Map || value is List) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null') {
        return text;
      }
    }
    return '';
  }

  dynamic _readValue(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      if (map.containsKey(key) && map[key] != null) {
        return map[key];
      }
    }
    return null;
  }

  double _amountFor(Map<String, dynamic> entry) {
    return _toDouble(
      _readValue(entry, const [
        'amount',
        'cash_received_amount',
        'collected_amount',
        'cod_amount',
        'received_amount',
        'wallet_amount',
      ]),
    );
  }

  String _entryId(Map<String, dynamic> entry) {
    return _readString(entry, const ['id', 'cash_received_id', 'transaction_id']);
  }

  String _orderId(Map<String, dynamic> entry) {
    return _readString(
      entry,
      const ['order_id', 'order_no', 'invoice_no', 'reference_id'],
    );
  }

  Map<String, dynamic>? _readMap(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is Map) {
        return Map<String, dynamic>.from(value as Map);
      }
    }
    return null;
  }

  String _customerNameFor(Map<String, dynamic> entry) {
    final direct = _readString(entry, const ['customer_name', 'party_name', 'name']);
    if (direct.isNotEmpty) return direct;

    final customerMap = _readMap(
      entry,
      const ['customer', 'customer_detail', 'customer_details', 'party', 'user'],
    );
    if (customerMap == null) return '';

    return _readString(
      customerMap,
      const ['customer_name', 'party_name', 'name', 'full_name'],
    );
  }

  String _customerPhoneFor(Map<String, dynamic> entry) {
    final direct = _readString(
      entry,
      const ['customer_phone', 'customer_mobile', 'mobile', 'phone', 'phone_no'],
    );
    if (direct.isNotEmpty) return direct;

    final customerMap = _readMap(
      entry,
      const ['customer', 'customer_detail', 'customer_details', 'party', 'user'],
    );
    if (customerMap == null) return '';

    return _readString(
      customerMap,
      const [
        'mobile',
        'mobile_no',
        'phone',
        'phone_no',
        'contact',
        'contact_no',
      ],
    );
  }

  String _customerDisplayLine(Map<String, dynamic> entry) {
    final name = _customerNameFor(entry);
    final phone = _customerPhoneFor(entry);
    if (name.isEmpty && phone.isEmpty) return '';
    if (name.isNotEmpty && phone.isNotEmpty) return '$name • $phone';
    return name.isNotEmpty ? name : phone;
  }

  String _titleFor(Map<String, dynamic> entry) {
    final orderId = _orderId(entry);
    if (orderId.isNotEmpty) {
      return 'Order #$orderId';
    }

    final customer = _customerNameFor(entry);
    if (customer.isNotEmpty) {
      return customer;
    }

    final entryId = _entryId(entry);
    return entryId.isNotEmpty ? 'Payment #$entryId' : 'Cash Received';
  }

  String _subtitleFor(Map<String, dynamic> entry) {
    final method = _readString(
      entry,
      const ['payment_mode', 'payment_method', 'mode', 'type'],
    );
    final dateText = _formatDate(
      _readString(
        entry,
        const ['received_at', 'created_at', 'updated_at', 'date'],
      ),
    );

    if (method.isNotEmpty && dateText.isNotEmpty) {
      return '$method • $dateText';
    }
    if (method.isNotEmpty) return method;
    if (dateText.isNotEmpty) return dateText;
    return 'Tap to view detail';
  }

  Widget _buildEntrySubtitle(Map<String, dynamic> entry) {
    final orderId = _orderId(entry);
    final customerName = _customerNameFor(entry);
    final customerPhone = _customerPhoneFor(entry);
    final customerLine = orderId.isNotEmpty
        ? _customerDisplayLine(entry)
        : (customerName.isNotEmpty && customerPhone.isNotEmpty
            ? customerPhone
            : _customerDisplayLine(entry));
    final metaLine = _subtitleFor(entry);

    if (customerLine.isEmpty) {
      return Text(
        metaLine,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 12.5,
          color: Colors.black54,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          customerLine,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          metaLine,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  String _formatCurrency(dynamic value) {
    final amount = _toDouble(value);
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: 'Rs. ',
      decimalDigits: amount % 1 == 0 ? 0 : 2,
    ).format(amount);
  }

  String _formatDate(String raw) {
    if (raw.trim().isEmpty) return '';
    final parsed = DateTime.tryParse(raw.trim());
    if (parsed == null) return raw;
    return DateFormat('dd MMM yyyy, hh:mm a').format(parsed.toLocal());
  }

  Future<void> _showWalletDetail(Map<String, dynamic> entry) async {
    final entryId = _entryId(entry);
    if (entryId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wallet detail is not available for this item.')),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _WalletDetailSheet(
          title: _titleFor(entry),
          fallbackData: entry,
          loadDetail: () => ApiService.fetchCashReceivedDetail(
            cashReceivedId: entryId,
            roleId: widget.roleId,
          ),
          formatCurrency: _formatCurrency,
          formatDate: _formatDate,
          readString: _readString,
          readValue: _readValue,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalAmount = _entries.fold<double>(
      0,
      (sum, entry) => sum + _amountFor(entry),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F3),
      appBar: AppBar(
        elevation: 0,
        title: Text(widget.title),
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[_primaryGreen, _darkGreen],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadWalletEntries,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[_primaryGreen, _darkGreen],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x26145A00),
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Cash Collected',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.92),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _formatCurrency(totalAmount),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${_entries.length} payment${_entries.length == 1 ? '' : 's'} received',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.88),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Received Payments',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _WalletErrorState(message: _error!, onRetry: _loadWalletEntries)
            else if (_entries.isEmpty)
              const _WalletEmptyState()
            else
              ..._entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => _showWalletDetail(entry),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE5E9DD)),
                      ),
                      child: Row(
                        children: <Widget>[
                          Container(
                            height: 46,
                            width: 46,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE9F7E5),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet_outlined,
                              color: _primaryGreen,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  _titleFor(entry),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                _buildEntrySubtitle(entry),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: <Widget>[
                              Text(
                                _formatCurrency(_amountFor(entry)),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: _primaryGreen,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Icon(
                                Icons.arrow_forward_ios,
                                size: 14,
                                color: Colors.black38,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WalletErrorState extends StatelessWidget {
  const _WalletErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6D6D6)),
      ),
      child: Column(
        children: <Widget>[
          const Icon(Icons.error_outline, size: 36, color: Colors.redAccent),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1F8B00),
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _WalletEmptyState extends StatelessWidget {
  const _WalletEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E9DD)),
      ),
      child: const Column(
        children: <Widget>[
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 40,
            color: Color(0xFF9AA58E),
          ),
          SizedBox(height: 12),
          Text(
            'No cash received entries found.',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 6),
          Text(
            'Pull down to refresh after new COD payments are recorded.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _WalletDetailSheet extends StatefulWidget {
  const _WalletDetailSheet({
    required this.title,
    required this.fallbackData,
    required this.loadDetail,
    required this.formatCurrency,
    required this.formatDate,
    required this.readString,
    required this.readValue,
  });

  final String title;
  final Map<String, dynamic> fallbackData;
  final Future<Map<String, dynamic>> Function() loadDetail;
  final String Function(dynamic value) formatCurrency;
  final String Function(String raw) formatDate;
  final String Function(Map<String, dynamic> map, List<String> keys) readString;
  final dynamic Function(Map<String, dynamic> map, List<String> keys) readValue;

  @override
  State<_WalletDetailSheet> createState() => _WalletDetailSheetState();
}

class _WalletDetailSheetState extends State<_WalletDetailSheet> {
  bool _isLoading = true;
  String? _error;
  late Map<String, dynamic> _detail;

  @override
  void initState() {
    super.initState();
    _detail = widget.fallbackData;
    _load();
  }

  Future<void> _load() async {
    try {
      final detail = await widget.loadDetail();
      if (!mounted) return;
      setState(() {
        if (detail.isNotEmpty) {
          _detail = detail;
        }
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic>? _readMap(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is Map) {
        return Map<String, dynamic>.from(value as Map);
      }
    }
    return null;
  }

  String _customerName() {
    final direct = widget.readString(
      _detail,
      const ['customer_name', 'party_name', 'name'],
    );
    if (direct.isNotEmpty) return direct;

    final customerMap = _readMap(
      _detail,
      const ['customer', 'customer_detail', 'customer_details', 'party', 'user'],
    );
    if (customerMap == null) return '';

    return widget.readString(
      customerMap,
      const ['customer_name', 'party_name', 'name', 'full_name'],
    );
  }

  String _customerPhone() {
    final direct = widget.readString(
      _detail,
      const ['customer_phone', 'customer_mobile', 'mobile', 'phone', 'phone_no'],
    );
    if (direct.isNotEmpty) return direct;

    final customerMap = _readMap(
      _detail,
      const ['customer', 'customer_detail', 'customer_details', 'party', 'user'],
    );
    if (customerMap == null) return '';

    return widget.readString(
      customerMap,
      const [
        'mobile',
        'mobile_no',
        'phone',
        'phone_no',
        'contact',
        'contact_no',
      ],
    );
  }

  String _customerAddress() {
    final direct = widget.readString(
      _detail,
      const ['customer_address', 'address', 'full_address'],
    );
    if (direct.isNotEmpty) return direct;

    final customerMap = _readMap(
      _detail,
      const ['customer', 'customer_detail', 'customer_details', 'party', 'user'],
    );
    if (customerMap == null) return '';

    final addressValue = customerMap['address'] ?? customerMap['full_address'];
    if (addressValue is String) {
      final text = addressValue.trim();
      return text.isNotEmpty && text.toLowerCase() != 'null' ? text : '';
    }
    if (addressValue is Map) {
      final addressMap = Map<String, dynamic>.from(addressValue as Map);
      final parts = <String>[
        widget.readString(
          addressMap,
          const ['address1', 'address_1', 'line1', 'street'],
        ),
        widget.readString(
          addressMap,
          const ['address2', 'address_2', 'line2', 'area'],
        ),
        widget.readString(addressMap, const ['city']),
        widget.readString(addressMap, const ['state']),
        widget.readString(
          addressMap,
          const ['pincode', 'pin_code', 'zip', 'postal_code'],
        ),
      ].where((part) => part.trim().isNotEmpty).toList();
      return parts.join(', ');
    }

    return '';
  }

  String _customerDetailText() {
    return <String>[
      _customerName(),
      _customerPhone(),
      _customerAddress(),
    ].where((text) => text.trim().isNotEmpty).join('\n');
  }

  List<_DetailRowData> _rows() {
    final rows = <_DetailRowData>[
      _DetailRowData(
        label: 'Amount',
        value: widget.formatCurrency(
          widget.readValue(
            _detail,
            const [
              'amount',
              'cash_received_amount',
              'collected_amount',
              'cod_amount',
              'received_amount',
            ],
          ),
        ),
      ),
      _DetailRowData(
        label: 'Order ID',
        value: widget.readString(
          _detail,
          const ['order_id', 'order_no', 'invoice_no', 'reference_id'],
        ),
      ),
      _DetailRowData(
        label: 'Customer',
        value: _customerDetailText(),
      ),
      _DetailRowData(
        label: 'Payment Mode',
        value: widget.readString(
          _detail,
          const ['payment_mode', 'payment_method', 'mode', 'type'],
        ),
      ),
      _DetailRowData(
        label: 'Received At',
        value: widget.formatDate(
          widget.readString(
            _detail,
            const ['received_at', 'created_at', 'updated_at', 'date'],
          ),
        ),
      ),
      _DetailRowData(
        label: 'Status',
        value: widget.readString(
          _detail,
          const ['status', 'payment_status', 'received_status'],
        ),
      ),
      _DetailRowData(
        label: 'Reference',
        value: widget.readString(
          _detail,
          const ['reference_no', 'transaction_no', 'transaction_id', 'id'],
        ),
      ),
      _DetailRowData(
        label: 'Notes',
        value: widget.readString(
          _detail,
          const ['notes', 'remark', 'remarks', 'description'],
        ),
      ),
    ];

    return rows.where((row) => row.value.trim().isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 52,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD7D7D7),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        children: <Widget>[
                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ...rows.map(
                            (row) => Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7F8F6),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  SizedBox(
                                    width: 110,
                                    child: Text(
                                      row.label,
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      row.value,
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRowData {
  const _DetailRowData({required this.label, required this.value});

  final String label;
  final String value;
}
