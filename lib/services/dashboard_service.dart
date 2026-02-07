import 'package:final_crackteck/model/sales_person/notification_model.dart';
import 'package:final_crackteck/model/sales_person/sales_overview_model.dart';
import 'package:final_crackteck/model/sales_person/task_model.dart';
import 'package:final_crackteck/services/api_service.dart';

/// Service class for handling all salesperson dashboard related API calls.
///
/// This layer is responsible for:
/// - Calling the dashboard-related endpoints from [ApiService]
/// - Mapping raw JSON into strongly-typed models
/// - Skipping malformed list entries so the UI never crashes
class DashboardService {
  /// Fetch dashboard data for a specific user
  /// Endpoint: GET /dashboard?user_id={userId}&role_id={roleId}
  /// Returns [DashboardData] with sales metrics and tasks
  static Future<DashboardData> getDashboard(String userId) async {
    final res = await ApiService.fetchDashboard(userId);
    return DashboardData.fromJson(res);
  }

  /// Fetch sales overview data
  /// Endpoint: GET /sales-overview?user_id={userId}
  /// Returns [DashboardData] with sales performance metrics
  static Future<DashboardData> getSalesOverview() async {
    final res = await ApiService.fetchSalesOverview();
    return DashboardData.fromJson(res);
  }

  /// Fetch list of tasks
  /// Endpoint: GET /task?user_id={userId}
  /// Returns list of [TaskModel] objects
  static Future<List<TaskModel>> getTasks() async {
    final taskList = await ApiService.fetchTasks();

    final List<TaskModel> tasks = [];
    for (final item in taskList) {
      if (item is Map<String, dynamic>) {
        try {
          tasks.add(TaskModel.fromJson(item));
        } catch (_) {
          // Skip malformed task items
        }
      }
    }
    return tasks;
  }

  /// Fetch list of notifications
  /// Endpoint: GET /notifications
  /// Returns list of [NotificationModel] objects
  static Future<List<NotificationModel>> getNotifications() async {
    final notificationList = await ApiService.fetchNotifications();

    final List<NotificationModel> notifications = [];
    for (final item in notificationList) {
      if (item is Map<String, dynamic>) {
        try {
          notifications.add(NotificationModel.fromJson(item));
        } catch (_) {
          // Skip malformed notification items
        }
      }
    }
    return notifications;
  }
}
