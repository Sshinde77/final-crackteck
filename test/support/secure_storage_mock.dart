import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class SecureStorageMock {
  SecureStorageMock._();

  static const MethodChannel _channel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  static final Map<String, String> _store = <String, String>{};
  static bool _installed = false;

  static void install() {
    if (_installed) return;
    TestWidgetsFlutterBinding.ensureInitialized();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (MethodCall call) async {
      final Object? rawArgs = call.arguments;
      final Map<Object?, Object?> args =
          rawArgs is Map ? rawArgs : const <Object?, Object?>{};
      final String? key = args['key']?.toString();

      switch (call.method) {
        case 'write':
          if (key != null) {
            _store[key] = args['value']?.toString() ?? '';
          }
          return null;
        case 'read':
          if (key == null) return null;
          return _store[key];
        case 'delete':
          if (key != null) {
            _store.remove(key);
          }
          return null;
        case 'deleteAll':
          _store.clear();
          return null;
        case 'containsKey':
          if (key == null) return false;
          return _store.containsKey(key);
        case 'readAll':
          return Map<String, String>.from(_store);
        default:
          return null;
      }
    });

    _installed = true;
  }

  static void reset() {
    if (!_installed) return;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
    _store.clear();
    _installed = false;
  }
}

