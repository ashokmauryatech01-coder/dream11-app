import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:js' if (dart.library.io) 'package:fantasy_crick/core/utils/js_stub.dart' as js;
import 'package:fantasy_crick/common/widgets/beauty_dialog.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';
import 'package:fantasy_crick/core/services/profile_service.dart';
import 'package:fantasy_crick/core/services/wallet_service.dart';
import 'package:fantasy_crick/features/wallet/screens/payment_webview_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fantasy_crick/common/widgets/winning_celebration_animation.dart';

class AddCashScreen extends StatefulWidget {
  const AddCashScreen({super.key});

  @override
  State<AddCashScreen> createState() => _AddCashScreenState();
}

class _AddCashScreenState extends State<AddCashScreen> {
  // Removed RazorpayService _razorpayService = RazorpayService();
  final TextEditingController _amountController = TextEditingController();
  double _selectedAmount = 100.0;
  final List<double> _quickAmounts = [100, 200, 500, 1000, 2000, 5000];
  bool _isProcessing = false;
  double _walletBalance = 0.0;
  bool _isLoadingBalance = true;
  int? _walletId;
  bool _showCelebration = false;
  double _lastAddedAmount = 0.0;
  String _userName = 'User';
  int _userId = 0;
  String? _pendingOrderNo;
  double _pendingAmount = 0;
  int _pendingTxnId = 0;
  // String? _userEmail; // Removed unused
  // String? _userPhone; // Removed unused

  @override
  void initState() {
    super.initState();
    _amountController.text = _selectedAmount.toString();
    // _initializeRazorpay(); // Removed Razorpay initialization
    _loadWalletBalance();
  }

  Future<void> _loadWalletBalance() async {
    setState(() => _isLoadingBalance = true);
    try {
      // Logic for fetching balance will now strictly happen in the latter part of this function 
      // when currentUserId is verified. This avoids the initial getLocalBalance call.
      setState(() => _walletBalance = 0.0); 

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

      var currentUserId = parseId(user['user_id'] ?? user['userid'] ?? user['id']);
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
          currentUserId = parseId(user['user_id'] ?? user['userid'] ?? user['id']);
          debugPrint('AddCashScreen: Updated Current User ID: $currentUserId');
        }
      }

      if (currentUserId == 0) {
        debugPrint('AddCashScreen: ID still 0, checking direct prefs...');
        final prefs = await SharedPreferences.getInstance();
        currentUserId = prefs.getInt('user_id') ?? 0;
      }

      _userName = user['name'] ?? user['full_name'] ?? 'User';
      _userId = currentUserId;
      // _userEmail = user['email'];
      // _userPhone = user['phone'];

      debugPrint('AddCashScreen: Final ID for wallet fetch: $_userId');

      if (_userId != 0) {
        final walletData = await ProfileService.getUserWallets(_userId);
        debugPrint('AddCashScreen: Wallet data response: $walletData');
        if (walletData != null) {
          // Robust unwrap of the nested 'wallet' key
          final wallet = walletData.containsKey('wallet')
              ? walletData['wallet']
              : walletData;

          setState(() {
            _walletBalance =
                double.tryParse(wallet['balance']?.toString() ?? '0') ?? 0.0;
            _walletId = parseId(wallet['id']);
          });
          debugPrint(
            'AddCashScreen: Identified Wallet ID: $_walletId, Balance: $_walletBalance',
          );
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

  // Removed _initializeRazorpay logic

  void _handleSuccess(double amount) {
    setState(() {
      _showCelebration = true;
      _lastAddedAmount = amount;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showCelebration = false);
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    // _razorpayService.dispose(); // Removed Razorpay dispose
    super.dispose();
  }

  void _makePayment(double amount) async {
    if (amount < 200) {
      _showMessage('Invalid Amount', 'Minimum amount is ₹200', false);
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Create a unique order number and transaction ID
      final String orderNo = "ORD_${DateTime.now().millisecondsSinceEpoch}";
      final int txnId = _userId; // Using userId as txnId as shown in user example

      debugPrint('Initiating Pay-In for Wallet');
      debugPrint('Payload: orderNo: $orderNo, amount: $amount, userId: $_userId');

      // Step 1: Pay-In
      final payinResult = await WalletService.payIn(
        orderNo: orderNo,
        amountINR: amount,
        userId: _userId,
      );

      debugPrint('Pay-In Response: $payinResult');

      if (payinResult != null && payinResult['success'] == true) {
        final serverOrderNo = payinResult['order_no']?.toString() ?? orderNo;
        final paymentUrl = payinResult['payment_url']?.toString() ?? '';

        debugPrint('Pay-In Success. Server OrderNo: $serverOrderNo');
        
        setState(() {
          _pendingOrderNo = serverOrderNo;
          _pendingAmount = amount;
          _pendingTxnId = txnId;
          _isProcessing = false; // Allow interaction with the Verify button
        });

        // Launch Payment URL in In-App WebView
        if (paymentUrl.isNotEmpty) {
           debugPrint('AddCashScreen: Opening Payment URL in WebView: $paymentUrl');
           debugPrint('AddCashScreen: kIsWeb = $kIsWeb, mounted = $mounted');
           try {
             if (kIsWeb) {
               // For web platform, still use external window
               debugPrint('AddCashScreen: Opening in external browser (web platform)');
               js.context.callMethod('open', [paymentUrl]);
             } else {
               // For mobile, open in-app WebView
               if (mounted) {
                 debugPrint('AddCashScreen: Pushing PaymentWebViewScreen...');
                 Navigator.push(
                   context,
                   MaterialPageRoute(
                     builder: (context) => PaymentWebViewScreen(
                       paymentUrl: paymentUrl,
                       orderNo: serverOrderNo,
                       amount: amount,
                     ),
                   ),
                 ).then((_) {
                   debugPrint('AddCashScreen: PaymentWebViewScreen closed');
                 });
                 debugPrint('AddCashScreen: PaymentWebViewScreen pushed successfully');
               } else {
                 debugPrint('AddCashScreen: ERROR - not mounted, cannot push WebView');
               }
             }
           } catch (e, stackTrace) {
             debugPrint('AddCashScreen: Payment screen navigation error: $e');
             debugPrint('AddCashScreen: Stack trace: $stackTrace');
           }
        } else {
          debugPrint('AddCashScreen: ERROR - paymentUrl is empty!');
        }
        
        // AUTO-POLLING: Start verifying automatically
        _startAutoVerification();
      } else {
        _showMessage('Failed', payinResult?['message'] ?? 'Payment initiation failed', false);
        setState(() => _isProcessing = false);
      }
    } catch (e) {
      debugPrint('Error during payment processing: $e');
      _showMessage('Error', 'An error occurred: $e', false);
      setState(() => _isProcessing = false);
    }
  }

  void _startAutoVerification() async {
    int attempts = 0;
    const int maxAttempts = 30; // 30 attempts * 4 seconds = 2 minutes

    while (attempts < maxAttempts && _pendingOrderNo != null) {
      await Future.delayed(const Duration(seconds: 4));
      if (!mounted) return;
      
      attempts++;
      debugPrint('Auto-Verifying Payment (Attempt $attempts / $maxAttempts)...');
      
      try {
        final result = await WalletService.paymentCallback(
          orderNo: _pendingOrderNo!,
          amount: _pendingAmount,
          txnId: _pendingTxnId,
          paymentUrl: "deposit",
          status: "success",
        );

        if (result != null && result['success'] == true) {
          final addedAmount = _pendingAmount;
          setState(() {
            _pendingOrderNo = null;
          });
          _handleSuccess(addedAmount);
          await _loadWalletBalance();
          return; // Success!
        }
      } catch (e) {
        debugPrint('Auto-verification polling error: $e');
      }
    }
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
            backgroundColor: AppColors.background,
            foregroundColor: AppColors.text,
            elevation: 0,
            title: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.sports_cricket,
                    color: AppColors.primary,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Add Cash'),
              ],
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
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
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
                          color: Colors.grey.withOpacity(0.08),
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
                                  color: Colors.grey.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.account_balance_wallet_rounded,
                                  color: AppColors.text,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Current Balance',
                                style: TextStyle(
                                  color: AppColors.text,
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
                                    color: AppColors.primary,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  '₹${_walletBalance.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    color: AppColors.text,
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
                    borderRadius: BorderRadius.circular(12),
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
                  height: 48,
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
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      shadowColor: AppColors.primary.withOpacity(0.3),
                    ),
                    child: _isProcessing && _pendingOrderNo == null
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: AppColors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text('Initiating...'),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_circle_outline, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'Add Cash ₹${_selectedAmount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                if (_pendingOrderNo != null) ...[
                  const SizedBox(height: 16),
                  const Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(color: AppColors.secondary),
                        SizedBox(height: 12),
                        Text(
                          'Monitoring Payment...',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                        Text(
                          'The balance will update automatically upon completion.',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
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
