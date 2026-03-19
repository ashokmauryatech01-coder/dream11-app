import 'package:flutter/material.dart';
import 'package:fantasy_crick/common/widgets/cricket_animation.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';
import 'package:fantasy_crick/core/services/razorpay_service.dart';
import 'package:fantasy_crick/core/services/profile_service.dart';
import 'package:fantasy_crick/core/services/wallet_service.dart';
import 'package:fantasy_crick/main.dart';

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
      final localBalance = await WalletService.getLocalBalance();
      setState(() {
        _walletBalance = localBalance;
      });

      final savedData = await ProfileService.getSavedUserData();
      final currentUserId = savedData['id'] ?? 0;

      final walletData = await WalletService.getWallets(currentUserId);
      if (walletData != null) {
        setState(() {
          _walletBalance = (walletData['balance'] ?? localBalance).toDouble();
          _walletId = walletData['id'] as int?;
        });
        // Sync local with remote if remote is available
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
            _showMessage(
              'Payment Successful!',
              'Payment ID: $paymentId\nFunds added to wallet',
              true,
            );
            await _loadWalletBalance(); // Refresh balance
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
                        child: _buildCardField(
                          label: 'Expiry Date',
                          hint: 'MM / YY',
                          controller: expiryController,
                          onChanged: (v) => updateState(),
                          keyboardType: TextInputType.datetime,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildCardField(
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

    // Simulate payment and update local balance (DUMMY MODE)
    await Future.delayed(const Duration(seconds: 2)); // Simulate network delay

    final newBalance = await WalletService.updateLocalBalance(amount);

    setState(() {
      _isProcessing = false;
      _walletBalance = newBalance;
    });

    _showMessage(
      'Success',
      '₹${amount.toStringAsFixed(0)} added to your wallet!',
      true,
    );
  }

  void _showMessage(String title, String message, bool isSuccess) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            if (isSuccess) ...[
              CricketAnimation(
                type: AnimationType.trophy,
                size: 30,
                color: Colors.amber,
                duration: const Duration(seconds: 2),
              ),
              const SizedBox(width: 12),
            ],
            Text(title),
          ],
        ),
        content: Row(
          children: [
            if (isSuccess) ...[
              CricketAnimation(
                type: AnimationType.coin,
                size: 40,
                color: Colors.green,
                duration: const Duration(seconds: 3),
              ),
              const SizedBox(width: 16),
            ],
            Expanded(child: Text(message)),
          ],
        ),
        actions: [
          if (isSuccess) ...[
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext); // Close dialog
                // Safe back navigation
                if (navigatorKey.currentState?.canPop() ?? false) {
                  navigatorKey.currentState?.pop();
                }
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
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Balance',
                          style: TextStyle(color: AppColors.white, fontSize: 16),
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
                  const SizedBox(width: 20),
                  CricketAnimation(
                    type: AnimationType.coin,
                    size: 60,
                    color: AppColors.white,
                    duration: const Duration(seconds: 3),
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
              style: TextStyle(fontSize: 12, color: AppColors.textLight),
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
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '₹${amount.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? AppColors.white : AppColors.text,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          CricketAnimation(
                            type: AnimationType.coin,
                            size: 20,
                            color: AppColors.white,
                            duration: const Duration(seconds: 2),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 30),

            // Payment Methods
            // const Text(
            //   'Bank Transfer (Recommended)',
            //   style: TextStyle(
            //     fontSize: 18,
            //     fontWeight: FontWeight.bold,
            //     color: AppColors.text,
            //   ),
            // ),
            // const SizedBox(height: 12),
            // Container(
            //   padding: const EdgeInsets.all(20),
            //   decoration: BoxDecoration(
            //     color: Colors.blue.withOpacity(0.05),
            //     borderRadius: BorderRadius.circular(12),
            //     border: Border.all(color: Colors.blue.withOpacity(0.2)),
            //   ),
            //   child: Column(
            //     crossAxisAlignment: CrossAxisAlignment.start,
            //     children: [
            //       _bankDetail('Account Name', 'Pramukh Enterprise'),
            //       _bankDetail('Bank Name', 'IDBI Bank'),
            //       _bankDetail('Account Number', '0082102000044688'),
            //       _bankDetail('IFSC Code', 'IBKL0000082'),
            //       _bankDetail('Customer ID', '102212061'),
            //       const Divider(height: 32),
            //       const Row(
            //         children: [
            //           Icon(Icons.info_outline, size: 16, color: Colors.blue),
            //           SizedBox(width: 8),
            //           Expanded(
            //             child: Text(
            //               'Transfer funds to this account and share the screenshot for instant wallet update.',
            //               style: TextStyle(
            //                 fontSize: 12,
            //                 color: Colors.blueGrey,
            //                 fontStyle: FontStyle.italic,
            //               ),
            //             ),
            //           ),
            //         ],
            //       ),
            //     ],
            //   ),
            // ),
            // const SizedBox(height: 40),

            // Add Cash Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isProcessing
                    ? null
                    : () => _makePayment(_selectedAmount),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isProcessing
                      ? Colors.grey
                      : AppColors.primary,
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

  Widget _bankDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
