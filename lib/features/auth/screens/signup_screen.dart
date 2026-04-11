import 'package:flutter/material.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';
import 'package:fantasy_crick/core/services/auth_service.dart';
import 'package:fantasy_crick/common/widgets/beauty_dialog.dart';
import 'package:fantasy_crick/core/services/location_service.dart';
import 'package:fantasy_crick/features/auth/screens/otp_verification_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _upiController = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String _countryCode = '+91';

  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final upiId = _upiController.text.trim();

    if (name.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        upiId.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      await BeautyDialog.show(context,
          title: 'Incomplete Details',
          message: 'Please fill all fields, including UPI ID, to create your account.',
          type: BeautyDialogType.warning);
      return;
    }

    if (password != confirmPassword) {
      await BeautyDialog.show(context,
          title: 'Password Mismatch',
          message: 'The passwords you entered do not match.',
          type: BeautyDialogType.error);
      return;
    }

    if (password.length < 6) {
      await BeautyDialog.show(context,
          title: 'Weak Password',
          message: 'Password must be at least 6 characters.',
          type: BeautyDialogType.warning);
      return;
    }

    setState(() => _loading = true);
    
    final fullPhone = '$_countryCode$phone';

    try {
      await _authService.signUp(
        name, 
        email, 
        fullPhone, 
        password, 
        upiId: upiId,
        userType: 'user',
      );

      await _authService.sendOTP(fullPhone);

      setState(() => _loading = false);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpVerificationScreen(
            sentTo: fullPhone,
            isLogin: false,
            registrationData: {
              'phone': fullPhone,
              'user_type': 'user',
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      final msg = e.toString().replaceFirst('Exception: ', '');
      await BeautyDialog.show(context,
          title: 'Registration Failed',
          message: msg,
          type: BeautyDialogType.error);
    }
  }

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
                  
                  const SizedBox(height: 20),
                  
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
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            const Text(
                              'Create Account',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.text,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Register to start your fantasy journey',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textLight,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
  
                            // Form Fields
                            _buildInputField(
                              controller: _nameController,
                              hint: 'Full Name',
                              icon: Icons.person_outline,
                            ),
                            const SizedBox(height: 16),
                            _buildInputField(
                              controller: _emailController,
                              hint: 'Email Address',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 16),
                            _buildInputField(
                              controller: _upiController,
                              hint: 'UPI ID (Optional)',
                              icon: Icons.payments_outlined,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F9FF),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFB3E5FC)),
                                  ),
                                  child: Text(
                                    _countryCode,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textLight),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildInputField(
                                    controller: _phoneController,
                                    hint: 'Phone Number',
                                    icon: Icons.phone_android_outlined,
                                    keyboardType: TextInputType.phone,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildInputField(
                              controller: _passwordController,
                              hint: 'Password',
                              icon: Icons.lock_outline,
                              obscure: _obscurePassword,
                              isPassword: true,
                              toggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            const SizedBox(height: 16),
                            _buildInputField(
                              controller: _confirmPasswordController,
                              hint: 'Confirm Password',
                              icon: Icons.lock_reset_outlined,
                              obscure: _obscureConfirm,
                              isPassword: true,
                              toggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm),
                            ),
  
                            const SizedBox(height: 32),
  
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _handleSignUp,
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
                                      'Complete Register',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                              ),
                            ),
  
                            const SizedBox(height: 24),
  
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Already have an account? ",
                                  style: TextStyle(color: AppColors.textLight, fontSize: 13),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: const Text(
                                    'Sign In',
                                    style: TextStyle(
                                      color: Color(0xFF1976D2),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
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
