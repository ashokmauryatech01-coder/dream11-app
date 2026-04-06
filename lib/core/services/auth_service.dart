import 'api_client.dart';

class AuthService {
  /// Login with email + password. Returns token + user on success.
  Future<Map<String, dynamic>> login(String email, String password, {String? ip}) async {
    final response = await ApiClient.post('/auth/login', {
      'email': email,
      'password': password,
      'user_type': 'user',
      if (ip != null) 'ip_address': ip,
    });

    final token = response?['token'] ?? response?['data']?['token'];
    final user = response?['user'] ?? response?['data']?['user'];

    if (token != null) {
      await ApiClient.saveToken(token as String);
      return {'token': token, 'user': user};
    }

    throw Exception(response?['message'] ?? 'Login failed. Please try again.');
  }

  /// Register a new user account. Returns the full registration response.
  Future<Map<String, dynamic>> signUp(
    String name,
    String email,
    String phone,
    String password, {
    String? upiId,
    String? userType,
    String? ip,
  }) async {
    final formattedPhone = _formatPhone(phone);
    final response = await ApiClient.post('/auth/register', {
      'name': name,
      'email': email,
      'upi_id': upiId ?? '',
      'phone': formattedPhone,
      'password': password,
      'password_confirmation': password,
      'user_type': userType ?? 'user',
      if (ip != null) 'ip_address': ip,
    });

    print('DEBUG: Registration Response: $response');

    // Optionally save token if provided during registration
    final token = response?['token'] ?? response?['data']?['token'];
    if (token != null) {
      await ApiClient.saveToken(token as String);
    }

    return response as Map<String, dynamic>;
  }

  /// Send OTP to email for password reset.
  Future<void> forgotPassword(String email) async {
    final response = await ApiClient.post('/auth/forgot-password', {
      'email': email,
    });

    // Accept success if status is 200/201 (handled by ApiClient)
    // If server returns an error message, surface it
    if (response != null && response['success'] == false) {
      throw Exception(response['message'] ?? 'Failed to send OTP.');
    }
  }

  /// Verify OTP sent to email during password reset flow.
  Future<void> verifyOtp(String email, String otp) async {
    final response = await ApiClient.post('/auth/verify-otp', {
      'email': email,
      'otp': otp,
    });

    if (response != null && response['success'] == false) {
      throw Exception(response['message'] ?? 'OTP verification failed.');
    }
  }

  /// Reset password using token + new password.
  Future<void> resetPassword(
    String email,
    String token,
    String newPassword,
    String confirmPassword,
  ) async {
    final response = await ApiClient.post('/auth/reset-password', {
      'email': email,
      'token': token,
      'password': newPassword,
      'password_confirmation': confirmPassword,
    });

    if (response != null && response['success'] == false) {
      throw Exception(response['message'] ?? 'Password reset failed.');
    }
  }

  /// Verify phone/email OTP after registration. Returns true on success.
  Future<bool> verifyRegistrationOtp(String phone, String otp, {String userType = 'user'}) async {
    final formattedPhone = _formatPhone(phone);
    final response = await ApiClient.post('/auth/verify-otp', {
      'phone': formattedPhone,
      'user_type': userType,
      'otp': otp,
    });

    if (response != null && response['success'] == true) {
      final token = response['token'] ?? response['data']?['token'];
      if (token != null) {
        await ApiClient.saveToken(token as String);
      }
      return true;
    }

    throw Exception(response?['message'] ?? 'OTP verification failed.');
  }

  /// Send login OTP to phone number.
  Future<Map<String, dynamic>> sendOTP(String phone, {String userType = 'user'}) async {
    final formattedPhone = _formatPhone(phone);
    final response = await ApiClient.post('/auth/send-otp', {
      'phone': formattedPhone,
      'user_type': userType,
    });

    if (response != null && response['success'] == true) {
      return response;
    }

    throw Exception(response?['message'] ?? 'Failed to send OTP.');
  }

  /// Resend login OTP to phone number.
  Future<Map<String, dynamic>> resendOTP(String phone, {String userType = 'user'}) async {
    final formattedPhone = _formatPhone(phone);
    final response = await ApiClient.post('/auth/resend-otp', {
      'phone': formattedPhone,
      'user_type': userType,
    });

    if (response != null && response['success'] == true) {
      return response;
    }

    throw Exception(response?['message'] ?? 'Failed to resend OTP.');
  }

  /// Verify phone OTP for login. Returns token + user on success.
  Future<Map<String, dynamic>> verifyOTPLogin(String phone, String otp, {String userType = 'user'}) async {
    final formattedPhone = _formatPhone(phone);
    final response = await ApiClient.post('/auth/verify-otp', {
      'phone': formattedPhone,
      'otp': otp,
      'user_type': userType,
    });

    final token = response?['token'] ?? response?['data']?['token'];
    final user = response?['user'] ?? response?['data']?['user'];

    if (token != null) {
      await ApiClient.saveToken(token as String);
      return {'token': token, 'user': user};
    }

    throw Exception(response?['message'] ?? 'OTP Login verification failed.');
  }

  static String _formatPhone(String phone) {
    String p = phone.trim().replaceAll(' ', '').replaceAll('-', '');
    if (!p.startsWith('+')) {
      if (p.startsWith('91') && p.length == 12) {
        return '+$p';
      }
      return '+91$p';
    }
    return p;
  }

  /// Logout and clear stored token.
  Future<void> logout() async {
    try {
      await ApiClient.post('/auth/logout', {});
    } catch (_) {
      // Ignore logout API errors — always clear local token
    } finally {
      await ApiClient.clearToken();
    }
  }
}
