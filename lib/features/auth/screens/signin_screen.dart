import 'package:flutter/material.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';
import 'package:fantasy_crick/core/services/auth_service.dart';
import 'package:fantasy_crick/common/widgets/beauty_dialog.dart';
import 'package:fantasy_crick/core/services/location_service.dart';
import 'package:fantasy_crick/features/auth/screens/signup_screen.dart';
import 'package:fantasy_crick/features/home/screens/home_screen.dart';
import 'package:fantasy_crick/features/auth/screens/forgot_password_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  String _userIp = '';
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
        _userIp = data['ip'] ?? '';
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      await BeautyDialog.show(
        context,
        title: 'Missing Details',
        message: 'Please fill all fields to continue.',
        type: BeautyDialogType.warning,
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await _authService.login(email, password, ip: _userIp);

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      await BeautyDialog.show(
        context,
        title: 'Login Failed',
        message: msg,
        type: BeautyDialogType.error,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: SizedBox.expand(
              child: Image.asset(
                'assets/images/cricket_login_bg.png',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
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
                  
                  const SizedBox(height: 60),
                  
                  // Bottom Card
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Welcome back!',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Sign in to your account',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textLight,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
  
                          // Form Fields
                          _buildInputField(
                            controller: _emailController,
                            hint: 'Email Address',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
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
  
                          // Forgot Password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                                );
                              },
                              child: const Text(
                                'Forgot Password?',
                                style: TextStyle(color: Color(0xFF1976D2), fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ),
  
                          const SizedBox(height: 16),
  
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _handleSignIn,
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
                                    'Sign In',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                            ),
                          ),
  
                          const SizedBox(height: 24),
  
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Don't have an account? ",
                                style: TextStyle(color: AppColors.textLight, fontSize: 13),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const SignUpScreen()),
                                  );
                                },
                                child: const Text(
                                  'Sign Up',
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

