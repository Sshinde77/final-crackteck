class DiagnosisItem {
  final String name;
  final String statusLabel;
  final String? report;

  const DiagnosisItem({
    required this.name,
    this.statusLabel = '',
    this.report,
  });

  factory DiagnosisItem.fromJson(Map<String, dynamic> json) {
    dynamic readRaw(List<String> keys) {
      for (final key in keys) {
        if (!json.containsKey(key)) continue;
        final value = json[key];
        if (value == null) continue;
        return value;
      }
      return null;
    }

    String readString(List<String> keys) {
      final value = readRaw(keys);
      if (value == null || value is Map || value is List) return '';
      final text = value.toString().trim();
      if (text.isEmpty || text.toLowerCase() == 'null') return '';
      return text;
    }

    final name = readString(const [
      'name',
      'diagnosis_name',
      'diagnosisName',
      'diagnosis',
      'title',
      'label',
    ]);

    final reportText = readString(const [
      'report',
      'remarks',
      'remark',
      'note',
      'notes',
      'problem_solution',
      'problemSolution',
      'description',
    ]);

    final rawStatus = readRaw(const [
      'status',
      'status_label',
      'statusLabel',
      'diagnosis_status',
      'diagnosisStatus',
      'is_working',
      'isWorking',
      'working',
    ]);

    return DiagnosisItem(
      name: name,
      statusLabel: _normalizeStatusLabel(rawStatus),
      report: reportText.isEmpty ? null : reportText,
    );
  }

  static String _normalizeStatusLabel(dynamic rawStatus) {
    if (rawStatus == null) return '';
    if (rawStatus is bool) {
      return rawStatus ? 'Working' : 'Not Working';
    }

    final rawText = rawStatus.toString().trim();
    if (rawText.isEmpty || rawText.toLowerCase() == 'null') return '';

    final normalized = rawText
        .toLowerCase()
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    switch (normalized) {
      case 'working':
        return 'Working';
      case 'not working':
        return 'Not Working';
      case 'add to pickup':
        return 'Add to Pickup';
      case 'use stock in hand':
        return 'Use Stock in Hand';
      case 'request a part':
        return 'Request a Part';
      default:
        return _toTitleCase(normalized);
    }
  }

  static String _toTitleCase(String text) {
    if (text.isEmpty) return '';
    final words = text.split(' ');
    return words
        .where((word) => word.isNotEmpty)
        .map(
          (word) =>
              '${word[0].toUpperCase()}${word.length > 1 ? word.substring(1) : ''}',
        )
        .join(' ');
  }
}
