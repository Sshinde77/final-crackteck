class CustomerAddress {
  final String? id;
  final String branchName;
  final String address1;
  final String address2;
  final String city;
  final String state;
  final String country;
  final String pincode;

  const CustomerAddress({
    this.id,
    this.branchName = '',
    this.address1 = '',
    this.address2 = '',
    this.city = '',
    this.state = '',
    this.country = '',
    this.pincode = '',
  });

  factory CustomerAddress.fromJson(Map<String, dynamic> json) {
    String read(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value == null) continue;
        final text = value.toString().trim();
        if (text.isNotEmpty && text.toLowerCase() != 'null') {
          return text;
        }
      }
      return '';
    }

    return CustomerAddress(
      id: read(const ['id', 'address_id', 'customer_address_id']),
      branchName: read(const ['branch_name', 'branchName']),
      address1: read(const ['address1', 'address_1', 'address_line_1', 'line1']),
      address2: read(const ['address2', 'address_2', 'address_line_2', 'line2']),
      city: read(const ['city', 'city_name']),
      state: read(const ['state', 'state_name']),
      country: read(const ['country', 'country_name']),
      pincode: read(const ['pincode', 'pin_code', 'postal_code', 'zip']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null && id!.trim().isNotEmpty) 'id': id,
      'branch_name': branchName,
      'address1': address1,
      'address2': address2,
      'city': city,
      'state': state,
      'country': country,
      'pincode': pincode,
    };
  }

  bool get hasData {
    return branchName.trim().isNotEmpty ||
        address1.trim().isNotEmpty ||
        address2.trim().isNotEmpty ||
        city.trim().isNotEmpty ||
        state.trim().isNotEmpty ||
        country.trim().isNotEmpty ||
        pincode.trim().isNotEmpty;
  }

  String get formattedMultiline {
    final lines = <String>[];

    if (branchName.trim().isNotEmpty) {
      lines.add(branchName.trim());
    }

    final addressLine = <String>[
      address1.trim(),
      address2.trim(),
    ].where((value) => value.isNotEmpty).join(', ');
    if (addressLine.isNotEmpty) {
      lines.add(addressLine);
    }

    final cityStateCountry = <String>[
      city.trim(),
      state.trim(),
      country.trim(),
    ].where((value) => value.isNotEmpty).join(', ');

    String lastLine = cityStateCountry;
    if (pincode.trim().isNotEmpty) {
      if (lastLine.isEmpty) {
        lastLine = pincode.trim();
      } else {
        lastLine = '$lastLine - ${pincode.trim()}';
      }
    }

    if (lastLine.isNotEmpty) {
      lines.add(lastLine);
    }

    return lines.join('\n');
  }
}

class FieldExecutiveServiceRequestDetail {
  final Map<String, dynamic> raw;
  final String? customerAddressId;
  final CustomerAddress? customerAddress;

  const FieldExecutiveServiceRequestDetail({
    required this.raw,
    this.customerAddressId,
    this.customerAddress,
  });

  factory FieldExecutiveServiceRequestDetail.fromJson(
    Map<String, dynamic> json,
  ) {
    final raw = Map<String, dynamic>.from(json);

    final requestMap = _asMap(raw['service_request']) ??
        _asMap(raw['request']) ??
        _asMap(raw['service']);
    final customerMap = _asMap(raw['customer']) ??
        _asMap(raw['customer_details']) ??
        _asMap(raw['user']);

    final addressId = _firstNonEmptyString([
      raw['customer_address_id'],
      raw['customerAddressId'],
      raw['address_id'],
      requestMap?['customer_address_id'],
      requestMap?['customerAddressId'],
      requestMap?['address_id'],
      customerMap?['customer_address_id'],
      customerMap?['customerAddressId'],
      customerMap?['address_id'],
    ]);

    final normalizedAddressId = _normalizeId(addressId);
    CustomerAddress? matchedAddress;

    if (normalizedAddressId.isNotEmpty) {
      matchedAddress = _findAddressById(
        normalizedAddressId,
        <dynamic>[
          raw['customer_address'],
          raw['customerAddress'],
          requestMap?['customer_address'],
          requestMap?['customerAddress'],
          customerMap?['customer_address'],
          customerMap?['customerAddress'],
          raw['customer_addresses'],
          raw['addresses'],
          customerMap?['customer_addresses'],
          customerMap?['addresses'],
        ],
      );
    }

    return FieldExecutiveServiceRequestDetail(
      raw: raw,
      customerAddressId: addressId.trim().isEmpty ? null : addressId,
      customerAddress: matchedAddress,
    );
  }

  Map<String, dynamic> toJson() {
    final mapped = Map<String, dynamic>.from(raw);
    if (customerAddressId != null && customerAddressId!.trim().isNotEmpty) {
      mapped['customer_address_id'] = customerAddressId;
    }
    if (customerAddress != null) {
      mapped['customer_address'] = customerAddress!.toJson();
    }
    return mapped;
  }

  static CustomerAddress? _findAddressById(
    String normalizedAddressId,
    List<dynamic> candidates,
  ) {
    final maps = <Map<String, dynamic>>[];
    for (final candidate in candidates) {
      _collectAddressMaps(candidate, maps);
    }

    for (final map in maps) {
      final candidateId = _normalizeId(
        _firstNonEmptyString([
          map['id'],
          map['address_id'],
          map['customer_address_id'],
          map['customerAddressId'],
        ]),
      );
      if (candidateId.isEmpty) continue;
      if (candidateId == normalizedAddressId) {
        return CustomerAddress.fromJson(map);
      }
    }

    return null;
  }

  static void _collectAddressMaps(dynamic value, List<Map<String, dynamic>> out) {
    if (value == null) return;

    final map = _asMap(value);
    if (map != null) {
      out.add(map);
      for (final key in const [
        'customer_address',
        'customerAddress',
        'customer_addresses',
        'addresses',
        'address',
      ]) {
        _collectAddressMaps(map[key], out);
      }
      return;
    }

    if (value is List) {
      for (final item in value) {
        _collectAddressMaps(item, out);
      }
    }
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static String _firstNonEmptyString(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty && text.toLowerCase() != 'null') {
        return text;
      }
    }
    return '';
  }

  static String _normalizeId(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return '';
    return value.replaceFirst(RegExp(r'^#'), '').toLowerCase();
  }
}
