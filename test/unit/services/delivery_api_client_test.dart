import 'package:final_crackteck/services/delivery_person/delivery_api_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('replaceId strips leading # and substitutes {id}', () {
    final client = DeliveryApiClient();
    expect(
      client.replaceId('https://example.com/orders/{id}', '#123'),
      'https://example.com/orders/123',
    );
  });

  test('replaceId throws on empty/invalid id', () {
    final client = DeliveryApiClient();
    expect(
      () => client.replaceId('https://example.com/orders/{id}', '   '),
      throwsA(isA<Exception>()),
    );
  });

  test('extractList finds lists under common keys', () {
    final client = DeliveryApiClient();
    final extracted = client.extractList(<String, dynamic>{
      'data': [
        {'id': 1},
        {'id': 2},
      ],
    });
    expect(extracted.length, 2);
    expect(extracted.first['id'], 1);
  });

  test('decodeBody marks HTML as isHtml', () {
    final client = DeliveryApiClient();
    final decoded = client.decodeBody('<html>login</html>');
    expect(decoded['isHtml'], true);
    expect(decoded['success'], false);
  });
}

