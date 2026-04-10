import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';
import 'package:fantasy_crick/common/widgets/beauty_dialog.dart';
import 'package:fantasy_crick/core/services/auth_service.dart';
import 'package:fantasy_crick/features/auth/screens/signin_screen.dart';
import 'dart:async';

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

  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
      List.generate(6, (_) => FocusNode());

  bool _loading = false;
  bool _otpSent = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  final AuthService _authService = AuthService();
  
  Timer? _resendTimer;
  int _secondsRemaining = 60;
  bool _canResend = false;

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() {
      _secondsRemaining = 60;
      _canResend = false;
    });
    
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _canResend = true;
          _resendTimer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    for (final c in _otpControllers) { c.dispose(); }
    for (final f in _otpFocusNodes) { f.dispose(); }
    _resendTimer?.cancel();
    super.dispose();
  }

  String get _otp =>
      _otpControllers.map((c) => c.text).join();

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
      
      _startResendTimer();

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
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/cricket_login_bg.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          
          // Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ),

          Positioned.fill(
            child: SafeArea(
              child: Column(
                children: [
                  // Logo Area
                  const SizedBox(height: 48),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/segga_logo.png',
                              height: 40,
                              width: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.sports_cricket, color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Flexible(
                          child: Text(
                            'SEGGA SPORTZ',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const Spacer(flex: 2),
                  
                  // Bottom Card
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _otpSent ? 'Reset Password' : 'Forgot Password?',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _otpSent
                                ? 'Enter the OTP and create a new password'
                                : "No worries! Enter your email and we'll send you a reset code.",
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textLight,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
  
                          if (!_otpSent) ...[
                            _buildInputField(
                              controller: _emailController,
                              hint: 'Email Address',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _sendOTP,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF00C853),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: _loading 
                                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Text(
                                      'Send Reset Code',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                              ),
                            ),
                          ] else ...[
                            _buildOtpSection(),
                            const SizedBox(height: 16),
                            _buildInputField(
                              controller: _newPasswordController,
                              hint: 'New Password',
                              icon: Icons.lock_outline,
                              obscure: _obscureNew,
                              isPassword: true,
                              toggleObscure: () => setState(() => _obscureNew = !_obscureNew),
                            ),
                            const SizedBox(height: 16),
                            _buildInputField(
                              controller: _confirmPasswordController,
                              hint: 'Confirm Password',
                              icon: Icons.lock_outline,
                              obscure: _obscureConfirm,
                              isPassword: true,
                              toggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm),
                            ),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _resetPassword,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF00C853),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: _loading 
                                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Text(
                                      'Reset Password',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            TextButton(
                              onPressed: _canResend ? _sendOTP : null,
                              child: Text(
                                _canResend ? "Didn't receive code? Resend" : "Resend in ${_secondsRemaining}s",
                                style: TextStyle(
                                  color: _canResend ? const Color(0xFF1976D2) : AppColors.textLight.withOpacity(0.5),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
  
                          const SizedBox(height: 16),
                          
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'Back to Sign In',
                              style: TextStyle(color: Color(0xFF1976D2), fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          Positioned(
            top: 40,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Verification Code',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.text),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) {
            return SizedBox(
              width: 44,
              height: 54,
              child: TextField(
                controller: _otpControllers[index],
                focusNode: _otpFocusNodes[index],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: const Color(0xFFF7FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF00C853), width: 2),
                  ),
                  contentPadding: EdgeInsets.zero,
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
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    bool isPassword = false,
    VoidCallback? toggleObscure,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F9FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFB3E5FC)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Icon(icon, color: AppColors.textLight, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              obscureText: obscure,
              style: const TextStyle(fontSize: 16, color: AppColors.text, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Color(0xFFA0AEC0)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          if (isPassword)
            IconButton(
              onPressed: toggleObscure,
              icon: Icon(
                obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppColors.textLight,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }
}
