import 'package:flutter/material.dart';

import '../../constants/api_constants.dart';
import '../../services/api_service.dart';
import 'field_executive_delivery_detail_base_screen.dart';
import 'field_executive_delivery_flow_helpers.dart';

class FieldExecutiveDeliveryReturnDetailScreen extends StatelessWidget {
  final int roleId;
  final String roleName;
  final int? userId;
  final String requestId;

  const FieldExecutiveDeliveryReturnDetailScreen({
    super.key,
    required this.roleId,
    required this.roleName,
    this.userId,
    required this.requestId,
  });

  @override
  Widget build(BuildContext context) {
    return FieldExecutiveDeliveryDetailBaseScreen(
      roleId: roleId,
      roleName: roleName,
      userId: userId,
      deliveryType: FieldExecutiveDeliveryTypes.returnRequest,
      requestId: requestId,
      appBarTitle: 'Return Request Detail',
      loadDetail: (selectedRequestId, selectedRoleId, selectedUserId) =>
          ApiService.fetchDeliveryRequestDetail(
        deliveryType: DeliveryRequestTypes.returnRequest,
        deliveryId: selectedRequestId,
        roleId: selectedRoleId,
      ),
    );
  }
}
