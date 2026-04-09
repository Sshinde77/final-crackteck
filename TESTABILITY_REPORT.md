# TESTABILITY REPORT — `final_crackteck` (Flutter)

This report is derived from the repo’s current implementation (Provider/ChangeNotifier state, static/singleton services, route generator wiring, token/session logic, and API client behavior including HTML-as-unauthorized detection).

## Executive Summary (what will fight tests first)

1. **Plugin-heavy flows executed from UI** (Firebase Messaging, permissions, secure storage, sms_autofill) cause `MissingPluginException`/flakiness in `flutter test` unless guarded or mocked.
2. **Static singletons + in-memory caches** (`SecureStorageService`, `NavigationService`, `SessionManager`, `ApiService`) create cross-test leakage unless reset between tests.
3. **Service layer triggers navigation** on auth failures (`ApiService`, `DeliveryApiClient`) which complicates unit testing unless there is a navigator available or redirects are gated.
4. **Long-running timers** (OTP screens and delivery OTP timers) make `pumpAndSettle()` unsafe and require deterministic time control in tests.

## Tightly Coupled / High Side-Effect Code

### `lib/services/api_service.dart`
- Mixes **HTTP + token persistence + session clearing + navigation redirect** in the same call paths.
- Auth helpers (`_performAuthenticatedGet/Post/Delete`) read `SecureStorageService` directly and invoke `_handleAuthFailure()` which calls `NavigationService`.
- Test impact: unit tests for “retry/refresh behavior” must either (a) provide a `MaterialApp` with `NavigationService.navigatorKey`, or (b) ensure redirects are harmless/no-op.

### `lib/services/delivery_person/delivery_api_client.dart`
- Similar coupling: network + storage + refresh + navigation.
- Test impact: on auth failures, it will attempt to navigate to auth root; without a navigator it’s a no-op but still a side-effect.

### `lib/routes/route_generator.dart`
- Creates providers inside route constructors. Tests that build routes can unintentionally spin up providers that call APIs unless HTTP is overridden.

## Hard-to-Mock Dependencies

### Firebase/notifications (`lib/services/notification_service.dart`)
- Uses `firebase_core`, `firebase_messaging` streams, `permission_handler`, and `flutter_local_notifications`.
- Test impact: calling `initialize()` or any code path that calls `Firebase.initializeApp()` can break in CI unless gated.

### SMS autofill (`lib/otp_screen.dart`)
- Calls `listenForCode()` (platform channel) in `initState`.
- Test impact: widget tests can fail unless the call is guarded for test builds or the channel is mocked.

### Pickers/permissions (`image_picker`, `permission_handler`)
- Primarily routed through `lib/services/media_picker_service.dart`.
- Test impact: widget tests that tap receipt/camera flows require method-channel mocks or injection seams.

## Singleton / Static Misuse (cross-test leakage)

### `lib/core/secure_storage_service.dart`
- Static caches (`_accessToken`, `_roleId`, `_userId`, `_deviceId`, etc.) and the in-memory set `_vehicleRegisteredUserIds`.
- Risk: tests become order-dependent if cached values persist across test cases.

### `lib/core/navigation_service.dart`
- Static global state (`_currentRouteName`, `_isNavigatingToAuthRoot`) affects behavior across tests.

### `lib/services/session_manager.dart`
- Static `_sessionWriteCompleter` coordinates session writes; can introduce timing sensitivity in tests.

## Direct BuildContext Business Logic

### `lib/services/session_manager.dart`
- `openProtectedRouteForRole(...)` and `navigateAfterAuthentication(...)` directly drive navigation and use `context.mounted`.
- Test impact: logic must be covered via widget tests; pure unit tests can’t validate navigation behavior without a widget harness.

## Async / State Risks

### Periodic timers (OTP)
- `lib/otp_screen.dart`, `lib/provider/delivery_person/delivery_order_action_provider.dart`
- Test impact: `pumpAndSettle()` can hang; tests must pump finite durations or use `fake_async` (for unit tests).

### Manual delays
- OTP flow includes `Future.delayed(...)` for UX pacing.
- Test impact: increases flakiness and requires explicit `pump(Duration(...))`.

## Minimum Refactors Recommended (CI stability)

These changes are intentionally small and local:

1. **Guard SMS autofill in tests**
   - `lib/otp_screen.dart`: skip `listenForCode()` when `FLUTTER_TEST` is true.
2. **Disable notifications in tests and allow deterministic CI**
   - `lib/main.dart`: skip notification initialization when `DISABLE_NOTIFICATIONS=true` (already present).
   - `lib/services/notification_service.dart`: treat notifications as disabled under `FLUTTER_TEST` or `DISABLE_NOTIFICATIONS`.
3. **Reset global state between tests**
   - Add/maintain `resetForTesting()` hooks for static services and call them from `test/support/test_bootstrap.dart`.

## What’s Already Implemented in This Repo (testability hardening)

- `lib/main.dart`: build-time flag to skip notification initialization:
  - `DISABLE_NOTIFICATIONS` with fallback to `FLUTTER_TEST`.
- `lib/otp_screen.dart`: SMS autofill is skipped under `FLUTTER_TEST`.
- `lib/services/notification_service.dart`: `initialize()` and `syncTokenWithBackendIfPossible()` are no-ops when notifications are disabled.
- `lib/core/secure_storage_service.dart`: `resetForTesting()` clears in-memory caches and the vehicle-registration set.
- `lib/core/navigation_service.dart`: `resetForTesting()` clears route/guard flags.
- `test/support/test_bootstrap.dart`: resets `SecureStorageService` and `NavigationService` and installs `SecureStorageMock`.

