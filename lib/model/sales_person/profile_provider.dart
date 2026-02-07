import 'package:flutter/foundation.dart';

import '../../services/api_service.dart';
import 'profile_model.dart';

class ProfileProvider extends ChangeNotifier {
  ProfileModel? profile;
  bool loading = false;
  String? error;

  Future<void> loadProfile() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final result = await ApiService.fetchProfile();
      final parsed = ProfileModel.fromUserEnvelope(result);

      if (parsed == null) {
        error = 'Profile data not available';
        profile = null;
      } else {
        profile = parsed;
      }
    } catch (e, stack) {
      debugPrint('🔴 Error in ProfileProvider.loadProfile: $e');
      debugPrint(stack.toString());
      error = e.toString();
      profile = null;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshProfile() async {
    await loadProfile();
  }
}

