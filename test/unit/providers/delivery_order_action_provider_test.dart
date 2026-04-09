import 'package:final_crackteck/model/api_response.dart';
import 'package:final_crackteck/provider/delivery_person/delivery_order_action_provider.dart';
import 'package:final_crackteck/services/delivery_person/delivery_orders_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDeliveryOrdersService extends DeliveryOrdersService {
  _FakeDeliveryOrdersService({
    required this.verifySuccess,
    required this.deliverSuccess,
  });

  final bool verifySuccess;
  final bool deliverSuccess;

  int verifyCount = 0;
  int deliverCount = 0;

  @override
  Future<ApiResponse<Map<String, dynamic>>> verifyOrderOtp({
    required String orderId,
    required String otp,
  }) async {
    verifyCount++;
    return ApiResponse<Map<String, dynamic>>(
      success: verifySuccess,
      message: verifySuccess ? 'OTP ok' : 'OTP invalid',
      data: const <String, dynamic>{},
    );
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> markOrderDelivered(
    String orderId,
  ) async {
    deliverCount++;
    return ApiResponse<Map<String, dynamic>>(
      success: deliverSuccess,
      message: deliverSuccess ? 'Delivered' : 'Delivery failed',
      data: const <String, dynamic>{},
    );
  }
}

void main() {
  group('DeliveryOrderActionProvider', () {
    testWidgets('startOtpTimer counts down', (tester) async {
      // Arrange
      final service = _FakeDeliveryOrdersService(
        verifySuccess: true,
        deliverSuccess: true,
      );
      final provider = DeliveryOrderActionProvider(
        orderId: '123',
        ordersService: service,
      );

      expect(provider.secondsRemaining, 80);
      expect(provider.canResend, isFalse);

      // Act
      provider.startOtpTimer();
      await tester.pump(const Duration(seconds: 1));

      // Assert
      expect(provider.secondsRemaining, 79);
      expect(provider.canResend, isFalse);
    });

    test('verifyAndDeliver calls verify then deliver on success', () async {
      // Arrange
      final service = _FakeDeliveryOrdersService(
        verifySuccess: true,
        deliverSuccess: true,
      );
      final provider = DeliveryOrderActionProvider(
        orderId: '123',
        ordersService: service,
      );

      // Act
      final message = await provider.verifyAndDeliver('1234');

      // Assert
      expect(service.verifyCount, 1);
      expect(service.deliverCount, 1);
      expect(message.toLowerCase(), contains('delivered'));
      expect(provider.lastActionSucceeded, isTrue);
    });

    test('verifyAndDeliver stops when OTP verification fails', () async {
      // Arrange
      final service = _FakeDeliveryOrdersService(
        verifySuccess: false,
        deliverSuccess: true,
      );
      final provider = DeliveryOrderActionProvider(
        orderId: '123',
        ordersService: service,
      );

      // Act
      final message = await provider.verifyAndDeliver('9999');

      // Assert
      expect(service.verifyCount, 1);
      expect(service.deliverCount, 0);
      expect(message.toLowerCase(), contains('otp'));
      expect(provider.lastActionSucceeded, isFalse);
    });
  });
}
