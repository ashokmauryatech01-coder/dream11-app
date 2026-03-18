import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:fantasy_crick/core/constants/app_constants.dart';

class RazorpayService {
  static final RazorpayService _instance = RazorpayService._internal();
  factory RazorpayService() => _instance;
  RazorpayService._internal();

  Razorpay? _razorpay;
  Function(String)? onPaymentSuccess;
  Function(String)? onPaymentError;
  Function(String)? onPaymentExternalWallet;
  bool _isWeb = kIsWeb;

  void initialize({
    Function(String)? onPaymentSuccess,
    Function(String)? onPaymentError,
    Function(String)? onPaymentExternalWallet,
  }) {
    this.onPaymentSuccess = onPaymentSuccess;
    this.onPaymentError = onPaymentError;
    this.onPaymentExternalWallet = onPaymentExternalWallet;

    if (!_isWeb) {
      try {
        _razorpay = Razorpay();
        _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
        _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
        _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
      } catch (e) {
        print('Error initializing Razorpay: $e');
      }
    }
  }

  void openPayment({
    required String name,
    required String description,
    required double amount,
    String? contact,
    String? email,
  }) {
    if (_isWeb) {
      // Web fallback - show payment dialog
      _showWebPaymentDialog(amount, description);
      return;
    }

    if (_razorpay == null) {
      onPaymentError?.call('Razorpay not initialized');
      return;
    }

    final options = {
      'key': AppConstants.razorpayKeyId,
      'amount': (amount * 100).toInt(), // Convert to paise
      'name': name,
      'description': description,
      'prefill': {
        'contact': contact ?? '9999999999',
        'email': email ?? 'test@example.com',
      },
      'theme': {
        'color': '#CE404D',
      },
    };

    try {
      _razorpay!.open(options);
    } catch (e) {
      print('Error opening Razorpay: $e');
      onPaymentError?.call('Failed to open payment: $e');
    }
  }

  void _showWebPaymentDialog(double amount, String description) {
    // For web, simulate payment success after 2 seconds
    onPaymentSuccess?.call('web_payment_${DateTime.now().millisecondsSinceEpoch}');
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    debugPrint('Payment Success: ${response.paymentId}');
    onPaymentSuccess?.call(response.paymentId ?? '');
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('Payment Error: ${response.code} - ${response.message}');
    onPaymentError?.call('${response.code}: ${response.message}');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('External Wallet: ${response.walletName}');
    onPaymentExternalWallet?.call(response.walletName ?? '');
  }

  void dispose() {
    if (!_isWeb && _razorpay != null) {
      try {
        _razorpay!.clear();
      } catch (e) {
        print('Error disposing Razorpay: $e');
      }
    }
  }
}
