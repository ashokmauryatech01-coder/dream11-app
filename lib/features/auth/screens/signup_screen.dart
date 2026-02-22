import 'package:flutter/material.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';
import 'package:fantasy_crick/common/widgets/custom_button.dart';
import 'package:fantasy_crick/common/widgets/custom_input.dart';
import 'package:fantasy_crick/core/services/auth_service.dart';
import 'package:fantasy_crick/features/auth/screens/signin_screen.dart';
import 'package:fantasy_crick/features/auth/screens/otp_verification_screen.dart';
import 'package:fantasy_crick/common/widgets/beauty_dialog.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // Using simplified state management for inputs for now, normally use controllers
  String _name = '';
  String _email = '';
  String _phone = '';
  String _password = '';
  String _confirmPassword = '';
  
  bool _loading = false;
  final AuthService _authService = AuthService();

  Future<void> _handleSignUp() async {
    if (_name.isEmpty || _email.isEmpty || _phone.isEmpty || _password.isEmpty || _confirmPassword.isEmpty) {
      await BeautyDialog.show(
        context,
        title: 'Incomplete Details',
        message: 'Please fill all fields to create your account.',
        type: BeautyDialogType.warning,
      );
      return;
    }

    if (_password != _confirmPassword) {
      await BeautyDialog.show(
        context,
        title: 'Password Mismatch',
        message: 'The passwords you entered do not match.',
        type: BeautyDialogType.error,
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      await _authService.signUp(_name, _email, _phone, _password);
      
      if (!mounted) return;
      
      // Navigate to OTP or directly to Home/SignIn
      await BeautyDialog.show(
        context,
        title: 'Account Created',
        message: 'Your account is ready. Please verify your OTP.',
        type: BeautyDialogType.success,
        confirmText: 'Verify OTP',
        onConfirm: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const OtpVerificationScreen()),
          );
        },
      );
      
    } catch (e) {
      if (!mounted) return;
      await BeautyDialog.show(
        context,
        title: 'Sign Up Failed',
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
              const SizedBox(height: 40),
              const Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Join the fantasy cricket world',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textLight,
                ),
              ),
              const SizedBox(height: 30),
              
              CustomInput(
                label: 'Full Name',
                placeholder: 'Enter your full name',
                value: _name,
                onChanged: (v) => setState(() => _name = v),
              ),
              
              CustomInput(
                label: 'Email',
                placeholder: 'Enter your email',
                value: _email,
                onChanged: (v) => setState(() => _email = v),
                keyboardType: TextInputType.emailAddress,
              ),
              
              CustomInput(
                label: 'Phone Number',
                placeholder: 'Enter your phone number',
                value: _phone,
                onChanged: (v) => setState(() => _phone = v),
                keyboardType: TextInputType.phone,
              ),
              
              CustomInput(
                label: 'Password',
                placeholder: 'Enter your password',
                value: _password,
                onChanged: (v) => setState(() => _password = v),
                secureTextEntry: true,
              ),
              
              CustomInput(
                label: 'Confirm Password',
                placeholder: 'Confirm your password',
                value: _confirmPassword,
                onChanged: (v) => setState(() => _confirmPassword = v),
                secureTextEntry: true,
              ),
              
              const SizedBox(height: 20),
              
              CustomButton(
                title: 'Sign Up',
                onTap: _handleSignUp,
                loading: _loading,
              ),
              
              const SizedBox(height: 20),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Already have an account? ",
                    style: TextStyle(color: AppColors.textLight),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const SignInScreen()),
                      );
                    },
                    child: const Text(
                      'Sign In',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
