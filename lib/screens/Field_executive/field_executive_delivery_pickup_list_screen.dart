import 'package:flutter/material.dart';

import 'field_executive_delivery_flow_helpers.dart';
import 'field_executive_delivery_request_list_base.dart';

class FieldExecutiveDeliveryPickupListScreen extends StatelessWidget {
  final int roleId;
  final String roleName;

  const FieldExecutiveDeliveryPickupListScreen({
    super.key,
    required this.roleId,
    required this.roleName,
  });

  @override
  Widget build(BuildContext context) {
    return FieldExecutiveDeliveryRequestListBase(
      roleId: roleId,
      roleName: roleName,
      deliveryType: FieldExecutiveDeliveryTypes.pickupRequest,
      appBarTitle: 'Pickup Requests',
    );
  }
}
