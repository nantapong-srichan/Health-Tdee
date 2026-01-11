import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class ApiService {
  static const String tokenKey = 'jwt_token';
  static const String userKey = 'user_data';
  
  final _secureStorage = const FlutterSecureStorage();
  
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  
  factory ApiService() {
    return _instance;
  }
  
  ApiService._internal();
  
  // Get JWT token from secure storage
  Future<String?> getToken() async {
    return await _secureStorage.read(key: tokenKey);
  }
  
  // Save JWT token to secure storage
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: tokenKey, value: token);
  }
  
  // Delete JWT token
  Future<void> deleteToken() async {
    await _secureStorage.delete(key: tokenKey);
  }
  
  // Make HTTP request with JWT token (public for use by services)
  Future<http.Response> makeRequest(
    String method,
    String url, {
    dynamic body,
    Map<String, String>? headers,
  }) async {
    try {
      final token = await getToken();
      
      final requestHeaders = headers ?? {};
      requestHeaders['Content-Type'] = 'application/json';
      
      if (token != null) {
        requestHeaders['Authorization'] = 'Bearer $token';
      }
      
      late http.Response response;
      
      switch (method) {
        case 'GET':
          response = await http.get(
            Uri.parse(url),
            headers: requestHeaders,
          );
          break;
        case 'POST':
          response = await http.post(
            Uri.parse(url),
            headers: requestHeaders,
            body: jsonEncode(body),
          );
          break;
        case 'PUT':
          response = await http.put(
            Uri.parse(url),
            headers: requestHeaders,
            body: jsonEncode(body),
          );
          break;
        case 'DELETE':
          response = await http.delete(
            Uri.parse(url),
            headers: requestHeaders,
          );
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }
      
      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null;
  }
  
  // Decode JWT to get userId
  Future<String?> getUserId() async {
    final token = await getToken();
    if (token == null) return null;
    
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      
      return payload['userId']?.toString();
    } catch (e) {
      return null;
    }
  }
}
