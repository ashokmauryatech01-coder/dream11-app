import 'package:flutter/material.dart';
import 'package:fantasy_crick/common/widgets/beauty_dialog.dart';
import 'package:fantasy_crick/common/widgets/winning_celebration_animation.dart';
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
  bool _showCelebration = false;
  double _lastWithdrawnAmount = 0.0;
  
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
        });
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
    
    if (amount > _walletBalance) {
      _showMessage('Insufficient Balance', 'Amount exceeds available balance', false);
      return;
    }

    setState(() => _isProcessing = true);

    try {
      await Future.delayed(const Duration(seconds: 2));
      final newBalance = await WalletService.updateLocalBalance(-amount);
      
      setState(() {
        _isProcessing = false;
        _walletBalance = newBalance;
        _lastWithdrawnAmount = amount;
        _showCelebration = true;
      });

      _clearForm();
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
    BeautyDialog.show(
      context,
      title: title,
      message: message,
      type: isSuccess ? BeautyDialogType.success : BeautyDialogType.error,
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
              'WITHDRAW FUNDS',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 2),
            ),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Premium Withdrawal Balance Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1E3C72), Color(0xFF2A5298)], // Deep Royal Blue
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1E3C72).withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                right: -15,
                                bottom: -15,
                                child: Icon(
                                  Icons.payments_rounded,
                                  size: 90,
                                  color: Colors.white.withOpacity(0.08),
                                ),
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Icon(Icons.account_balance_rounded, color: Colors.white, size: 16),
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              'Withdrawable Balance',
                                              style: TextStyle(color: AppColors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          '₹${_walletBalance.toStringAsFixed(2)}',
                                          style: const TextStyle(color: AppColors.white, fontSize: 36, fontWeight: FontWeight.w900),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_upward_rounded, color: Colors.white70, size: 32),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Input Container
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Withdrawal Amount', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textLight)),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _amountController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.primary),
                                decoration: const InputDecoration(
                                  prefixText: '₹ ',
                                  prefixStyle: TextStyle(color: AppColors.primary, fontSize: 24, fontWeight: FontWeight.bold),
                                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
                                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
                                ),
                                validator: (v) => (v == null || v.isEmpty) ? 'Enter amount' : (double.tryParse(v) ?? 0) < 100 ? 'Minimum ₹100' : (double.tryParse(v) ?? 0) > _walletBalance ? 'Insufficient balance' : null,
                                onChanged: (v) => setState(() => _selectedAmount = double.tryParse(v) ?? 0),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Quick Amounts
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: _quickAmounts.map((amt) {
                            final selected = _selectedAmount == amt;
                            return GestureDetector(
                              onTap: () => _selectQuickAmount(amt),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: selected ? AppColors.primary : AppColors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: selected ? AppColors.primary : Colors.grey.shade200),
                                  boxShadow: selected ? [BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))] : [],
                                ),
                                child: Text(
                                  '₹$amt',
                                  style: TextStyle(
                                    color: selected ? AppColors.white : AppColors.text,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 32),

                        // UPI Field
                        _buildInputField(
                          controller: _upiController,
                          label: 'UPI ID',
                          hint: 'username@bank',
                          icon: Icons.account_balance_wallet_rounded,
                        ),
                        const SizedBox(height: 16),
                        _buildInputField(
                          controller: _recipientController,
                          label: 'Recipient Name',
                          hint: 'Account Holder Name',
                          icon: Icons.person_rounded,
                        ),
                        
                        const SizedBox(height: 40),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isProcessing ? null : _processWithdrawal,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD32F2F), // Premium Alert Red
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              elevation: 8,
                              shadowColor: const Color(0xFFD32F2F).withOpacity(0.3),
                            ),
                            child: _isProcessing
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('CONFIRM WITHDRAWAL', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
        if (_showCelebration)
          WinningCelebrationAnimation(
            winnerName: "Withdrawal Request Sent",
            prizeAmount: _lastWithdrawnAmount,
            contestName: "Funds will reach your account soon",
            showTrophy: false,
            onCelebrationComplete: () {
              setState(() => _showCelebration = false);
              _showMessage(
                'Request Received',
                'Your withdrawal of ₹${_lastWithdrawnAmount.toStringAsFixed(0)} is being processed.',
                true,
              );
            },
          ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textLight)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border.withOpacity(0.5)),
          ),
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              prefixIcon: Icon(icon, size: 20, color: AppColors.primary.withOpacity(0.7)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }
}
