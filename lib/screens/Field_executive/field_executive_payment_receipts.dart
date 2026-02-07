import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../routes/app_routes.dart';

class FieldExecutivePaymentReceiptsScreen extends StatefulWidget {
  final int roleId;
  final String roleName;

  const FieldExecutivePaymentReceiptsScreen({
    super.key,
    required this.roleId,
    required this.roleName,
  });

  @override
  State<FieldExecutivePaymentReceiptsScreen> createState() =>
      _FieldExecutivePaymentReceiptsScreenState();
}

class _FieldExecutivePaymentReceiptsScreenState
    extends State<FieldExecutivePaymentReceiptsScreen> {
  static const Color primaryGreen = Color(0xFF1F8B00);
  static const Color navyBlue = Color(0xFF1A1A8E);

  String? selectedAccountant;
  final List<String> accountants = ['Accountant 1', 'Accountant 2', 'Accountant 3'];
  bool isDropdownOpen = false;

  File? _image;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
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
          'Payment receipts',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            const Text(
              'How much you have spend',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            // Dropdown Selector
            Column(
              children: [
                GestureDetector(
                  onTap: () => setState(() => isDropdownOpen = !isDropdownOpen),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: selectedAccountant == null ? navyBlue : Colors.white,
                      borderRadius: isDropdownOpen 
                        ? const BorderRadius.vertical(top: Radius.circular(12)) 
                        : BorderRadius.circular(12),
                      border: Border.all(color: selectedAccountant == null ? navyBlue : Colors.black12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedAccountant ?? 'Submit Cash to',
                          style: TextStyle(
                            color: selectedAccountant == null ? Colors.white : Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Icon(
                          isDropdownOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: selectedAccountant == null ? Colors.white : Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ),
                if (isDropdownOpen)
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Column(
                      children: accountants.map((item) {
                        return InkWell(
                          onTap: () {
                            setState(() {
                              selectedAccountant = item;
                              isDropdownOpen = false;
                            });
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: const BoxDecoration(
                              border: Border(top: BorderSide(color: Colors.black12, width: 0.5)),
                            ),
                            child: Text(item, style: const TextStyle(fontSize: 15)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 24),
            const Text(
              'Enter amount',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText: '₹ ',
                prefixStyle: const TextStyle(color: Colors.black, fontSize: 18),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black12),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Receipt Photo Button
            InkWell(
              onTap: _pickImage,
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  color: primaryGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: const [
                    Icon(Icons.camera_alt, color: Colors.white),
                    SizedBox(width: 12),
                    Text(
                      'Receipt photo',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    Spacer(),
                    Icon(Icons.arrow_forward, color: Colors.white),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Preview Image
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _image != null
                      ? Image.file(
                          _image!,
                          width: 150,
                          height: 110,
                          fit: BoxFit.cover,
                        )
                      : Image.asset(
                          'assets/images/map_placeholder.jpg', // Default placeholder
                          width: 150,
                          height: 110,
                          fit: BoxFit.cover,
                        ),
                ),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    margin: const EdgeInsets.all(6),
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: primaryGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 100), // Space for bottom button

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.FieldExecutivePaymentDoneScreen,
                    arguments: fieldexecutivepaymentdoneArguments(
                      roleId: widget.roleId,
                      roleName: widget.roleName,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Submit',
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
}
