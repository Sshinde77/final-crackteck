import 'package:flutter/material.dart';

import '../wallet/wallet_screen.dart';

class FieldExecutiveCashInHandScreen extends StatelessWidget {
  final int roleId;
  final String roleName;

  const FieldExecutiveCashInHandScreen({
    super.key,
    required this.roleId,
    required this.roleName,
  });

  @override
  Widget build(BuildContext context) {
    return WalletScreen(
      roleId: roleId,
      roleName: roleName,
      title: 'Wallet',
    );
  }
}
