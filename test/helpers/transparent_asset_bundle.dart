import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';

/// Asset bundle that always returns a 1x1 transparent PNG.
///
/// Use this to avoid loading real asset files in widget tests.
class TransparentAssetBundle extends CachingAssetBundle {
  static final Uint8List _transparentPng = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+X2u8AAAAASUVORK5CYII=',
  );

  @override
  Future<ByteData> load(String key) async {
    return ByteData.view(_transparentPng.buffer);
  }
}

