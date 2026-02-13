import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class FieldExecutiveCaseTransferScreen extends StatefulWidget {
  final int roleId;
  final String roleName;
  final String serviceId;

  const FieldExecutiveCaseTransferScreen({
    super.key,
    required this.roleId,
    required this.roleName,
    required this.serviceId,
  });

  @override
  State<FieldExecutiveCaseTransferScreen> createState() => _FieldExecutiveCaseTransferScreenState();
}

class _FieldExecutiveCaseTransferScreenState extends State<FieldExecutiveCaseTransferScreen> {
  final TextEditingController _reasonController = TextEditingController();
  static const primaryGreen = Color(0xFF1E7C10);
  bool _isSubmitting = false;

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submitCaseTransfer() async {
    if (_isSubmitting) return;

    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      _snack('Please enter a reason');
      return;
    }

    final serviceRequestId = widget.serviceId.trim().replaceFirst(RegExp(r'^#'), '');
    if (int.tryParse(serviceRequestId) == null) {
      _snack('Invalid service request id');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final response = await ApiService.transferServiceRequestCase(
      serviceRequestId,
      engineerReason: reason,
      roleId: widget.roleId,
    );

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (!response.success) {
      _snack(response.message ?? 'Failed to submit case transfer');
      return;
    }

    _snack(response.message ?? 'Case transfer submitted successfully');
    Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          'Case Transfer',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Reason',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _reasonController,
                maxLines: 8,
                decoration: InputDecoration(
                  hintText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.black12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.black12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: primaryGreen),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitCaseTransfer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Submit',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
