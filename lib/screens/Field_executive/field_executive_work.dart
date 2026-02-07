import 'package:flutter/material.dart';

class WorksScreen extends StatefulWidget {
  final int roleId;
  final String roleName;
  const WorksScreen({super.key, required this.roleId, required this.roleName});

  @override
  State<WorksScreen> createState() => _WorksScreenState();
}

class _WorksScreenState extends State<WorksScreen> {
  int selectedTab = 0; // 0=Done, 1=Pending, 2=Transferred

  final List<Map<String, dynamic>> works = [
    {
      "title": "Office CCTV Installation",
      "name": "Darron Kulikowski",
      "serviceId": "#UORD658858DYE",
      "amount": "₹ 2,500",
      "date": "Dec 24, 2024\n07:24 PM",
      "status": "Completed",
      "tab": 0,
    },
    {
      "title": "Office CCTV Installation",
      "name": "Darron Kulikowski",
      "serviceId": "#UORD658858DYE",
      "amount": "₹ 2,500",
      "date": "Dec 24, 2024\n07:24 PM",
      "status": "Pending",
      "tab": 1,
    },
    {
      "title": "Office CCTV Installation",
      "name": "Darron Kulikowski",
      "serviceId": "#UORD658858DYE",
      "amount": "₹ 2,500",
      "date": "Dec 24, 2024\n07:24 PM",
      "status": "Transferred",
      "tab": 2,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredList =
    works.where((item) => item["tab"] == selectedTab).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Works", style: TextStyle(color: Colors.white)),
      ),

      /// Calendar Floating Button
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.green.shade700,
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Calendar clicked")),
          );
        },
        icon: const Icon(Icons.calendar_month),
        label: const Text("Calendar"),
      ),

      body: SafeArea(
        child: Column(
          children: [
          const SizedBox(height: 12),

          /// Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _tabButton("Done", 0),
                _tabButton("Pending", 1),
                _tabButton("Transferred", 2),
              ],
            ),
          ),

          const SizedBox(height: 16),

          /// List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredList.length,
              itemBuilder: (context, index) {
                final item = filteredList[index];
                return _workCard(item);
              },
            ),
          ),
          ],
        ),
      ),
    );
  }

  /// Tab Button
  Widget _tabButton(String text, int index) {
    final isSelected = selectedTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => selectedTab = index);
        },
        child: Container(
          height: 42,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? Colors.green.shade700 : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  /// Work Card
  Widget _workCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item["title"],
            style: TextStyle(
              color: Colors.green.shade700,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(),

          _row("Name", item["name"]),
          _row("Service ID", item["serviceId"]),
          _row("Amount (USD)", item["amount"]),
          _row("Transaction Date", item["date"]),
          _row("Status", item["status"]),

          if (item["status"] == "Pending") ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Work started again")),
                  );
                },
                child: const Text(
                  "Start again",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
