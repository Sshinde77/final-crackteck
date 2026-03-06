import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class MediaPickerService {
  const MediaPickerService._();

  static Future<XFile?> pickImage(
    BuildContext context, {
    required ImagePicker picker,
    required ImageSource source,
    int? imageQuality,
  }) async {
    final bool canAccess = await _ensurePermissionForSource(
      context,
      source: source,
      isVideo: false,
    );
    if (!canAccess) {
      return null;
    }

    try {
      return await picker.pickImage(
        source: source,
        imageQuality: imageQuality,
      );
    } on PlatformException catch (error) {
      await _showPickerErrorDialog(
        context,
        title: source == ImageSource.camera
            ? 'Camera unavailable'
            : 'Photos unavailable',
        message: _messageForPlatformError(
          error,
          source: source,
          isVideo: false,
        ),
      );
      return null;
    } catch (_) {
      await _showPickerErrorDialog(
        context,
        title: source == ImageSource.camera
            ? 'Camera unavailable'
            : 'Photos unavailable',
        message: source == ImageSource.camera
            ? 'The camera could not be opened on this device. Please try again.'
            : 'Photos could not be opened right now. Please try again.',
      );
      return null;
    }
  }

  static Future<XFile?> pickVideo(
    BuildContext context, {
    required ImagePicker picker,
    required ImageSource source,
  }) async {
    final bool canAccess = await _ensurePermissionForSource(
      context,
      source: source,
      isVideo: true,
    );
    if (!canAccess) {
      return null;
    }

    try {
      return await picker.pickVideo(source: source);
    } on PlatformException catch (error) {
      await _showPickerErrorDialog(
        context,
        title: source == ImageSource.camera
            ? 'Camera unavailable'
            : 'Videos unavailable',
        message: _messageForPlatformError(
          error,
          source: source,
          isVideo: true,
        ),
      );
      return null;
    } catch (_) {
      await _showPickerErrorDialog(
        context,
        title: source == ImageSource.camera
            ? 'Camera unavailable'
            : 'Videos unavailable',
        message: source == ImageSource.camera
            ? 'The camera could not record video on this device. Please try again.'
            : 'Videos could not be opened right now. Please try again.',
      );
      return null;
    }
  }

  static Future<bool> _ensurePermissionForSource(
    BuildContext context, {
    required ImageSource source,
    required bool isVideo,
  }) async {
    if (source == ImageSource.gallery) {
      if (!Platform.isIOS) {
        return true;
      }
      return _requestPermission(
        context,
        permission: Permission.photos,
        title: 'Photos permission needed',
        message:
            'Allow photo library access so you can attach existing images to the service record.',
      );
    }

    final bool cameraGranted = await _requestPermission(
      context,
      permission: Permission.camera,
      title: 'Camera permission needed',
      message:
          'Allow camera access so you can capture installation and receipt photos in the app.',
    );
    if (!cameraGranted) {
      return false;
    }

    if (!isVideo) {
      return true;
    }

    return _requestPermission(
      context,
      permission: Permission.microphone,
      title: 'Microphone permission needed',
      message:
          'Allow microphone access so recorded service videos can include audio when needed.',
    );
  }

  static Future<bool> _requestPermission(
    BuildContext context, {
    required Permission permission,
    required String title,
    required String message,
  }) async {
    PermissionStatus status = await permission.status;
    if (_isGranted(status)) {
      return true;
    }

    status = await permission.request();
    if (_isGranted(status)) {
      return true;
    }

    if (!context.mounted) {
      return false;
    }

    await _showPermissionDialog(
      context,
      title: title,
      message: message,
      isPermanentlyDenied: status.isPermanentlyDenied || status.isRestricted,
    );
    return false;
  }

  static bool _isGranted(PermissionStatus status) {
    return status.isGranted || status.isLimited;
  }

  static Future<void> _showPermissionDialog(
    BuildContext context, {
    required String title,
    required String message,
    required bool isPermanentlyDenied,
  }) async {
    if (!context.mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(
            isPermanentlyDenied
                ? '$message Please enable the permission from system settings.'
                : '$message If you already denied it, you can enable it from system settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Not now'),
            ),
            TextButton(
              onPressed: () async {
                await openAppSettings();
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('Open settings'),
            ),
          ],
        );
      },
    );
  }

  static Future<void> _showPickerErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    if (!context.mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  static String _messageForPlatformError(
    PlatformException error, {
    required ImageSource source,
    required bool isVideo,
  }) {
    final String code = error.code.toLowerCase();
    final String details = '${error.message ?? ''} ${error.details ?? ''}'
        .toLowerCase();

    if (code.contains('camera') || details.contains('camera')) {
      if (code.contains('no_available_camera') ||
          details.contains('no available camera') ||
          details.contains('no camera available')) {
        return 'No camera is available on this device.';
      }
      return isVideo
          ? 'The camera could not start video capture. Please close other camera apps and try again.'
          : 'The camera could not start. Please close other camera apps and try again.';
    }

    if (source == ImageSource.gallery) {
      return 'The selected media library could not be opened.';
    }

    return isVideo
        ? 'Video capture failed unexpectedly. Please try again.'
        : 'Image capture failed unexpectedly. Please try again.';
  }
}
