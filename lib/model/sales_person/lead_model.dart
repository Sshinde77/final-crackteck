import 'package:flutter/foundation.dart';

/// Model representing a single lead from `/api/v1/leads`.
class LeadModel {
  final int id;
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
    int _toInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) {
        return int.tryParse(value) ?? 0;
      }
      return 0;
    }

    String _toString(dynamic value) {
      if (value == null) return '';
      try {
        return value.toString();
      } catch (_) {
        return '';
      }
    }

    final model = LeadModel(
      id: _toInt(json['id']),
      name: _toString(json['name']),
      phone: _toString(json['phone']),
      email: _toString(json['email']),
      dob: _toString(json['dob']),
      gender: _toString(json['gender']),
      companyName: _toString(json['company_name']),
      designation: _toString(json['designation']),
      industryType: _toString(json['industry_type']),
      source: _toString(json['source']),
      requirementType: _toString(json['requirement_type']),
      budgetRange: _toString(json['budget_range']),
      urgency: _toString(json['urgency']),
      status: _toString(json['status']),
      createdAt: _toString(json['created_at']),
      updatedAt: _toString(json['updated_at']),
    );

    if (kDebugMode) {
      debugPrint('Parsed LeadModel(id: \\${model.id}, name: \\${model.name})');
    }

    return model;
  }
}

