import 'package:flutter/material.dart';

class RepairRequestScreen extends StatefulWidget {
  final int roleId;
  final String roleName;
  const RepairRequestScreen({super.key, required this.roleId, required this.roleName});

  @override
  State<RepairRequestScreen> createState() => _RepairRequestScreenState();
}

class _RepairRequestScreenState extends State<RepairRequestScreen> {
  static const Color brandGreen = Color(0xFF1B6E1B);

  // ✅ Dummy Data for Repair Requests
  final List<RepairRequestItem> items = [
    RepairRequestItem(
      requestId: "R-101",
      serviceId: "#HWDSF776567DS",
      location: "Borivali (West)",
      status: "Pending",
      qty: 1,
      name: "Khushi Yadav",
      title: "example@.com",
      requestDate: "02/04/2025",
      requestTime: "11:00 AM",
      deviceType: "MacBook",
      issue: "Screen Flicker",
      address: "Borivali (West)",
      timelineIndex: 1, // 0=Created, 1=Assigned, 2=Completed
      attachments: const ["IMAGE", "IMAGE"],
    ),
    RepairRequestItem(
      requestId: "R-102",
      serviceId: "#HWDSF776567DS",
      location: "Goregaon (West)",
      status: "Pending",
      qty: 2,
      name: "Riya Sharma",
      title: "riya@.com",
      requestDate: "03/04/2025",
      requestTime: "04:30 PM",
      deviceType: "Laptop",
      issue: "Battery Drain",
      address: "Goregaon (West)",
      timelineIndex: 1,
      attachments: const ["IMAGE", "IMAGE"],
    ),
    RepairRequestItem(
      requestId: "R-104",
      serviceId: "#HWDSF776567DS",
      location: "Andheri (West)",
      status: "Done",
      qty: 1,
      name: "Aman Verma",
      title: "aman@.com",
      requestDate: "01/04/2025",
      requestTime: "10:00 AM",
      deviceType: "Desktop",
      issue: "No Power",
      address: "Andheri (West)",
      timelineIndex: 2,
      attachments: const ["IMAGE", "IMAGE"],
    ),
    RepairRequestItem(
      requestId: "R-105",
      serviceId: "#HWDSF776567DS",
      location: "Borivali (West)",
      status: "Pending",
      qty: 1,
      name: "Neha Singh",
      title: "neha@.com",
      requestDate: "04/04/2025",
      requestTime: "01:15 PM",
      deviceType: "Mobile",
      issue: "Speaker Issue",
      address: "Borivali (West)",
      timelineIndex: 0,
      attachments: const ["IMAGE", "IMAGE"],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: brandGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context), // ✅ navigation pop
        ),
        title: const Text(
          "Repair Requests",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 110),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _RepairCard(
                    item: item,
                    onTap: () => _openDetailsPopup(item),
                  );
                },
              ),
            ),

            // ✅ Bottom Done button (same style)
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
              decoration: const BoxDecoration(color: Color(0xFFF3F4F6)),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Done",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
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

  void _openDetailsPopup(RepairRequestItem item) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: _RepairDetailsPopup(
            item: item,
            onCall: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Calling... (dummy action)")),
              );
            },
            onChat: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Opening chat... (dummy action)")),
              );
            },
          ),
        );
      },
    );
  }
}

/* -------------------- MODEL -------------------- */

class RepairRequestItem {
  final String requestId;
  final String serviceId;
  final String location;
  final String status; // Pending / Done
  final int qty;

  // popup fields
  final String name;
  final String title;
  final String requestDate;
  final String requestTime;
  final String deviceType;
  final String issue;
  final String address;
  final int timelineIndex; // 0=Created,1=Assigned,2=Completed
  final List<String> attachments;

  RepairRequestItem({
    required this.requestId,
    required this.serviceId,
    required this.location,
    required this.status,
    required this.qty,
    required this.name,
    required this.title,
    required this.requestDate,
    required this.requestTime,
    required this.deviceType,
    required this.issue,
    required this.address,
    required this.timelineIndex,
    required this.attachments,
  });
}

/* -------------------- CARD -------------------- */

class _RepairCard extends StatelessWidget {
  final RepairRequestItem item;
  final VoidCallback onTap;

  const _RepairCard({
    required this.item,
    required this.onTap,
  });

  static const Color brandGreen = Color(0xFF1B6E1B);

  @override
  Widget build(BuildContext context) {
    final isDone = item.status.toLowerCase() == "done";

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE6E7EA)),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // left image placeholder
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F2F4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE6E7EA)),
              ),
              child: const Icon(Icons.build_circle, size: 36, color: Color(0xFF555555)),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _rowLabelValue("Request ID", item.requestId, valueBold: true),
                  const SizedBox(height: 4),
                  _rowLabelValue("Service ID", item.serviceId, valueColor: brandGreen, valueBold: true),
                  const SizedBox(height: 4),
                  _rowLabelValue("Location", item.location, valueColor: brandGreen),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text(
                        "Status :",
                        style: TextStyle(fontSize: 12.5, color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        item.status,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: isDone ? brandGreen : const Color(0xFFD11A2A),
                        ),
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            "Qty",
                            style: TextStyle(fontSize: 12.5, color: brandGreen, fontWeight: FontWeight.w800),
                          ),
                          Text(
                            "${item.qty}",
                            style: const TextStyle(fontSize: 16, color: brandGreen, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _rowLabelValue(
      String label,
      String value, {
        bool valueBold = false,
        Color? valueColor,
      }) {
    return Row(
      children: [
        Text(
          "$label : ",
          style: const TextStyle(fontSize: 12.5, color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
        ),
        Expanded(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: valueBold ? FontWeight.w800 : FontWeight.w600,
              color: valueColor ?? const Color(0xFF111827),
            ),
          ),
        ),
      ],
    );
  }
}

/* -------------------- POPUP -------------------- */

class _RepairDetailsPopup extends StatelessWidget {
  final RepairRequestItem item;
  final VoidCallback onCall;
  final VoidCallback onChat;

  const _RepairDetailsPopup({
    required this.item,
    required this.onCall,
    required this.onChat,
  });

  static const Color brandGreen = Color(0xFF1B6E1B);

  @override
  Widget build(BuildContext context) {
    final isPending = item.status.toLowerCase() == "pending";

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 12),

          _kv("Request ID", item.requestId, bold: true),
          _kv("Service ID", item.serviceId, color: brandGreen, bold: true),
          _kv("Name", item.name, bold: true),
          _kv("Title", item.title, bold: true),
          _kv("Request Date", item.requestDate, bold: true),
          _kv("Request Time", item.requestTime, bold: true),
          _kv("Device", item.deviceType, bold: true),
          _kv("Issue", item.issue, bold: true),
          _kv("Address", item.address, bold: true),
          _kv(
            "Status",
            item.status,
            bold: true,
            color: isPending ? const Color(0xFFD11A2A) : brandGreen,
          ),

          const SizedBox(height: 14),

          _RepairTimeline(timelineIndex: item.timelineIndex),

          const SizedBox(height: 14),

          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Attachments",
              style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF374151)),
            ),
          ),
          const SizedBox(height: 10),

          Row(
            children: item.attachments
                .take(2)
                .map(
                  (a) => Expanded(
                child: Container(
                  height: 70,
                  margin: EdgeInsets.only(right: a == item.attachments.first ? 10 : 0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      a,
                      style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF4B5563)),
                    ),
                  ),
                ),
              ),
            )
                .toList(),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: onCall,
                    icon: const Icon(Icons.call, color: Colors.white, size: 18),
                    label: const Text("Call", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: onChat,
                    icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 18),
                    label: const Text("Chat", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              k,
              style: const TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              v,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: color ?? const Color(0xFF111827),
                fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------------- TIMELINE -------------------- */

class _RepairTimeline extends StatelessWidget {
  final int timelineIndex; // 0..2
  const _RepairTimeline({required this.timelineIndex});

  static const Color brandGreen = Color(0xFF1B6E1B);

  @override
  Widget build(BuildContext context) {
    final bool step0 = timelineIndex >= 0;
    final bool step1 = timelineIndex >= 1;
    final bool step2 = timelineIndex >= 2;

    return Column(
      children: [
        Row(
          children: [
            _stepCircle(active: step0),
            Expanded(child: _dashedLine(active: step1)),
            _stepCircle(active: step1),
            Expanded(child: _dashedLine(active: step2)),
            _stepCircle(active: step2),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            SizedBox(width: 70, child: Text("Created", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
            SizedBox(width: 70, child: Text("Assigned", textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
            SizedBox(width: 70, child: Text("Completed", textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
          ],
        ),
      ],
    );
  }

  Widget _stepCircle({required bool active}) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: active ? brandGreen : const Color(0xFFE5E7EB),
        shape: BoxShape.circle,
      ),
      child: active ? const Icon(Icons.check, size: 16, color: Colors.white) : const SizedBox.shrink(),
    );
  }

  Widget _dashedLine({required bool active}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dashWidth = 6.0;
        final dashSpace = 4.0;
        final dashCount = (constraints.maxWidth / (dashWidth + dashSpace)).floor();

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (_) {
            return Container(
              width: dashWidth,
              height: 2,
              decoration: BoxDecoration(
                color: active ? brandGreen : const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}
