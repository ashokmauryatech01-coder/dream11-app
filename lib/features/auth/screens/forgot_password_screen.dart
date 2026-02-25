import 'package:flutter/material.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';
import 'package:fantasy_crick/common/widgets/custom_button.dart';
import 'package:fantasy_crick/common/widgets/beauty_dialog.dart';
import 'package:fantasy_crick/core/services/auth_service.dart';
import 'package:fantasy_crick/features/auth/screens/signin_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Individual OTP digit controllers
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
      List.generate(6, (_) => FocusNode());

  bool _loading = false;
  bool _otpSent = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    for (final c in _otpControllers) { c.dispose(); }
    for (final f in _otpFocusNodes) { f.dispose(); }
    super.dispose();
  }

  String get _otp =>
      _otpControllers.map((c) => c.text).join();

  /// Step 1: Send OTP to email via API
  Future<void> _sendOTP() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      await BeautyDialog.show(context,
          title: 'Email Required',
          message: 'Please enter your email address.',
          type: BeautyDialogType.warning);
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      await BeautyDialog.show(context,
          title: 'Invalid Email',
          message: 'Please enter a valid email address.',
          type: BeautyDialogType.warning);
      return;
    }

    setState(() => _loading = true);

    try {
      await _authService.forgotPassword(email);

      if (!mounted) return;
      setState(() {
        _loading = false;
        _otpSent = true;
      });

      await BeautyDialog.show(context,
          title: 'OTP Sent',
          message:
              'A 6-digit verification code has been sent to $email',
          type: BeautyDialogType.success);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      final msg = e.toString().replaceFirst('Exception: ', '');
      await BeautyDialog.show(context,
          title: 'Failed to Send OTP',
          message: msg,
          type: BeautyDialogType.error);
    }
  }

  /// Step 2: Verify OTP + reset password via API
  Future<void> _resetPassword() async {
    final otp = _otp;
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (otp.length < 6) {
      await BeautyDialog.show(context,
          title: 'Invalid OTP',
          message: 'Please enter the 6-digit code sent to your email.',
          type: BeautyDialogType.warning);
      return;
    }

    if (newPassword.isEmpty || newPassword.length < 6) {
      await BeautyDialog.show(context,
          title: 'Weak Password',
          message: 'Password must be at least 6 characters long.',
          type: BeautyDialogType.warning);
      return;
    }

    if (newPassword != confirmPassword) {
      await BeautyDialog.show(context,
          title: 'Password Mismatch',
          message: 'The passwords you entered do not match.',
          type: BeautyDialogType.error);
      return;
    }

    setState(() => _loading = true);

    try {
      await _authService.resetPassword(
        _emailController.text.trim(),
        otp,
        newPassword,
        confirmPassword,
      );

      if (!mounted) return;
      setState(() => _loading = false);

      await BeautyDialog.show(
        context,
        title: 'Password Reset!',
        message:
            'Your password has been reset successfully. Please sign in with your new password.',
        type: BeautyDialogType.success,
        confirmText: 'Sign In',
        onConfirm: () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const SignInScreen()),
            (route) => false,
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      final msg = e.toString().replaceFirst('Exception: ', '');
      await BeautyDialog.show(context,
          title: 'Reset Failed',
          message: msg,
          type: BeautyDialogType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.text),
        title: const Text(
          'Forgot Password',
          style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildHeader(),
              const SizedBox(height: 40),
              if (!_otpSent) ...[
                _buildEmailSection(),
              ] else ...[
                _buildResetSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _otpSent ? Icons.lock_reset : Icons.lock_outline,
            size: 50,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _otpSent ? 'Reset Password' : 'Forgot Password?',
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _otpSent
              ? 'Enter the OTP and create a new password'
              : "No worries! Enter your email and we'll send you a reset code.",
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, color: AppColors.textLight),
        ),
      ],
    );
  }

  Widget _buildEmailSection() {
    return Column(
      children: [
        _buildInputField(
          controller: _emailController,
          label: 'Email Address',
          hint: 'Enter your registered email',
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.email_outlined,
        ),
        const SizedBox(height: 24),
        CustomButton(
          title: 'Send Reset Code',
          onTap: _sendOTP,
          loading: _loading,
        ),
        const SizedBox(height: 20),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Back to Sign In',
            style: TextStyle(
                color: AppColors.primary, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildResetSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Email chip
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.email, color: AppColors.success, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('OTP sent to',
                        style: TextStyle(
                            color: AppColors.textLight, fontSize: 12)),
                    Text(
                      _emailController.text,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.text),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => setState(() {
                  _otpSent = false;
                   for (final c in _otpControllers) { c.clear(); }
                }),
                child: const Text('Change',
                    style: TextStyle(color: AppColors.primary)),
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // OTP boxes
        const Text(
          'Verification Code',
          style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppColors.text),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) {
            return SizedBox(
              width: 46,
              height: 56,
              child: TextField(
                controller: _otpControllers[index],
                focusNode: _otpFocusNodes[index],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: AppColors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty && index < 5) {
                    _otpFocusNodes[index + 1].requestFocus();
                  } else if (value.isEmpty && index > 0) {
                    _otpFocusNodes[index - 1].requestFocus();
                  }
                },
              ),
            );
          }),
        ),

        const SizedBox(height: 24),

        // New password
        _buildPasswordField(
          controller: _newPasswordController,
          label: 'New Password',
          hint: 'Enter new password',
          obscure: _obscureNew,
          onToggle: () => setState(() => _obscureNew = !_obscureNew),
        ),
        const SizedBox(height: 16),
        _buildPasswordField(
          controller: _confirmPasswordController,
          label: 'Confirm Password',
          hint: 'Confirm new password',
          obscure: _obscureConfirm,
          onToggle: () =>
              setState(() => _obscureConfirm = !_obscureConfirm),
        ),

        const SizedBox(height: 28),

        CustomButton(
          title: 'Reset Password',
          onTap: _resetPassword,
          loading: _loading,
        ),

        const SizedBox(height: 16),

        Center(
          child: TextButton(
            onPressed: _sendOTP,
            child: const Text(
              "Didn't receive code? Resend",
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    IconData? prefixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.text)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(color: AppColors.text),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.textLight),
              border: InputBorder.none,
              prefixIcon: prefixIcon != null
                  ? Icon(prefixIcon, color: AppColors.textLight)
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.text)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            style: const TextStyle(color: AppColors.text),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.textLight),
              border: InputBorder.none,
              prefixIcon:
                  const Icon(Icons.lock_outline, color: AppColors.textLight),
              suffixIcon: IconButton(
                icon: Icon(
                  obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.textLight,
                ),
                onPressed: onToggle,
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}
