/// App-wide string constants
class AppStrings {
  AppStrings._(); // Private constructor to prevent instantiation

  // Role Selection Screen
  static const String roleSelectionTitle = 'Select your service role';
  static const String roleSelectionSubtitle = 'Choose your role to continue';

  // User Roles
  static const String fieldExecutive = 'Field Executive';
  static const String deliveryMan = 'Delivery Man';
  static const String salesPerson = 'Sales Person';

  // App Name
  static const String appName = 'CrackTech';

  // Login Screen
  static const String welcomeBack = 'Welcome Back!';
  static const String numberLabel = 'Phone Number :';
  static const String loginButton = 'Login';
  static const String dontHaveAccount = "Don't have account? ";
  static const String signUp = 'Sign Up';

  // Error Messages
  static const String phoneNotFound = 'Phone Number is Not found';
  static const String invalidPhoneFormat =
      'Please enter a valid 10-digit phone number';
  static const String networkError = 'Network error. Please try again.';
  static const String somethingWentWrong =
      'Something went wrong. Please try again.';

  // Dialog Buttons
  static const String cancel = 'Cancel';
  static const String signUpButton = 'Sign Up';

  // OTP Screen
  static const String otpVerification = 'OTP Verification';
  static const String enterOtp = 'Enter the OTP sent to your phone';
  static const String verifyButton = 'Verify';
  static const String resendOtp = 'Resend OTP';

  // Sign Up Screen
  static const String createAccount = 'Create Account';
  static const String nameLabel = 'Full Name';
  static const String emailLabel = 'Email';
  static const String registerButton = 'Register';
  static const String alreadyHaveAccount = 'Already have an account? ';
  static const String login = 'Login';

  // Product Details Screen
  static const String productTitle = 'Product';
  static const String systemSpecs = 'System Specs';
  static const String processor = 'Processor';
  static const String os = 'Operating System';
  static const String graphicCard = 'Graphic Card';
  static const String memory = 'Memory';
  static const String storage = 'Storage';
  static const String display = 'Display';
  static const String camera = 'Camera';
  static const String audio = 'Audio';
  static const String pointingDevice = 'Pointing Device';
  static const String keyboard = 'Keyboard';
  static const String wifi = 'WIFI';
  static const String warranty = 'Warranty';
  static const String color = 'Color';
  static const String brand = 'Brand';
  static const String screenResolution = 'Screen Resolution';
  static const String softwarePreload = 'Software Preload';
  static const String services = 'Services';
  static const String inclTaxes = 'Incl. Shipping & all Taxes';
  static const String addButton = 'Add';


  // Product Payment Screen
  static const String productPaymentTitle = 'Product payment';
  static const String offers = 'Offers';
  static const String enterOfferCode = 'Enter Offer Code';
  static const String online = 'Online';
  static const String googlePay = 'Google Pay';
  static const String phonePe = 'PhonePe';
  static const String addNewUpiId = 'Add New UPI ID';
  static const String cash = 'Cash';
  static const String amount = 'Amount';
  static const String done = 'Done';
}




/// Helper function to generate dynamic subtitle
String getLoginSubtitle(String roleName) {
  return '$roleName, please continue to login';
}

/// Helper function to generate dynamic signup subtitle
String getSignUpSubtitle(String roleName) {
  return '$roleName, please fill the details to sign up';
}
