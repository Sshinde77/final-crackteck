/// API endpoint constants
class ApiConstants {
  ApiConstants._(); // Private constructor to prevent instantiation

  // Base URL Configuration

  // Override with:
  // flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1  (Android emulator)
  // flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1 (iOS simulator/Desktop)
  // flutter run --dart-define=API_BASE_URL=http://<LAN-IP>:8000/api/v1   (Physical device)
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://crackteck.co.in/api/v1',
  );

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
  static const String serviceRequestdetails = "$baseUrl/service-request/{service-request_id}";
  static const String serviceRequestdetail =
      "$baseUrl/service-request/{service-request_id}";
  static const String ServiceRequestAccept =
      "$baseUrl/service-request/{service-request_id}";
  static const String ServiceRequestsendotp =
      "$baseUrl/service-request/{service-request_id}/send-otp";
  static const String ServiceRequestverifyotp =
      "$baseUrl/service-request/{service-request_id}/verify-otp";
  static const String ServiceRequestcasetransfer =
      "$baseUrl/service-request/{service-request_id}/case-transfer";
  static const String ServiceRequestreschedule =
      "$baseUrl/service-request/{service-request_id}/reschedule";
  static const String ServiceRequestdiagnosis =
      "$baseUrl/service-request/{service-request_id}/{product_id}/diagnosis-list";
  static const String ServiceRequestsubmitdiagnosis =
      "$baseUrl/service-request/{service-request_id}/{product_id}/submit-diagnosis";
  static const String stockinhand =
      "$baseUrl/stock-in-hand/list";
  static const String productlistFE =
      "$baseUrl/products";
  static const String productlistdetailFE =
      "$baseUrl/products/{product_id}";
  static const String Requestnewproduct =
      "$baseUrl/stock-in-hand/request";
  static const String deliverypickuprequestlist =
      "$baseUrl/pickup-requests";
  static const String deliveryreturnrequestlist =
      "$baseUrl/return-requests";
  static const String deliverypartrequestlist =
      "$baseUrl/part-requests";
  static const String deliverypickuprequestdetail =
      "$baseUrl/pickup-request";
  static const String deliveryreturnrequestdetail =
      "$baseUrl/return-request";
  static const String deliverypartrequestdetail =
      "$baseUrl/part-request";

  static const String deliverypickuprequestaccept =
      "$baseUrl/pickup-request/{id}/accept";
  static const String deliveryreturnrequestaccept =
      "$baseUrl/return-request/{id}/accept";
  static const String deliverypartrequestaccept =
      "$baseUrl/part-request/{id}/accept";

  static const String deliverypickuprequestsendotp =
      "$baseUrl/pickup-request/{id}/send-otp";
  static const String deliveryreturnrequestsendotp =
      "$baseUrl/return-request/{id}/send-otp";
  static const String deliverypartrequestsendotp =
      "$baseUrl/part-request/{id}/send-otp";

  static const String deliverypickuprequestverifyotp =
      "$baseUrl/pickup-request/{id}/verify-otp";
  static const String deliveryreturnrequestverifyotp =
      "$baseUrl/return-request/{id}/verify-otp";
  static const String deliverypartrequestverifyotp =
      "$baseUrl/part-request/{id}/verify-otp";

  static const String fieldexecutiveclockin =
      "$baseUrl/check-in";
  static const String fieldexecutiveclockout =
      "$baseUrl/check-out";
  static const String fieldexecutiveattendance =
      "$baseUrl/attendance";
  static const String fieldexecutivefeedback =
      "$baseUrl/get-all-feedback";
  static const String fieldexecutivefeedbackdetail =

      "$baseUrl/get-feedback";

  static const String fieldexecutivepersonalinfo =
      "$baseUrl/profile";

  static const String amcplanslist =
      "$baseUrl/amc-plans";

  static const String googlelogin =
      "$baseUrl/google-login";

  static const String fieldexecutivedeliveryproductlist =
      "$baseUrl/orders";
  static const String fieldexecutivedeliveryproductdetail =
      "$baseUrl/orders/{id}";
  static const String fieldexecutivedeliveryproductacceptorder =
      "$baseUrl/accept-order/{id}";
  static const String fieldexecutivedeliveryproductsendotp =
      "$baseUrl/order/{id}/otp";
  static const String fieldexecutivedeliveryproductverifyotp =
      "$baseUrl/order/{id}/verify-otp";
  static const String staffreimbursements =
      "$baseUrl/staff-reimbursements";
  static const String staffreimbursementdetail =
      "$baseUrl/staff-reimbursements/{id}";
  static const String addstaffreimbursement =
      "$baseUrl/staff-reimbursements/";







  // Country Code
  static const String defaultCountryCode = '+91';
}

/// Delivery request type helper.
///
/// Use one `deliveryType` identifier end-to-end and resolve label/endpoint
/// from here so widgets don't hardcode API URLs.
class DeliveryRequestTypes {
  DeliveryRequestTypes._();

  static const String pickup = 'pickup';
  static const String returnRequest = 'return';
  static const String part = 'part';
  static const String productDelivery = 'product_delivery';

  static String normalize(String deliveryType) {
    return deliveryType.trim().toLowerCase();
  }

  static String labelFor(String deliveryType) {
    switch (normalize(deliveryType)) {
      case pickup:
        return 'Pickup Request';
      case returnRequest:
        return 'Return Request';
      case part:
        return 'Part Request';
      case productDelivery:
        return 'Product Delivery';
      default:
        return 'Delivery Request';
    }
  }

  static String endpointFor(String deliveryType) {
    switch (normalize(deliveryType)) {
      case pickup:
        return ApiConstants.deliverypickuprequestlist;
      case returnRequest:
        return ApiConstants.deliveryreturnrequestlist;
      case part:
        return ApiConstants.deliverypartrequestlist;
      case productDelivery:
        return ApiConstants.fieldexecutivedeliveryproductlist;
      default:
        throw ArgumentError('Invalid delivery type: $deliveryType');
    }
  }

  static String detailEndpointFor(String deliveryType) {
    switch (normalize(deliveryType)) {
      case pickup:
        return ApiConstants.deliverypickuprequestdetail;
      case returnRequest:
        return ApiConstants.deliveryreturnrequestdetail;
      case part:
        return ApiConstants.deliverypartrequestdetail;
      case productDelivery:
        return ApiConstants.fieldexecutivedeliveryproductdetail;
      default:
        throw ArgumentError('Invalid delivery type: $deliveryType');
    }
  }

  static String acceptEndpointTemplateFor(String deliveryType) {
    switch (normalize(deliveryType)) {
      case pickup:
        return ApiConstants.deliverypickuprequestaccept;
      case returnRequest:
        return ApiConstants.deliveryreturnrequestaccept;
      case part:
        return ApiConstants.deliverypartrequestaccept;
      case productDelivery:
        return ApiConstants.fieldexecutivedeliveryproductacceptorder;
      default:
        throw ArgumentError('Invalid delivery type: $deliveryType');
    }
  }

  static String sendOtpEndpointTemplateFor(String deliveryType) {
    switch (normalize(deliveryType)) {
      case pickup:
        return ApiConstants.deliverypickuprequestsendotp;
      case returnRequest:
        return ApiConstants.deliveryreturnrequestsendotp;
      case part:
        return ApiConstants.deliverypartrequestsendotp;
      case productDelivery:
        return ApiConstants.fieldexecutivedeliveryproductsendotp;
      default:
        throw ArgumentError('Invalid delivery type: $deliveryType');
    }
  }

  static String verifyOtpEndpointTemplateFor(String deliveryType) {
    switch (normalize(deliveryType)) {
      case pickup:
        return ApiConstants.deliverypickuprequestverifyotp;
      case returnRequest:
        return ApiConstants.deliveryreturnrequestverifyotp;
      case part:
        return ApiConstants.deliverypartrequestverifyotp;
      case productDelivery:
        return ApiConstants.fieldexecutivedeliveryproductverifyotp;
      default:
        throw ArgumentError('Invalid delivery type: $deliveryType');
    }
  }
}
