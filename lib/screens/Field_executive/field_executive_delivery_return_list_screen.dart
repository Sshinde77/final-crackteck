import 'package:flutter/material.dart';

import 'field_executive_delivery_flow_helpers.dart';
import 'field_executive_delivery_request_list_base.dart';

class FieldExecutiveDeliveryReturnListScreen extends StatelessWidget {
  final int roleId;
  final String roleName;

  const FieldExecutiveDeliveryReturnListScreen({
    super.key,
    required this.roleId,
    required this.roleName,
  });

  @override
  Widget build(BuildContext context) {
    return FieldExecutiveDeliveryRequestListBase(
      roleId: roleId,
      roleName: roleName,
      deliveryType: FieldExecutiveDeliveryTypes.returnRequest,
      appBarTitle: 'Return Requests',
    );
  }
}
