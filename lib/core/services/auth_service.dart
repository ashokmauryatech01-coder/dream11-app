import 'api_client.dart';

class AuthService {
  /// Login with email + password. Returns token + user on success.
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await ApiClient.post('/auth/login', {
      'email': email,
      'password': password,
      'user_type': 'user',
    });

    if (response != null &&
        response['data'] != null &&
        response['data']['token'] != null) {
      final token = response['data']['token'] as String;
      await ApiClient.saveToken(token);
      return {'token': token, 'user': response['data']['user']};
    }

    throw Exception(response?['message'] ?? 'Login failed. Please try again.');
  }

  /// Register a new user account. Returns token + user on success.
  Future<Map<String, dynamic>> signUp(
    String name,
    String email,
    String phone,
    String password,
  ) async {
    final response = await ApiClient.post('/auth/register', {
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'password_confirmation': password,
      'user_type': 'user',
    });

    if (response != null &&
        response['data'] != null &&
        response['data']['token'] != null) {
      final token = response['data']['token'] as String;
      await ApiClient.saveToken(token);
      return {'token': token, 'user': response['data']['user']};
    }

    throw Exception(
        response?['message'] ?? 'Registration failed. Please try again.');
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

  /// Reset password using OTP + new password.
  Future<void> resetPassword(
    String email,
    String otp,
    String newPassword,
    String confirmPassword,
  ) async {
    final response = await ApiClient.post('/auth/reset-password', {
      'email': email,
      'otp': otp,
      'password': newPassword,
      'password_confirmation': confirmPassword,
    });

    if (response != null && response['success'] == false) {
      throw Exception(response['message'] ?? 'Password reset failed.');
    }
  }

  /// Verify phone/email OTP after registration.
  Future<void> verifyRegistrationOtp(String otp) async {
    final response = await ApiClient.post('/auth/verify', {
      'otp': otp,
    });

    if (response != null && response['success'] == false) {
      throw Exception(response['message'] ?? 'OTP verification failed.');
    }
  }

  /// Send login OTP to phone number.
  Future<Map<String, dynamic>> sendOTP(String phone) async {
    final response = await ApiClient.post('/auth/send-otp', {
      'phone': phone,
      'user_type': 'user',
    });

    if (response != null && response['success'] == true) {
      return response;
    }

    throw Exception(response?['message'] ?? 'Failed to send OTP.');
  }

  /// Resend login OTP to phone number.
  Future<Map<String, dynamic>> resendOTP(String phone) async {
    final response = await ApiClient.post('/auth/resend-otp', {
      'phone': phone,
      'user_type': 'user',
    });

    if (response != null && response['success'] == true) {
      return response;
    }

    throw Exception(response?['message'] ?? 'Failed to resend OTP.');
  }

  /// Verify phone OTP for login. Returns token + user on success.
  Future<Map<String, dynamic>> verifyOTPLogin(String phone, String otp) async {
    final response = await ApiClient.post('/auth/verify-otp', {
      'phone': phone,
      'otp': otp,
      'user_type': 'user',
    });

    if (response != null && response['success'] != false && response['data'] != null && response['data']['token'] != null) {
      final token = response['data']['token'] as String;
      await ApiClient.saveToken(token);
      return {'token': token, 'user': response['data']['user']};
    }

    throw Exception(response?['message'] ?? 'OTP Login verification failed.');
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
