import 'package:flutter/foundation.dart';

import '../../model/signup/common_signup_request.dart';
import '../../model/signup/delivery_signup_request.dart';
import '../../services/delivery_person/delivery_signup_service.dart';

class SignupProvider extends ChangeNotifier {
  SignupProvider({DeliverySignupService? signupService})
    : _signupService = signupService ?? DeliverySignupService();

  final DeliverySignupService _signupService;

  bool _isSubmitting = false;
  bool _lastSubmitSucceeded = false;
  String? _lastMessage;
  Map<String, dynamic>? _lastErrors;

  bool get isSubmitting => _isSubmitting;
  bool get lastSubmitSucceeded => _lastSubmitSucceeded;
  String? get lastMessage => _lastMessage;
  Map<String, dynamic>? get lastErrors => _lastErrors;

  Future<void> submit({
    required bool isDelivery,
    CommonSignupRequest? commonRequest,
    DeliverySignupRequest? deliveryRequest,
  }) async {
    _isSubmitting = true;
    _lastSubmitSucceeded = false;
    _lastMessage = null;
    _lastErrors = null;
    notifyListeners();

    try {
      final response = isDelivery
          ? await _signupService.submitDelivery(deliveryRequest!)
          : await _signupService.submitCommon(commonRequest!);

      debugPrint(
        'Signup result: success=${response.success}, message=${response.message}, errors=${response.errors}',
      );

      _lastSubmitSucceeded = response.success;
      _lastErrors = response.errors;
      _lastMessage =
          response.message ?? (response.success ? 'Signup successful' : 'Signup failed');
    } catch (error) {
      _lastSubmitSucceeded = false;
      _lastMessage = error.toString().replaceFirst('Exception: ', '');
      _lastErrors = null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
