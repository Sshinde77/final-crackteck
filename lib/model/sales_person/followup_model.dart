import 'package:flutter/foundation.dart';

import 'lead_model.dart';

/// Model representing a single follow-up entry from `/api/v1/follow-up`.
class FollowUpModel {
  final int id;
  final int userId;
  final String leadId;
  final DateTime followupDate;
  final String followupTime;
  final String status;
  final String remarks;
  final DateTime createdAt;
  final DateTime updatedAt;
  final LeadModel? lead;

  FollowUpModel({
    required this.id,
    required this.userId,
    required this.leadId,
    required this.followupDate,
    required this.followupTime,
    required this.status,
    required this.remarks,
    required this.createdAt,
    required this.updatedAt,
    required this.lead,
  });

  /// Defensive JSON parsing to tolerate missing or malformed fields.
  factory FollowUpModel.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    String toStr(dynamic value) {
      if (value == null) return '';
      try {
        return value.toString();
      } catch (_) {
        return '';
      }
    }

    DateTime parseDate(dynamic value) {
      final raw = toStr(value).trim();
      if (raw.isEmpty) {
        return DateTime.now();
      }
      try {
        return DateTime.parse(raw);
      } catch (_) {
        // Fallback if server sends unexpected format.
        return DateTime.now();
      }
    }

    final model = FollowUpModel(
      id: toInt(json['id']),
      userId: toInt(json['user_id']),
      leadId: toStr(json['lead_id']),
      followupDate: parseDate(json['followup_date']),
      followupTime: toStr(json['followup_time']),
      status: toStr(json['status']),
      remarks: toStr(json['remarks']),
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
      lead: json['lead'] is Map<String, dynamic>
          ? LeadModel.fromJson(json['lead'] as Map<String, dynamic>)
          : null,
    );

    if (kDebugMode) {
      debugPrint(
        'Parsed FollowUpModel(id: ${model.id}, leadId: ${model.leadId}, status: ${model.status})',
      );
    }

    return model;
  }
}

