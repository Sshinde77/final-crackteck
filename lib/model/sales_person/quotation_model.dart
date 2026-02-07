import 'package:flutter/foundation.dart';

/// Models for salesperson quotations and their products.
class QuotationProductModel {
  final int id;
  final int quotationId;
  final String productName;
  final String hsnCode;
  final String sku;
  final double price;
  final int quantity;
  final double tax;
  final double total;

  const QuotationProductModel({
    required this.id,
    required this.quotationId,
    required this.productName,
    required this.hsnCode,
    required this.sku,
    required this.price,
    required this.quantity,
    required this.tax,
    required this.total,
  });

  factory QuotationProductModel.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic value, {int fallback = 0}) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? fallback;
      return fallback;
    }

    double toDouble(dynamic value, {double fallback = 0}) {
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? fallback;
      return fallback;
    }

    String toStr(dynamic value) {
      if (value == null) return '';
      if (value is String) return value;
      return value.toString();
    }

    return QuotationProductModel(
      id: toInt(json['id']),
      quotationId: toInt(json['quotation_id'] ?? json['quotationId']),
      productName: toStr(json['product_name'] ?? json['name'] ?? json['product']),
      hsnCode: toStr(json['hsn_code'] ?? json['hsn'] ?? ''),
      sku: toStr(json['sku'] ?? json['sku_code'] ?? ''),
      price: toDouble(json['price'] ?? json['unit_price']),
      quantity: toInt(json['quantity'] ?? json['qty'] ?? 1, fallback: 1),
      tax: toDouble(json['tax'] ?? json['tax_amount']),
      total: toDouble(json['total'] ?? json['line_total']),
    );
  }
}

class QuotationModel {
  final int id;
  final String leadId;
  final String quotationNumber;
  final String clientName;
  final String status;
  final String createdAtRaw;
  final String updatedAtRaw;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<QuotationProductModel> products;

  const QuotationModel({
    required this.id,
    required this.leadId,
    required this.quotationNumber,
    required this.clientName,
    required this.status,
    required this.createdAtRaw,
    required this.updatedAtRaw,
    required this.createdAt,
    required this.updatedAt,
    required this.products,
  });

  factory QuotationModel.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic value, {int fallback = 0}) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? fallback;
      return fallback;
    }

    String toStr(dynamic value) {
      if (value == null) return '';
      if (value is String) return value;
      return value.toString();
    }

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      final s = toStr(value).trim();
      if (s.isEmpty) return null;
      try {
        return DateTime.parse(s);
      } catch (_) {
        if (kDebugMode) {
          debugPrint('QuotationModel date parse failed for "$s"');
        }
        return null;
      }
    }

    final id = toInt(json['id']);
    final leadId = toStr(json['lead_id'] ?? json['leadId']);

    final quotationNumber = toStr(
      json['quotation_no'] ??
          json['quotation_number'] ??
          json['quotation_id'] ??
          json['quote_number'] ??
          id,
    );

    String clientName = toStr(json['client_name'] ?? json['customer_name']);
    final lead = json['lead'];
    if (clientName.isEmpty && lead is Map<String, dynamic>) {
      clientName = toStr(
        lead['name'] ?? lead['full_name'] ?? lead['company_name'],
      );
    }

    final status = toStr(json['status']);

    final createdRaw = toStr(json['created_at'] ?? json['quote_date']);
    final updatedRaw = toStr(json['updated_at'] ?? json['expiry_date']);

    final createdAt = parseDate(createdRaw);
    final updatedAt = parseDate(updatedRaw);

    final List<QuotationProductModel> products = <QuotationProductModel>[];
    final rawProducts = json['products'] ?? json['quotation_products'];
    if (rawProducts is List) {
      for (final item in rawProducts) {
        if (item is Map<String, dynamic>) {
          try {
            products.add(QuotationProductModel.fromJson(item));
          } catch (e, st) {
            if (kDebugMode) {
              debugPrint('QuotationProductModel parse error: $e\n$st');
            }
          }
        }
      }
    }

    return QuotationModel(
      id: id,
      leadId: leadId,
      quotationNumber: quotationNumber,
      clientName: clientName,
      status: status,
      createdAtRaw: createdRaw,
      updatedAtRaw: updatedRaw,
      createdAt: createdAt,
      updatedAt: updatedAt,
      products: products,
    );
  }
}

