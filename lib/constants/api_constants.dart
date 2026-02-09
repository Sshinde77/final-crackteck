/// API endpoint constants
class ApiConstants {
  ApiConstants._(); // Private constructor to prevent instantiation

  // Base URL Configuration

  // Current Configuration: Android Emulator
  static const String baseUrl = 'https://crackteck.co.in/api/v1';

  // Authentication Endpoints
  static const String login = '$baseUrl/send-otp';
  static const String verifyOtp = '$baseUrl/verify-otp';
  static const String refreshToken = '$baseUrl/refresh-token';
  static const String signup = '$baseUrl/signup';
  static const String logout = '$baseUrl/logout';
  // Sales Person Dashboard
  static const dashboard = "$baseUrl/dashboard";
  static const salesOverview = "$baseUrl/sales-overview";
  static const task = "$baseUrl/task";
  static const notifications = "$baseUrl/notifications";
  static const updateTaskStatus = "$baseUrl/update-task-status";
  

  //Leads Tab endpoints
  static const lead_page = "$baseUrl/leads";
  static const view_detail_lead = "$baseUrl/lead/{lead_id}";
  static const new_lead = "$baseUrl/lead";
  static const edit_lead = "$baseUrl/lead/{lead_id}";
  static const delete_lead = "$baseUrl/lead/{lead_id}";

  //Follow-up Tab endpoints
  static const follow_up_page = "$baseUrl/follow-up";
  static const view_detail_follow_up = "$baseUrl/follow-up/{follow_up_id}";
  static const new_follow_up = "$baseUrl/follow-up";
  static const edit_follow_up = "$baseUrl/follow-up/{follow_up_id}";
  static const delete_follow_up = "$baseUrl/follow-up/{follow_up_id}";

  //Meeting Tab endpoints
  static const meets_page = "$baseUrl/meets";
  static const view_detail_meet = "$baseUrl/meet/{meet_id}";
  static const new_meet = "$baseUrl/meet";
  static const edit_meet = "$baseUrl/meet/{meet_id}";
  static const delete_meet = "$baseUrl/meet/{meet_id}";

  // Quotation Tab endpoints
  static const quotation_page = "$baseUrl/quotation";
  static const view_detail_quotation = "$baseUrl/quotation/{quotation_id}";
  static const new_quotation = "$baseUrl/quotation";
  static const edit_quotation = "$baseUrl/quotation/{quotation_id}";
  static const delete_quotation = "$baseUrl/quotation/{quotation_id}";
  static const profile_page = "$baseUrl/profile";

  // Request Timeout
  static const Duration requestTimeout = Duration(seconds: 30);

  // Delivery Person Endpoints
  static const String registervehicle = "$baseUrl/vehicle-registration";
  static const String deliveryPersonDashboard = "$baseUrl/delivery-person-dashboard";
  
  //field executive 
    static const String serviceRequests = "$baseUrl/service-requests";
    static const String serviceRequest = "$baseUrl/service-request";


  // Country Code
  static const String defaultCountryCode = '+91';
}
