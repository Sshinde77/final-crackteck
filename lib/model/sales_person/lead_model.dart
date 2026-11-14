import 'package:flutter/foundation.dart';

/// Model representing a single lead from `/api/v1/leads`.
class LeadModel {
  final int id;
  final String leadNumber;
  final String name;
  final String phone;
  final String email;
  final String dob;
  final String gender;
  final String companyName;
  final String designation;
  final String industryType;
  final String source;
  final String requirementType;
  final String budgetRange;
  final String urgency;
  final String status;
  final String createdAt;
  final String updatedAt;

  LeadModel({
    required this.id,
    required this.leadNumber,
    required this.name,
    required this.phone,
    required this.email,
    required this.dob,
    required this.gender,
    required this.companyName,
    required this.designation,
    required this.industryType,
    required this.source,
    required this.requirementType,
    required this.budgetRange,
    required this.urgency,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Defensive JSON parsing to tolerate missing or malformed fields.
  factory LeadModel.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) {
        return int.tryParse(value) ?? 0;
      }
      return 0;
    }

    String toString(dynamic value) {
      if (value == null) return '';
      try {
        return value.toString();
      } catch (_) {
        return '';
      }
    }

    final model = LeadModel(
      id: toInt(json['id']),
      leadNumber: toString(json['lead_number']),
      name: toString(json['name']),
      phone: toString(json['phone']),
      email: toString(json['email']),
      dob: toString(json['dob']),
      gender: toString(json['gender']),
      companyName: toString(json['company_name']),
      designation: toString(json['designation']),
      industryType: toString(json['industry_type']),
      source: toString(json['source']),
      requirementType: toString(json['requirement_type']),
      budgetRange: toString(json['budget_range']),
      urgency: toString(json['urgency']),
      status: toString(json['status']),
      createdAt: toString(json['created_at']),
      updatedAt: toString(json['updated_at']),
    );

    if (kDebugMode) {
      debugPrint('Parsed LeadModel(id: \\${model.id}, name: \\${model.name})');
    }

    return model;
  }
}
