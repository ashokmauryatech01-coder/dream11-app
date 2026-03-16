import 'package:flutter/material.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';
import 'package:fantasy_crick/features/auth/screens/otp_verification_screen.dart';
import 'package:fantasy_crick/features/auth/screens/signin_screen.dart';
import 'package:fantasy_crick/features/auth/screens/signup_screen.dart';
import 'package:fantasy_crick/features/home/screens/home_screen.dart';
import 'package:fantasy_crick/features/live/screens/live_matches_screen.dart';
import 'package:fantasy_crick/features/profile/screens/privacy_policy_screen.dart';
import 'package:fantasy_crick/features/splash/screens/splash_screen.dart';
import 'package:fantasy_crick/features/wallet/screens/wallet_screen.dart';

class ScreenNavigator extends StatelessWidget {
  const ScreenNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = _categories(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'FantasyCrick - All Screens',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return _CategorySection(category: category);
        },
      ),
    );
  }

  List<_Category> _categories(BuildContext context) {
    final allScreens = <_ScreenItem>[
      _ScreenItem('SplashScreen', 'Splash Screen', const SplashScreen()),
      _ScreenItem('SignInScreen', 'Sign In Screen', const SignInScreen()),
      _ScreenItem('SignUpScreen', 'Sign Up Screen', const SignUpScreen()),
      _ScreenItem(
        'OTPVerificationScreen',
        'OTP Verification Screen',
        const OtpVerificationScreen(),
      ),
      _ScreenItem('HomeScreen', 'Home Screen', const HomeScreen()),
      _ScreenItem(
        'LiveMatchesScreen',
        'Live Matches Screen',
        const LiveMatchesScreen(),
      ),
      _ScreenItem('WalletScreen', 'Wallet Screen', const WalletScreen()),
      _ScreenItem(
        'PrivacyPolicyScreen',
        'Privacy Policy Screen',
        const PrivacyPolicyScreen(),
      ),
    ];

    return [
      _Category('Authentication Screens', allScreens.sublist(0, 4)),
      _Category('Core App Screens', allScreens.sublist(4, 5)),
      _Category('Match Screens', allScreens.sublist(5, 6)),
      _Category('Profile & Utility Screens', allScreens.sublist(6)),
    ];
  }
}

class _CategorySection extends StatelessWidget {
  final _Category category;

  const _CategorySection({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.only(bottom: 6),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
            child: Text(
              category.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
          ),
          const SizedBox(height: 10),
          ...category.screens.map((screen) {
            return InkWell(
              onTap: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => screen.widget));
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        screen.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                    Text(
                      screen.name,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textLight,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _Category {
  final String title;
  final List<_ScreenItem> screens;

  const _Category(this.title, this.screens);
}

class _ScreenItem {
  final String name;
  final String title;
  final Widget widget;

  const _ScreenItem(this.name, this.title, this.widget);
}
