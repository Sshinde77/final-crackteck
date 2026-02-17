import 'package:flutter/material.dart';

enum FieldExecutiveProductServiceStatus {
  incomplete,
  completed,
}

class FieldExecutiveProductService {
  final String title;
  final String serviceId;
  final String location;
  final String priority;
  final String description;
  final String imageUrl;
  final String requestId;
  FieldExecutiveProductServiceStatus status;

  FieldExecutiveProductService({
    required this.title,
    required this.serviceId,
    required this.location,
    required this.priority,
    this.description = '',
    this.imageUrl = '',
    this.requestId = '',
    this.status = FieldExecutiveProductServiceStatus.incomplete,
  });

  bool get isCompleted =>
      status == FieldExecutiveProductServiceStatus.completed;
}

class FieldExecutiveProductServicesController extends ChangeNotifier {
  final List<FieldExecutiveProductService> _items;

  FieldExecutiveProductServicesController(this._items);

  factory FieldExecutiveProductServicesController.withDefaults() {
    return FieldExecutiveProductServicesController([
      FieldExecutiveProductService(
        title: 'Desktop Installation',
        serviceId: '#LYCFF776567DS',
        location: 'Kandivali (West)',
        priority: 'High',
      ),
      FieldExecutiveProductService(
        title: 'Monitor Setup',
        serviceId: '#MNSP224466AA',
        location: 'Borivali (East)',
        priority: 'Medium',
      ),
      FieldExecutiveProductService(
        title: 'UPS Installation',
        serviceId: '#UPSI667788BB',
        location: 'Malad (West)',
        priority: 'Low',
      ),
      FieldExecutiveProductService(
        title: 'Keyboard and Mouse',
        serviceId: '#KBMS334455CC',
        location: 'Kandivali (West)',
        priority: 'Low',
      ),
    ]);
  }

  List<FieldExecutiveProductService> get items =>
      List.unmodifiable(_items);

  void replaceItems(
    List<FieldExecutiveProductService> nextItems, {
    bool preserveExistingStatus = true,
  }) {
    final existingStatus = <String, FieldExecutiveProductServiceStatus>{};
    if (preserveExistingStatus) {
      for (final item in _items) {
        existingStatus[item.serviceId] = item.status;
      }
    }

    _items
      ..clear()
      ..addAll(
        nextItems.map((item) {
          final previous = existingStatus[item.serviceId];
          if (previous != null) {
            item.status = previous;
          }
          return item;
        }),
      );

    notifyListeners();
  }

  FieldExecutiveProductService? findByServiceId(String serviceId) {
    try {
      return _items.firstWhere((item) => item.serviceId == serviceId);
    } catch (_) {
      return null;
    }
  }

  void markCompleted(String serviceId) {
    final item = findByServiceId(serviceId);
    if (item == null) {
      return;
    }
    if (item.status == FieldExecutiveProductServiceStatus.completed) {
      return;
    }
    item.status = FieldExecutiveProductServiceStatus.completed;
    notifyListeners();
  }

  bool get hasIncomplete =>
      _items.any((item) => item.status == FieldExecutiveProductServiceStatus.incomplete);

  bool get allCompleted =>
      _items.every((item) => item.status == FieldExecutiveProductServiceStatus.completed);
}
