import 'package:flutter/material.dart';

class PaymentDetailScreen extends StatelessWidget {
  final Map<String, dynamic> paymentData;

  const PaymentDetailScreen({super.key, required this.paymentData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Payment detail',
          style: TextStyle(color: Colors.white),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _detailRow(context, 'Amount', _asString(paymentData['amount'], fallback: 'Rs. 0')),
                _divider(),
                _detailRow(context, 'Name', _asString(paymentData['name'], fallback: 'N/A')),
                _divider(),
                _detailRow(
                  context,
                  'Bank Account',
                  _asString(paymentData['bankAccount'], fallback: '846735629'),
                ),
                _divider(),
                _detailRow(context, 'Category', _asString(paymentData['category'], fallback: 'CCTV')),
                _divider(),
                _detailRow(context, 'Method', _asString(paymentData['mode'], fallback: 'Online')),
                _divider(),
                _detailRow(
                  context,
                  'Transaction Date',
                  _asString(paymentData['date'], fallback: 'Dec 24, 2024 | 07:24 PM')
                      .replaceAll(' | ', '\n'),
                ),
                _divider(),
                _detailRow(
                  context,
                  'Transaction ID',
                  _asString(paymentData['transactionId'], fallback: '372638263769'),
                ),
                _divider(),
                _detailRow(context, 'Status', _asString(paymentData['status'], fallback: 'Completed')),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('E-Receipt downloaded successfully'),
                        ),
                      );
                    },
                    child: const Text(
                      'Download E-Receipt',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _asString(dynamic value, {required String fallback}) {
    if (value == null) return fallback;
    return value.toString();
  }

  Widget _detailRow(BuildContext context, String title, String value) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title clicked')),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Divider(color: Colors.grey.shade300, height: 1);
  }
}


