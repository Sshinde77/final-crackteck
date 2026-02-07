import 'package:flutter/foundation.dart';

import 'followup_model.dart';
import '../../services/api_service.dart';

/// Provider to manage salesperson follow-up state and API integration.
class FollowUpProvider extends ChangeNotifier {
  List<FollowUpModel> followUps = [];
  bool loading = false;
  String? error;

  int currentPage = 1;
  int lastPage = 1;
  int total = 0;
  int perPage = 0;

  bool get hasMore => currentPage < lastPage;

  String _normalizeError(Object e) {
    final raw = e.toString().trim();
    const prefix = 'Exception: ';
    if (raw.startsWith(prefix)) {
      return raw.substring(prefix.length).trim();
    }
    return raw;
  }

  Future<void> loadFollowUps({int page = 1, bool append = false}) async {
    loading = true;
    error = null;
    if (!append) {
      currentPage = page;
    }
    notifyListeners();

    try {
      final result = await ApiService.fetchFollowUps(page: page);
      final data = result['data'];

      final List<FollowUpModel> parsed = [];
      if (data is List) {
        for (final item in data) {
          if (item is Map<String, dynamic>) {
            try {
              parsed.add(FollowUpModel.fromJson(item));
            } catch (e) {
              // Skip malformed follow-up items.
              debugPrint('Skipping malformed follow-up item: $e');
            }
          }
        }
      }

      if (append && page > 1) {
        followUps = [...followUps, ...parsed];
      } else {
        followUps = parsed;
      }

      final meta = result['meta'];
      if (meta is Map<String, dynamic>) {
        currentPage = _asInt(meta['current_page'], fallback: page);
        lastPage = _asInt(meta['last_page'], fallback: currentPage);
        total = _asInt(meta['total'], fallback: followUps.length);
        perPage = _asInt(meta['per_page'], fallback: parsed.length);
      } else {
        currentPage = page;
        lastPage = page;
        total = followUps.length;
        perPage = parsed.length;
      }
    } catch (e) {
      error = _normalizeError(e);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  int _asInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }
    return fallback;
  }
}
