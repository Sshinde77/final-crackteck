import 'package:flutter/foundation.dart';

import 'package:final_crackteck/model/sales_person/meeting_model.dart';
import 'package:final_crackteck/services/api_service.dart';

class MeetingsProvider extends ChangeNotifier {
  List<MeetingModel> meetings = <MeetingModel>[];
  bool isLoading = false;
  String? errorMessage;

  int currentPage = 1;
  int totalPages = 1;
  bool hasMore = false;

  String _normalizeError(Object e) {
    final raw = e.toString().trim();
    const prefix = 'Exception: ';
    if (raw.startsWith(prefix)) {
      return raw.substring(prefix.length).trim();
    }
    return raw;
  }

  Future<void> loadMeetings(
    String userId,
    int roleId, {
    int page = 1,
    bool append = false,
  }) async {
    isLoading = true;
    errorMessage = null;
    if (!append) {
      currentPage = page;
    }
    notifyListeners();

    try {
      final response = await ApiService.fetchMeetings(userId, roleId, page: page);
      final data = response['data'];

      final List<MeetingModel> parsed = <MeetingModel>[];
      if (data is List) {
        for (final item in data) {
          if (item is Map<String, dynamic>) {
            try {
              parsed.add(MeetingModel.fromJson(item));
            } catch (e, st) {
              if (kDebugMode) {
                debugPrint('MeetingsProvider item parse error: $e\n$st');
              }
            }
          }
        }
      }

      if (append && page > 1) {
        meetings = <MeetingModel>[...meetings, ...parsed];
      } else {
        meetings = parsed;
      }

      final meta = response['meta'];
      if (meta is Map<String, dynamic>) {
        int _toInt(dynamic value, {int fallback = 0}) {
          if (value is int) return value;
          if (value is double) return value.toInt();
          if (value is String) return int.tryParse(value) ?? fallback;
          return fallback;
        }

        currentPage = _toInt(meta['current_page'], fallback: page);
        totalPages = _toInt(meta['last_page'], fallback: currentPage);
        hasMore = currentPage < totalPages;
      } else {
        currentPage = 1;
        totalPages = 1;
        hasMore = false;
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('MeetingsProvider loadMeetings error: $e\n$st');
      }
      errorMessage = _normalizeError(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshMeetings(String userId, int roleId) async {
    await loadMeetings(userId, roleId, page: 1, append: false);
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }
}
