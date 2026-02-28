import 'package:flutter/material.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';
import 'package:fantasy_crick/common/widgets/custom_button.dart';
import 'package:fantasy_crick/core/services/auth_service.dart';
import 'package:fantasy_crick/features/auth/screens/otp_verification_screen.dart';
import 'package:fantasy_crick/common/widgets/beauty_dialog.dart';
import 'package:fantasy_crick/core/services/location_service.dart';

class MobileLoginScreen extends StatefulWidget {
  const MobileLoginScreen({super.key});

  @override
  State<MobileLoginScreen> createState() => _MobileLoginScreenState();
}

class _MobileLoginScreenState extends State<MobileLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _loading = false;
  String _countryCode = '+91';
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    final data = await LocationService.getLocationData();
    if (mounted) {
      setState(() {
        _countryCode = data['country_calling_code'] ?? '+91';
      });
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOTP() async {
    final phone = _phoneController.text.trim();

    if (phone.isEmpty) {
      await BeautyDialog.show(context,
          title: 'Enter Phone Number',
          message: 'Please provide your mobile number to receive an OTP.',
          type: BeautyDialogType.warning);
      return;
    }

    setState(() => _loading = true);

    try {
      final fullPhone = '$_countryCode$phone';
      await _authService.sendOTP(fullPhone);

      if (!mounted) return;
      setState(() => _loading = false);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(sentTo: fullPhone),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      final msg = e.toString().replaceFirst('Exception: ', '');
      await BeautyDialog.show(context,
          title: 'OTP Failed',
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.phone_android_rounded, size: 48, color: AppColors.primary),
              ),
              const SizedBox(height: 24),
              const Text('Login with Mobile',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.text)),
              const SizedBox(height: 8),
              const Text('We will send a 4-digit OTP to verify',
                style: TextStyle(fontSize: 16, color: AppColors.textLight)),
              const SizedBox(height: 48),
              
              _buildPhoneField(),
              
              const SizedBox(height: 32),
              CustomButton(
                title: 'Continue',
                onTap: _handleSendOTP,
                loading: _loading,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Phone Number',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text)),
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
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(_countryCode,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.text)),
              ),
              Container(width: 1, height: 24, color: AppColors.border),
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(fontSize: 16, color: AppColors.text),
                  decoration: const InputDecoration(
                    hintText: '000 000 0000',
                    hintStyle: TextStyle(color: AppColors.textLight),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
