import 'package:flutter/material.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';
import 'package:fantasy_crick/features/splash/screens/splash_screen.dart';
import 'package:fantasy_crick/features/auth/screens/signin_screen.dart';
import 'package:fantasy_crick/features/home/screens/home_screen.dart';
import 'package:fantasy_crick/features/profile/screens/es_how_to_play_screen.dart';
import 'package:fantasy_crick/features/wallet/screens/add_cash_screen.dart';
import 'package:fantasy_crick/features/profile/screens/user_profile_screen.dart';
import 'package:fantasy_crick/features/wallet/screens/wallet_transaction_screen.dart';
import 'package:fantasy_crick/features/wallet/screens/withdrawal_screen.dart';
import 'package:fantasy_crick/features/profile/screens/privacy_policy_screen.dart';
import 'package:fantasy_crick/features/contest/screens/es_teams_list_screen.dart';
import 'package:fantasy_crick/core/services/app_lifecycle_manager.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  // Ensure Flutter binding is initialized first
  WidgetsFlutterBinding.ensureInitialized();
  
  // Add error handling for Flutter web
  FlutterError.onError = (FlutterErrorDetails details) {
    print('Flutter Error: ${details.exception}');
    print('Stack: ${details.stack}');
  };
  
  // Initialize lifecycle manager for automatic token validation
  AppLifecycleManager().initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Set error widget builder
    ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
      return Container(
        color: Colors.white,
        child: Center(
          child: Text(
            'Error occurred. Please restart the app.',
            style: TextStyle(color: Colors.red),
          ),
        ),
      );
    };

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Segga Sportzz',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      routes: {
        '/signin': (context) => const SignInScreen(),
        '/home': (context) => const HomeScreen(),
        '/how-to-play': (context) => const EsHowToPlayScreen(),
        '/add-cash': (context) => const AddCashScreen(),
        '/user-profile': (context) => const UserProfileScreen(),
        '/wallet-transactions': (context) => const WalletTransactionScreen(),
        '/withdrawal': (context) => const WithdrawalScreen(),
        '/privacy-policy': (context) => PrivacyPolicyScreen(),
        '/teams': (context) => const EsTeamsListScreen(),
      },
    );
  }
}
