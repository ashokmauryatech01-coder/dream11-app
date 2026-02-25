import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';
import 'package:fantasy_crick/common/widgets/custom_button.dart';
import 'package:fantasy_crick/features/home/screens/home_screen.dart';
import 'package:fantasy_crick/common/widgets/beauty_dialog.dart';
import 'package:fantasy_crick/core/services/auth_service.dart';

class OtpVerificationScreen extends StatefulWidget {
  /// Email or phone that the OTP was sent to (shown to the user)
  final String? sentTo;
  final bool isLogin;

  const OtpVerificationScreen({super.key, this.sentTo, this.isLogin = false});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _loading = false;
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    for (final c in _controllers) { c.dispose(); }
    for (final f in _focusNodes) { f.dispose(); }
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();

  void _onDigitChanged(String value, int index) {
    if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    } else {
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }
  }

  Future<void> _handleVerify() async {
    final otp = _otp;
    if (otp.length != 6) {
      await BeautyDialog.show(
        context,
        title: 'Invalid OTP',
        message: 'Please enter the 6-digit OTP sent to your account.',
        type: BeautyDialogType.warning,
      );
      return;
    }

    setState(() => _loading = true);

    try {
      if (widget.isLogin && widget.sentTo != null) {
        await _authService.verifyOTPLogin(widget.sentTo!, otp);
      } else {
        await _authService.verifyRegistrationOtp(widget.sentTo ?? '', otp);
      }

      if (!mounted) return;
      setState(() => _loading = false);

      await BeautyDialog.show(
        context,
        title: widget.isLogin ? 'Login Verified! 🎉' : 'Verified! 🎉',
        message: widget.isLogin ? "You're successfully logged in." : 'Your account has been verified successfully.',
        type: BeautyDialogType.success,
        confirmText: 'Go to Home',
        onConfirm: () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      final msg = e.toString().replaceFirst('Exception: ', '');
      await BeautyDialog.show(
        context,
        title: 'Verification Failed',
        message: msg,
        type: BeautyDialogType.error,
      );
    }
  }

  Future<void> _handleResend() async {
    // Clear all OTP boxes
    for (final c in _controllers) { c.clear(); }
    _focusNodes[0].requestFocus();

    try {
      if (widget.sentTo != null) {
        await _authService.resendOTP(widget.sentTo!);
      }
      
      if (!mounted) return;
      await BeautyDialog.show(
        context,
        title: 'OTP Resent',
        message:
            'A new OTP has been sent to ${widget.sentTo ?? 'your registered contact'}.',
        type: BeautyDialogType.info,
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      await BeautyDialog.show(
        context,
        title: 'Resend Failed',
        message: msg,
        type: BeautyDialogType.error,
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Icon
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_user_outlined,
                  size: 48,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Verify OTP',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                widget.sentTo != null
                    ? "We've sent a 6-digit code to\n${widget.sentTo}"
                    : "We've sent a 6-digit code to your registered contact",
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textLight,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // OTP digit boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 46,
                    height: 56,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      onChanged: (value) => _onDigitChanged(value, index),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 2),
                        ),
                        filled: true,
                        fillColor: AppColors.white,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 40),

              CustomButton(
                title: 'Verify OTP',
                onTap: _handleVerify,
                loading: _loading,
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Didn't receive the code? ",
                    style: TextStyle(color: AppColors.textLight),
                  ),
                  GestureDetector(
                    onTap: _handleResend,
                    child: const Text(
                      'Resend OTP',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
