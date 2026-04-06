import 'package:final_crackteck/model/sales_person/notification_model.dart';
import 'package:final_crackteck/model/sales_person/sales_overview_model.dart';
import 'package:final_crackteck/model/sales_person/task_model.dart';
import 'package:final_crackteck/services/dashboard_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Provider for managing sales dashboard state and data
class DashboardProvider extends ChangeNotifier {
  DashboardData? sales;
  List<TaskModel> tasks = [];
  List<NotificationModel> notifications = [];
  String? _lastLoadedUserId;

  bool loading = false;
  String? error;

  Future<void> _runWithLoading(Future<void> Function() action) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      await action();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> _runWithoutLoading(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      error = e.toString();
    } finally {
      notifyListeners();
    }
  }

  /// Load all dashboard data including sales overview and tasks.
  ///
  /// Uses the following endpoints:
  /// - GET /dashboard for sales data and today-task cards
  ///
  /// NOTE: Notifications are **not** loaded automatically anymore to avoid
  /// hitting the `/notifications` API, which is still under development.
  /// The [notifications] list will remain unchanged unless explicitly updated
  /// via a future, opt-in method.
  Future<void> loadDashboard(String userId) async {
    await _runWithLoading(() async {
      _lastLoadedUserId = userId;

      // Fetch core dashboard data (meets/followups and any inline metrics)
      final dashboardData = await DashboardService.getDashboard(userId);

      // Fetch sales overview metrics from /sales-overview. If this call fails
      // we still want the rest of the dashboard to load, so catch errors
      // locally instead of failing the whole load.
      DashboardData? overviewData;
      try {
        overviewData = await DashboardService.getSalesOverview();
      } catch (e) {
        debugPrint('⚠️ Failed to load sales-overview: $e');
      }

      // Merge dashboard + sales-overview into a single DashboardData used by
      // the UI. Prefer non-zero metrics from sales-overview while keeping the
      // richer collections (meets/followups/tasks) from the /dashboard call.
      if (overviewData != null) {
        sales = DashboardData(
          target: overviewData.target != 0
              ? overviewData.target
              : dashboardData.target,
          achieved: overviewData.achieved != 0
              ? overviewData.achieved
              : dashboardData.achieved,
          pending: overviewData.pending != 0
              ? overviewData.pending
              : dashboardData.pending,
          tasks: dashboardData.tasks,
          meets: dashboardData.meets,
          followups: dashboardData.followups,
          lostLeads: overviewData.lostLeads != 0
              ? overviewData.lostLeads
              : dashboardData.lostLeads,
          newLeads: overviewData.newLeads != 0
              ? overviewData.newLeads
              : dashboardData.newLeads,
          contactedLeads: overviewData.contactedLeads != 0
              ? overviewData.contactedLeads
              : dashboardData.contactedLeads,
          qualifiedLeads: overviewData.qualifiedLeads != 0
              ? overviewData.qualifiedLeads
              : dashboardData.qualifiedLeads,
          quotedLeads: overviewData.quotedLeads != 0
              ? overviewData.quotedLeads
              : dashboardData.quotedLeads,
        );
      } else {
        sales = dashboardData;
      }

      debugPrint(
        '📊 DashboardData for user $userId -> '
        'target: ${sales?.target}, achieved: ${sales?.achieved}, pending: ${sales?.pending}',
      );
      debugPrint(
        '📊 Sales metrics -> '
        'lost: ${sales?.lostLeads}, new: ${sales?.newLeads}, '
        'contacted: ${sales?.contactedLeads}, '
        'qualified: ${sales?.qualifiedLeads}, quoted: ${sales?.quotedLeads}',
      );

      // Build Today Task cards directly from the /dashboard response.
      tasks = DashboardService.buildDashboardTasks(dashboardData);
    });
  }

  /// Load only sales overview data
  /// Uses GET /sales-overview endpoint
  Future<void> loadSalesOverview() async {
    await _runWithLoading(() async {
      sales = await DashboardService.getSalesOverview();
      debugPrint(
        '📊 loadSalesOverview -> target: ${sales?.target}, '
        'achieved: ${sales?.achieved}, pending: ${sales?.pending}',
      );
    });
  }

  /// Refresh tasks only
  Future<void> refreshTasks() async {
    await _runWithoutLoading(() async {
      final userId = _lastLoadedUserId;
      if (userId == null || userId.trim().isEmpty) {
        tasks = <TaskModel>[];
        return;
      }

      final dashboardData = await DashboardService.getDashboard(userId);
      tasks = DashboardService.buildDashboardTasks(dashboardData);
    });
  }

  /// Refresh notifications only
  Future<void> refreshNotifications() async {
    await _runWithoutLoading(() async {
      notifications = await DashboardService.getNotifications();
    });
  }
}
