import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../model/field executive/field_executive_product_service.dart';
import '../../routes/app_routes.dart';
import 'field_executive_installation_checklist_screen.dart';

class FieldExecutiveUploadBeforeImagesScreen extends StatefulWidget {
  final int roleId;
  final String roleName;
  final String serviceId;
  final FieldExecutiveProductItemDetailFlow flow;
  final FieldExecutiveProductServicesController controller;

  const FieldExecutiveUploadBeforeImagesScreen({
    super.key,
    required this.roleId,
    required this.roleName,
    required this.serviceId,
    required this.flow,
    required this.controller,
  });

  @override
  State<FieldExecutiveUploadBeforeImagesScreen> createState() =>
      _FieldExecutiveUploadBeforeImagesScreenState();
}

class _FieldExecutiveUploadBeforeImagesScreenState
    extends State<FieldExecutiveUploadBeforeImagesScreen> {
  final ImagePicker _picker = ImagePicker();
  static const primaryGreen = Color(0xFF1E7C10);

  /// 🔒 Prevent multiple permission / camera calls
  bool _isPicking = false;

  final Map<String, File?> _pickedFiles = {
    'Top photo': null,
    'Bottom photo': null,
    'Left photo': null,
    'Right photo': null,
    'Screen photo': null,
    'Keyboard photo': null,
    'Device video': null,
  };

  Future<void> _pickImage(String category, bool isVideo) async {
    /// 🚫 Block multiple taps
    if (_isPicking) return;
    _isPicking = true;

    try {
      /// ✅ Request required permissions ONCE
      final cameraStatus = await Permission.camera.request();
      if (!cameraStatus.isGranted) {
        if (cameraStatus.isPermanentlyDenied && mounted) {
          _showPermissionDialog();
        }
        return;
      }

      if (isVideo) {
        final micStatus = await Permission.microphone.request();
        if (!micStatus.isGranted) return;

        final XFile? video =
        await _picker.pickVideo(source: ImageSource.camera);

        if (video != null && mounted) {
          setState(() {
            _pickedFiles[category] = File(video.path);
          });
        }
      } else {
        final XFile? photo = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 50,
        );

        if (photo != null && mounted) {
          setState(() {
            _pickedFiles[category] = File(photo.path);
          });
        }
      }
    } catch (e, st) {
      debugPrint('Pick error: $e');
      debugPrintStack(stackTrace: st);
    } finally {
      /// 🔓 Always unlock
      _isPicking = false;
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Camera Permission'),
        content: const Text(
          'Camera permission is required to take photos. Please enable it in settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.pop(context);
            },
            child: const Text('Settings'),
          ),
        ],
      ),
    );
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
          'Upload before images',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildUploadItem('Top photo', Icons.camera_alt_outlined),
                  const SizedBox(height: 12),
                  _buildUploadItem('Bottom photo', Icons.camera_alt_outlined),
                  const SizedBox(height: 12),
                  _buildUploadItem('Left photo', Icons.camera_alt_outlined),
                  const SizedBox(height: 12),
                  _buildUploadItem('Right photo', Icons.camera_alt_outlined),
                  const SizedBox(height: 12),
                  _buildUploadItem('Screen photo', Icons.camera_alt_outlined),
                  const SizedBox(height: 12),
                  _buildUploadItem('Keyboard photo', Icons.camera_alt_outlined),
                  const SizedBox(height: 12),
                  _buildUploadItem(
                    'Device video',
                    Icons.videocam_outlined,
                    isVideo: true,
                  ),
                ],
              ),
            ),
            _buildBottomImagePreview(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FieldExecutiveInstallationChecklistScreen(
                        roleId: widget.roleId,
                        roleName: widget.roleName,
                        serviceId: widget.serviceId,
                        flow: widget.flow,
                        controller: widget.controller,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Next',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomImagePreview() {
    final capturedItems =
    _pickedFiles.entries.where((e) => e.value != null).toList();

    if (capturedItems.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 16, bottom: 8),
            child: Text(
              "Captured Images",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: capturedItems.length,
              itemBuilder: (context, index) {
                final entry = capturedItems[index];
                final isVideo = entry.key == 'Device video';

                return Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border:
                    Border.all(color: primaryGreen.withOpacity(0.3)),
                    image: isVideo
                        ? null
                        : DecorationImage(
                      image: FileImage(entry.value!),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Stack(
                    children: [
                      if (isVideo)
                        const Center(
                          child: Icon(
                            Icons.play_circle_fill,
                            color: primaryGreen,
                          ),
                        ),
                      Positioned(
                        top: -2,
                        right: -2,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _pickedFiles[entry.key] = null;
                            });
                          },
                          child: const CircleAvatar(
                            radius: 8,
                            backgroundColor: Colors.red,
                            child: Icon(Icons.close,
                                size: 10, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadItem(
      String title,
      IconData icon, {
        bool isVideo = false,
      }) {
    final pickedFile = _pickedFiles[title];

    return GestureDetector(
      onTap: _isPicking ? null : () => _pickImage(title, isVideo),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: primaryGreen),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              pickedFile != null
                  ? Icons.check_circle
                  : Icons.arrow_forward,
              color: primaryGreen,
            ),
          ],
        ),
      ),
    );
  }
}
