import 'package:final_crackteck/model/sales_person/task_model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants/api_constants.dart';

class TaskViewModal extends StatefulWidget {
  final TaskModel task;

  const TaskViewModal({super.key, required this.task});

  @override
  State<TaskViewModal> createState() => _TaskViewModalState();
}

class _TaskViewModalState extends State<TaskViewModal> {
  String selectedStatus = "";

  @override
  void initState() {
    super.initState();
    selectedStatus = widget.task.status;
  }

  Future<void> updateStatus() async {
    final res = await http.post(
      Uri.parse(ApiConstants.updateTaskStatus),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "task_id": widget.task.id,
        "status": selectedStatus,
      }),
    );

    if (res.statusCode == 200) {
      Navigator.pop(context, true); // refresh dashboard
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.task.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

          const SizedBox(height: 12),

          Text("Lead ID: ${widget.task.leadId}"),
          Text("Phone: ${widget.task.phone}"),
          Text("Location: ${widget.task.location}"),

          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            value: selectedStatus,
            items: const [
              DropdownMenuItem(value: "pending", child: Text("Pending")),
              DropdownMenuItem(value: "completed", child: Text("Completed")),
              DropdownMenuItem(value: "cancelled", child: Text("Cancelled")),
            ],
            onChanged: (v) => setState(() => selectedStatus = v!),
            decoration: const InputDecoration(labelText: "Update Status"),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: updateStatus,
              child: const Text("Update"),
            ),
          ),
        ],
      ),
    );
  }
}
