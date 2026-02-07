class NotificationModel {
  final String title;
  final String message;
  final String time;

  NotificationModel.fromJson(Map<String, dynamic> json)
    : title = (json['title'] ?? 'No Title').toString(),
      message = (json['message'] ?? 'No Message').toString(),
      time = (json['time'] ?? '').toString();
}
