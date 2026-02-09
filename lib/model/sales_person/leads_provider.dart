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

  String _normalizeError(Object e) {
    final raw = e.toString().trim();
    const prefix = 'Exception: ';
    if (raw.startsWith(prefix)) {
      return raw.substring(prefix.length).trim();
    }
    return raw;
  }

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
      error = _normalizeError(e);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteLead(String leadId) async {
    error = null;
    notifyListeners();

    try {
      await ApiService.deleteLead(leadId);

      leads = leads.where((lead) => lead.id.toString() != leadId).toList();
      if (total > 0) {
        total -= 1;
      }
      notifyListeners();
      return true;
    } catch (e) {
      error = _normalizeError(e);
      notifyListeners();
      return false;
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
