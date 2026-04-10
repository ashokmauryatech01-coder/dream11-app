import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String baseUrl = 'http://173.208.188.172:8080/api/v1';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  static Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<dynamic> get(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    _logRequest('GET', url);
    final response = await http
        .get(url, headers: await getHeaders())
        .timeout(const Duration(seconds: 30));
    _logResponse('GET', url, response);
    return _handleResponse(response);
  }

  static Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final url = Uri.parse('$baseUrl$endpoint');
    _logRequest('POST', url, body: body);
    final response = await http
        .post(url, headers: await getHeaders(), body: jsonEncode(body))
        .timeout(const Duration(seconds: 15));
    _logResponse('POST', url, response);
    return _handleResponse(response);
  }

  static Future<dynamic> delete(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    _logRequest('DELETE', url, body: body);
    final response = await http
        .delete(url, headers: await getHeaders(), body: body != null ? jsonEncode(body) : null)
        .timeout(const Duration(seconds: 15));
    _logResponse('DELETE', url, response);
    return _handleResponse(response);
  }

  static void _logRequest(
    String method,
    Uri url, {
    Map<String, dynamic>? body,
  }) {
    print('---------------- API REQUEST ----------------');
    print('METHOD: $method');
    print('URL: $url');
    if (body != null) {
      print('BODY: ${jsonEncode(body)}');
    }
    print('---------------------------------------------');
  }

  static void _logResponse(String method, Uri url, http.Response response) {
    print('---------------- API RESPONSE ---------------');
    print('METHOD: $method');
    print('URL: $url');
    print('STATUS CODE: ${response.statusCode}');
    print('RESPONSE: ${response.body}');
    print('---------------------------------------------');
  }

  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isNotEmpty) {
        return jsonDecode(response.body);
      }
      return null;
    } else {
      String errorMessage = 'Request failed (${response.statusCode})';
      try {
        if (response.body.isNotEmpty) {
          final body = jsonDecode(response.body);
          if (body is Map) {
            errorMessage =
                body['message']?.toString() ??
                body['error']?.toString() ??
                body['msg']?.toString() ??
                errorMessage;
          }
        }
      } catch (_) {
        if (response.body.isNotEmpty && response.body.length < 100) {
          errorMessage = response.body;
        }
      }
      throw Exception(errorMessage);
    }
  }
}
