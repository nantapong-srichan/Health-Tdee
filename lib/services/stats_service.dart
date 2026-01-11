import 'dart:convert';
import 'api_service.dart';
import 'api_config.dart';

class StatsService {
  final _apiService = ApiService();
  
  // Get daily statistics
  Future<Map<String, dynamic>> getDailyStats({
    String? date, // Format: YYYY-MM-DD, defaults to today
  }) async {
    try {
      String url = ApiConfig.statsDaily;
      if (date != null) {
        url += '?date=$date';
      }
      
      final response = await _apiService.makeRequest('GET', url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'stats': data['stats'],
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch daily stats',
          'stats': {},
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
        'stats': {},
      };
    }
  }
  
  // Get weekly statistics
  Future<Map<String, dynamic>> getWeeklyStats({
    String? startDate, // Format: YYYY-MM-DD, defaults to 7 days ago
  }) async {
    try {
      String url = ApiConfig.statsWeekly;
      if (startDate != null) {
        url += '?startDate=$startDate';
      }
      
      final response = await _apiService.makeRequest('GET', url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'weeklyStats': data['weeklyStats'],
          'averageStats': data['averageStats'],
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch weekly stats',
          'weeklyStats': [],
          'averageStats': {},
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
        'weeklyStats': [],
        'averageStats': {},
      };
    }
  }
  
  // Get calorie summary (macronutrient breakdown)
  Future<Map<String, dynamic>> getCalorieSummary({
    String? startDate, // Format: YYYY-MM-DD
    String? endDate,   // Format: YYYY-MM-DD
  }) async {
    try {
      String url = ApiConfig.statsSummary;
      List<String> params = [];
      
      if (startDate != null) {
        params.add('startDate=$startDate');
      }
      if (endDate != null) {
        params.add('endDate=$endDate');
      }
      
      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }
      
      final response = await _apiService.makeRequest('GET', url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'summary': data['summary'],
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch summary',
          'summary': {},
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
        'summary': {},
      };
    }
  }
  
  // Get nutritional insights (AI recommendations)
  Future<Map<String, dynamic>> getNutritionalInsights({
    String? startDate, // Format: YYYY-MM-DD, defaults to 7 days ago
  }) async {
    try {
      String url = ApiConfig.statsInsights;
      if (startDate != null) {
        url += '?startDate=$startDate';
      }
      
      final response = await _apiService.makeRequest('GET', url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'insights': data['insights'] ?? [],
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch insights',
          'insights': [],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
        'insights': [],
      };
    }
  }
  
  // Helper: Get today's date in YYYY-MM-DD format
  String getTodayDate() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
  
  // Helper: Get date 7 days ago
  String getWeekAgoDate() {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return '${weekAgo.year}-${weekAgo.month.toString().padLeft(2, '0')}-${weekAgo.day.toString().padLeft(2, '0')}';
  }
}
