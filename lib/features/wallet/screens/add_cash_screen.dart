import 'package:flutter/material.dart';
import 'package:fantasy_crick/common/widgets/beauty_dialog.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';
import 'package:fantasy_crick/core/services/razorpay_service.dart';
import 'package:fantasy_crick/core/services/profile_service.dart';
import 'package:fantasy_crick/core/services/wallet_service.dart';
import 'package:fantasy_crick/common/widgets/winning_celebration_animation.dart';

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
  bool _showCelebration = false;
  double _lastAddedAmount = 0.0;
  String _userName = 'User';

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
      final localBalance = await WalletService.getLocalBalance();
      setState(() {
        _walletBalance = localBalance;
      });

      final savedData = await ProfileService.getSavedUserData();
      final currentUserId = savedData['id'] ?? 0;
      _userName = savedData['name'] ?? 'User';

      final walletData = await WalletService.getWallets(currentUserId);
      if (walletData != null) {
        setState(() {
          _walletBalance = (walletData['balance'] ?? localBalance).toDouble();
          _walletId = walletData['id'] as int?;
        });
        await WalletService.saveWalletDataLocally(walletData);
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
             _handleSuccess(_selectedAmount);
            await _loadWalletBalance();
          } else {
            _showMessage(
              'Payment Successful',
              'Funds will be added shortly',
              true,
            );
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

  void _handleSuccess(double amount) {
    setState(() {
      _showCelebration = true;
      _lastAddedAmount = amount;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showCelebration = false);
        _showMessage(
          'Success',
          '₹${amount.toStringAsFixed(0)} added to your wallet!',
          true,
        );
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _razorpayService.dispose();
    super.dispose();
  }

  void _makePayment(double amount) async {
    if (amount < 50) {
      _showMessage('Invalid Amount', 'Minimum amount is ₹50', false);
      return;
    }
    _showCardDialog(amount);
  }

  void _showCardDialog(double amount) {
    final TextEditingController cardController = TextEditingController();
    final TextEditingController expiryController = TextEditingController();
    final TextEditingController cvvController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          bool isFormValid = cardController.text.length >= 16 &&
              expiryController.text.length >= 4 &&
              cvvController.text.length >= 3;

          void updateState() {
            setDialogState(() {
              isFormValid = cardController.text.replaceAll(' ', '').length >= 16 &&
                  expiryController.text.replaceAll('/', '').replaceAll(' ', '').length >= 4 &&
                  cvvController.text.length >= 3;
            });
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Enter Card Details'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   _buildCardField(
                    label: 'Card Number',
                    hint: 'XXXX XXXX XXXX XXXX',
                    icon: Icons.credit_card,
                    controller: cardController,
                    onChanged: (v) => updateState(),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child:  _buildCardField(
                          label: 'Expiry Date',
                          hint: 'MM / YY',
                          controller: expiryController,
                          onChanged: (v) => updateState(),
                          keyboardType: TextInputType.datetime,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child:  _buildCardField(
                          label: 'CVV',
                          hint: 'XXX',
                          obscure: true,
                          controller: cvvController,
                          onChanged: (v) => updateState(),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: isFormValid
                    ? () {
                        Navigator.pop(context);
                        _processPayment(amount);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFormValid ? AppColors.primary : Colors.grey.shade300,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade500,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('Pay ₹${amount.toStringAsFixed(0)}'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _processPayment(double amount) async {
    setState(() => _isProcessing = true);

    await Future.delayed(const Duration(seconds: 2));

    final newBalance = await WalletService.updateLocalBalance(amount);

    setState(() {
      _isProcessing = false;
      _walletBalance = newBalance;
    });

    _handleSuccess(amount);
  }

  void _showMessage(String title, String message, bool isSuccess) {
    BeautyDialog.show(
      context,
      title: title,
      message: message,
      type: isSuccess ? BeautyDialogType.success : BeautyDialogType.error,
      onConfirm: () {
        if (isSuccess) {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.white,
            foregroundColor: AppColors.text,
            elevation: 0,
            centerTitle: true,
            title: const Text(
              'ADD CASH',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 2,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              children: [
                // Premium Balance Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withRed(220),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.35),
                        blurRadius: 25,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -20,
                        top: -20,
                        child: Icon(
                          Icons.account_balance_wallet_rounded,
                          size: 100,
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.account_balance_wallet_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Current Balance',
                                style: TextStyle(
                                  color: AppColors.white.withOpacity(0.9),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _isLoadingBalance
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : Text(
                                  '₹${_walletBalance.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    color: AppColors.white,
                                    fontSize: 38,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Input Area
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Enter Amount',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textLight,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                        decoration: InputDecoration(
                          prefixText: '₹ ',
                          prefixStyle: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 24,
                              fontWeight: FontWeight.bold),
                          enabledBorder: UnderlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.grey.shade200)),
                          focusedBorder: const UnderlineInputBorder(
                              borderSide:
                                  BorderSide(color: AppColors.primary)),
                        ),
                        onChanged: (v) {
                          final amount = double.tryParse(v);
                          if (amount != null)
                            setState(() => _selectedAmount = amount);
                        },
                      ),
                      const SizedBox(height: 24),

                      // Quick Amounts
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _quickAmounts.map((amt) {
                          final selected = _selectedAmount == amt;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedAmount = amt;
                                _amountController.text = amt.toString();
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: selected
                                        ? AppColors.primary
                                        : Colors.grey.shade200),
                                boxShadow: selected
                                    ? [
                                        BoxShadow(
                                            color: AppColors.primary
                                                .withOpacity(0.2),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4))
                                      ]
                                    : [],
                              ),
                              child: Text(
                                '₹$amt',
                                style: TextStyle(
                                  color: selected
                                      ? AppColors.white
                                      : AppColors.text,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Final CTA
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isProcessing
                        ? null
                        : () => _makePayment(_selectedAmount),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C853), // Modern Emerald Green
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      elevation: 8,
                      shadowColor: const Color(0xFF00C853).withOpacity(0.4),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            'PROCEED TO PAY ₹${_selectedAmount.toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_showCelebration)
          WinningCelebrationAnimation(
            winnerName: _userName,
            prizeAmount: _lastAddedAmount,
            contestName: 'Wallet Top-up Success',
            showTrophy: false,
            onCelebrationComplete: () {
              setState(() => _showCelebration = false);
            },
          ),
      ],
    );
  }

  Widget _buildCardField({
    required String label,
    required String hint,
    IconData? icon,
    bool obscure = false,
    TextEditingController? controller,
    Function(String)? onChanged,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.textLight,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border.withOpacity(0.5)),
          ),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            obscureText: obscure,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              prefixIcon: icon != null
                  ? Icon(icon, size: 20, color: Colors.grey)
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
