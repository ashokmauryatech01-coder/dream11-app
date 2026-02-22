import 'package:flutter/material.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';
import 'package:fantasy_crick/common/widgets/custom_button.dart';
import 'package:fantasy_crick/common/widgets/custom_input.dart';
import 'package:fantasy_crick/core/services/auth_service.dart';
import 'package:fantasy_crick/features/auth/screens/signup_screen.dart';
import 'package:fantasy_crick/features/auth/screens/forgot_password_screen.dart';
import 'package:fantasy_crick/features/home/screens/home_screen.dart';
import 'package:fantasy_crick/common/widgets/beauty_dialog.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;
  final AuthService _authService = AuthService();

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

    setState(() {
      _loading = true;
    });

    try {
      await _authService.login(email, password);
      
      if (!mounted) return;
      
      await BeautyDialog.show(
        context,
        title: 'Welcome Back!',
        message: 'Login successful. Let’s get you to the app.',
        type: BeautyDialogType.success,
        confirmText: 'Continue',
        onConfirm: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      await BeautyDialog.show(
        context,
        title: 'Login Failed',
        message: e.toString(),
        type: BeautyDialogType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              const Text(
                'Welcome Back!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sign in to continue',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textLight,
                ),
              ),
              const SizedBox(height: 40),
              
              CustomInput(
                label: 'Email',
                placeholder: 'Enter your email',
                value: _emailController.text,
                onChanged: (value) => _emailController.text = value, // Note: In real app use controller directly
                keyboardType: TextInputType.emailAddress,
              ),
              
              CustomInput(
                label: 'Password',
                placeholder: 'Enter your password',
                value: _passwordController.text,
                onChanged: (value) => _passwordController.text = value,
                secureTextEntry: true,
              ),
              
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
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              CustomButton(
                title: 'Sign In',
                onTap: _handleSignIn,
                loading: _loading,
              ),
              
              const SizedBox(height: 20),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account? ",
                    style: TextStyle(color: AppColors.textLight),
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
