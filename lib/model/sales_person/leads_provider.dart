import 'package:flutter/foundation.dart';

import 'lead_model.dart';
import '../../services/api_service.dart';

/// Provider to manage salesperson leads state and API integration.
class LeadsProvider extends ChangeNotifier {
  List<LeadModel> leads = [];
  bool loading = false;
  String? error;

  int currentPage = 1;
  int lastPage = 1;
  int total = 0;
  int perPage = 0;

  bool get hasMore => currentPage < lastPage;

  Future<void> loadLeads(String userId, int roleId, {int page = 1, bool append = false}) async {
    loading = true;
    error = null;
    if (!append) {
      // When not appending, reset pagination.
      currentPage = page;
    }
    notifyListeners();

    try {
      final result = await ApiService.fetchLeads(userId, roleId, page: page);

      final data = result['data'];
      final List<LeadModel> parsed = [];
      if (data is List) {
        for (final item in data) {
          if (item is Map<String, dynamic>) {
            try {
              parsed.add(LeadModel.fromJson(item));
            } catch (e) {
              // Skip malformed lead items.
              debugPrint('Skipping malformed lead item: $e');
            }
          }
        }
      }

      if (append && page > 1) {
        leads = [...leads, ...parsed];
      } else {
        leads = parsed;
      }

      final meta = result['meta'];
      if (meta is Map<String, dynamic>) {
        currentPage = _asInt(meta['current_page'], fallback: page);
        lastPage = _asInt(meta['last_page'], fallback: currentPage);
        total = _asInt(meta['total'], fallback: leads.length);
        perPage = _asInt(meta['per_page'], fallback: parsed.length);
      } else {
        currentPage = page;
        lastPage = page;
        total = leads.length;
        perPage = parsed.length;
      }
    } catch (e) {
      error = e.toString();
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

