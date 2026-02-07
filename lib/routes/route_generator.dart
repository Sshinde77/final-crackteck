import 'package:final_crackteck/screens/Delivery_person/vehicalregistration.dart';
import 'package:final_crackteck/screens/sales_person/Sales_new_follow-up_screen.dart';
import 'package:final_crackteck/screens/sales_person/Task.dart';
import 'package:final_crackteck/screens/sales_person/sales_add_new_meeting.dart';
import 'package:final_crackteck/screens/sales_person/sales_dashbord.dart';
import 'package:final_crackteck/screens/sales_person/sales_new_lead_screens.dart';
import 'package:final_crackteck/screens/sales_person/sales_new_quotation.dart';
import 'package:final_crackteck/screens/sales_person/sales_person_sales_overview_screen.dart';
import 'package:final_crackteck/screens/sales_person/sales_personal_info_screen.dart';
import 'package:final_crackteck/screens/sales_person/salesperson_leads_screen.dart';
import 'package:final_crackteck/screens/sales_person/salesperson_ followup_ screen.dart';
import 'package:final_crackteck/screens/sales_person/sales_person_meeting_tabs.dart';
import 'package:final_crackteck/screens/sales_person/sales_quatation_tabs_screen.dart';
import 'package:final_crackteck/screens/sales_person/salesperson_profile_tab.dart';
import 'package:final_crackteck/model/sales_person/leads_provider.dart';
import 'package:final_crackteck/model/sales_person/followup_provider.dart';
import 'package:final_crackteck/model/sales_person/meetings_provider.dart';
import 'package:final_crackteck/model/sales_person/quotations_provider.dart';
import 'package:final_crackteck/model/sales_person/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_strings.dart';
import '../login_screen.dart';
import '../role_screen.dart';
import '../screens/Delivery_person/delivery_dashboard.dart';
import '../screens/Field_executive/field_excutive_attendance.dart';
import '../screens/Field_executive/field_executive_add_product.dart';
import '../screens/Field_executive/field_executive_all_products_screen.dart';
import '../screens/Field_executive/field_executive_case_transfer_screen.dart';
import '../screens/Field_executive/field_executive_cash_in_hand.dart';
import '../screens/Field_executive/field_executive_dashboard.dart';
import '../screens/Field_executive/field_executive_detail_requested_product.dart' as detail_requested;
import '../screens/Field_executive/field_executive_feedback.dart';
import '../screens/Field_executive/field_executive_installation_detail_screen.dart';
import '../screens/Field_executive/field_executive_map_tracking_screen.dart';
import '../screens/Field_executive/field_executive_notification.dart';
import '../screens/Field_executive/field_executive_otp_verification_screen.dart';
import '../screens/Field_executive/field_executive_payment.dart';
import '../screens/Field_executive/field_executive_payment_done.dart';
import '../screens/Field_executive/field_executive_payment_receipts.dart';
import '../screens/Field_executive/field_executive_personal_info.dart';
import '../screens/Field_executive/field_executive_pickup_product.dart';
import '../screens/Field_executive/field_executive_privacy_policy.dart';
import '../screens/Field_executive/field_executive_product_detail.dart' as product_detail;
import '../screens/Field_executive/field_executive_product_item_detail_screen.dart';
import '../screens/Field_executive/field_executive_product_list_to_add_more.dart' as product_list;
import '../screens/Field_executive/field_executive_product_payment.dart';
import '../screens/Field_executive/field_executive_repair_request_part.dart';
import '../screens/Field_executive/field_executive_stock_in_hand.dart';
import '../screens/Field_executive/field_executive_upload_before_images_screen.dart';
import '../screens/Field_executive/field_executive_work.dart';
import '../screens/Field_executive/field_executive_work_call.dart';
import '../screens/Field_executive/field_executive_write_report_screen.dart';
import '../temp_placeholder_screen.dart';
import 'app_routes.dart';
import 'package:final_crackteck/otp_screen.dart';
import 'package:final_crackteck/signup.dart';

/// Centralized route generator for the application
class RouteGenerator {
  RouteGenerator._(); // Private constructor to prevent instantiation

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.roleSelection:
        return MaterialPageRoute(
          builder: (_) => const rolesccreen(),
          settings: settings,
        );

      case AppRoutes.login:
        final args = settings.arguments as LoginArguments?;
        if (args == null) {
          return _errorRoute('Login arguments missing');
        }
        return MaterialPageRoute(
          builder: (_) =>
              LoginScreen(roleId: args.roleId, roleName: args.roleName),
          settings: settings,
        );

      case AppRoutes.otpVerification:
        final args = settings.arguments as OtpArguments?;
        if (args == null) {
          return _errorRoute('OTP arguments missing');
        }
        return MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(args: args),
          settings: settings,
        );

      case AppRoutes.signUp:
        final args = settings.arguments as SignUpArguments?;
        if (args == null) {
          return _errorRoute('Sign Up arguments missing');
        }
        return MaterialPageRoute(
          builder: (_) => SignupScreen(arg: args),
          settings: settings,
        );

      case AppRoutes.salespersonDashboard:
        return MaterialPageRoute(
          builder: (_) => const SalespersonDashboard(),
          settings: settings,
        );

      case AppRoutes.salespersonLeads:
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider<LeadsProvider>(
            create: (_) => LeadsProvider(),
            child: const SalesPersonLeadsScreen(),
          ),
          settings: settings,
        );
      case AppRoutes.NewLeadScreen:
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider<ProfileProvider>(
            create: (_) => ProfileProvider(),
            child: const NewLeadScreen(roleId: 3, roleName: 'Salesperson'),
          ),
          settings: settings,
        );
      case AppRoutes.salespersonFollowUp:
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider<FollowUpProvider>(
            create: (_) => FollowUpProvider(),
            child: const SalesPersonFollowUpScreen(
              roleId: 3,
              roleName: 'Salesperson',
            ),
          ),
          settings: settings,
        );
      case AppRoutes.newfollowupscreen:
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider<FollowUpProvider>(
            create: (_) => FollowUpProvider(),
            child: const NewFollowUpScreen(roleId: 3, roleName: 'Salesperson'),
          ),
          settings: settings,
        );

      case AppRoutes.salespersonProfile:
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider<ProfileProvider>(
            create: (_) => ProfileProvider(),
            child: const SalesPersonMoreScreen(
              roleId: 3,
              roleName: 'Salesperson',
            ),
          ),
          settings: settings,
        );

      case AppRoutes.salesoverview:
        return MaterialPageRoute(
          builder: (_) =>
              const SalesOverviewScreen(roleId: 3, roleName: 'Salesperson'),
          settings: settings,
        );

      case AppRoutes.TaskViewAll:
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider<LeadsProvider>(
            create: (_) => LeadsProvider(),
            child: const TaskScreen(roleId: 3, roleName: 'Salesperson'),
          ),
          settings: settings,
        );

      case AppRoutes.salespersonMeeting:
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider<MeetingsProvider>(
            create: (_) => MeetingsProvider(),
            child: const SalesPersonMeetingScreen(
              roleId: 3,
              roleName: 'Salesperson',
            ),
          ),
          settings: settings,
        );
      case AppRoutes.salespernewsonMeeting:
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider<MeetingsProvider>(
            create: (_) => MeetingsProvider(),
            child: const NewMeetingScreen(roleId: 3, roleName: 'Salesperson'),
          ),
          settings: settings,
        );

      case AppRoutes.salespersonNewQuotation:
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider<QuotationsProvider>(
            create: (_) => QuotationsProvider(),
            child: const NewQuotationScreen(roleId: 3, roleName: 'Salesperson'),
          ),
          settings: settings,
        );

      case AppRoutes.salespersonQuotation:
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider<QuotationsProvider>(
            create: (_) => QuotationsProvider(),
            child: const SalesPersonQuotationScreen(
              roleId: 3,
              roleName: 'Salesperson',
            ),
          ),
          settings: settings,
        );

      case AppRoutes.SalesPersonPersonalInfoScreen:
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider<ProfileProvider>(
            create: (_) => ProfileProvider(),
            child: const SalesPersonPersonalInfoScreen(
              roleId: 3,
              roleName: 'Salesperson',
            ),
          ),
          settings: settings,
        );
      //Delivery Person

      case AppRoutes.adminDashboard:
        // Temporary placeholder for Field Executive dashboard (roleId = 1)
        return MaterialPageRoute(
          builder: (_) =>
              const TempPlaceholderScreen(title: 'Field Executive Dashboard'),
          settings: settings,
        );

      case AppRoutes.vehicalregister:
        // Vehicle registration screen for Delivery Person
        return MaterialPageRoute(
          builder: (_) => const VehicleScreen(),
          settings: settings,
        );

      case AppRoutes.Deliverypersondashbord:
        // Delivery Person main dashboard (roleId = 2)
        return MaterialPageRoute(
          builder: (_) => const DeliveryDashboard(
            roleId: 2,
            roleName: AppStrings.deliveryMan,
          ),
          settings: settings,
        );


    // Field Executive cases
      case AppRoutes.FieldExecutiveDashboard:
        final args = settings.arguments as fieldexecutivedashboardArguments?;
        if (args == null) {
          return _errorRoute('Arguments missing');
        }
        return MaterialPageRoute(
          builder: (_) =>
              FieldExecutiveDashboard(
                roleId: args.roleId,
                roleName: args.roleName,
                initialIndex: args.initialIndex,
              ),
          settings: settings,
        );

      case AppRoutes.FieldExecutiveNotificationScreen:
        // final args = settings.arguments as fieldexecutivenotificationArguments?;
        // if (args == null) {
        //   return _errorRoute('Arguments missing');
        // }
        return MaterialPageRoute(
          builder: (_) =>
              const EnigneerNotificationScreen(
                // roleId: args.roleId,
                // roleName: args.roleName,
              ),
          settings: settings,
        );

      case AppRoutes.FieldExecutiveStockInHandScreen:
        final args = settings.arguments as fieldexecutivestockinhandArguments?;
        if (args == null) {
          return _errorRoute('Arguments missing');
        }
        return MaterialPageRoute(
          builder: (_) =>
              StockInHandScreen(
                roleId: args.roleId,
                roleName: args.roleName,
              ),
          settings: settings,
        );

      case AppRoutes.FieldExecutiveProductDetailScreen:
        final args = settings.arguments as fieldexecutiveproductdetailArguments?;
        if (args == null) {
          return _errorRoute('Arguments missing');
        }
        return MaterialPageRoute(
          builder: (_) =>
              product_detail.ProductDetailScreen(
                roleId: args.roleId,
                roleName: args.roleName,
              ),
          settings: settings,
        );

      case AppRoutes.FieldExecutiveAddProductScreen:
        final args = settings.arguments as fieldexecutiveaddproductArguments?;
        if (args == null) {
          return _errorRoute('Arguments missing');
        }
        return MaterialPageRoute(
          builder: (_) =>
              AddProductScreen(
                roleId: args.roleId,
                roleName: args.roleName,
              ),
          settings: settings,
        );

      case AppRoutes.FieldExecutiveProductListToAddMoreScreen:
        final args = settings.arguments as fieldexecutiveproductlisttoaddmoreArguments?;
        if (args == null) {
          return _errorRoute('Arguments missing');
        }
        return MaterialPageRoute(
          builder: (_) =>
              product_list.ProductListScreen(
                roleId: args.roleId,
                roleName: args.roleName,
              ),
          settings: settings,
        );

      case AppRoutes.FieldExecutiveRequestedProductDetailScreen:
        final args = settings.arguments as fieldexecutiverequestedproductlistArguments?;
        if (args == null) {
          return _errorRoute('Arguments missing');
        }
        return MaterialPageRoute(
          builder: (_) =>
              detail_requested.ProductRequestedDetailScreen(
                roleId: args.roleId,
                roleName: args.roleName,
              ),
          settings: settings,
        );

      case AppRoutes.FieldExecutiveProductPaymentScreen:
        final args = settings.arguments as fieldexecutiveproductpaymentArguments?;
        if (args == null) {
          return _errorRoute('Arguments missing');
        }
        return MaterialPageRoute(
          builder: (_) =>
              FieldExecutiveProductPaymentScreen(
                roleId: args.roleId,
                roleName: args.roleName,
              ),
          settings: settings,
        );

      case AppRoutes.FieldExecutiveCashInHandScreen:
        final args = settings.arguments as fieldexecutivecashinhandArguments?;
        if (args == null) {
          return _errorRoute('Arguments missing');
        }
        return MaterialPageRoute(
          builder: (_) =>
              FieldExecutiveCashInHandScreen(
                roleId: args.roleId,
                roleName: args.roleName,
              ),
          settings: settings,
        );

      case AppRoutes.FieldExecutivePaymentReceiptsScreen:
        final args = settings.arguments as fieldexecutivepaymentreceiptsArguments?;
        if (args == null) {
          return _errorRoute('Arguments missing');
        }
        return MaterialPageRoute(
          builder: (_) =>
              FieldExecutivePaymentReceiptsScreen(
                roleId: args.roleId,
                roleName: args.roleName,
              ),
          settings: settings,
        );

      case AppRoutes.FieldExecutivePaymentDoneScreen:
        final args = settings.arguments as fieldexecutivepaymentdoneArguments?;
        if (args == null) {
          return _errorRoute('Arguments missing');
        }
        return MaterialPageRoute(
          builder: (_) =>
              FieldExecutivePaymentDoneScreen(
                roleId: args.roleId,
                roleName: args.roleName,
              ),
          settings: settings,
        );

      case AppRoutes.FieldExecutiveWorkCallScreen:
        final args = settings.arguments as fieldexecutiveworkcallArguments?;
        if (args == null) {
          return _errorRoute('Arguments missing');
        }
        return MaterialPageRoute(
          builder: (_) =>
              FieldExecutiveWorkCallScreen(
                roleId: args.roleId,
                roleName: args.roleName,
              ),
          settings: settings,
        );


      case AppRoutes.FieldExecutiveOtpVerificationScreen:
        final args = settings.arguments as fieldexecutiveotpverificationArguments?;
        if (args == null) {
          return _errorRoute('Arguments missing');
        }
        return MaterialPageRoute(
          builder: (_) =>
              FieldExecutiveOtpVerificationScreen(
                roleId: args.roleId,
                roleName: args.roleName,
              ),
          settings: settings,
        );

      case AppRoutes.FieldExecutiveAllProductsScreen:
        final args = settings.arguments as fieldexecutiveallproductsArguments?;
        if (args == null) {
          return _errorRoute('Arguments missing');
        }
        return MaterialPageRoute(
          builder: (_) =>
              FieldExecutiveAllProductsScreen(
                roleId: args.roleId,
                roleName: args.roleName,
                flow: args.flow,
                controller: args.controller,
              ),
          settings: settings,
        );

      case AppRoutes.FieldExecutiveProductItemDetailScreen:
        final args = settings.arguments as fieldexecutiveproductitemdetailArguments?;
        if (args == null) {
          return _errorRoute('Arguments missing');
        }
        return MaterialPageRoute(
          builder: (_) =>
              FieldExecutiveProductItemDetailScreen(
                roleId: args.roleId,
                roleName: args.roleName,
                title: args.title,
                serviceId: args.serviceId,
                location: args.location,
                priority: args.priority,
                flow: args.flow,
                controller: args.controller,
              ),
          settings: settings,
        );

      case AppRoutes.FieldExecutiveMapTrackingScreen:
        final args = settings.arguments as fieldexecutivemaptrackingArguments?;
        if (args == null) {
          return _errorRoute('Arguments missing');
        }
        return MaterialPageRoute(
          builder: (_) =>
              FieldExecutiveMapTrackingScreen(
                roleId: args.roleId,
                roleName: args.roleName,
                serviceId: args.serviceId,
              ),
          settings: settings,
        );

      case AppRoutes.FieldExecutiveUploadBeforeImagesScreen:
        final args = settings.arguments as fieldexecutiveuploadbeforeimagesArguments?;
        if (args == null) {
          return _errorRoute('Arguments missing');
        }
        return MaterialPageRoute(
          builder: (_) =>
              FieldExecutiveUploadBeforeImagesScreen(
                roleId: args.roleId,
                roleName: args.roleName,
                serviceId: args.serviceId,
                flow: args.flow,
                controller: args.controller,
              ),
          settings: settings,
        );

      case AppRoutes.FieldExecutiveInstallationDetailScreen:
        final args = settings.arguments as fieldexecutiveinstallationdetailArguments?;
        if (args == null) {
          return _errorRoute('Arguments missing');
        }
        return MaterialPageRoute(
          builder: (_) =>
              FieldExecutiveInstallationDetailScreen(
                roleId: args.roleId,
                roleName: args.roleName,
                title: args.title,
                serviceId: args.serviceId,
                location: args.location,
                priority: args.priority,
                // new: pass jobType so the screen can render differently for repairs
                jobType: args.jobType,
              ),
          settings: settings,
        );

      case AppRoutes.FieldExecutiveWriteReportScreen:
        final args = settings.arguments as fieldexecutivewritereportArguments?;
        if (args == null) {
          return _errorRoute('Arguments missing');
        }
        return MaterialPageRoute(
          builder: (_) =>
              FieldExecutiveWriteReportScreen(
                roleId: args.roleId,
                roleName: args.roleName,
                serviceId: args.serviceId,
                flow: args.flow,
                controller: args.controller,
              ),
          settings: settings,
        );

      case AppRoutes.FieldExecutiveCaseTransferScreen:
        final args = settings.arguments as fieldexecutivecasetransferArguments?;
        if (args == null) {
          return _errorRoute('Arguments missing');
        }
        return MaterialPageRoute(
          builder: (_) => FieldExecutiveCaseTransferScreen(
            roleId: args.roleId,
            roleName: args.roleName,
          ),
          settings: settings,
        );

      case AppRoutes.FieldExecutivePersonalInfo:
        final args = settings.arguments as fieldexecutivePersonalInfoArguments?;
        if (args == null) {
          return _errorRoute('Arguments missing');
        }
        return MaterialPageRoute(
          builder: (_) => FieldExecutivePersonalInfo(
            roleId: args.roleId,
            roleName: args.roleName,
          ),
          settings: settings,
        );

      case AppRoutes.field_executive_attendance:
        final args = settings.arguments as fieldexecutiveattendanceArguments?;
        if (args == null) {
          return _errorRoute('Arguments missing');
        }
        return MaterialPageRoute(
          builder: (_) => field_executive_attendance(
            roleId: args.roleId,
            roleName: args.roleName,
          ),
          settings: settings,
        );

      case AppRoutes.PickupMaterialsScreen:
        final args = settings.arguments as fieldexecutivePickupMaterialArguments?;
        if (args == null) {
          return _errorRoute('Arguments missing');
        }
        return MaterialPageRoute(
          builder: (_) => PickupMaterialsScreen(
            roleId: args.roleId,
            roleName: args.roleName,
          ),
          settings: settings,
        );

      case AppRoutes.RepairRequestScreen:
        final args = settings.arguments as fieldexecutiveRepairRequestArguments?;
        if (args == null) {
          return _errorRoute('Arguments missing');
        }
        return MaterialPageRoute(
          builder: (_) => RepairRequestScreen(
            roleId: args.roleId,
            roleName: args.roleName,
          ),
          settings: settings,
        );

      case AppRoutes.PaymentsScreen:
        final args = settings.arguments as fieldexecutivePaymentsScreenArguments?;
        if (args == null) {
          return _errorRoute('Arguments missing');
        }
        return MaterialPageRoute(
          builder: (_) => PaymentsScreen(
            roleId: args.roleId,
            roleName: args.roleName,
          ),
          settings: settings,
        );


      case AppRoutes.WorksScreen:
        final args = settings.arguments as fieldexecutiveWorksScreenArguments?;
        if (args == null) {
          return _errorRoute('Arguments missing');
        }
        return MaterialPageRoute(
          builder: (_) => WorksScreen(
            roleId: args.roleId,
            roleName: args.roleName,
          ),
          settings: settings,
        );



      case AppRoutes.fieldexecutivePrivacyPolicyScreen:
        final args = settings.arguments as fieldexecutivePrivacyPolicyScreenArguments?;
        if (args == null) {
          return _errorRoute('Arguments missing');
        }
        return MaterialPageRoute(
          builder: (_) => fieldexecutivePrivacyPolicyScreen(
            roleId: args.roleId,
            roleName: args.roleName,
          ),
          settings: settings,
        );





      case AppRoutes.fieldexecutiveFeedbackScreen:
        final args = settings.arguments as fieldexecutiveFeedbackScreenArguments?;
        if (args == null) {
          return _errorRoute('Arguments missing');
        }
        return MaterialPageRoute(
          builder: (_) => fieldexecutiveFeedbackScreen(
            roleId: args.roleId,
            roleName: args.roleName,
          ),
          settings: settings,
        );



      default:
        return _errorRoute(settings.name);
    }
  }

  static Route<dynamic> _errorRoute(String? routeName) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text('No route defined for $routeName')),
      ),
    );
  }
}
