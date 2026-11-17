# SRB Computer Engineer — Play Store & App Store Submission Checklist

यह document SRB Computer Engineer app को Google Play Store और Apple App Store पर publish करने के लिए है। Store policies समय के साथ बदल सकती हैं; submission से पहले official console warnings भी check करें.

## 1. App identity

| Item | Value |
|---|---|
| App name | SRB Computer Engineer |
| Android package/application ID | `com.srbcomputer.engineer` |
| iOS Bundle ID | `com.srbcomputer.engineer` |
| Dart package | `srb_computer_engineer` |
| API base URL | `https://srbcomputers.co.in/api/v1` |
| Website | `https://srbcomputers.co.in` |
| Firebase project | `srb-computers-1be29` |

Before upload, confirm that these values are the same in the binary, Firebase console, Play Console, and App Store Connect.

## 2. Ready store text

### Common app name

`SRB Computer Engineer`

### Google Play short description — maximum 80 characters

`Manage field service, delivery and sales operations in one app.`

### Apple subtitle — maximum 30 characters

`Field Service Management`

### Google Play and Apple description

```text
SRB Computer Engineer helps service teams manage field operations, delivery work and sales activities from one place.

Key features:

• Field service requests and case tracking
• Service, installation and repair updates
• Delivery orders, pickup and return workflows
• OTP-based order and service verification
• Attendance and work tracking
• Product, stock and payment information
• Sales leads, follow-ups, meetings and quotations
• Reimbursement and profile management
• Push notifications for important updates
• Secure login and role-based access

The app is intended for authorized SRB Computer employees, engineers, delivery personnel and sales teams. Some features require an active company account and internet connection.
```

### Apple keywords — maximum 100 bytes

`field service,engineer,delivery,attendance,service orders,sales,CRM`

Remove any keyword that is not accurate for the final app. Apple does not allow other companies’ names in keywords.

### Apple promotional text — maximum 170 characters

`Manage service requests, delivery tasks, attendance and sales workflows with SRB Computer Engineer.`

### Suggested category

- Primary: Business
- Secondary: Productivity

Confirm the final category with the business owner before submission.

## 3. Store graphics and screenshots

### App icon

- Android Play listing icon: 512 × 512 px, 32-bit PNG with alpha, maximum 1 MB.
- Android launcher icon: already configured in the Android project; verify it uses the final SRB Computer branding.
- iOS App Store icon: 1024 × 1024 px source in the Xcode `AppIcon` asset catalog.
- Do not include “#1”, “Best”, discounts, rankings, Google/Apple badges, or misleading notification badges.
- Use the same logo, colors and brand treatment across Android and iOS.

### Google Play graphics

- Feature graphic: 1024 × 500 px, JPG or 24-bit PNG without alpha.
- Phone screenshots: prepare at least 4–6 screenshots showing real app screens.
- Recommended screenshot sequence:
  1. Login / role selection
  2. Field service dashboard
  3. Service request or case details
  4. Delivery order workflow
  5. Attendance / work tracking
  6. Sales leads, quotation or notification screen
- Optional: short preview video showing the real app.
- Do not show real customer phone numbers, emails, tokens, addresses, or private business data.

### Apple App Store graphics

- Upload at least one screenshot for each supported required device class.
- Since this project supports iPhone and iPad targets, prepare iPhone and iPad screenshots unless iPad support is intentionally removed.
- Current Apple reference sizes include:
  - iPhone Dynamic Island medium: 1179 × 2556 or 1206 × 2622 px.
  - iPhone Dynamic Island large: 1260 × 2736, 1290 × 2796, or 1320 × 2868 px.
  - iPad 13-inch: 2064 × 2752 or 2048 × 2732 px.
- Screenshots may be JPG or PNG and must not contain transparent alpha channels.
- App Preview video is optional; if used, show only genuine app functionality.

## 4. Android release package

- Build and upload an Android App Bundle (`.aab`), not only an APK.
- Package ID must be `com.srbcomputer.engineer`.
- Increment `versionCode` for every upload and set the correct user-facing `versionName`.
- Use the final release keystore. Keep the keystore, alias, passwords and backup secure.
- Add release SHA-1 and SHA-256 fingerprints in Firebase and Google services if required.
- Confirm the app targets the current Google Play requirement. As of 31 August 2026, new apps and updates must target Android 16 / API 36 or higher.
- Confirm `google-services.json` belongs to Firebase project `srb-computers-1be29` and package `com.srbcomputer.engineer`.
- Test a signed release build, not only a debug build.

Example commands:

```powershell
flutter clean
flutter pub get
flutter build appbundle --release
```

Output to upload:

```text
build/app/outputs/bundle/release/app-release.aab
```

## 5. iOS release package

- Apple Developer Program membership must be active.
- App Store Connect app record must use Bundle ID `com.srbcomputer.engineer`.
- Configure the App ID, distribution certificate and App Store provisioning profile.
- Enable Push Notifications capability for the App ID.
- Configure APNs authentication key or certificate in Firebase Cloud Messaging.
- Confirm `GoogleService-Info.plist` belongs to project `srb-computers-1be29` and bundle ID `com.srbcomputer.engineer`.
- Upload an Archive through Xcode or Transporter.
- Increase `CFBundleShortVersionString` / build number for each new upload.
- Test the release/TestFlight build on a real iPhone. Simulator push testing is not sufficient for APNs validation.

## 6. Privacy, data safety and permissions

Create and publish a real, public HTTPS privacy-policy page before submission. Suggested URL placeholder:

`https://srbcomputers.co.in/privacy-policy`

Replace this URL if the actual privacy-policy path is different.

The policy should accurately explain:

- Account/login information such as phone number, email and user profile details.
- Authentication tokens and secure local storage.
- Push-notification tokens and device information used to deliver notifications.
- Photos and videos captured for service, installation, KYC, receipt or work records.
- Camera, microphone and photo-library access and why each permission is needed.
- API/backend processing, retention, deletion and support contact.
- Firebase and other third-party SDK processing.
- How a user can request account/data deletion.

Complete the following console forms accurately:

- Google Play: Data safety, content rating, target audience, ads declaration, app access/reviewer instructions and privacy policy.
- Apple: App Privacy data types, privacy policy URL, age rating, export compliance and app review information.

Do not select “No data collected” if the app or its SDKs collect account data, photos, device identifiers, notification tokens or analytics data.

## 7. Reviewer access

Because the app requires login, prepare a reviewer account:

```text
Company / app: SRB Computer Engineer
Role: [Field Executive / Delivery Person / Sales Person]
Phone or email: [REVIEWER_TEST_ACCOUNT]
OTP/password: [REVIEWER_LOGIN_INSTRUCTIONS]
Environment: Production
Notes: [Explain how to reach the main features after login]
```

The account must remain active during review and must not require an employee’s personal phone or manual approval.

## 8. Notification test checklist

- Install a fresh signed Android build and a TestFlight iOS build.
- Grant notification permission on both devices.
- Log in and confirm an FCM token is generated.
- Confirm the token is synced to the backend using the new API URL.
- Send a Firebase Console test notification while the app is:
  - Foreground
  - Background
  - Fully closed
- Tap the notification and confirm it opens the expected in-app notification screen/deep link.
- Verify Android 13+ notification permission.
- Verify iOS APNs permission, Push Notifications capability and Firebase APNs configuration.
- Confirm the backend uses the Firebase Admin credentials for project `srb-computers-1be29`, not the old Firebase project.

## 9. Final Play Console checklist

- [ ] Developer account and payments/profile completed
- [ ] App created with correct name and package ID
- [ ] Store listing text entered
- [ ] App icon, feature graphic and screenshots uploaded
- [ ] Privacy policy URL added
- [ ] Data Safety form completed
- [ ] Content rating completed
- [ ] Target audience and ads declaration completed
- [ ] App access instructions and reviewer account added
- [ ] Release `.aab` uploaded
- [ ] Internal/closed testing completed
- [ ] Release notes added
- [ ] Production rollout submitted

## 10. Final App Store Connect checklist

- [ ] App record created with Bundle ID `com.srbcomputer.engineer`
- [ ] App name, subtitle, description and keywords entered
- [ ] Privacy Policy URL and support URL added
- [ ] App Privacy questionnaire completed
- [ ] Age rating completed
- [ ] iPhone/iPad screenshots uploaded
- [ ] App icon included in Xcode build
- [ ] APNs and Push Notifications configured
- [ ] Archive uploaded and processed
- [ ] TestFlight internal testing completed
- [ ] Export compliance answered
- [ ] Review notes and test account added
- [ ] Build selected and submitted for review

## Official references

- [Google Play store listing setup](https://support.google.com/googleplay/android-developer/answer/9859152)
- [Google Play graphics and screenshots](https://support.google.com/googleplay/android-developer/answer/9866151)
- [Google Play review preparation and privacy policy](https://support.google.com/googleplay/android-developer/answer/9859455)
- [Google Play target API requirements](https://support.google.com/googleplay/android-developer/answer/11926878)
- [Apple App Store information and limits](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information/)
- [Apple screenshots](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications)
- [Apple app icon](https://developer.apple.com/help/app-store-connect/manage-app-information/add-an-app-icon)
- [Apple App Privacy](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy)
- [Apple upload builds](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/)
