import 'package:flutter/foundation.dart';

import 'quotation_model.dart';
import '../../services/api_service.dart';

/// Provider to manage salesperson quotations list and API integration.
class QuotationsProvider extends ChangeNotifier {
  List<QuotationModel> quotations = <QuotationModel>[];
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

  Future<void> loadQuotations({int page = 1, bool append = false}) async {
    loading = true;
    error = null;
    if (!append) {
      currentPage = page;
    }
    notifyListeners();

    try {
      final result = await ApiService.fetchQuotations(page: page);
      final data = result['data'];

      final List<QuotationModel> parsed = <QuotationModel>[];
      if (data is List) {
        for (final item in data) {
          if (item is Map<String, dynamic>) {
            try {
              parsed.add(QuotationModel.fromJson(item));
            } catch (e, st) {
              if (kDebugMode) {
                debugPrint('Skipping malformed quotation item: $e\n$st');
              }
            }
          }
        }
      }

      if (append && page > 1) {
        quotations = <QuotationModel>[...quotations, ...parsed];
      } else {
        quotations = parsed;
      }

      final meta = result['meta'];
      if (meta is Map<String, dynamic>) {
        currentPage = _asInt(meta['current_page'], fallback: page);
        lastPage = _asInt(meta['last_page'], fallback: currentPage);
        total = _asInt(meta['total'], fallback: quotations.length);
        perPage = _asInt(meta['per_page'], fallback: parsed.length);
      } else {
        currentPage = page;
        lastPage = page;
        total = quotations.length;
        perPage = parsed.length;
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('QuotationsProvider loadQuotations error: $e\n$st');
      }
      error = _normalizeError(e);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshQuotations() async {
    await loadQuotations(page: 1, append: false);
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
