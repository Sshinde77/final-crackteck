# Sales Dashboard API Integration Summary

## Overview
This document summarizes the API integration for the sales person dashboard in the CrackTeck Flutter application.

## Base URL
```
https://crackteck.co.in/api/v1
```

## Integrated Endpoints

### 1. Dashboard Endpoint
- **URL**: `GET /dashboard/{userId}`
- **Purpose**: Fetch dashboard data for a specific user including sales metrics and tasks
- **Implementation**: `ApiService.fetchDashboard(userId, token: token)`
- **Service Method**: `DashboardService.getDashboard(userId, token: token)`
- **Returns**: `DashboardData` object with target, achieved, pending values and tasks list

### 2. Sales Overview Endpoint
- **URL**: `GET /sales-overview`
- **Purpose**: Fetch sales performance metrics overview
- **Implementation**: `ApiService.fetchSalesOverview(token: token)`
- **Service Method**: `DashboardService.getSalesOverview(token: token)`
- **Returns**: `DashboardData` object with sales metrics

### 3. Tasks Endpoint
- **URL**: `GET /task`
- **Purpose**: Fetch list of tasks assigned to the salesperson
- **Implementation**: `ApiService.fetchTasks(token: token)`
- **Service Method**: `DashboardService.getTasks(token: token)`
- **Returns**: `List<TaskModel>` containing task details

### 4. Notifications Endpoint
- **URL**: `GET /notifications`
- **Purpose**: Fetch list of notifications for the salesperson
- **Implementation**: `ApiService.fetchNotifications(token: token)`
- **Service Method**: `DashboardService.getNotifications(token: token)`
- **Returns**: `List<NotificationModel>` containing notification details

## File Structure

### API Layer
- **`lib/constants/api_constants.dart`**: Contains all API endpoint constants
- **`lib/services/api_service.dart`**: Low-level HTTP methods for API calls
- **`lib/services/dashboard_service.dart`**: High-level service methods for dashboard operations

### Data Models
- **`lib/model/sales_person/sales_overview_model.dart`**: DashboardData and Task models
- **`lib/model/sales_person/task_model.dart`**: TaskModel for task list
- **`lib/model/sales_person/notification_model.dart`**: NotificationModel for notifications

### State Management
- **`lib/model/sales_person/dashboard_provider_impl.dart`**: Provider for managing dashboard state

### UI
- **`lib/screens/sales_person/sales_dashbord.dart`**: Sales dashboard screen

## Usage Example

```dart
// In your widget or provider
final provider = Provider.of<DashboardProvider>(context, listen: false);

// Load all dashboard data (dashboard, tasks, notifications)
await provider.loadDashboard("userId", token: "authToken");

// Or load only sales overview
await provider.loadSalesOverview(token: "authToken");

// Refresh tasks only
await provider.refreshTasks(token: "authToken");

// Refresh notifications only
await provider.refreshNotifications(token: "authToken");
```

## Error Handling
All API methods include comprehensive error handling for:
- Timeout exceptions
- Network connectivity issues (SocketException)
- HTTP status code errors
- JSON parsing errors

## Authentication
All endpoints support optional Bearer token authentication via the `token` parameter.

## Response Structure
The API methods handle multiple response structures:
- Direct data objects: `{ "target": 10000, "achieved": 8000, ... }`
- Wrapped in data field: `{ "data": { "target": 10000, ... } }`
- Arrays: `[{ "id": 1, "title": "Task 1" }, ...]`
- Wrapped arrays: `{ "data": [{ "id": 1, ... }] }`

## Next Steps
1. Replace hardcoded userId "1" with actual authenticated user ID
2. Implement proper token management (storage and refresh)
3. Add pull-to-refresh functionality in the UI
4. Implement error UI states (loading, error, empty states)
5. Add unit tests for API service methods
6. Add integration tests for dashboard provider

