import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fantasy_crick/main.dart';
import 'package:fantasy_crick/core/services/api_client.dart';

class AuthManager {
  static const String _tokenKey = 'auth_token';
  static const String _tokenExpiryKey = 'token_expiry';

  /// Check if token is expired based on stored expiry time
  /// Added 5-minute grace period to prevent premature logout
  static Future<bool> isTokenExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final expiryTime = prefs.getInt(_tokenExpiryKey);
    
    if (expiryTime == null) {
      // No expiry time stored, assume token is valid
      print('DEBUG: AuthManager - No expiry time stored, token considered valid');
      return false;
    }
    
    final now = DateTime.now().millisecondsSinceEpoch;
    // Add 5 minute grace period (300 seconds * 1000 ms)
    final gracePeriod = 5 * 60 * 1000;
    final isExpired = now >= (expiryTime + gracePeriod);
    
    print('DEBUG: AuthManager - Token expiry check: now=$now, expiry=$expiryTime, gracePeriod=$gracePeriod, isExpired=$isExpired');
    return isExpired;
  }

  /// Save token with expiry time (default 24 hours)
  static Future<void> saveTokenWithExpiry(String token, {int hours = 24}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    
    // Set expiry time
    final expiryTime = DateTime.now().add(Duration(hours: hours)).millisecondsSinceEpoch;
    await prefs.setInt(_tokenExpiryKey, expiryTime);
  }

  /// Get current token
  static Future<String?> getToken() async {
    return await ApiClient.getToken();
  }

  /// Check authentication status and redirect if needed
  /// Checks both token existence AND expiry time
  /// Logs out user if token is expired
  static Future<bool> checkAuthStatus() async {
    final token = await getToken();
    
    if (token == null || token.isEmpty) {
      print('DEBUG: AuthManager - No token found, redirecting to login');
      await _redirectToLogin();
      return false;
    }
    
    // Check if token is expired (with 5-minute grace period)
    if (await isTokenExpired()) {
      print('DEBUG: AuthManager - Token expired, logging out user');
      await logout();
      return false;
    }
    
    print('DEBUG: AuthManager - Token valid, session active');
    return true;
  }

  /// Logout and clear all authentication data
  static Future<void> logout() async {
    try {
      // Call logout API if available
      await ApiClient.post('/auth/logout', {});
    } catch (_) {
      // Ignore logout API errors
    } finally {
      // Clear local data
      await clearAuthData();
      await _redirectToLogin();
    }
  }

  /// Clear all authentication data
  static Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_tokenExpiryKey);
    await ApiClient.clearToken();
  }

  /// Redirect to login screen
  static Future<void> _redirectToLogin() async {
    // Use navigatorKey to navigate from anywhere
    final context = navigatorKey.currentContext;
    if (context != null) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/signin',
        (route) => false,
      );
    }
  }

  /// Validate token format (basic JWT check)
  static bool isValidTokenFormat(String token) {
    if (token.isEmpty) return false;
    
    // Basic JWT format check: header.payload.signature
    final parts = token.split('.');
    if (parts.length != 3) return false;
    
    try {
      // Try to decode the payload to check if it's valid JSON
      String payload = parts[1];
      // Pad base64 string if needed
      while (payload.length % 4 != 0) {
        payload += '=';
      }
      final decoded = utf8.decode(base64.decode(payload));
      final payloadMap = jsonDecode(decoded);
      
      // Check if token has required claims
      final exp = payloadMap['exp'];
      if (exp != null) {
        final expiryTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
        final now = DateTime.now();
        return now.isBefore(expiryTime);
      }
      
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Periodic token validation (call this from app lifecycle)
  /// NOTE: This is now completely passive - it never triggers logout
  /// Token validation happens reactively via API 401 responses only
  static Future<void> validateTokenPeriodically() async {
    final token = await getToken();
    print('DEBUG: AuthManager - validateTokenPeriodically called, token exists: ${token != null && token.isNotEmpty}');
    
    // This method is now completely passive
    // It only logs debug info but never triggers logout
    // Logout only happens when API returns 401
    if (token != null && token.isNotEmpty) {
      final formatValid = isValidTokenFormat(token);
      print('DEBUG: AuthManager - Token format check: $formatValid (no action taken)');
    }
    
    // DO NOT call logout() here - let API 401s handle it
  }
}
