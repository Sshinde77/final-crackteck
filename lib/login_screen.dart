import 'package:final_crackteck/core/secure_storage_service.dart';
import 'package:final_crackteck/routes/app_routes.dart';
import 'package:final_crackteck/services/api_service.dart';
import 'package:final_crackteck/services/auth_service.dart';
import 'package:final_crackteck/services/google_auth_service.dart';
import 'package:final_crackteck/widgets/error_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'constants/api_constants.dart';
import 'constants/app_colors.dart';
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

enum _LoginTab { phone, email }

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final ApiService _apiService = ApiService.instance;
  final AuthService _authService = AuthService();
  final GoogleAuthService _googleAuthService = GoogleAuthService();

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;
  String? _errorText;
  _LoginTab _selectedTab = _LoginTab.phone;

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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

  Future<void> _handleLogin() async {
    if (!_validatePhoneNumber()) return;

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final phoneNumber = _phoneController.text.trim();

      debugPrint('Login attempt for ${widget.roleName} with phone: $phoneNumber');

      final response = await _apiService.login(
        roleId: widget.roleId,
        phoneNumber: phoneNumber,
      );

      if (!mounted) return;

      debugPrint(
        'Login response - success: ${response.success}, message: ${response.message}',
      );

      if (response.success) {
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
        if (response.message != null &&
            response.message!.toLowerCase().contains('network error')) {
          showErrorDialog(
            context: context,
            message: response.message ?? AppStrings.networkError,
          );
        } else {
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
      debugPrint('Exception during login: $e');
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

  void _showUnavailableMessage(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$feature is not wired in the current authentication flow. Existing login logic was left unchanged.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cardWidth = size.width > 700 ? 520.0 : double.infinity;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F7FB),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF182134)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  kToolbarHeight -
                  24,
            ),
            child: Center(
              child: SizedBox(
                width: cardWidth,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    Image.asset(
                      'assets/logo.png',
                      height: 88,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.business,
                        size: 88,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 26),
                    const Text(
                      'Welcome Back',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF162033),
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Login to continue',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF6E7B91),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF152033).withOpacity(0.06),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTabSwitcher(),
                          const SizedBox(height: 24),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            switchInCurve: Curves.easeOut,
                            switchOutCurve: Curves.easeIn,
                            child: _selectedTab == _LoginTab.phone
                                ? PhoneLoginTab(
                                    key: const ValueKey('phone-tab'),
                                    controller: _phoneController,
                                    errorText: _errorText,
                                    isLoading: _isLoading,
                                    onChanged: (_) {
                                      if (_errorText != null) {
                                        setState(() {
                                          _errorText = null;
                                        });
                                      }
                                    },
                                    onLoginPressed: _handleLogin,
                                  )
                                : EmailLoginTab(
                                    key: const ValueKey('email-tab'),
                                    emailController: _emailController,
                                    passwordController: _passwordController,
                                    obscurePassword: _obscurePassword,
                                    onToggleVisibility: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                    onForgotPassword: () {
                                      _showUnavailableMessage(
                                        'Forgot password',
                                      );
                                    },
                                    onLoginPressed: () {
                                      _showUnavailableMessage('Email login');
                                    },
                                  ),
                          ),
                          const SizedBox(height: 28),
                          const OrDivider(),
                          const SizedBox(height: 28),
                          Row(
                            children: [
                              Expanded(
                                child: SocialActionButton(
                                  label: 'Google',
                                  accentColor: const Color(0xFF4285F4),
                                  iconText: 'G',
                                  isLoading: _isGoogleLoading,
                                  onPressed: (_isLoading || _isGoogleLoading)
                                      ? null
                                      : _handleGoogleSignIn,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: SocialActionButton(
                                  label: 'Facebook',
                                  accentColor: const Color(0xFF1877F2),
                                  iconText: 'f',
                                  onPressed: () {
                                    _showUnavailableMessage('Facebook login');
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Don't have an account? ",
                                style: TextStyle(
                                  color: Color(0xFF7A879A),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              GestureDetector(
                                onTap: _navigateToSignUp,
                                child: const Text(
                                  'Sign Up',
                                  style: TextStyle(
                                    color: Color(0xFF0A8A35),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabSwitcher() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabButton(
              label: 'Phone',
              selected: _selectedTab == _LoginTab.phone,
              onTap: () {
                setState(() {
                  _selectedTab = _LoginTab.phone;
                  _errorText = null;
                });
              },
            ),
          ),
          Expanded(
            child: _TabButton(
              label: 'Email',
              selected: _selectedTab == _LoginTab.email,
              onTap: () {
                setState(() {
                  _selectedTab = _LoginTab.email;
                  _errorText = null;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}

class PhoneLoginTab extends StatelessWidget {
  const PhoneLoginTab({
    super.key,
    required this.controller,
    required this.errorText,
    required this.isLoading,
    required this.onChanged,
    required this.onLoginPressed,
  });

  final TextEditingController controller;
  final String? errorText;
  final bool isLoading;
  final ValueChanged<String> onChanged;
  final VoidCallback onLoginPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Phone Number',
          style: TextStyle(
            color: Color(0xFF1B2435),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        PhoneField(
          controller: controller,
          errorText: errorText,
          onChanged: onChanged,
        ),
        const SizedBox(height: 22),
        PrimaryActionButton(
          label: 'Login with OTP',
          isLoading: isLoading,
          onPressed: onLoginPressed,
        ),
      ],
    );
  }
}

class EmailLoginTab extends StatelessWidget {
  const EmailLoginTab({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onToggleVisibility,
    required this.onForgotPassword,
    required this.onLoginPressed,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onToggleVisibility;
  final VoidCallback onForgotPassword;
  final VoidCallback onLoginPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Email Address',
          style: TextStyle(
            color: Color(0xFF1B2435),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        ModernInputField(
          controller: emailController,
          hintText: 'Email',
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.alternate_email,
        ),
        const SizedBox(height: 14),
        ModernInputField(
          controller: passwordController,
          hintText: 'Password',
          obscureText: obscurePassword,
          prefixIcon: Icons.lock_outline,
          suffix: IconButton(
            onPressed: onToggleVisibility,
            icon: Icon(
              obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: const Color(0xFF6F7C91),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: onForgotPassword,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Forgot Password?',
              style: TextStyle(
                color: Color(0xFF0A8A35),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        PrimaryActionButton(label: 'Login', onPressed: onLoginPressed),
      ],
    );
  }
}

class PhoneField extends StatelessWidget {
  const PhoneField({
    super.key,
    required this.controller,
    required this.errorText,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String? errorText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 84,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F8FB),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: errorText != null
                  ? Colors.red.shade300
                  : const Color(0xFFD9DEE7),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  ApiConstants.defaultCountryCode,
                  style: TextStyle(
                    color: Color(0xFF182134),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 34,
                margin: const EdgeInsets.symmetric(horizontal: 14),
                color: const Color(0xFFD9DEE7),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  onChanged: onChanged,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    counterText: '',
                    hintText: '9876543210',
                    hintStyle: TextStyle(
                      color: Color(0xFF758198),
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: const TextStyle(
                    color: Color(0xFF182134),
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              errorText!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        ],
      ],
    );
  }
}

class ModernInputField extends StatelessWidget {
  const ModernInputField({
    super.key,
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIcon,
    this.suffix,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final IconData? prefixIcon;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD9DEE7)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Color(0xFF5B6578),
            fontSize: 17,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: prefixIcon == null
              ? null
              : Icon(prefixIcon, color: const Color(0xFF6F7C91)),
          suffixIcon: suffix,
        ),
        style: const TextStyle(
          color: Color(0xFF182134),
          fontSize: 17,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class PrimaryActionButton extends StatelessWidget {
  const PrimaryActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 68,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF058A31),
          foregroundColor: Colors.white,
          elevation: 0,
          disabledBackgroundColor: const Color(0xFF058A31).withOpacity(0.7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }
}

class SocialActionButton extends StatelessWidget {
  const SocialActionButton({
    super.key,
    required this.label,
    required this.accentColor,
    required this.iconText,
    this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final Color accentColor;
  final String iconText;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFD9DEE7)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      iconText,
                      style: TextStyle(
                        color: accentColor,
                        fontSize: label == 'Facebook' ? 18 : 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF182134),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider(color: Color(0xFFD9DEE7), thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: TextStyle(
              color: Color(0xFF98A4B8),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(child: Divider(color: Color(0xFFD9DEE7), thickness: 1)),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF152033).withOpacity(0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected
                ? const Color(0xFF182134)
                : const Color(0xFF6F7C91),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
