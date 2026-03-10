import 'package:final_crackteck/routes/app_routes.dart';
import 'package:final_crackteck/core/secure_storage_service.dart';
import 'package:final_crackteck/services/auth_service.dart';
import 'package:final_crackteck/services/api_service.dart';
import 'package:final_crackteck/services/google_auth_service.dart';
import 'package:final_crackteck/widgets/custom_button.dart';
import 'package:final_crackteck/widgets/error_dialog.dart';
import 'package:final_crackteck/widgets/google_sign_in_button.dart';
import 'package:final_crackteck/widgets/phone_input_field.dart';
import 'package:flutter/material.dart';

import 'constants/app_colors.dart';
import 'constants/app_spacing.dart';
import 'constants/app_strings.dart';


/// Unified Login Screen for all roles
class LoginScreen extends StatefulWidget {
  final int roleId;
  final String roleName;

  const LoginScreen({Key? key, required this.roleId, required this.roleName})
    : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final ApiService _apiService = ApiService.instance;
  final AuthService _authService = AuthService();
  final GoogleAuthService _googleAuthService = GoogleAuthService();

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  /// Validate phone number
  bool _validatePhoneNumber() {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length != 10) {
      setState(() {
        _errorText = AppStrings.invalidPhoneFormat;
      });
      return false;
    }
    setState(() {
      _errorText = null;
    });
    return true;
  }

  /// Handle login button press
  Future<void> _handleLogin() async {
    if (!_validatePhoneNumber()) return;

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final phoneNumber = _phoneController.text.trim(); // ✅ 10 digit only


      debugPrint(
        '🟢 Login attempt for ${widget.roleName} with phone: $phoneNumber',
      );

      final response = await _apiService.login(
        roleId: widget.roleId,
        phoneNumber: phoneNumber,
      );

      if (!mounted) return;

      debugPrint(
        '🟢 Login response - success: ${response.success}, message: ${response.message}',
      );

      if (response.success) {
        // Navigate to OTP verification screen
        debugPrint(
          '✅ Login successful - Navigating to OTP verification screen',
        );
        Navigator.pushNamed(
          context,
          AppRoutes.otpVerification,
          arguments: OtpArguments(
            roleId: widget.roleId,
            roleName: widget.roleName,
            phoneNumber: phoneNumber,
          ),
        );

      } else {
        // Check if it's a network error or API error
        if (response.message != null &&
            response.message!.toLowerCase().contains('network error')) {
          // Network error - show generic error dialog
          debugPrint(
            '🔴 Network error detected - Showing generic error dialog',
          );
          debugPrint('🔴 Error message: ${response.message}');
          showErrorDialog(
            context: context,
            message: response.message ?? AppStrings.networkError,
          );
        } else {
          // API error (phone not found, etc.) - show phone not found dialog
          debugPrint('❌ API error - Showing phone not found dialog');
          debugPrint('❌ Error message: ${response.message}');
          await showPhoneNotFoundDialog(
            context: context,
            onSignUpPressed: () {
              Navigator.pushNamed(
                context,
                AppRoutes.signUp,
                arguments: SignUpArguments(
                  roleId: widget.roleId,
                  roleName: widget.roleName,
                ),
              );
            },
          );
        }
      }
    } catch (e) {
      debugPrint('🔴 Exception during login: $e');
      if (!mounted) return;
      showErrorDialog(context: context, message: AppStrings.networkError);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isGoogleLoading = true;
      _errorText = null;
    });

    try {
      final GoogleAuthResult googleResult = await _googleAuthService.signIn();
      final Map<String, dynamic> response = await _authService.loginWithGoogle(
        googleResult.accessToken,
        roleId: widget.roleId,
      );

      if (!mounted) return;

      final bool isSuccess = response['success'] == true;
      if (!isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message']?.toString() ??
                  'Google sign-in failed. Please try again.',
            ),
          ),
        );
        return;
      }

      await SecureStorageService.saveRoleId(widget.roleId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google sign-in successful.')),
      );
      _navigateToDashboard();
    } on GoogleAuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (error) {
      debugPrint('Unhandled Google sign-in error: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google sign-in failed. Please try again.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
    }
  }

  void _navigateToDashboard() {
    switch (widget.roleId) {
      case 1:
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.FieldExecutiveDashboard,
          (route) => false,
          arguments: fieldexecutivedashboardArguments(
            roleId: widget.roleId,
            roleName: widget.roleName,
          ),
        );
        return;
      case 2:
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.Deliverypersondashbord,
          (route) => false,
        );
        return;
      case 3:
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.salespersonDashboard,
          (route) => false,
        );
        return;
      default:
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.roleSelection,
          (route) => false,
        );
    }
  }

  /// Navigate to sign up screen
  void _navigateToSignUp() {
    Navigator.pushNamed(
      context,
      AppRoutes.signUp,
      arguments: SignUpArguments(
        roleId: widget.roleId,
        roleName: widget.roleName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.horizontalPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.loginTopPadding),

              // Title
              const Text(
                AppStrings.welcomeBack,
                style: TextStyle(
                  color: AppColors.black,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.titleSubtitleSpacing),

              // Subtitle (dynamic based on role)
              Text(
                getLoginSubtitle(widget.roleName),
                style: const TextStyle(
                  color: AppColors.lightGrey,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.subtitleInputSpacing),

              // Phone Number Input
              PhoneInputField(
                controller: _phoneController,
                label: AppStrings.numberLabel,
                errorText: _errorText,
                onChanged: (_) {
                  if (_errorText != null) {
                    setState(() {
                      _errorText = null;
                    });
                  }
                },
              ),

              const SizedBox(height: AppSpacing.inputButtonSpacing),

              // Login Button
              CustomButton(
                text: AppStrings.loginButton,
                onPressed: _handleLogin,
                isLoading: _isLoading,
              ),

              const SizedBox(height: 16),

              GoogleSignInButton(
                onPressed: (_isLoading || _isGoogleLoading)
                    ? null
                    : _handleGoogleSignIn,
                isLoading: _isGoogleLoading,
              ),

              const SizedBox(height: AppSpacing.buttonSignUpSpacing),

              // Sign Up Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    AppStrings.dontHaveAccount,
                    style: TextStyle(color: AppColors.lightGrey, fontSize: 14),
                  ),
                  GestureDetector(
                    onTap: _navigateToSignUp,
                    child: const Text(
                      AppStrings.signUp,

                      style: TextStyle(
                        color: AppColors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.bottomPadding),
            ],
          ),
        ),
      ),
    );
  }
}
