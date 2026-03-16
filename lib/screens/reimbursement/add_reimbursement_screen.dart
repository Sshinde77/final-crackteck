import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../model/reimbursement_model.dart';
import '../../services/api_service.dart';
import '../../services/media_picker_service.dart';

class AddReimbursementScreen extends StatefulWidget {
  const AddReimbursementScreen({super.key});

  @override
  State<AddReimbursementScreen> createState() => _AddReimbursementScreenState();
}

class _AddReimbursementScreenState extends State<AddReimbursementScreen> {
  static const Color _primaryColor = Color(0xFF145A00);
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;
  XFile? _selectedReceipt;

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickReceipt(ImageSource source) async {
    final XFile? pickedFile = await MediaPickerService.pickImage(
      context,
      picker: _picker,
      source: source,
      imageQuality: 75,
    );

    if (pickedFile == null || !mounted) {
      return;
    }

    setState(() {
      _selectedReceipt = pickedFile;
    });
  }

  Future<void> _showReceiptPickerOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Upload Receipt',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1C1C1C),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose a source for the expense receipt image.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 20),
                _PickerOptionTile(
                  icon: Icons.photo_camera_outlined,
                  title: 'Take Photo',
                  subtitle: 'Capture a fresh receipt image',
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _pickReceipt(ImageSource.camera);
                  },
                ),
                const SizedBox(height: 12),
                _PickerOptionTile(
                  icon: Icons.photo_library_outlined,
                  title: 'Choose from Gallery',
                  subtitle: 'Select an existing receipt image',
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _pickReceipt(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    final bool isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    if (_selectedReceipt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a receipt image.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final response = await ApiService.addStaffReimbursement(
      amount: _amountController.text.trim(),
      reason: _reasonController.text.trim(),
      receipt: _selectedReceipt!,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
    });

    if (!response.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.message ?? 'Failed to submit reimbursement request.',
          ),
        ),
      );
      return;
    }

    final reimbursement =
        response.data != null && response.data!.isNotEmpty
        ? ReimbursementModel.fromJson(response.data!)
        : ReimbursementModel(
            amount: double.tryParse(_amountController.text.trim()) ?? 0,
            reason: _reasonController.text.trim(),
            status: ReimbursementStatus.pending,
            receiptImagePath: _selectedReceipt!.path,
            createdAt: DateTime.now(),
          );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          response.message ?? 'Reimbursement request added successfully.',
        ),
      ),
    );

    Navigator.pop(context, reimbursement);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Add Reimbursement',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x12000000),
                        blurRadius: 24,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reimbursement Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Fill in the expense information and attach the receipt for review.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _FormLabel(label: 'Amount'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: _inputDecoration(
                          hintText: 'Enter amount',
                          prefixText: '\u20B9 ',
                        ),
                        validator: (value) {
                          final String input = value?.trim() ?? '';
                          if (input.isEmpty) {
                            return 'Amount is required';
                          }
                          final double? amount = double.tryParse(input);
                          if (amount == null || amount <= 0) {
                            return 'Enter a valid amount';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      _FormLabel(label: 'Reason'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _reasonController,
                        minLines: 4,
                        maxLines: 5,
                        decoration: _inputDecoration(
                          hintText: 'Describe the expense',
                        ),
                        validator: (value) {
                          final String input = value?.trim() ?? '';
                          if (input.isEmpty) {
                            return 'Reason is required';
                          }
                          if (input.length < 5) {
                            return 'Reason should be at least 5 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      _FormLabel(label: 'Receipt Image'),
                      const SizedBox(height: 8),
                      InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: _showReceiptPickerOptions,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFD7DCE4)),
                          ),
                          child: Column(
                            children: [
                              if (_selectedReceipt == null) ...[
                                Container(
                                  height: 56,
                                  width: 56,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE9F6E5),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: const Icon(
                                    Icons.receipt_long_outlined,
                                    color: _primaryColor,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Tap to upload receipt',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Use camera or gallery',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ] else ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.file(
                                    File(_selectedReceipt!.path),
                                    height: 180,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'Receipt selected successfully',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF111827),
                                        ),
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: _showReceiptPickerOptions,
                                      icon: const Icon(Icons.edit_outlined, size: 18),
                                      label: const Text('Change'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: _primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Submit',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    String? prefixText,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixText: prefixText,
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFD7DCE4)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFD7DCE4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _primaryColor, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.4),
      ),
    );
  }
}

class _FormLabel extends StatelessWidget {
  final String label;

  const _FormLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Color(0xFF111827),
      ),
    );
  }
}

class _PickerOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PickerOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFE9F6E5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: const Color(0xFF145A00)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF145A00)),
          ],
        ),
      ),
    );
  }
}
