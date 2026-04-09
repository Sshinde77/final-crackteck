import 'dart:convert';
import 'dart:typed_data';

import 'package:final_crackteck/role_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/secure_storage_mock.dart';
import 'support/test_bootstrap.dart';

class _TransparentAssetBundle extends CachingAssetBundle {
  static final Uint8List _transparentPng = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+X2u8AAAAASUVORK5CYII=',
  );

  @override
  Future<ByteData> load(String key) async {
    return ByteData.view(_transparentPng.buffer);
  }
}

void main() {
  setUp(() async {
    await testBootstrap();
  });

  tearDown(() {
    SecureStorageMock.reset();
  });

  testWidgets('Role selection screen renders', (tester) async {
    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: _TransparentAssetBundle(),
        child: const MaterialApp(
          home: rolesccreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Field Executive'), findsOneWidget);
    expect(find.text('Delivery Man'), findsOneWidget);
    expect(find.text('Sales Person'), findsOneWidget);
  });
}
