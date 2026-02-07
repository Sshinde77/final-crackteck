//   TaskModel.fromJson(Map<String, dynamic> json) {
//     return TaskModel(
//       id: json['id'].toString(),
//       title: json['title'] ?? '',
//       customerName: json['customer_name'] ?? '',
//       taskStatus: json['status'] ?? '',
//     );
//   }
// }

int _parseInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    final parsed = int.tryParse(value);
    return parsed ?? 0;
  }
  return 0;
}

String _parseString(dynamic value, String fallback) {
  if (value == null) return fallback;
  if (value is String) return value;
  return value.toString();
}

/// Lead details attached to a meeting or follow-up task.
///
/// This maps the `lead_details` object returned by the backend for
/// both `/dashboard` and `/task` responses.
class LeadDetails {
  final int id;
  final int userId;
  final String firstName;
  final String lastName;
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

  LeadDetails({
    required this.id,
    required this.userId,
    required this.firstName,
    required this.lastName,
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

  factory LeadDetails.fromJson(Map<String, dynamic> json) {
    return LeadDetails(
      id: _parseInt(json['id']),
      userId: _parseInt(json['user_id']),
      firstName: _parseString(json['first_name'], ''),
      lastName: _parseString(json['last_name'], ''),
      phone: _parseString(json['phone'], ''),
      email: _parseString(json['email'], ''),
      dob: _parseString(json['dob'], ''),
      gender: _parseString(json['gender'], ''),
      companyName: _parseString(json['company_name'], ''),
      designation: _parseString(json['designation'], ''),
      industryType: _parseString(json['industry_type'], ''),
      source: _parseString(json['source'], ''),
      requirementType: _parseString(json['requirement_type'], ''),
      budgetRange: _parseString(json['budget_range'], ''),
      urgency: _parseString(json['urgency'], ''),
      status: _parseString(json['status'], ''),
      createdAt: _parseString(json['created_at'], ''),
      updatedAt: _parseString(json['updated_at'], ''),
    );
  }
}

/// Represents a meeting entry from the `meets` array.
class MeetTaskItem {
  final int id;
  final int userId;
  final int leadId;
  final String meetTitle;
  final String meetingType;
  final String date;
  final String time;
  final String location;
  final String attachment;
  final String meetAgenda;
  final String followUp;
  final String status;
  final String createdAt;
  final String updatedAt;
  final LeadDetails? leadDetails;

  MeetTaskItem({
    required this.id,
    required this.userId,
    required this.leadId,
    required this.meetTitle,
    required this.meetingType,
    required this.date,
    required this.time,
    required this.location,
    required this.attachment,
    required this.meetAgenda,
    required this.followUp,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.leadDetails,
  });

  factory MeetTaskItem.fromJson(Map<String, dynamic> json) {
    return MeetTaskItem(
      id: _parseInt(json['id']),
      userId: _parseInt(json['user_id']),
      leadId: _parseInt(json['lead_id']),
      meetTitle: _parseString(json['meet_title'], ''),
      meetingType: _parseString(json['meeting_type'], ''),
      date: _parseString(json['date'], ''),
      time: _parseString(json['time'], ''),
      location: _parseString(json['location'], ''),
      attachment: _parseString(json['attachment'], ''),
      meetAgenda: _parseString(json['meetAgenda'], ''),
      followUp: _parseString(json['followUp'], ''),
      status: _parseString(json['status'], ''),
      createdAt: _parseString(json['created_at'], ''),
      updatedAt: _parseString(json['updated_at'], ''),
      leadDetails: json['lead_details'] is Map<String, dynamic>
          ? LeadDetails.fromJson(json['lead_details'])
          : null,
    );
  }
}

/// Represents a follow-up entry from the `followup` array.
class FollowupTaskItem {
  final int id;
  final int userId;
  final int leadId;
  final String followupDate;
  final String followupTime;
  final String status;
  final String remarks;
  final String createdAt;
  final String updatedAt;
  final LeadDetails? leadDetails;

  FollowupTaskItem({
    required this.id,
    required this.userId,
    required this.leadId,
    required this.followupDate,
    required this.followupTime,
    required this.status,
    required this.remarks,
    required this.createdAt,
    required this.updatedAt,
    this.leadDetails,
  });

  factory FollowupTaskItem.fromJson(Map<String, dynamic> json) {
    return FollowupTaskItem(
      id: _parseInt(json['id']),
      userId: _parseInt(json['user_id']),
      leadId: _parseInt(json['lead_id']),
      followupDate: _parseString(json['followup_date'], ''),
      followupTime: _parseString(json['followup_time'], ''),
      status: _parseString(json['status'], ''),
      remarks: _parseString(json['remarks'], ''),
      createdAt: _parseString(json['created_at'], ''),
      updatedAt: _parseString(json['updated_at'], ''),
      leadDetails: json['lead_details'] is Map<String, dynamic>
          ? LeadDetails.fromJson(json['lead_details'])
          : null,
    );
  }
}

class TaskModel {
  final int id;
  final String title;
  final String leadId;
  final String followUpId;
  final String phone;
  final String location;
  final String status;
  final LeadDetails? leadDetails;
  final MeetTaskItem? meet;
  final FollowupTaskItem? followup;

  TaskModel({
    required this.id,
    required this.title,
    required this.leadId,
    required this.followUpId,
    required this.phone,
    required this.location,
    required this.status,
    this.leadDetails,
    this.meet,
    this.followup,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    final hasMeetFields =
        json.containsKey('meet_title') || json.containsKey('meeting_type');
    final hasFollowupFields =
        json.containsKey('followup_date') || json.containsKey('followup_time');

    final LeadDetails? leadDetails =
        json['lead_details'] is Map<String, dynamic>
        ? LeadDetails.fromJson(json['lead_details'])
        : null;

    final MeetTaskItem? meetItem = hasMeetFields
        ? MeetTaskItem.fromJson(json)
        : null;
    final FollowupTaskItem? followupItem = hasFollowupFields
        ? FollowupTaskItem.fromJson(json)
        : null;

    // Determine a human-friendly title
    String title;
    if (json.containsKey('title')) {
      title = _parseString(json['title'], 'Untitled Task');
    } else if (hasMeetFields) {
      title = _parseString(json['meet_title'], 'Untitled Meeting');
    } else if (hasFollowupFields) {
      final name =
          '${leadDetails?.firstName ?? ''} ${leadDetails?.lastName ?? ''}'
              .trim();
      title = name.isNotEmpty ? 'Follow-up with $name' : 'Follow-up';
    } else {
      title = 'Untitled Task';
    }

    final phone = leadDetails?.phone ?? _parseString(json['phone'], 'N/A');

    String location = _parseString(json['location'], '');
    if (location.isEmpty && leadDetails != null) {
      location = _parseString(leadDetails.companyName, 'N/A');
    }
    if (location.isEmpty) {
      location = 'N/A';
    }

    final leadId = _parseString(json['lead_id'], 'N/A');

    String followUpId;
    if (json.containsKey('followup_id')) {
      followUpId = _parseString(json['followup_id'], 'N/A');
    } else if (hasMeetFields) {
      followUpId = _parseString(json['followUp'], 'N/A');
    } else if (hasFollowupFields) {
      followUpId = _parseString(json['id'], 'N/A');
    } else {
      followUpId = 'N/A';
    }

    final status = _parseString(json['status'], 'pending');

    return TaskModel(
      id: _parseInt(json['id']),
      title: title,
      leadId: leadId,
      followUpId: followUpId,
      phone: phone,
      location: location,
      status: status,
      leadDetails: leadDetails,
      meet: meetItem,
      followup: followupItem,
    );
  }
}
