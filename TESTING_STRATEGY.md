# Production-Grade Testing Strategy — `final_crackteck` (Flutter)

This strategy is based on the repo’s current implementation (Provider/ChangeNotifier state, route generator wiring, static singleton services, and HTTP-based services with refresh-token retry + HTML-as-unauthorized detection).

## 1) Project Architecture Understanding

### Architecture pattern (as implemented)
- **Hybrid layered UI + provider + service + model** (no strict clean-architecture boundaries):
  - UI: `lib/screens/**` plus auth screens in `lib/login_screen.dart`, `lib/role_screen.dart`, `lib/otp_screen.dart`, `lib/signup.dart`
  - State: **Provider + ChangeNotifier**
    - Root: `MultiProvider` in `lib/main.dart`
    - Route-scoped: providers created in `lib/routes/route_generator.dart`
  - Services: `lib/services/**` call HTTP (via `ApiHttpClient`) and persist session data
  - Models: `lib/model/**` parsing + normalization

### State management
- `provider` package with `ChangeNotifier` providers:
  - Sales: `lib/model/sales_person/*_provider.dart`, `lib/model/sales_person/dashboard_provider.dart`
  - Delivery: `lib/provider/delivery_person/*.dart`
  - Shared: `lib/provider/attendance_provider.dart`, `lib/provider/signup/signup_provider.dart`

### Dependency injection
- **Ad-hoc DI**:
  - Some providers accept optional services (good seams): e.g. `AttendanceProvider({AttendanceService? service})`
  - Several services are **static/singleton** and are overridden at the HTTP layer for tests:
    - `ApiHttpClient.overrideForTesting(...)`
    - `ApiService.instance` (singleton, not injectable)
    - Static storage/session: `SecureStorageService`, `SessionManager`, `NavigationService`

### API / network layer
- `lib/core/network/api_http_client.dart`: `http.BaseClient` wrapper
  - Request/response logging (`ApiLogger`)
  - Timeout (`ApiConstants.requestTimeout`)
  - Test seam: `overrideForTesting(...)` and `resetOverride()`
- `lib/services/api_service.dart`: large service with:
  - “safe decode” + **HTML detection**
  - authenticated request helpers with **refresh-token retry**
  - auth failure handling: clears session + navigates to auth root
- Delivery-specific client:
  - `lib/services/delivery_person/delivery_api_client.dart` (own auth validation + refresh retry)

### Navigation / routes
- Route names + argument classes: `lib/routes/app_routes.dart`
- Route factory + provider wiring: `lib/routes/route_generator.dart`
- Global navigator + auth redirect support: `lib/core/navigation_service.dart`
- Auth gating: `lib/services/session_manager.dart`

### Local storage
- `SharedPreferences`:
  - session flags, token expiry epoch, attendance snapshots
- `flutter_secure_storage`:
  - tokens, user id, role id, profile, device id, FCM token + last sync signature
- In-memory caching:
  - `SecureStorageService` caches tokens/ids and keeps per-session “vehicle registered” flags

## 2) Risk Analysis (crash-prone / bug-prone areas)

### P0 risks
- **Session/token lifecycle** (`SecureStorageService`, `SessionManager`)
- **Auth retry/refresh** and “HTML as unauthorized” behavior (`ApiService`, `DeliveryApiClient`)
- **Delivery order action state machine** (OTP timer + verify + delivered)
- **Plugin-heavy code paths** in auth flows (notifications + sms_autofill)
- **Multipart uploads** (selfie / documents / reimbursements) and related permission flows

### P1 risks
- Sales dashboard merge logic (`DashboardProvider.loadDashboard`) + screen-level aggregation in `sales_dashbord.dart`
- Pagination correctness in list providers
- Reimbursement form submission + receipt selection

### P2 risks
- Mostly-presentational widgets and static constants

## 3) Testing Strategy Summary

### Target pyramid
- **Unit tests (largest):** storage/session, API retry/refresh, parsing-heavy models, providers.
- **Widget tests (medium):** auth shell (splash/role/login/otp) + 1–2 representative screens per role + key reusable widgets.
- **Integration tests (small):** deterministic end-to-end flows with mocked HTTP (CI friendly).

### Non-negotiable seams for deterministic tests
- `ApiHttpClient.overrideForTesting(MockClient(...))`
- `SharedPreferences.setMockInitialValues(...)`
- `test/support/secure_storage_mock.dart` for `flutter_secure_storage`
- Avoid `pumpAndSettle()` in screens with periodic timers (OTP).

## 4) File-by-File Test Classification (repo-accurate)

Legend: **UNIT TEST / WIDGET TEST / INTEGRATION TEST / DO NOT TEST DIRECTLY / TEST INDIRECTLY THROUGH HIGHER LAYER**

### `lib/` root
- `lib/main.dart` — **INTEGRATION TEST**: boot + route wiring + lifecycle resume redirect (mock HTTP + disable notifications).
- `lib/login_screen.dart` — **WIDGET TEST**: OTP login validation + navigation; email/password + google are present but higher cost to mock.
- `lib/otp_screen.dart` — **WIDGET TEST**: OTP verify + resend gating + navigation per role/redirect (requires sms_autofill guarded for tests).
- `lib/role_screen.dart` — **WIDGET TEST**: role taps route to protected login/dashboard logic.
- `lib/signup.dart` — **WIDGET TEST** (selective): form validation + provider submit states; picker permissions require mocks.
- `lib/temp_placeholder_screen.dart` — **DO NOT TEST DIRECTLY**: placeholder.

### `lib/constants/`
- `lib/constants/api_constants.dart` — **DO NOT TEST DIRECTLY**: endpoints/constants; tested indirectly via service/provider tests.
- `lib/constants/app_colors.dart` — **DO NOT TEST DIRECTLY**
- `lib/constants/app_spacing.dart` — **DO NOT TEST DIRECTLY**
- `lib/constants/app_strings.dart` — **DO NOT TEST DIRECTLY**

### `lib/core/`
- `lib/core/navigation_service.dart` — **TEST INDIRECTLY THROUGH HIGHER LAYER**: validate via widget/integration tests (navigation effects).
- `lib/core/secure_storage_service.dart` — **UNIT TEST**: token normalization, caching, pending-write behavior, deviceId, vehicle flag.

### `lib/core/network/`
- `lib/core/network/api_http_client.dart` — **UNIT TEST**: override/reset + response body preservation + timeout wrapping.
- `lib/core/network/api_logger.dart` — **DO NOT TEST DIRECTLY**: logging only.
- `lib/core/network/api_client.dart` — **TEST INDIRECTLY THROUGH HIGHER LAYER**: via `ApiService`/feature tests.

### `lib/model/`
- `lib/model/api_response.dart` — **UNIT TEST**: mapping/typing behavior.
- Delivery models (parsing-heavy) — **UNIT TEST**:
  - `lib/model/Delivery_person/delivery_attendance_model.dart`
  - `lib/model/Delivery_person/delivery_order_model.dart`
  - `lib/model/Delivery_person/delivery_order_detail_model.dart`
  - `lib/model/Delivery_person/delivery_personal_info_model.dart`
  - `lib/model/Delivery_person/delivery_profile_model.dart`
- Field executive models (normalization) — **UNIT TEST**:
  - `lib/model/field executive/delivery_request_model.dart`
  - `lib/model/field executive/diagnosis_item.dart`
  - `lib/model/field executive/field_executive_product_service.dart`
  - `lib/model/field executive/field_executive_service_request_detail.dart`
  - `lib/model/field executive/requested_product.dart`
  - `lib/model/field executive/selected_stock_item.dart`
- Sales models — **UNIT TEST**:
  - `lib/model/sales_person/followup_model.dart`
  - `lib/model/sales_person/lead_model.dart`
  - `lib/model/sales_person/meeting_model.dart`
  - `lib/model/sales_person/notification_model.dart`
  - `lib/model/sales_person/profile_model.dart`
  - `lib/model/sales_person/quotation_model.dart`
  - `lib/model/sales_person/sales_overview_model.dart`
  - `lib/model/sales_person/task_model.dart`
- Signup request DTOs — **UNIT TEST**:
  - `lib/model/signup/common_signup_request.dart`
  - `lib/model/signup/delivery_signup_request.dart`
- `lib/model/reimbursement_model.dart` — **UNIT TEST**: status normalization + numeric/date parsing fallbacks.

### `lib/model/*_provider.dart` and `lib/provider/**`
- Sales providers — **UNIT TEST** (pagination + error normalization):
  - `lib/model/sales_person/dashboard_provider.dart`
  - `lib/model/sales_person/leads_provider.dart`
  - `lib/model/sales_person/followup_provider.dart`
  - `lib/model/sales_person/meetings_provider.dart`
  - `lib/model/sales_person/quotations_provider.dart`
  - `lib/model/sales_person/profile_provider.dart`
- Shared providers — **UNIT TEST**:
  - `lib/provider/attendance_provider.dart` (state transitions + expiry logic)
  - `lib/provider/signup/signup_provider.dart`
- Delivery providers — **UNIT TEST**:
  - `lib/provider/delivery_person/delivery_home_provider.dart`
  - `lib/provider/delivery_person/delivery_order_action_provider.dart`
  - `lib/provider/delivery_person/delivery_order_detail_provider.dart`
  - `lib/provider/delivery_person/delivery_attendance_provider.dart`
  - `lib/provider/delivery_person/delivery_documents_provider.dart`
  - `lib/provider/delivery_person/delivery_kyc_provider.dart`
  - `lib/provider/delivery_person/delivery_personal_info_provider.dart`
  - `lib/provider/delivery_person/delivery_profile_provider.dart`

### `lib/routes/`
- `lib/routes/app_routes.dart` — **UNIT TEST (light)**: constant sanity + argument classes.
- `lib/routes/route_generator.dart` — **WIDGET TEST**: route builds correct screen + provider injection (select key routes).

### `lib/services/`
- `lib/services/session_manager.dart` — **UNIT TEST (+ WIDGET indirect)**: JWT expiry parsing, isLoggedIn, save/clear session, defaultRouteForRole.
- `lib/services/api_service.dart` — **UNIT TEST**: auth retry/refresh, HTML detection, critical endpoint wrappers.
- `lib/services/auth_service.dart` — **UNIT TEST**: email+google backend login parsing + token persistence.
- `lib/services/google_auth_service.dart` — **UNIT TEST (thin)**: cancel/no-token cases (prefer injection if needed later).
- `lib/services/dashboard_service.dart` — **UNIT TEST**: mapping + malformed entry handling.
- `lib/services/attendance_service.dart` — **UNIT TEST**: scoped keys + expiry clearing.
- `lib/services/notification_service.dart` — **TEST INDIRECTLY THROUGH HIGHER LAYER**: only ensure “does not crash when disabled”; don’t deeply unit-test Firebase in CI.
- `lib/services/media_picker_service.dart` — **WIDGET TEST (selective)**: permission denied dialogs and PlatformException messaging (requires channel mocks).
- `lib/services/requested_products_store.dart` — **UNIT TEST**: add/update/remove/merge behavior.
- `lib/services/mock_product_delivery_service.dart` — **UNIT TEST**: deterministic fake behavior.
- `lib/services/delivery_man_service.dart` — **TEST INDIRECTLY THROUGH HIGHER LAYER**: covered by delivery API client/service/provider tests.

### `lib/services/delivery_person/`
- `lib/services/delivery_person/delivery_api_client.dart` — **UNIT TEST**: unauthorized detection + refresh retry + helpers (`replaceId`, `extractList`, `requiredQuery`).
- `lib/services/delivery_person/delivery_orders_service.dart` — **UNIT TEST**: endpoint selection + mapping to `ApiResponse`.
- `lib/services/delivery_person/delivery_profile_service.dart` — **UNIT TEST**
- `lib/services/delivery_person/delivery_documents_service.dart` — **UNIT TEST** (multipart fields)
- `lib/services/delivery_person/delivery_attendance_service.dart` — **UNIT TEST**
- `lib/services/delivery_person/delivery_dashboard_service.dart` — **UNIT TEST**
- `lib/services/delivery_person/delivery_kyc_service.dart` — **UNIT TEST**
- `lib/services/delivery_person/delivery_signup_service.dart` — **UNIT TEST** (multipart + normalization)

### `lib/screens/`
- `lib/screens/splash_screen.dart` — **WIDGET TEST**: routes based on auth/session state.
- Sales screens — **WIDGET TEST (selective, P1+)**:
  - `lib/screens/sales_person/sales_dashbord.dart` (state + navigation; contains screen-local aggregation logic)
  - `lib/screens/sales_person/salesperson_leads_screen.dart` (loading/empty/error/success + navigation)
  - `lib/screens/sales_person/salesperson_ followup_ screen.dart`
  - `lib/screens/sales_person/sales_person_meeting_tabs.dart`
  - `lib/screens/sales_person/sales_quatation_tabs_screen.dart`
  - `lib/screens/sales_person/sales_new_lead_screens.dart`
  - `lib/screens/sales_person/Sales_new_follow-up_screen.dart`
  - `lib/screens/sales_person/sales_add_new_meeting.dart`
  - `lib/screens/sales_person/sales_new_quotation.dart`
  - `lib/screens/sales_person/sales_person_sales_overview_screen.dart`
  - `lib/screens/sales_person/sales_personal_info_screen.dart`
  - `lib/screens/sales_person/salesperson_profile_tab.dart`
  - `lib/screens/sales_person/Task.dart`
- Delivery screens — **WIDGET TEST (selective; prioritize flows with state transitions/navigation)**:
  - `lib/screens/Delivery_person/delivery_dashboard.dart` — **WIDGET TEST (P0/P1)**: bottom nav + page switching.
  - `lib/screens/Delivery_person/delivery_home_tab.dart` — **WIDGET TEST (P0/P1)**: provider loading/error/success states.
  - `lib/screens/Delivery_person/delivery_detail_screen.dart` — **WIDGET TEST (P0/P1)**: accept + navigate to OTP.
  - `lib/screens/Delivery_person/delivery_otp_verification_screen.dart` — **WIDGET TEST (P0)**: verifyAndDeliver success path + resend gating.
  - `lib/screens/Delivery_person/delivery_done_screen.dart` — **TEST INDIRECTLY THROUGH HIGHER LAYER**: confirmation UI.
  - `lib/screens/Delivery_person/delivery_track_order.dart` — **TEST INDIRECTLY THROUGH HIGHER LAYER**: map/detail UI (avoid deep tests).
  - `lib/screens/Delivery_person/delivery_otp_screen.dart` — **TEST INDIRECTLY THROUGH HIGHER LAYER**: older/alternate OTP UI unless actively used.
  - `lib/screens/Delivery_person/product_to_be_deliveried_screen.dart` — **TEST INDIRECTLY THROUGH HIGHER LAYER**: list UI covered via home/order flows.
  - `lib/screens/Delivery_person/map_with-start.dart` — **DO NOT TEST DIRECTLY**: map UI placeholder (high cost, low ROI).
  - KYC/documents/profile/terms screens — **WIDGET TEST (P1 selective)**:
    - `lib/screens/Delivery_person/delivery_kyc_screen.dart`
    - `lib/screens/Delivery_person/delivery_person_documents.dart`
    - `lib/screens/Delivery_person/delivery_profile_tab.dart`
    - `lib/screens/Delivery_person/delivery_personal_info_screen.dart`
    - `lib/screens/Delivery_person/delivery_person_attendance.dart`
    - `lib/screens/Delivery_person/delivery_notification.dart`
    - `lib/screens/Delivery_person/delivery_feedback.dart`
    - `lib/screens/Delivery_person/delivery_privacy_policy.dart`
    - `lib/screens/Delivery_person/delivery_terms_condition.dart`
    - `lib/screens/Delivery_person/delivery_vehilcle_details.dart`
    - `lib/screens/Delivery_person/vehicalregistration.dart`
    - `lib/screens/Delivery_person/delivery_edit_adhar_card.dart`
    - `lib/screens/Delivery_person/delivery_edit_pan_card.dart`
    - `lib/screens/Delivery_person/delivery_edit_License_card.dart`
- Field executive screens — **WIDGET TEST (selective, P1)**:
  - Parsing/normalization helpers — **UNIT TEST (P1)**:
    - `lib/screens/Field_executive/field_executive_delivery_flow_helpers.dart`
  - Dashboard shell — **WIDGET TEST (P1)**:
    - `lib/screens/Field_executive/field_executive_dashboard.dart`
    - `lib/screens/Field_executive/field_executive_home_tab.dart`
  - Delivery request list/detail flows — **WIDGET TEST (P1 selective)**:
    - `lib/screens/Field_executive/field_executive_delivery_request_list_base.dart`
    - `lib/screens/Field_executive/field_executive_delivery_request_list_screen.dart`
    - `lib/screens/Field_executive/field_executive_delivery_detail_base_screen.dart`
    - `lib/screens/Field_executive/field_executive_delivery_screen.dart`
    - `lib/screens/Field_executive/field_executive_delivery_send_otp_screen.dart`
    - `lib/screens/Field_executive/field_executive_delivery_otp_verification_screen.dart`
    - `lib/screens/Field_executive/field_executive_delivery_map_tracking_screen.dart`
    - `lib/screens/Field_executive/field_executive_delivery_product_detail_screen.dart`
    - `lib/screens/Field_executive/field_executive_delivery_pickup_list_screen.dart`
    - `lib/screens/Field_executive/field_executive_delivery_pickup_detail_screen.dart`
    - `lib/screens/Field_executive/field_executive_delivery_return_list_screen.dart`
    - `lib/screens/Field_executive/field_executive_delivery_return_detail_screen.dart`
    - `lib/screens/Field_executive/field_executive_delivery_part_request_list_screen.dart`
    - `lib/screens/Field_executive/field_executive_delivery_part_request_detail_screen.dart`
  - Other field executive screens — **TEST INDIRECTLY THROUGH HIGHER LAYER** (only promote to widget tests when they cause regressions):
    - `lib/screens/Field_executive/field_excutive_attendance.dart`
    - `lib/screens/Field_executive/field_executive_add_product.dart`
    - `lib/screens/Field_executive/field_executive_all_products_screen.dart`
    - `lib/screens/Field_executive/field_executive_case_transfer_screen.dart`
    - `lib/screens/Field_executive/field_executive_cash_in_hand.dart`
    - `lib/screens/Field_executive/field_executive_detail_requested_product.dart`
    - `lib/screens/Field_executive/field_executive_feedback.dart`
    - `lib/screens/Field_executive/field_executive_installation_checklist_screen.dart`
    - `lib/screens/Field_executive/field_executive_installation_detail_screen.dart`
    - `lib/screens/Field_executive/field_executive_map_tracking_screen.dart`
    - `lib/screens/Field_executive/field_executive_notification.dart`
    - `lib/screens/Field_executive/field_executive_otp_verification_screen.dart`
    - `lib/screens/Field_executive/field_executive_payment.dart`
    - `lib/screens/Field_executive/field_executive_payment_detail.dart`
    - `lib/screens/Field_executive/field_executive_payment_done.dart`
    - `lib/screens/Field_executive/field_executive_payment_receipts.dart`
    - `lib/screens/Field_executive/field_executive_personal_info.dart`
    - `lib/screens/Field_executive/field_executive_pickup_product.dart`
    - `lib/screens/Field_executive/field_executive_privacy_policy.dart`
    - `lib/screens/Field_executive/field_executive_product_detail.dart`
    - `lib/screens/Field_executive/field_executive_product_item_detail_screen.dart`
    - `lib/screens/Field_executive/field_executive_product_list_to_add_more.dart`
    - `lib/screens/Field_executive/field_executive_product_payment.dart`
    - `lib/screens/Field_executive/field_executive_profile_screen.dart`
    - `lib/screens/Field_executive/field_executive_repair_request_part.dart`
    - `lib/screens/Field_executive/field_executive_stock_in_hand.dart`
    - `lib/screens/Field_executive/field_executive_upload_after_images_screen.dart`
    - `lib/screens/Field_executive/field_executive_upload_before_images_screen.dart`
    - `lib/screens/Field_executive/field_executive_work.dart`
    - `lib/screens/Field_executive/field_executive_work_call.dart`
    - `lib/screens/Field_executive/field_executive_write_report_screen.dart`
- Reimbursement screens — **WIDGET TEST (P0/P1)**:
  - `lib/screens/reimbursement/reimbursement_screen.dart`
  - `lib/screens/reimbursement/add_reimbursement_screen.dart`
  - `lib/screens/reimbursement/reimbursement_detail_screen.dart`
- Wallet screen — **WIDGET TEST (P1)**:
  - `lib/screens/wallet/wallet_screen.dart`

### `lib/widgets/`
- `lib/widgets/custom_button.dart` — **WIDGET TEST (P0/P1)**: loading/disabled behavior + tap callback.
- `lib/widgets/error_dialog.dart` — **WIDGET TEST (P1)**: renders expected message/buttons.
- `lib/widgets/bottom_navigation.dart` — **WIDGET TEST (P1)**: taps call the expected callbacks.
- `lib/widgets/delivery_man_bottom_navigation.dart` — **WIDGET TEST (P1)**.
- `lib/widgets/placeholder.dart` — **DO NOT TEST DIRECTLY**: trivial UI.
- `lib/widgets/badge_icon.dart` — **TEST INDIRECTLY THROUGH HIGHER LAYER**: presentational.
- `lib/widgets/google_sign_in_button.dart` — **TEST INDIRECTLY THROUGH HIGHER LAYER**: presentational; behavior covered via login screen tests.
- `lib/widgets/phone_input_field.dart` — **TEST INDIRECTLY THROUGH HIGHER LAYER**: validation covered via login/signup screens.
- `lib/widgets/reimbursement/reimbursement_section.dart` — **TEST INDIRECTLY THROUGH HIGHER LAYER**: list formatting.
- `lib/widgets/task_view_modal.dart` — **TEST INDIRECTLY THROUGH HIGHER LAYER**: modal UI.

## 5) Roadmap / Priorities (P0 / P1 / P2)

### P0 (must test before production)
- **Session/token lifecycle:** `SecureStorageService`, `SessionManager`
- **Auth retry/refresh engine:** `ApiService` authenticated helpers (prove retry works)
- **Delivery OTP delivery state machine:** `DeliveryOrderActionProvider.verifyAndDeliver`, timer behavior
- **Auth widget shell:** `SplashScreen`, `rolesccreen`, `LoginScreen`, `OtpVerificationScreen`
- **Reimbursement add flow:** form validation + submission behavior (widget + service unit)
- **Integration smoke:** logged out boot, Sales OTP login flow, Delivery OTP login flow (mock HTTP)

### P1 (important)
- Sales dashboard + list pagination providers
- Delivery home + order detail providers and key screens
- Field executive parsing helpers + request list/detail screens
- Wallet parsing + UI states
- Media/permission dialogs for critical forms

### P2 (nice to have)
- Selected goldens, minor widgets, purely presentational screens

## 6) Recommended Test Folder Structure (already created in repo)

- `test/support/test_bootstrap.dart`
- `test/support/secure_storage_mock.dart`
- `test/helpers/http_router.dart`
- `test/helpers/pump_app.dart`
- `test/helpers/transparent_asset_bundle.dart`
- `test/unit/**`
- `test/widget/**`
- `integration_test/**`

## 7) Recommended Packages (minimal, high ROI)

Already present in `pubspec.yaml`:
- `mocktail` (for mocking injected services when needed)
- `fake_async` (timers in providers/models)
- `golden_toolkit` + `network_image_mock` (selective goldens only)
- `integration_test`, `flutter_test`

## 8) Current P0 Tests Implemented (repo status)

Unit (P0):
- `test/unit/core/secure_storage_service_test.dart`
- `test/session_manager_test.dart`
- `test/unit/services/api_service_auth_retry_test.dart`
- `test/unit/services/delivery_api_client_test.dart`
- `test/unit/providers/delivery_order_action_provider_test.dart`
- `test/unit/models/delivery_order_model_test.dart`
- `test/unit/models/reimbursement_model_test.dart`

Widget (P0):
- `test/widget/auth/splash_screen_widget_test.dart`
- `test/role_screen_widget_test.dart`
- `test/widget/auth/login_screen_widget_test.dart`
- `test/widget/auth/otp_screen_widget_test.dart`
- `test/widget/reimbursement/add_reimbursement_screen_widget_test.dart`

Integration (P0, mocked HTTP):
- `integration_test/app_smoke_test.dart`
- `integration_test/flows/auth_sales_flow_test.dart`
- `integration_test/flows/auth_delivery_flow_test.dart`

## 9) CI / Local Commands (deterministic)

- Run unit + widget tests:
  - `flutter test`
- Run integration tests with mocked HTTP:
  - `flutter test integration_test`
- Disable notifications explicitly (optional; main.dart already skips them under `FLUTTER_TEST`):
  - `flutter test --dart-define=DISABLE_NOTIFICATIONS=true`
