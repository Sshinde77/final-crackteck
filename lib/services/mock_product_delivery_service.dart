class MockProductDeliveryService {
  MockProductDeliveryService._();

  static const List<Map<String, dynamic>> _requests = <Map<String, dynamic>>[
    <String, dynamic>{
      'id': '101',
      'request_id': 'PD-1001',
      'status': 'Pending',
      'location': 'Andheri East, Mumbai',
      'customer_name': 'Amit Sharma',
      'customer_phone': '9876543210',
      'customer_address':
          'Crackteck Service Hub, Andheri East, Mumbai, Maharashtra - 400069',
      'request_type': 'product_delivery',
      'product': <String, dynamic>{
        'product_name': 'RO Water Purifier',
        'model_no': 'CT-RO-900',
        'final_price': '15999',
        'short_description':
            'Premium purifier unit packed and ready for doorstep delivery.',
        'main_product_image': '',
      },
      'service_request': <String, dynamic>{
        'request_id': 'PD-1001',
        'request_type': 'product_delivery',
        'customer': <String, dynamic>{
          'first_name': 'Amit',
          'last_name': 'Sharma',
          'phone': '9876543210',
          'email': 'amit.sharma@example.com',
        },
        'customer_address': <String, dynamic>{
          'branch_name': 'Mumbai Branch',
          'address1': 'Plot 12, MIDC Road',
          'address2': 'Near Seepz Gate 2',
          'city': 'Mumbai',
          'state': 'Maharashtra',
          'country': 'India',
          'pincode': '400069',
        },
      },
    },
    <String, dynamic>{
      'id': '102',
      'request_id': 'PD-1002',
      'status': 'Pending',
      'location': 'Sector 62, Noida',
      'customer_name': 'Neha Verma',
      'customer_phone': '9123456780',
      'customer_address':
          'A-24, Sector 62, Noida, Uttar Pradesh - 201309',
      'request_type': 'product_delivery',
      'product': <String, dynamic>{
        'product_name': 'Smart Air Cooler',
        'model_no': 'CT-AC-450',
        'final_price': '12499',
        'short_description':
            'Box-packed cooling unit assigned for customer delivery.',
        'main_product_image': '',
      },
      'service_request': <String, dynamic>{
        'request_id': 'PD-1002',
        'request_type': 'product_delivery',
        'customer': <String, dynamic>{
          'first_name': 'Neha',
          'last_name': 'Verma',
          'phone': '9123456780',
          'email': 'neha.verma@example.com',
        },
        'customer_address': <String, dynamic>{
          'branch_name': 'Noida Branch',
          'address1': 'A-24, Sector 62',
          'address2': 'Near Electronic City Metro',
          'city': 'Noida',
          'state': 'Uttar Pradesh',
          'country': 'India',
          'pincode': '201309',
        },
      },
    },
  ];

  static List<Map<String, dynamic>> fetchRequests() {
    return _requests
        .map((request) => Map<String, dynamic>.from(request))
        .toList();
  }

  static Map<String, dynamic> fetchRequestDetail(String deliveryId) {
    final normalizedId = deliveryId.trim().replaceFirst(RegExp(r'^#'), '');
    final request = _requests.firstWhere(
      (item) => item['id']?.toString() == normalizedId,
      orElse: () => const <String, dynamic>{},
    );

    if (request.isEmpty) {
      throw Exception('Product delivery details not found for id $deliveryId');
    }

    return <String, dynamic>{
      'data': Map<String, dynamic>.from(request),
    };
  }
}
