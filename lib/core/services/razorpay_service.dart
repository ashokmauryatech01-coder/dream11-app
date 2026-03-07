import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:fantasy_crick/core/constants/app_constants.dart';

class RazorpayService {
  static final RazorpayService _instance = RazorpayService._internal();
  factory RazorpayService() => _instance;
  RazorpayService._internal();

  late Razorpay _razorpay;
  Function(String)? onPaymentSuccess;
  Function(String)? onPaymentError;
  Function(String)? onPaymentExternalWallet;

  void initialize({
    Function(String)? onPaymentSuccess,
    Function(String)? onPaymentError,
    Function(String)? onPaymentExternalWallet,
  }) {
    this.onPaymentSuccess = onPaymentSuccess;
    this.onPaymentError = onPaymentError;
    this.onPaymentExternalWallet = onPaymentExternalWallet;

    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void openPayment({
    required String name,
    required String description,
    required double amount,
    String? contact,
    String? email,
  }) {
    final options = {
      'key': AppConstants.razorpayKeyId,
      'amount': (amount * 100).round(), // Convert to paise
      'name': name,
      'description': description,
      'timeout': 300, // 5 minutes
      'currency': AppConstants.currency,
      if (contact != null) 'contact': contact,
      if (email != null) 'email': email,
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error opening Razorpay: $e');
      onPaymentError?.call('Payment initialization failed: $e');
    }
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
    _razorpay.clear();
  }
}
