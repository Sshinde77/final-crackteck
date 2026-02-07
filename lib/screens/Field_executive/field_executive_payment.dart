import 'package:flutter/material.dart';
import 'field_executive_payment_detail.dart';

class PaymentsScreen extends StatelessWidget {
  final int roleId;
  final String roleName;
  PaymentsScreen({super.key, required this.roleId, required this.roleName});

  /// Dummy Data (SINGLE FILE)
  final List<Map<String, dynamic>> payments = [
    {
      "name": "Darron Kulikowski",
      "amount": "Rs. 2,500",
      "date": "Dec 24, 2024 | 11:36 AM",
      "mode": "Online",
      "bankAccount": "846735629",
      "category": "CCTV",
      "transactionId": "372638263769",
      "status": "Completed"
    },
    {
      "name": "Darron Kulikowski",
      "amount": "Rs. 2,500",
      "date": "Dec 24, 2024 | 11:36 AM",
      "mode": "Cash",
      "bankAccount": "846735629",
      "category": "CCTV",
      "transactionId": "372638263770",
      "status": "Completed"
    },
    {
      "name": "Darron Kulikowski",
      "amount": "Rs. 2,500",
      "date": "Dec 24, 2024 | 11:36 AM",
      "mode": "Online",
      "bankAccount": "846735629",
      "category": "CCTV",
      "transactionId": "372638263771",
      "status": "Completed"
    },
    {
      "name": "Darron Kulikowski",
      "amount": "Rs. 2,500",
      "date": "Dec 24, 2024 | 11:36 AM",
      "mode": "Online",
      "bankAccount": "846735629",
      "category": "CCTV",
      "transactionId": "372638263772",
      "status": "Completed"
    },
    {
      "name": "Darron Kulikowski",
      "amount": "Rs. 2,500",
      "date": "Dec 24, 2024 | 11:36 AM",
      "mode": "Cash",
      "bankAccount": "846735629",
      "category": "CCTV",
      "transactionId": "372638263773",
      "status": "Completed"
    },
    {
      "name": "Darron Kulikowski",
      "amount": "Rs. 2,500",
      "date": "Dec 24, 2024 | 11:36 AM",
      "mode": "Cash",
      "bankAccount": "846735629",
      "category": "CCTV",
      "transactionId": "372638263774",
      "status": "Completed"
    },
  ];

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
          "Payments",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
          /// Payment List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: payments.length,
              itemBuilder: (context, index) {
                final item = payments[index];

                return _paymentTile(
                  context: context,
                  data: item,
                );
              },
            ),
          ),

          /// Bottom Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 52,
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
                      content: Text("Request clear cash submitted"),
                    ),
                  );
                },
                child: const Text(
                  "Request clear cash",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
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

  /// Payment Tile UI
  Widget _paymentTile({
    required BuildContext context,
    required Map<String, dynamic> data,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentDetailScreen(paymentData: data),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data["name"],
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data["date"],
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 40,
              width: 1,
              color: Colors.grey.shade300,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  data["amount"],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data["mode"],
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


