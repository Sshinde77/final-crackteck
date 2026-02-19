import '../model/field executive/field_executive_product_service.dart';
import '../model/field executive/selected_stock_item.dart';

/// App-wide route name constants
class AppRoutes {
  AppRoutes._(); // Private constructor to prevent instantiation

  // Initial Route
  static const String roleSelection = '/';

  // Login Route (unified for all roles)
  static const String login = '/login';

  // OTP Verification Route
  static const String otpVerification = '/otp-verification';

  // Sign Up Routes
  static const String signUp = '/signup';
  static const String salespersonDashboard = '/SalespersonDashboard';
  static const String salespersonLeads = '/salesperson-leads';
  static const String NewLeadScreen = '/new-lead-screen';
  static const String salespersonFollowUp = '/salesperson-followup';
  static const String salespersonMeeting = '/salesperson-meeting';
  static const String salespersonQuotation = '/salesperson-quotation';
  static const String salespersonProfile = '/salesperson-profile';
  static const String SalesPersonPersonalInfoScreen =
      '/salesperson-personal-info';
  static const String SalesPersonAttendanceScreen = '/salesperson-attendance';
  static const String TaskViewAll = '/Task-Viewall';
  static const String salesoverview = '/sales-overview-screen';
  static const String newfollowupscreen = '/new-followup-screen';
  static const String salespersonNewQuotation = '/salesperson-new-quotation';
  static const String salespernewsonMeeting = '/salesperson-new-meeting';



  // field executive screens
  static const String FieldExecutiveDashboard = '/field_executive_dashboard';
  static const String FieldExecutiveNotificationScreen = '/field_executive_notification';
  static const String FieldExecutiveStockInHandScreen = '/field_executive_stock_in_hand';
  static const String FieldExecutiveProductDetailScreen = '/field_executive_product_detail';
  static const String FieldExecutiveAddProductScreen = '/field_executive_add_product';
  static const String FieldExecutiveProductListToAddMoreScreen = '/field_executive_product_list';
  static const String FieldExecutiveRequestedProductDetailScreen = '/field_executive_requested_product_detail';
  static const String FieldExecutiveProductPaymentScreen = '/field_executive_product_payment';
  static const String FieldExecutiveCashInHandScreen = '/field_executive_cash_in_hand';
  static const String FieldExecutivePaymentReceiptsScreen = '/field_executive_payment_receipts';
  static const String FieldExecutivePaymentDoneScreen = '/field_executive_payment_done';
  static const String FieldExecutiveWorkCallScreen = '/field_executive_work_call';
  static const String FieldExecutiveInstallationDetailScreen = '/field_executive_installation_detail';
  static const String FieldExecutiveOtpVerificationScreen = '/field_executive_otp_verification';
  static const String FieldExecutiveAllProductsScreen = '/field_executive_all_products';
  static const String FieldExecutiveProductItemDetailScreen = '/field_executive_product_item_detail';
  static const String FieldExecutiveMapTrackingScreen = '/field_executive_map_tracking';
  static const String FieldExecutiveUploadBeforeImagesScreen = '/field_executive_upload_before_images';
  static const String FieldExecutiveWriteReportScreen = '/field_executive_write_report';
  static const String FieldExecutiveCaseTransferScreen = '/field_executive_case_transfer';
  static const String FieldExecutivePersonalInfo = '/field_executive_personal_info';
  static const String field_executive_attendance = '/field_executive_attendance';
  static const String PickupMaterialsScreen = '/field_executive_pickup_material';
  static const String RepairRequestScreen = '/field_executive_repair_request';
  static const String PaymentsScreen = '/field_executive_payments';
  static const String WorksScreen = '/field_executive_works';
  static const String fieldexecutivePrivacyPolicyScreen = '/field_executive_privacy_policy';
  static const String fieldexecutiveFeedbackScreen = '/field_executive_feedback';

  static const String PlaceholderScreen = '/placeholder';


  // 🔹 TEMP DASHBOARD ROUTES (ADD THESE)
  static const String adminDashboard = '/admin-dashboard';
  static const String residentDashboard = '/resident-dashboard';
  // static const String securityDashboard = '/security-dashboard';

  //Delivery Dashbord
  static const String vehicalregister = '/vehical-register';
  static const String Deliverypersondashbord = '/deliverypersondashbord';
}



enum FieldExecutiveProductItemDetailFlow {
  normalBrowsing,
  afterOtpVerification,
}


/// Route arguments for passing data between screens
class LoginArguments {
  final int roleId;
  final String roleName;

  LoginArguments({required this.roleId, required this.roleName});
}

class OtpArguments {
  final int roleId;
  final String roleName;
  final String phoneNumber;

  OtpArguments({
    required this.roleId,
    required this.roleName,
    required this.phoneNumber,
  });
}

class SignUpArguments {
  final int roleId;
  final String roleName;

  SignUpArguments({required this.roleId, required this.roleName});
}





class fieldexecutivedashboardArguments {
  final int roleId;
  final String roleName;
  final int initialIndex;

  fieldexecutivedashboardArguments({required this.roleId, required this.roleName, this.initialIndex = 0});
}
class fieldexecutivenotificationArguments {
  final int roleId;
  final String roleName;

  fieldexecutivenotificationArguments({required this.roleId, required this.roleName});
}
class fieldexecutivestockinhandArguments {
  final int roleId;
  final String roleName;
  final bool selectionMode;
  final String diagnosisName;
  final List<SelectedStockItem> initialSelectedItems;

  fieldexecutivestockinhandArguments({
    required this.roleId,
    required this.roleName,
    this.selectionMode = false,
    this.diagnosisName = '',
    this.initialSelectedItems = const <SelectedStockItem>[],
  });
}
class fieldexecutiveproductdetailArguments {
  final int roleId;
  final String roleName;
  final String productId;

  fieldexecutiveproductdetailArguments({
    required this.roleId,
    required this.roleName,
    this.productId = '',
  });
}
class fieldexecutiveaddproductArguments {
  final int roleId;
  final String roleName;

  fieldexecutiveaddproductArguments({required this.roleId, required this.roleName});
}
class fieldexecutiverequestedproductlistArguments {
  final int roleId;
  final String roleName;
  final String productId;

  fieldexecutiverequestedproductlistArguments({
    required this.roleId,
    required this.roleName,
    this.productId = '',
  });
}

class fieldexecutiveproductlisttoaddmoreArguments {
  final int roleId;
  final String roleName;

  fieldexecutiveproductlisttoaddmoreArguments({required this.roleId, required this.roleName});
}

class fieldexecutiveproductpaymentArguments {
  final int roleId;
  final String roleName;

  fieldexecutiveproductpaymentArguments({required this.roleId, required this.roleName});
}

class fieldexecutivecashinhandArguments {
  final int roleId;
  final String roleName;

  fieldexecutivecashinhandArguments({required this.roleId, required this.roleName});
}

class fieldexecutivepaymentreceiptsArguments {
  final int roleId;
  final String roleName;

  fieldexecutivepaymentreceiptsArguments({required this.roleId, required this.roleName});
}

class fieldexecutivepaymentdoneArguments {
  final int roleId;
  final String roleName;

  fieldexecutivepaymentdoneArguments({required this.roleId, required this.roleName});
}

class fieldexecutiveworkcallArguments {
  final int roleId;
  final String roleName;

  fieldexecutiveworkcallArguments({required this.roleId, required this.roleName});
}

class fieldexecutiveinstallationdetailArguments {
  final int roleId;
  final String roleName;
  final String title;
  final String serviceId;
  final String location;
  final String priority;
  final String jobType; // 'installations' | 'repairs' | 'amc'

  fieldexecutiveinstallationdetailArguments({
    required this.roleId,
    required this.roleName,
    required this.title,
    required this.serviceId,
    required this.location,
    required this.priority,
    required this.jobType,
  });
}

class fieldexecutiveotpverificationArguments {
  final int roleId;
  final String roleName;
  final String serviceId;

  fieldexecutiveotpverificationArguments({
    required this.roleId,
    required this.roleName,
    this.serviceId = '',
  });
}

class fieldexecutiveallproductsArguments {
  final int roleId;
  final String roleName;
  final FieldExecutiveProductItemDetailFlow flow;
  final FieldExecutiveProductServicesController controller;
  final String serviceRequestId;

  fieldexecutiveallproductsArguments({
    required this.roleId,
    required this.roleName,
    this.flow = FieldExecutiveProductItemDetailFlow.normalBrowsing,
    this.serviceRequestId = '',
    FieldExecutiveProductServicesController? controller,
  }) : controller = controller ?? FieldExecutiveProductServicesController.withDefaults();
}

class fieldexecutiveproductitemdetailArguments {
  final int roleId;
  final String roleName;
  final String title;
  final String serviceId;
  final String serviceRequestId;
  final String displayServiceId;
  final String location;
  final String priority;
  final FieldExecutiveProductItemDetailFlow flow;
  final FieldExecutiveProductServicesController controller;

  fieldexecutiveproductitemdetailArguments({
    required this.roleId,
    required this.roleName,
    required this.title,
    required this.serviceId,
    this.serviceRequestId = '',
    this.displayServiceId = '',
    required this.location,
    required this.priority,
    this.flow = FieldExecutiveProductItemDetailFlow.normalBrowsing,
    FieldExecutiveProductServicesController? controller,
  }) : controller = controller ?? FieldExecutiveProductServicesController.withDefaults();
}

class fieldexecutivemaptrackingArguments {
  final int roleId;
  final String roleName;
  final String serviceId;
  final String customerName;
  final String customerAddress;
  final String customerPhone;
  final String displayServiceId;

  fieldexecutivemaptrackingArguments({
    required this.roleId,
    required this.roleName,
    required this.serviceId,
    this.customerName = '',
    this.customerAddress = '',
    this.customerPhone = '',
    this.displayServiceId = '',
  });
}

class fieldexecutiveuploadbeforeimagesArguments {
  final int roleId;
  final String roleName;
  final String serviceId;
  final FieldExecutiveProductItemDetailFlow flow;
  final FieldExecutiveProductServicesController controller;

  fieldexecutiveuploadbeforeimagesArguments({
    required this.roleId,
    required this.roleName,
    required this.serviceId,
    this.flow = FieldExecutiveProductItemDetailFlow.normalBrowsing,
    required this.controller,
  });
}

class fieldexecutivewritereportArguments {
  final int roleId;
  final String roleName;
  final String serviceId;
  final FieldExecutiveProductItemDetailFlow flow;
  final FieldExecutiveProductServicesController controller;

  fieldexecutivewritereportArguments({
    required this.roleId,
    required this.roleName,
    required this.serviceId,
    this.flow = FieldExecutiveProductItemDetailFlow.normalBrowsing,
    required this.controller,
  });
}

class fieldexecutivecasetransferArguments {
  final int roleId;
  final String roleName;
  final String serviceId;

  fieldexecutivecasetransferArguments({
    required this.roleId,
    required this.roleName,
    required this.serviceId,
  });
}


class fieldexecutivePersonalInfoArguments {
  final int roleId;
  final String roleName;

  fieldexecutivePersonalInfoArguments({required this.roleId, required this.roleName});
}


class fieldexecutiveattendanceArguments {
  final int roleId;
  final String roleName;

  fieldexecutiveattendanceArguments({required this.roleId, required this.roleName});
}


class fieldexecutivePickupMaterialArguments {
  final int roleId;
  final String roleName;

  fieldexecutivePickupMaterialArguments({required this.roleId, required this.roleName});
}


class fieldexecutiveRepairRequestArguments {
  final int roleId;
  final String roleName;

  fieldexecutiveRepairRequestArguments({required this.roleId, required this.roleName});
}


class fieldexecutivePaymentsScreenArguments {
  final int roleId;
  final String roleName;

  fieldexecutivePaymentsScreenArguments({required this.roleId, required this.roleName});
}

class fieldexecutiveWorksScreenArguments {
  final int roleId;
  final String roleName;

  fieldexecutiveWorksScreenArguments({required this.roleId, required this.roleName});
}


class fieldexecutivePrivacyPolicyScreenArguments {
  final int roleId;
  final String roleName;

  fieldexecutivePrivacyPolicyScreenArguments({required this.roleId, required this.roleName});
}



class fieldexecutiveFeedbackScreenArguments {
  final int roleId;
  final String roleName;

  fieldexecutiveFeedbackScreenArguments({required this.roleId, required this.roleName});
}
