import 'package:final_crackteck/model/sales_person/task_model.dart';

/// Combined data model for the salesperson dashboard.
///
/// This model is intentionally flexible so it can represent the responses from
/// both:
/// - `GET /api/v1/dashboard?user_id={userId}&role_id={roleId}`
///   which returns `{ "meets": [...], "followup": [...] }`
/// - `GET /api/v1/sales-overview?user_id={userId}`
///   which returns the sales metrics
class DashboardData {
  /// Metrics used by the donut chart in the UI.
  final double target;
  final double achieved;
  final double pending;

  /// Simplified tasks list used by some parts of the UI.
  final List<Task> tasks;

  /// Full meeting and follow-up collections from the backend.
  final List<MeetTaskItem> meets;
  final List<FollowupTaskItem> followups;

  /// Optional sales overview counters from `/sales-overview`.
  final int lostLeads;
  final int newLeads;
  final int contactedLeads;
  final int qualifiedLeads;
  final int quotedLeads;

  DashboardData({
    required this.target,
    required this.achieved,
    required this.pending,
    required this.tasks,
    this.meets = const [],
    this.followups = const [],
    this.lostLeads = 0,
    this.newLeads = 0,
    this.contactedLeads = 0,
    this.qualifiedLeads = 0,
    this.quotedLeads = 0,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    // Parse meeting/follow-up lists when present (dashboard/task responses).
    final meets = _parseMeetsList(json['meets']);
    final followups = _parseFollowupList(json['followup']);

    // Parse sales overview metrics when present.
    final lostLeads = _parseIntSafe(json['lost_leads']);
    final newLeads = _parseIntSafe(json['new_leads']);
    final contactedLeads = _parseIntSafe(json['contacted_leads']);
    final qualifiedLeads = _parseIntSafe(json['qualified_leads']);
    final quotedLeads = _parseIntSafe(json['quoted_leads']);

    // Backwards compatible metrics for the donut chart. If explicit
    // `target/achieved/pending` are provided, prefer them. Otherwise, try to
    // derive reasonable values from the overview counters.
    final target = _parseDouble(
      json['target'] ??
          (newLeads + contactedLeads + qualifiedLeads + quotedLeads),
    );
    final achieved = _parseDouble(json['achieved'] ?? contactedLeads);
    final pending = _parseDouble(json['pending'] ?? (target - achieved));

    return DashboardData(
      target: target < 0 ? 0 : target,
      achieved: achieved < 0 ? 0 : achieved,
      pending: pending < 0 ? 0 : pending,
      tasks: _parseTaskList(json['tasks'], meets: meets, followups: followups),
      meets: meets,
      followups: followups,
      lostLeads: lostLeads,
      newLeads: newLeads,
      contactedLeads: contactedLeads,
      qualifiedLeads: qualifiedLeads,
      quotedLeads: quotedLeads,
    );
  }
}

class Task {
  final String title;
  final String leadId;
  final String followUpId;
  final String number;
  final String location;

  Task({
    required this.title,
    required this.leadId,
    required this.followUpId,
    required this.number,
    required this.location,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      title: json['title']?.toString() ?? '',
      leadId: json['lead_id']?.toString() ?? '',
      followUpId:
          json['follow_up_id']?.toString() ??
          json['followup_id']?.toString() ??
          '',
      number: json['number']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
    );
  }
}

double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) {
    final d = value.toDouble();
    if (d.isNaN || d.isInfinite) return 0.0;
    return d;
  }
  if (value is String) {
    final parsed = double.tryParse(value);
    if (parsed == null || parsed.isNaN || parsed.isInfinite) return 0.0;
    return parsed;
  }
  return 0.0;
}

int _parseIntSafe(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    final parsed = int.tryParse(value);
    return parsed ?? 0;
  }
  return 0;
}

List<MeetTaskItem> _parseMeetsList(dynamic value) {
  if (value is List) {
    return value
        .whereType<Map<String, dynamic>>()
        .map((e) => MeetTaskItem.fromJson(e))
        .toList();
  }
  return const <MeetTaskItem>[];
}

List<FollowupTaskItem> _parseFollowupList(dynamic value) {
  if (value is List) {
    return value
        .whereType<Map<String, dynamic>>()
        .map((e) => FollowupTaskItem.fromJson(e))
        .toList();
  }
  return const <FollowupTaskItem>[];
}

List<Task> _parseTaskList(
  dynamic value, {
  List<MeetTaskItem>? meets,
  List<FollowupTaskItem>? followups,
}) {
  // If the backend sends an explicit `tasks` array, use it as-is.
  if (value is List) {
    return value
        .whereType<Map<String, dynamic>>()
        .map((e) => Task.fromJson(e))
        .toList();
  }

  // Otherwise, derive a simplified task list from the meets/followup
  // collections so existing UI can still render something meaningful.
  final List<Task> result = [];
  if (meets != null) {
    for (final m in meets) {
      result.add(
        Task(
          title: m.meetTitle,
          leadId: m.leadId.toString(),
          followUpId: m.followUp,
          number: m.leadDetails?.phone ?? '',
          location: m.location,
        ),
      );
    }
  }
  if (followups != null) {
    for (final f in followups) {
      final name =
          '${f.leadDetails?.firstName ?? ''} ${f.leadDetails?.lastName ?? ''}'
              .trim();
      final title = name.isNotEmpty ? 'Follow-up with $name' : 'Follow-up';
      result.add(
        Task(
          title: title,
          leadId: f.leadId.toString(),
          followUpId: f.id.toString(),
          number: f.leadDetails?.phone ?? '',
          location: f.leadDetails?.companyName ?? '',
        ),
      );
    }
  }
  return result;
}
