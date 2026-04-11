import 'package:flutter/material.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';
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
  bool _isAgeConfirmed = false;
  bool _getUpdates = true;
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
    if (!_isAgeConfirmed) {
      await BeautyDialog.show(context,
          title: 'Age Confirmation Required',
          message: 'Please confirm that you are 18+ years of age to continue.',
          type: BeautyDialogType.warning);
      return;
    }

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
          builder: (_) => OtpVerificationScreen(
            sentTo: fullPhone,
            isLogin: true,
          ),
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
          
          // Gradient Overlay to make text readable
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
                      mainAxisSize: MainAxisSize.min, // Fix overflow by taking only needed space
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
                              height: 40, // Slightly smaller to be safe
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
                              fontSize: 24, // Slightly smaller to avoid overflow
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
                  
                  const SizedBox(height: 60),
                  
                  // Bottom Input Card
                  Expanded(
                    child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'Login / Register',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildPhoneField(),
                        const SizedBox(height: 16),
                        
                        // Age Confirmation
                        GestureDetector(
                          onTap: () => setState(() => _isAgeConfirmed = !_isAgeConfirmed),
                          child: Row(
                            children: [
                              Checkbox(
                                value: _isAgeConfirmed,
                                onChanged: (v) => setState(() => _isAgeConfirmed = v ?? false),
                                activeColor: AppColors.success,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              ),
                              const Expanded(
                                child: Text(
                                  'I confirm that I am 18+ years in age',
                                  style: TextStyle(color: AppColors.textLight, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _handleSendOTP,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00C853),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            child: _loading 
                              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Continue'),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Additional Options
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Get updates on WhatsApp/RCS',
                                  style: TextStyle(fontSize: 12, color: AppColors.textLight),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  height: 24,
                                  width: 40,
                                  child: Switch(
                                    value: _getUpdates,
                                    onChanged: (v) => setState(() => _getUpdates = v),
                                    activeColor: AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () {},
                              child: const Text(
                                'Got invite code?',
                                style: TextStyle(
                                  color: Color(0xFF1976D2),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Footer Links
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                            children: [
                              const TextSpan(text: 'By continuing, you accept '),
                              TextSpan(
                                text: 'terms of service',
                                style: TextStyle(color: Colors.grey.shade600, decoration: TextDecoration.underline),
                              ),
                              const TextSpan(text: ' and '),
                              TextSpan(
                                text: 'privacy policy',
                                style: TextStyle(color: Colors.grey.shade600, decoration: TextDecoration.underline),
                              ),
                              const TextSpan(text: '.'),
                            ],
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
          
          // Back Button
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

  Widget _buildPhoneField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F9FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFB3E5FC)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          const Icon(Icons.phone_outlined, color: AppColors.textLight, size: 20),
          const SizedBox(width: 12),
          Text(
            _countryCode,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(fontSize: 16, color: AppColors.text, fontWeight: FontWeight.w500),
              decoration: const InputDecoration(
                hintText: 'Mobile Number',
                hintStyle: TextStyle(color: Color(0xFFA0AEC0)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

