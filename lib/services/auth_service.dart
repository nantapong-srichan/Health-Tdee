import 'dart:convert';
import 'api_service.dart';
import 'api_config.dart';

class AuthService {
  final _apiService = ApiService();
  
  // Register new user
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? dateOfBirth,
    int? age,
    required double weight,
    required double height,
    String? gender,
    String? goal,
    required String activityLevel,
    required int dailyCalorieGoal,
  }) async {
    try {
      final response = await _apiService.makeRequest(
        'POST',
        ApiConfig.authRegister,
        body: {
          'name': name,
          'email': email,
          'password': password,
          if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
          if (age != null) 'age': age,
          'weight': weight,
          'height': height,
          if (gender != null) 'gender': gender,
          if (goal != null) 'goal': goal,
          'activityLevel': activityLevel,
          'dailyCalorieGoal': dailyCalorieGoal,
        },
      );
      
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['token'] != null) {
          await _apiService.saveToken(data['token']);
        }
        return {
          'success': true,
          'message': data['message'],
          'userId': data['userId'],
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
  
  // Login user
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiService.makeRequest(
        'POST',
        ApiConfig.authLogin,
        body: {
          'email': email,
          'password': password,
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['token'] != null) {
          await _apiService.saveToken(data['token']);
        }
        return {
          'success': true,
          'message': 'Login successful',
          'userId': data['userId'],
          'user': data['user'],
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Login failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
  
  // Get current user profile
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await _apiService.makeRequest(
        'GET',
        ApiConfig.authProfile,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'user': data['user'],
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch user',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
  
  // Update user profile
  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required int age,
    required double weight,
    required double height,
    required String activityLevel,
    required int dailyCalorieGoal,
  }) async {
    try {
      final response = await _apiService.makeRequest(
        'PUT',
        ApiConfig.authProfileUpdate,
        body: {
          'name': name,
          'age': age,
          'weight': weight,
          'height': height,
          'activityLevel': activityLevel,
          'dailyCalorieGoal': dailyCalorieGoal,
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'Profile updated',
          'user': data['user'],
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Update failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
  
  // Change password
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _apiService.makeRequest(
        'POST',
        ApiConfig.authChangePassword,
        body: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Password changed successfully',
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to change password',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
  
  // Logout
  Future<void> logout() async {
    await _apiService.deleteToken();
  }
}
