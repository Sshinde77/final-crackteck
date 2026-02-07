import 'dart:async';
import 'package:flutter/material.dart';
import '../../constants/app_strings.dart';
import '../../routes/app_routes.dart';

class FieldExecutiveProductPaymentScreen extends StatefulWidget {
  final int roleId;
  final String roleName;

  const FieldExecutiveProductPaymentScreen({
    super.key,
    required this.roleId,
    required this.roleName,
  });

  @override
  State<FieldExecutiveProductPaymentScreen> createState() =>
      _FieldExecutiveProductPaymentScreenState();
}

class _FieldExecutiveProductPaymentScreenState
    extends State<FieldExecutiveProductPaymentScreen> {
  static const Color primaryGreen = Color(0xFF1F8B00);
  
  // Payment selection state
  int? selectedPaymentIndex = 0; 
  int qty = 5;
  bool isProcessing = false;

  void _processPayment() {
    setState(() {
      isProcessing = true;
    });

    Timer(const Duration(seconds: 5), () {
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.FieldExecutiveDashboard,
          (route) => false,
          arguments: fieldexecutivedashboardArguments(
            roleId: widget.roleId,
            roleName: widget.roleName,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isProcessing) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  strokeWidth: 8,
                  valueColor: const AlwaysStoppedAnimation<Color>(primaryGreen),
                  backgroundColor: primaryGreen.withOpacity(0.2),
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Please wait',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'payment is processing',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
              ],
            ),
          ),
        ),
      );
    }

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
          AppStrings.productPaymentTitle,
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Product Summary Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Image.asset(
                      'assets/products/motherboard.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Intel Core i3 12100F 12th Gen Desktop PC Processor',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '₹ 62,990',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text('Qty', style: TextStyle(fontWeight: FontWeight.w500)),
                            const SizedBox(width: 12),
                            _qtyButton(Icons.remove, () {
                              if (qty > 1) setState(() => qty--);
                            }),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            _qtyButton(Icons.add, () => setState(() => qty++)),
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text(AppStrings.offers, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                hintText: AppStrings.enterOfferCode,
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.black12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.black12),
                ),
              ),
            ),

            const SizedBox(height: 24),
            const Text(AppStrings.online, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black12),
              ),
              child: Column(
                children: [
                  _paymentOptionTile(
                    index: 0,
                    title: AppStrings.googlePay,
                    iconPath: 'assets/logo/logo.png', 
                    amount: '₹ 2,500',
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _paymentOptionTile(
                    index: 1,
                    title: AppStrings.phonePe,
                    iconPath: 'assets/logo/logo.png', 
                    amount: '₹ 2,500',
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.add, color: Colors.grey, size: 20),
                    title: const Text(
                      AppStrings.addNewUpiId,
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text(AppStrings.cash, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            _cashOptionTile(index: 2, amount: '₹ 2,500'),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  AppStrings.done,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: primaryGreen,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }

  Widget _paymentOptionTile({
    required int index,
    required String title,
    required String iconPath,
    required String amount,
  }) {
    bool isSelected = selectedPaymentIndex == index;
    return ListTile(
      onTap: () => setState(() => selectedPaymentIndex = index),
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(Icons.payment, size: 20, color: Colors.blue), 
      ),
      title: Text(title, style: const TextStyle(fontSize: 14, color: Colors.black87)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(width: 12),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isSelected ? primaryGreen : Colors.black26,
                width: 1.5,
              ),
              color: isSelected ? primaryGreen.withOpacity(0.1) : Colors.transparent,
            ),
            child: isSelected
                ? const Icon(Icons.check, size: 18, color: primaryGreen)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _cashOptionTile({required int index, required String amount}) {
    bool isSelected = selectedPaymentIndex == index;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          const Text(
            AppStrings.amount,
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const Spacer(),
          Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => setState(() => selectedPaymentIndex = index),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isSelected ? primaryGreen : Colors.black26,
                  width: 1.5,
                ),
                color: isSelected ? primaryGreen.withOpacity(0.1) : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 18, color: primaryGreen)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
