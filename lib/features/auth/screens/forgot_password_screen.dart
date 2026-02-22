import 'package:flutter/material.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';
import 'package:fantasy_crick/common/widgets/custom_button.dart';
import 'package:fantasy_crick/common/widgets/custom_input.dart';
import 'package:fantasy_crick/common/widgets/beauty_dialog.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _loading = false;
  bool _otpSent = false;
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      await BeautyDialog.show(
        context,
        title: 'Email Required',
        message: 'Please enter your email address.',
        type: BeautyDialogType.warning,
      );
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      await BeautyDialog.show(
        context,
        title: 'Invalid Email',
        message: 'Please enter a valid email address.',
        type: BeautyDialogType.warning,
      );
      return;
    }

    setState(() => _loading = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _loading = false;
        _otpSent = true;
      });

      await BeautyDialog.show(
        context,
        title: 'OTP Sent',
        message: 'A verification code has been sent to $email',
        type: BeautyDialogType.success,
      );
    }
  }

  Future<void> _resetPassword() async {
    final otp = _otpController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (otp.isEmpty || otp.length < 4) {
      await BeautyDialog.show(
        context,
        title: 'Invalid OTP',
        message: 'Please enter the verification code sent to your email.',
        type: BeautyDialogType.warning,
      );
      return;
    }

    if (newPassword.isEmpty || newPassword.length < 6) {
      await BeautyDialog.show(
        context,
        title: 'Weak Password',
        message: 'Password must be at least 6 characters long.',
        type: BeautyDialogType.warning,
      );
      return;
    }

    if (newPassword != confirmPassword) {
      await BeautyDialog.show(
        context,
        title: 'Password Mismatch',
        message: 'The passwords you entered do not match.',
        type: BeautyDialogType.error,
      );
      return;
    }

    setState(() => _loading = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _loading = false);

      await BeautyDialog.show(
        context,
        title: 'Password Reset',
        message: 'Your password has been reset successfully. Please sign in with your new password.',
        type: BeautyDialogType.success,
        confirmText: 'Sign In',
        onConfirm: () {
          Navigator.pop(context);
        },
      );
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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
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
            color: AppColors.primary.withOpacity(0.1),
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
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _otpSent
              ? 'Enter the OTP and create a new password'
              : "Don't worry! Enter your email and we'll send you a reset link.",
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.textLight,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailSection() {
    return Column(
      children: [
        CustomInput(
          label: 'Email Address',
          placeholder: 'Enter your registered email',
          value: _emailController.text,
          onChanged: (value) => setState(() => _emailController.text = value),
          keyboardType: TextInputType.emailAddress,
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
            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildResetSection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.email, color: AppColors.success),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('OTP sent to', style: TextStyle(color: AppColors.textLight, fontSize: 12)),
                    Text(_emailController.text, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _otpSent = false),
                child: const Text('Change', style: TextStyle(color: AppColors.primary)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildOTPInput(),
        const SizedBox(height: 20),
        CustomInput(
          label: 'New Password',
          placeholder: 'Enter new password',
          value: _newPasswordController.text,
          onChanged: (value) => setState(() => _newPasswordController.text = value),
          secureTextEntry: true,
        ),
        CustomInput(
          label: 'Confirm Password',
          placeholder: 'Confirm new password',
          value: _confirmPasswordController.text,
          onChanged: (value) => setState(() => _confirmPasswordController.text = value),
          secureTextEntry: true,
        ),
        const SizedBox(height: 24),
        CustomButton(
          title: 'Reset Password',
          onTap: _resetPassword,
          loading: _loading,
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _sendOTP,
          child: const Text(
            "Didn't receive code? Resend",
            style: TextStyle(color: AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildOTPInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Verification Code',
          style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.text),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(6, (index) {
            return SizedBox(
              width: 45,
              height: 55,
              child: TextField(
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty && index < 5) {
                    FocusScope.of(context).nextFocus();
                  }
                  // Update the OTP controller
                  final currentOtp = _otpController.text.padRight(6, ' ').split('');
                  currentOtp[index] = value.isEmpty ? ' ' : value;
                  _otpController.text = currentOtp.join().trim();
                },
              ),
            );
          }),
        ),
      ],
    );
  }
}
