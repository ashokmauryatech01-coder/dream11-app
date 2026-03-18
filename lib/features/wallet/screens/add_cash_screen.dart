import 'package:flutter/material.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';
import 'package:fantasy_crick/core/services/razorpay_service.dart';
import 'package:fantasy_crick/core/services/profile_service.dart';
import 'package:fantasy_crick/core/services/wallet_service.dart';

class AddCashScreen extends StatefulWidget {
  const AddCashScreen({super.key});

  @override
  State<AddCashScreen> createState() => _AddCashScreenState();
}

class _AddCashScreenState extends State<AddCashScreen> {
  final RazorpayService _razorpayService = RazorpayService();
  final TextEditingController _amountController = TextEditingController();
  double _selectedAmount = 50.0;
  final List<double> _quickAmounts = [50, 100, 200, 500, 1000, 2000];
  bool _isProcessing = false;
  double _walletBalance = 0.0;
  bool _isLoadingBalance = true;
  int? _walletId;

  @override
  void initState() {
    super.initState();
    _amountController.text = _selectedAmount.toString();
    _initializeRazorpay();
    _loadWalletBalance();
  }

  Future<void> _loadWalletBalance() async {
    setState(() => _isLoadingBalance = true);
    try {
      final savedData = await ProfileService.getSavedUserData();
      final currentUserId = savedData['id'] ?? 0;
      
      final walletData = await WalletService.getWallets(currentUserId);
      if (walletData != null) {
        setState(() {
          _walletBalance = (walletData['balance'] ?? 0.0).toDouble();
          _walletId = walletData['id'] as int?;
        });
      }
    } catch (e) {
      print('Error loading wallet balance: $e');
    } finally {
      setState(() => _isLoadingBalance = false);
    }
  }

  void _initializeRazorpay() {
    _razorpayService.initialize(
      onPaymentSuccess: (paymentId) async {
        setState(() => _isProcessing = false);
        
        // Add funds to wallet after successful payment
        if (_walletId != null) {
          final savedData = await ProfileService.getSavedUserData();
          final currentUserId = savedData['id'] ?? 0;
          
          final result = await WalletService.addFunds(
            userId: currentUserId,
            walletId: _walletId!,
            amount: _selectedAmount,
            paymentId: paymentId,
            paymentMethod: 'razorpay',
          );
          
          if (result != null) {
            _showMessage('Payment Successful!', 'Payment ID: $paymentId\nFunds added to wallet', true);
            await _loadWalletBalance(); // Refresh balance
          } else {
            _showMessage('Payment Successful', 'Funds will be added shortly', true);
          }
        } else {
          _showMessage('Payment Successful!', 'Payment ID: $paymentId', true);
        }
      },
      onPaymentError: (error) {
        setState(() => _isProcessing = false);
        _showMessage('Payment Failed', error, false);
      },
      onPaymentExternalWallet: (walletName) {
        setState(() => _isProcessing = false);
        _showMessage('External Wallet', 'Selected wallet: $walletName', true);
      },
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _razorpayService.dispose();
    super.dispose();
  }

  void _makePayment(double amount) {
    if (amount < 50) {
      _showMessage('Invalid Amount', 'Minimum amount is ₹50', false);
      return;
    }

    setState(() => _isProcessing = true);

    _razorpayService.openPayment(
      name: 'Segga Sportzz - Add Cash',
      description: 'Add ₹${amount.toStringAsFixed(0)} to wallet',
      amount: amount,
      contact: '9999999999',
      email: 'user@example.com',
    );
  }

  void _showMessage(String title, String message, bool isSuccess) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        icon: Icon(
          isSuccess ? Icons.check_circle : Icons.error,
          color: isSuccess ? Colors.green : Colors.red,
        ),
        actions: [
          if (isSuccess) ...[
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to previous screen
              },
              child: const Text('Done'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog only
              },
              child: const Text('Add More'),
            ),
          ] else ...[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        title: const Text('Add Cash'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Wallet Balance Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Balance',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _isLoadingBalance
                      ? const SizedBox(
                          width: 60,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: AppColors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          '₹${_walletBalance.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Custom Amount Input
            const Text(
              'Enter Amount',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
                decoration: const InputDecoration(
                  hintText: '0',
                  hintStyle: TextStyle(color: AppColors.textLight),
                  prefixText: '₹',
                  prefixStyle: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 16),
                ),
                onChanged: (value) {
                  final amount = double.tryParse(value);
                  if (amount != null) {
                    setState(() {
                      _selectedAmount = amount;
                    });
                  }
                },
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Minimum amount: ₹50',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: 30),

            // Quick Amount Selection
            const Text(
              'Quick Add',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 2.5,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _quickAmounts.length,
              itemBuilder: (context, index) {
                final amount = _quickAmounts[index];
                final isSelected = _selectedAmount == amount;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedAmount = amount;
                      _amountController.text = amount.toString();
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '₹${amount.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? AppColors.white : AppColors.text,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 30),

            // Payment Methods
            const Text(
              'Payment Methods',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.payment,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Razorpay',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                        Text(
                          'Credit Card, Debit Card, UPI, Wallet',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Secure',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Add Cash Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : () => _makePayment(_selectedAmount),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isProcessing ? Colors.grey : AppColors.primary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: _isProcessing
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Processing...'),
                        ],
                      )
                    : Text(
                        'Add Cash ₹${_selectedAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
