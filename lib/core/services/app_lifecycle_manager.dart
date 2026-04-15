import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'auth_manager.dart';

class AppLifecycleManager extends WidgetsBindingObserver {
  static final AppLifecycleManager _instance = AppLifecycleManager._internal();
  factory AppLifecycleManager() => _instance;
  AppLifecycleManager._internal();

  bool _isInitialized = false;
  DateTime? _lastValidationTime;

  void initialize() {
    if (!_isInitialized) {
      // Defer initialization to next microtask to ensure binding is ready
      // This is especially important for web platform
      Future.microtask(() {
        try {
          WidgetsBinding.instance.addObserver(this);
          _isInitialized = true;
          print('DEBUG: AppLifecycleManager initialized successfully');
        } catch (e) {
          print('DEBUG: AppLifecycleManager initialization failed: $e');
          // Will retry on next app lifecycle event
        }
      });
    }
  }

  void dispose() {
    if (_isInitialized) {
      try {
        WidgetsBinding.instance.removeObserver(this);
      } catch (e) {
        print('DEBUG: AppLifecycleManager dispose failed: $e');
      }
      _isInitialized = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        // App came to foreground, validate token (but not too frequently)
        // Skip on web platform as lifecycle events work differently
        if (!kIsWeb) {
          _validateTokenOnResume();
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // App went to background or is being closed
        break;
    }
  }

  Future<void> _validateTokenOnResume() async {
    try {
      // Throttle validation - only validate once per 5 minutes max
      // This is just for logging/debugging, no actual logout happens here
      final now = DateTime.now();
      if (_lastValidationTime != null) {
        final timeSinceLastValidation = now.difference(_lastValidationTime!);
        if (timeSinceLastValidation < const Duration(minutes: 5)) {
          print('DEBUG: AppLifecycleManager - Skipping validation, last check was ${timeSinceLastValidation.inSeconds}s ago');
          return;
        }
      }
      
      // Add a small delay to ensure the app is fully resumed
      await Future.delayed(const Duration(milliseconds: 500));
      
      // This is now completely passive - only logs, never logs out
      await AuthManager.validateTokenPeriodically();
      _lastValidationTime = now;
    } catch (e) {
      print('DEBUG: AppLifecycleManager - Error in validation: $e');
    }
  }
}
