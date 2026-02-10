import 'package:flutter/foundation.dart';

import 'package:final_crackteck/model/sales_person/lead_model.dart';

class MeetingModel {
  final int id;
  final int userId;
  final String leadId;
  final String meetTitle;
  final String meetingType;
  final String date;
  final String time;
  final String startTime;
  final String endTime;
  final String location;
  final String? attachment;
  final String meetAgenda;
  final String followUp;
  final String meetingNotes;
  final List<String> attendees;
  final String status;
  final String createdAt;
  final String updatedAt;
  final LeadModel? lead;

  const MeetingModel({
    required this.id,
    required this.userId,
    required this.leadId,
    required this.meetTitle,
    required this.meetingType,
    required this.date,
    required this.time,
    required this.startTime,
    required this.endTime,
    required this.location,
    this.attachment,
    required this.meetAgenda,
    required this.followUp,
    this.meetingNotes = '',
    this.attendees = const <String>[],
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.lead,
  });

  factory MeetingModel.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic value) {
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) {
        return int.tryParse(value) ?? 0;
      }
      return 0;
    }

    String toStr(dynamic value) {
      if (value == null) return '';
      return value.toString();
    }

    LeadModel? parseLead(dynamic value) {
      if (value is Map<String, dynamic>) {
        try {
          return LeadModel.fromJson(value);
        } catch (e, st) {
          if (kDebugMode) {
            debugPrint('MeetingModel.lead parse error: $e\n$st');
          }
        }
      }
      return null;
    }

    List<String> parseAttendees(dynamic value) {
      if (value is List) {
        return value
            .map((e) => toStr(e).trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
      if (value is String) {
        final raw = value.trim();
        if (raw.isEmpty) return const <String>[];
        return raw
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
      return const <String>[];
    }

    return MeetingModel(
      id: toInt(json['id']),
      userId: toInt(json['user_id']),
      leadId: toStr(json['lead_id'] ?? json['leadId']),
      meetTitle: toStr(json['meet_title'] ?? json['title']),
      meetingType: toStr(json['meeting_type'] ?? json['meetingType']),
      date: toStr(json['date'] ?? json['meeting_date']),
      time: toStr(json['time'] ?? json['meeting_time']),
      startTime: toStr(json['start_time'] ?? json['startTime']),
      endTime: toStr(json['end_time'] ?? json['endTime']),
      location: toStr(json['location'] ?? json['meeting_link']),
      attachment: json['attachment'] == null ? null : toStr(json['attachment']),
      meetAgenda: toStr(json['meetAgenda'] ?? json['meet_agenda'] ?? json['agenda']),
      followUp: toStr(json['followUp'] ?? json['follow_up']),
      meetingNotes: toStr(json['meeting_notes'] ?? json['notes']),
      attendees: parseAttendees(json['attendees']),
      status: toStr(json['status']),
      createdAt: toStr(json['created_at']),
      updatedAt: toStr(json['updated_at']),
      lead: parseLead(
        json['lead'] ??
            json['lead_data'] ??
            json['leadDetail'] ??
            json['lead_detail'],
      ),
    );
  }
}
