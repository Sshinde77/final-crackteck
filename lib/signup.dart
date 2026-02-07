import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:file_picker/file_picker.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_strings.dart';
import '../services/api_service.dart';
import '../routes/app_routes.dart';

enum _DocumentType { aadhar, pan, licenceFront, licenceBack }

class SignupScreen extends StatefulWidget {
  final SignUpArguments arg;
  const SignupScreen({super.key, required this.arg});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService.instance;

  final nameCtrl = TextEditingController();
  final numberCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final aadharCtrl = TextEditingController();
  final panCtrl = TextEditingController();
  final licenceNumberCtrl = TextEditingController();

  File? aadharFile;
  File? panFile;
  File? licenceFrontFile;
  File? licenceBackFile;

  bool agree = false;
  bool loading = false;

  // Use roleId to determine if current signup is for Delivery Person (roleId = 2)
  bool get _isDeliveryPerson => widget.arg.roleId == 2;

  Future<void> _pickFile(_DocumentType type) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'pdf'],
      withData: false,
    );

    if (result == null || result.files.isEmpty) return;

    final picked = result.files.single;
    final fileName = picked.name.toLowerCase();

    final isSupportedExtension =
        fileName.endsWith('.png') ||
        fileName.endsWith('.jpg') ||
        fileName.endsWith('.jpeg') ||
        fileName.endsWith('.pdf');

    if (!isSupportedExtension) {
      _snack("Please select a PNG, JPG, JPEG, or PDF file");
      return;
    }

    final sizeInBytes = picked.size;
    if (sizeInBytes > 2 * 1024 * 1024) {
      _snack("File size must be less than 2MB");
      return;
    }

    // On mobile/desktop platforms, FilePicker provides a path we can wrap in File.
    if (picked.path == null) {
      _snack(
        "This platform does not provide a local file path for uploads yet.",
      );
      return;
    }

    final file = File(picked.path!);

    setState(() {
      switch (type) {
        case _DocumentType.aadhar:
          aadharFile = file;
          break;
        case _DocumentType.pan:
          panFile = file;
          break;
        case _DocumentType.licenceFront:
          licenceFrontFile = file;
          break;
        case _DocumentType.licenceBack:
          licenceBackFile = file;
          break;
      }
    });
  }

  Future<void> signup() async {
    final isDelivery = _isDeliveryPerson;
    if (!_formKey.currentState!.validate()) return;
    if (!agree) {
      _snack("Please accept terms and conditions");
      return;
    }
    if (aadharFile == null || panFile == null) {
      _snack("Please upload required documents");
      return;
    }
    if (isDelivery && (licenceFrontFile == null || licenceBackFile == null)) {
      _snack("Please upload licence front and back files");
      return;
    }

    setState(() => loading = true);

    final res = await _apiService.signup(
      name: nameCtrl.text,
      phone: numberCtrl.text,
      email: emailCtrl.text,
      address: addressCtrl.text,
      aadhar: aadharCtrl.text,
      pan: panCtrl.text,
      aadharFile: aadharFile!,
      panFile: panFile!,
      drivingLicenceNumber: isDelivery ? licenceNumberCtrl.text : null,
      licenceFrontFile: isDelivery ? licenceFrontFile : null,
      licenceBackFile: isDelivery ? licenceBackFile : null,
    );

    if (!mounted) return;

    setState(() => loading = false);

    if (res.success) {
      _snack("Signup successful");
      Navigator.pop(context);
    } else {
      _snack(res.message ?? "Signup failed");
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _navigateToLogin() {
    Navigator.pushNamed(
      context,
      AppRoutes.login,
      arguments: LoginArguments(
        roleId: widget.arg.roleId,
        roleName: widget.arg.roleName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roleName = widget.arg.roleName;
    final isDelivery = _isDeliveryPerson;
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.horizontalPadding,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                Text(
                  "Hi, Welcome\n$roleName!",
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 10),
                Text(
                  getSignUpSubtitle(roleName),
                  style: const TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 20),

                _input("Name", nameCtrl),
                _input(
                  "Number",
                  numberCtrl,
                  keyboard: TextInputType.phone,
                  prefix: "+91 ",
                ),
                _input(
                  "Email",
                  emailCtrl,
                  keyboard: TextInputType.emailAddress,
                ),
                _input("Address", addressCtrl),
                _input("Aadhar no.", aadharCtrl),
                const SizedBox(height: 10),

                _uploadBox(
                  title: "Document",
                  subtitle: "Aadhar Card file in PNG, JPG, or PDF (max. 2MB)",
                  file: aadharFile,
                  onTap: () => _pickFile(_DocumentType.aadhar),
                ),
                const SizedBox(height: 10),
                _input("PAN no.", panCtrl),
                const SizedBox(height: 10),

                _uploadBox(
                  subtitle: "PAN Card file in PNG, JPG, or PDF (max. 2MB)",
                  file: panFile,
                  onTap: () => _pickFile(_DocumentType.pan),
                ),

                if (isDelivery) ...[
                  const SizedBox(height: 10),
                  _input("Driving Licence Number", licenceNumberCtrl),
                  const SizedBox(height: 10),
                  _uploadBox(
                    title: "Licence Front Image",
                    subtitle:
                        "Front side of licence in PNG, JPG, or PDF (max. 2MB)",
                    file: licenceFrontFile,
                    onTap: () => _pickFile(_DocumentType.licenceFront),
                  ),
                  const SizedBox(height: 12),
                  _uploadBox(
                    title: "Licence Back Image",
                    subtitle:
                        "Back side of licence in PNG, JPG, or PDF (max. 2MB)",
                    file: licenceBackFile,
                    onTap: () => _pickFile(_DocumentType.licenceBack),
                  ),
                ],

                const SizedBox(height: 15),

                Row(
                  children: [
                    Checkbox(
                      value: agree,
                      onChanged: (v) => setState(() => agree = v!),
                      activeColor: AppColors.primary,
                    ),
                    const Expanded(
                      child: Text(
                        "I agree to the terms and conditions",
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: loading ? null : signup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Sign Up",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 15),
                Center(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.black),
                      children: [
                        const TextSpan(text: "Have an account? "),
                        TextSpan(
                          text: "Login",
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = _navigateToLogin,
                        ),
                      ],
                    ),
                  ),
                ),

                // Center(
                //   child: RichText(
                //     text: const TextSpan(
                //       style: TextStyle(color: Colors.black),
                //       children: [
                //         TextSpan(text: "Have an account? "),
                //         TextSpan(
                //           text: "Login",
                //           style: TextStyle(
                //             color: AppColors.primary,
                //             fontWeight: FontWeight.bold,
                //           ),
                //         ),
                //       ],
                //     ),
                //   ),
                // ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _input(
    String hint,
    TextEditingController ctrl, {
    TextInputType keyboard = TextInputType.text,
    String? prefix,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboard,
        validator: (v) => v!.isEmpty ? "Required" : null,
        decoration: InputDecoration(
          hintText: hint,
          prefixText: prefix,
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _uploadBox({
    String? title,
    required String subtitle,
    required File? file,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onTap,
            child: Container(
              height: 45,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                file == null ? "Click to upload" : "File selected",
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
