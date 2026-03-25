class DeliveryAttendanceModel {
  const DeliveryAttendanceModel({
    required this.loginAt,
    required this.logoutAt,
  });

  final DateTime? loginAt;
  final DateTime? logoutAt;

  factory DeliveryAttendanceModel.fromJson(Map<String, dynamic> json) {
    return DeliveryAttendanceModel(
      loginAt: _parseDateTime(
        json['login_at'] ??
            json['check_in'] ??
            json['clock_in'] ??
            json['auth_log']?['login_at'],
      ),
      logoutAt: _parseDateTime(
        json['logout_at'] ??
            json['check_out'] ??
            json['clock_out'] ??
            json['auth_log']?['logout_at'],
      ),
    );
  }

  factory DeliveryAttendanceModel.empty() {
    return const DeliveryAttendanceModel(loginAt: null, logoutAt: null);
  }

  DeliveryAttendanceModel copyWith({
    DateTime? loginAt,
    DateTime? logoutAt,
    bool preserveLogin = true,
    bool preserveLogout = true,
  }) {
    return DeliveryAttendanceModel(
      loginAt: loginAt ?? (preserveLogin ? this.loginAt : null),
      logoutAt: logoutAt ?? (preserveLogout ? this.logoutAt : null),
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    final parsed = DateTime.tryParse(text);
    if (parsed == null) return null;
    return parsed.isUtc ? parsed.toLocal() : parsed;
  }
}
