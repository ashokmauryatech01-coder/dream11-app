import 'package:flutter/material.dart';
import 'package:fantasy_crick/common/widgets/cricket_animation.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';
import 'package:fantasy_crick/core/services/profile_service.dart';
import 'package:fantasy_crick/core/services/wallet_service.dart';

class WithdrawalScreen extends StatefulWidget {
  const WithdrawalScreen({super.key});

  @override
  State<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends State<WithdrawalScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _upiController = TextEditingController();
  final TextEditingController _recipientController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  double _walletBalance = 0.0;
  bool _isLoading = true;
  bool _isProcessing = false;
  
  final List<double> _quickAmounts = [100, 200, 500, 1000, 2000, 5000];
  double _selectedAmount = 100.0;

  @override
  void initState() {
    super.initState();
    _loadWalletData();
  }

  Future<void> _loadWalletData() async {
    setState(() => _isLoading = true);
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
          // _walletId = walletData['id'] as int?; // Temporarily disabled for dummy mode
        });
        // Sync local with remote if remote is available
        await WalletService.saveWalletDataLocally(walletData);
      }
    } catch (e) {
      print('Error loading wallet data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _upiController.dispose();
    _recipientController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _selectQuickAmount(double amount) {
    setState(() {
      _selectedAmount = amount;
      _amountController.text = amount.toString();
    });
  }

  Future<void> _processWithdrawal() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final upiId = _upiController.text.trim();
    final recipientName = _recipientController.text.trim();
    final description = _descriptionController.text.trim();

    if (amount > _walletBalance) {
      _showMessage('Insufficient Balance', 'Amount exceeds available balance', false);
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Simulate withdrawal processing (DUMMY MODE)
      await Future.delayed(const Duration(seconds: 2));
      
      // Update local balance
      final newBalance = await WalletService.updateLocalBalance(-amount);
      
      setState(() {
        _isProcessing = false;
        _walletBalance = newBalance;
      });

      _showMessage('Withdrawal Successful!', 
        'Amount: ₹${amount.toStringAsFixed(2)}\nRecipient: $recipientName\nUPI ID: $upiId\nStatus: Processing\nDesc: $description', 
        true);
      
      // Clear form
      _clearForm();
      
      /* 
      // REAL WITHDRAWAL INTEGRATION
      final savedData = await ProfileService.getSavedUserData();
      final currentUserId = savedData['id'] ?? 0;

      final result = await WalletService.upiTransfer(
        userId: currentUserId,
        amount: amount,
        upiId: upiId,
        recipientName: recipientName,
        walletId: _walletId!,
        description: description.isNotEmpty ? description : 'Withdrawal to bank account',
        transactionType: 'withdrawal',
      );

      setState(() => _isProcessing = false);

      if (result != null) {
        _showMessage('Withdrawal Successful!', 
          'Amount: ₹${amount.toStringAsFixed(2)}\nUPI ID: $upiId\nReference: ${result['reference_id'] ?? 'Processing'}', 
          true);
        
        // Clear form and refresh balance
        _clearForm();
        await _loadWalletData();
      } else {
        _showMessage('Withdrawal Failed', 'Please try again later', false);
      }
      */
    } catch (e) {
      setState(() => _isProcessing = false);
      _showMessage('Withdrawal Failed', 'Error: $e', false);
    }
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _amountController.clear();
    _upiController.clear();
    _recipientController.clear();
    _descriptionController.clear();
    setState(() => _selectedAmount = 100.0);
  }

  void _showMessage(String title, String message, bool isSuccess) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        icon: Icon(
          isSuccess ? Icons.check_circle : Icons.error,
          color: isSuccess ? Colors.green : Colors.red,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
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
        title: const Text('Withdraw Funds'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
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
                                  'Available Balance',
                                  style: TextStyle(
                                    color: AppColors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '₹${_walletBalance.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: AppColors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          CricketAnimation(
                            type: AnimationType.coin,
                            size: 50,
                            color: AppColors.white,
                            duration: const Duration(seconds: 3),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Withdrawal Amount
                    const Text(
                      'Withdrawal Amount',
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
                      child: TextFormField(
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
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter amount';
                          }
                          final amount = double.tryParse(value);
                          if (amount == null || amount <= 0) {
                            return 'Please enter valid amount';
                          }
                          if (amount < 100) {
                            return 'Minimum withdrawal amount is ₹100';
                          }
                          if (amount > _walletBalance) {
                            return 'Insufficient balance';
                          }
                          return null;
                        },
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
                    Text(
                      'Minimum withdrawal: ₹100',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Quick Amount Selection
                    const Text(
                      'Quick Amount',
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
                          onTap: () => _selectQuickAmount(amount),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : AppColors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : AppColors.border,
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

                    // UPI Details
                    const Text(
                      'UPI Details',
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
                      child: TextFormField(
                        controller: _upiController,
                        decoration: const InputDecoration(
                          labelText: 'UPI ID',
                          hintText: 'username@bankname',
                          prefixIcon: Icon(Icons.account_balance_wallet_rounded),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter UPI ID';
                          }
                          if (!value.contains('@') || value.split('@').length != 2) {
                            return 'Enter valid UPI ID (e.g., username@bankname)';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: TextFormField(
                        controller: _recipientController,
                        decoration: const InputDecoration(
                          labelText: 'Recipient Name',
                          hintText: 'Account holder name',
                          prefixIcon: Icon(Icons.person_rounded),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter recipient name';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description (Optional)',
                          hintText: 'Withdrawal description',
                          prefixIcon: Icon(Icons.description_rounded),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                        ),
                        maxLines: 2,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Withdraw Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isProcessing ? null : _processWithdrawal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isProcessing ? Colors.grey : Colors.red,
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
                            : const Text(
                                'Withdraw ₹[amount]',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Warning Message
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_rounded, color: Colors.orange),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Withdrawals are processed within 24-48 hours. Please verify UPI details before proceeding.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
