import 'package:flutter/material.dart';
import 'package:fantasy_crick/core/constants/app_constants.dart';

class RazorpayService {
  static final RazorpayService _instance = RazorpayService._internal();
  factory RazorpayService() => _instance;
  RazorpayService._internal();

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
  }

  void openPayment({
    required String name,
    required String description,
    required double amount,
    String? contact,
    String? email,
  }) {
    // Mock payment implementation for now
    debugPrint('Mock Payment: $name - $description - ₹$amount');
    
    // Simulate payment success after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      onPaymentSuccess?.call('mock_payment_id_${DateTime.now().millisecondsSinceEpoch}');
    });
  }

  void dispose() {
    // Cleanup if needed
  }
}
