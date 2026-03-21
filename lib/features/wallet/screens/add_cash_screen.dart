import 'package:flutter/material.dart';
import 'package:fantasy_crick/common/widgets/beauty_dialog.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';
import 'package:fantasy_crick/core/services/razorpay_service.dart';
import 'package:fantasy_crick/core/services/profile_service.dart';
import 'package:fantasy_crick/core/services/wallet_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  String? _userEmail;
  String? _userPhone;

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

      var savedData = await ProfileService.getSavedUserData();
      debugPrint('AddCashScreen: Loaded saved user data: $savedData');

      var user = savedData.containsKey('user') ? savedData['user'] : savedData;

      // Robust ID parsing
      int parseId(dynamic id) {
        if (id == null) return 0;
        if (id is int) return id;
        if (id is String) return int.tryParse(id) ?? 0;
        return 0;
      }

      var currentUserId = parseId(user['id']);
      debugPrint('AddCashScreen: Initial Current User ID: $currentUserId');

      if (currentUserId == 0) {
        debugPrint(
          'AddCashScreen: User ID not found locally, fetching from server...',
        );
        final profileData = await ProfileService.getProfile();
        if (profileData != null) {
          debugPrint('AddCashScreen: Profile fetched: $profileData');
          await ProfileService.saveUserDataLocally(profileData);
          savedData = profileData;
          user = savedData.containsKey('user') ? savedData['user'] : savedData;
          currentUserId = parseId(user['id']);
          debugPrint('AddCashScreen: Updated Current User ID: $currentUserId');
        }
      }

      if (currentUserId == 0) {
        debugPrint('AddCashScreen: ID still 0, checking direct prefs...');
        final prefs = await SharedPreferences.getInstance();
        currentUserId = prefs.getInt('user_id') ?? 0;
      }

      _userName = user['name'] ?? user['full_name'] ?? 'User';
      _userEmail = user['email'];
      _userPhone = user['phone'];

      debugPrint('AddCashScreen: Final ID for wallet fetch: $currentUserId');

      if (currentUserId != 0) {
        final walletData = await WalletService.getWallets(currentUserId);
        debugPrint('AddCashScreen: Wallet data response: $walletData');
        if (walletData != null) {
          setState(() {
            _walletBalance =
                double.tryParse(walletData['balance']?.toString() ?? '0') ??
                0.0;
            _walletId = parseId(walletData['id']);
          });
          debugPrint(
            'AddCashScreen: Wallet ID set to: $_walletId, Balance: $_walletBalance',
          );
          await WalletService.saveWalletDataLocally(walletData);
        }
      } else {
        debugPrint('AddCashScreen: ERROR - User ID is 0 after all attempts');
      }
    } catch (e) {
      debugPrint('AddCashScreen: Error in _loadWalletBalance: $e');
    } finally {
      setState(() => _isLoadingBalance = false);
    }
  }

  void _initializeRazorpay() {
    _razorpayService.initialize(
      onPaymentSuccess: (paymentId) async {
        debugPrint('\n--- RAZORPAY PAYMENT SUCCESS ---');
        debugPrint('Razorpay Payment ID: $paymentId');
        setState(() => _isProcessing = true);

        try {
          final savedData = await ProfileService.getSavedUserData();
          debugPrint('Success Flow: Saved Data: $savedData');

          final userObj = savedData.containsKey('user')
              ? savedData['user']
              : savedData;

          // Robust ID parsing
          int parseId(dynamic id) {
            if (id == null) return 0;
            if (id is int) return id;
            if (id is String) return int.tryParse(id) ?? 0;
            return 0;
          }

          var currentUserId = parseId(userObj['id']);

          if (currentUserId == 0) {
            final prefs = await SharedPreferences.getInstance();
            currentUserId = prefs.getInt('user_id') ?? 0;
          }

          debugPrint('Success Flow: Identified User ID: $currentUserId');

          if (_walletId == null) {
            debugPrint('Success Flow: Wallet ID missing, fetching...');
            final walletData = await WalletService.getWallets(currentUserId);
            debugPrint('Success Flow: Wallet Fetch Response: $walletData');
            if (walletData != null) {
              _walletId = parseId(walletData['id']);
            }
          }

          debugPrint('Success Flow: Wallet ID: $_walletId');

          if (currentUserId != 0 && _walletId != null) {
            debugPrint('Success Flow: ATTEMPTING RECHARGE API CALL');
            debugPrint(
              'Success Flow: URL: http://173.208.188.172:8080/api/v1/user/recharge-wallet',
            );
            debugPrint(
              'Success Flow: Payload: {user_id: $currentUserId, wallet_id: $_walletId, balance: $_selectedAmount, transaction_id: $paymentId}',
            );

            final result = await WalletService.rechargeWallet(
              userId: currentUserId,
              walletId: _walletId!,
              balance: _selectedAmount,
              // Using a static single-digit ID as requested for testing
              transactionId:
                  5, // DateTime.now().millisecondsSinceEpoch.toString(),
            );

            debugPrint('Success Flow: Recharge API Response: $result');

            if (result != null) {
              _handleSuccess(_selectedAmount);
              await _loadWalletBalance();
            } else {
              _showMessage(
                'Payment Success',
                'Funds will be added shortly.',
                true,
              );
            }
          } else {
            debugPrint(
              'Success Flow: ERROR - Missing data. UID: $currentUserId, WID: $_walletId',
            );
            _showMessage(
              'Payment Captured',
              'Wallet sync delayed. Please refresh.',
              true,
            );
          }
        } catch (e) {
          debugPrint('Success Flow: CRITICAL ERROR: $e');
        } finally {
          setState(() => _isProcessing = false);
          debugPrint('--- SUCCESS FLOW COMPLETED ---\n');
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

    setState(() => _isProcessing = true);

    _razorpayService.openPayment(
      name: 'Segga Sportz',
      description: 'Add cash to wallet',
      amount: amount,
      email: _userEmail,
      contact: _userPhone,
    );
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
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
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
                            fontWeight: FontWeight.bold,
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.primary),
                          ),
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
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selected
                                      ? AppColors.primary
                                      : Colors.grey.shade200,
                                ),
                                boxShadow: selected
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primary.withOpacity(
                                            0.2,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
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
                      backgroundColor: const Color(
                        0xFF00C853,
                      ), // Modern Emerald Green
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 8,
                      shadowColor: const Color(0xFF00C853).withOpacity(0.4),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'PROCEED TO PAY ₹${_selectedAmount.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
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
}
