import 'package:flutter/material.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';
import 'package:fantasy_crick/common/widgets/custom_button.dart';
import 'package:fantasy_crick/core/services/auth_service.dart';
import 'package:fantasy_crick/features/auth/screens/signin_screen.dart';
import 'package:fantasy_crick/features/auth/screens/otp_verification_screen.dart';
import 'package:fantasy_crick/common/widgets/beauty_dialog.dart';
import 'package:fantasy_crick/core/services/location_service.dart';
import 'package:fantasy_crick/core/constants/country_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String _countryCode = '+91';
  CountryInfo? _countryData;
  String _userIp = '';

  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (name.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      await BeautyDialog.show(context,
          title: 'Incomplete Details',
          message: 'Please fill all fields to create your account.',
          type: BeautyDialogType.warning);
      return;
    }

    if (password != confirmPassword) {
      await BeautyDialog.show(context,
          title: 'Password Mismatch',
          message: 'The passwords you entered do not match.',
          type: BeautyDialogType.error);
      return;
    }

    if (password.length < 6) {
      await BeautyDialog.show(context,
          title: 'Weak Password',
          message: 'Password must be at least 6 characters.',
          type: BeautyDialogType.warning);
      return;
    }

    setState(() => _loading = true);

    try {
      final fullPhone = '$_countryCode$phone';
      await _authService.signUp(name, email, fullPhone, password);

      // Save user country/currency preferences locally
      final prefs = await SharedPreferences.getInstance();
      if (_countryData != null) {
        await prefs.setString('user_country_code', _countryData!.code);
        await prefs.setString('user_currency', _countryData!.currency);
        await prefs.setString('user_currency_symbol', _countryData!.currencySymbol);
      }

      if (!mounted) return;
      setState(() => _loading = false);

      await BeautyDialog.show(
        context,
        title: 'Account Created! 🎉',
        message:
            'Your account is ready. Please verify the OTP sent to $phone.',
        type: BeautyDialogType.success,
        confirmText: 'Verify OTP',
        onConfirm: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OtpVerificationScreen(sentTo: phone),
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      final msg = e.toString().replaceFirst('Exception: ', '');
      await BeautyDialog.show(context,
          title: 'Sign Up Failed',
          message: msg,
          type: BeautyDialogType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),

              // Icon
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_add_alt_1,
                  size: 48,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Join the fantasy cricket world',
                style: TextStyle(fontSize: 15, color: AppColors.textLight),
              ),
              const SizedBox(height: 32),

              _buildTextField(
                controller: _nameController,
                label: 'Full Name',
                hint: 'Enter your full name',
                prefixIcon: Icons.person_outline,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _emailController,
                label: 'Email',
                hint: 'Enter your email',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
              ),
              const SizedBox(height: 16),

              _buildPhoneField(
                controller: _phoneController,
                label: 'Phone Number',
                hint: 'Enter your phone number',
                countryCode: _countryCode,
              ),
              const SizedBox(height: 16),

              _buildPasswordField(
                controller: _passwordController,
                label: 'Password',
                hint: 'Create a password',
                obscure: _obscurePassword,
                onToggle: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              const SizedBox(height: 16),

              _buildPasswordField(
                controller: _confirmPasswordController,
                label: 'Confirm Password',
                hint: 'Confirm your password',
                obscure: _obscureConfirm,
                onToggle: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              const SizedBox(height: 28),

              CustomButton(
                title: 'Create Account',
                onTap: _handleSignUp,
                loading: _loading,
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already have an account? ',
                    style: TextStyle(color: AppColors.textLight),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SignInScreen()),
                      );
                    },
                    child: const Text(
                      'Sign In',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    IconData? prefixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.text)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(color: AppColors.text),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.textLight),
              border: InputBorder.none,
              prefixIcon: prefixIcon != null
                  ? Icon(prefixIcon, color: AppColors.textLight)
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.text)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            style: const TextStyle(color: AppColors.text),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.textLight),
              border: InputBorder.none,
              prefixIcon:
                  const Icon(Icons.lock_outline, color: AppColors.textLight),
              suffixIcon: IconButton(
                icon: Icon(
                  obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.textLight,
                ),
                onPressed: onToggle,
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    final data = await LocationService.getLocationData();
    if (mounted) {
      setState(() {
        _countryCode = data['country_calling_code'] ?? '+91';
        _userIp = data['ip'] ?? '';
        
        // Find country data in constants
        final countryCode = data['country_code'];
        if (countryCode != null) {
          _countryData = CountryConstants.countries.firstWhere(
            (c) => c.code == countryCode,
            orElse: () => CountryConstants.countries.firstWhere((c) => c.code == "IN"),
          );
        }
      });
    }
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CountryPickerSheet(
        onSelected: (CountryInfo country) {
          setState(() {
            _countryCode = country.dialCode;
            _countryData = country;
          });
        },
      ),
    );
  }

  Widget _buildPhoneField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String countryCode,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.text)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: _showCountryPicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Text(
                        _countryData?.flag ?? '',
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        countryCode,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: AppColors.text),
                      ),
                      const Icon(Icons.arrow_drop_down, color: AppColors.textLight),
                    ],
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 24,
                color: AppColors.border,
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: AppColors.text),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(color: AppColors.textLight),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CountryPickerSheet extends StatefulWidget {
  final Function(CountryInfo) onSelected;
  const _CountryPickerSheet({required this.onSelected});

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<CountryInfo> _filteredCountries = CountryConstants.countries;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filter);
  }

  void _filter() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCountries = CountryConstants.countries
          .where((c) =>
              c.name.toLowerCase().contains(query) ||
              c.dialCode.contains(query) ||
              c.code.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  'Select Country',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search country name or code...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredCountries.length,
              itemBuilder: (context, index) {
                final country = _filteredCountries[index];
                return ListTile(
                  leading: Text(country.flag, style: const TextStyle(fontSize: 24)),
                  title: Text(country.name),
                  trailing: Text(
                    country.dialCode,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  onTap: () {
                    widget.onSelected(country);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
