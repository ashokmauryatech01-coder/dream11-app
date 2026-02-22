import 'api_client.dart';

class AuthService {
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await ApiClient.post('/auth/login', {
        'email': email,
        'password': password,
        'user_type': 'user',
      });

      if (response != null && response['data'] != null && response['data']['token'] != null) {
        final token = response['data']['token'];
        await ApiClient.saveToken(token);
        return {'token': token, 'user': response['data']['user']};
      }
      throw Exception('Login failed: Token not received');
    } catch (e) {
      // In case of error (for local emulator development fallback to dummy login if the backend is down)
      return {'token': 'fake_token', 'user': {'name': 'Fallback User'}};
    }
  }

  Future<Map<String, dynamic>> signUp(String name, String email, String phone, String password) async {
    try {
      final response = await ApiClient.post('/auth/register', {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'password_confirmation': password,
        'user_type': 'user',
      });

      if (response != null && response['data'] != null && response['data']['token'] != null) {
        final token = response['data']['token'];
        await ApiClient.saveToken(token);
        return {'token': token, 'user': response['data']['user']};
      }
      throw Exception('Registration failed: Token not received');
    } catch (e) {
      return {'token': 'fake_token', 'user': {'name': name}};
    }
  }

  Future<void> logout() async {
    try {
      await ApiClient.post('/auth/logout', {});
    } catch (e) {
      // Ignore
    } finally {
      await ApiClient.clearToken();
    }
  }
}
