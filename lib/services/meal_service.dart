import 'dart:convert';
import 'api_service.dart';
import 'api_config.dart';

class MealService {
  final _apiService = ApiService();
  
  // Save meal to backend
  Future<Map<String, dynamic>> saveMeal({
    required String foodName,
    required int calories,
    required double protein,
    required double carbs,
    required double fat,
    required double fiber,
    required double sodium,
    required double estimatedWeight,
    required double confidence,
    required String mealType,
    DateTime? mealTime,
    String? imageUrl,
    String? notes,
  }) async {
    try {
      final bodyData = {
        'foodName': foodName,
        'nutrition': {
          'calories': calories,
          'protein': protein,
          'carbohydrates': carbs,
          'fat': fat,
          'fiber': fiber,
          'sodium': sodium,
        },
        'estimatedWeight': estimatedWeight,
        'confidence': confidence,
        'mealType': mealType,
        'mealTime': mealTime?.toIso8601String() ?? DateTime.now().toIso8601String(),
        'imageUrl': imageUrl,
        'notes': notes,
      };
      
      print('DEBUG MEAL_SERVICE: Sending saveMeal request');
      print('DEBUG MEAL_SERVICE: Body data: $bodyData');
      
      final response = await _apiService.makeRequest(
        'POST',
        ApiConfig.mealSave,
        body: bodyData,
      );
      
      print('DEBUG MEAL_SERVICE: Response status code: ${response.statusCode}');
      print('DEBUG MEAL_SERVICE: Response body: ${response.body}');
      
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print('DEBUG MEAL_SERVICE: Success response: $data');
        return {
          'success': true,
          'message': 'Meal saved successfully',
          'mealId': data['meal']?['_id'],
          'meal': data['meal'],
        };
      } else {
        final error = jsonDecode(response.body);
        print('DEBUG MEAL_SERVICE: Error response: $error');
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to save meal',
          'errors': error['errors'],
        };
      }
    } catch (e) {
      print('DEBUG MEAL_SERVICE: Exception: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
  
  // Update existing meal
  Future<Map<String, dynamic>> updateMeal({
    required String mealId,
    required String foodName,
    required int calories,
    required double protein,
    required double carbs,
    required double fat,
    required double fiber,
    required double sodium,
    required double estimatedWeight,
  }) async {
    try {
      final bodyData = {
        'foodName': foodName,
        'nutrition': {
          'calories': calories,
          'protein': protein,
          'carbohydrates': carbs,
          'fat': fat,
          'fiber': fiber,
          'sodium': sodium,
        },
        'estimatedWeight': estimatedWeight,
      };
      
      print('DEBUG MEAL_SERVICE: Sending updateMeal request for $mealId');
      print('DEBUG MEAL_SERVICE: Body data: $bodyData');
      
      final response = await _apiService.makeRequest(
        'PUT',
        '${ApiConfig.mealSave}/$mealId',
        body: bodyData,
      );
      
      print('DEBUG MEAL_SERVICE: Update response status code: ${response.statusCode}');
      print('DEBUG MEAL_SERVICE: Update response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('DEBUG MEAL_SERVICE: Update success response: $data');
        return {
          'success': true,
          'message': 'Meal updated successfully',
          'meal': data['meal'],
        };
      } else {
        final error = jsonDecode(response.body);
        print('DEBUG MEAL_SERVICE: Update error response: $error');
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to update meal',
          'errors': error['errors'],
        };
      }
    } catch (e) {
      print('DEBUG MEAL_SERVICE: Update exception: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
  
  // Get meal history
  Future<Map<String, dynamic>> getMealHistory({
    int limit = 50,
    int offset = 0,
    String? startDate,
    String? endDate,
  }) async {
    try {
      String url = ApiConfig.mealHistory;
      url += '?limit=$limit&offset=$offset&timezone=Asia/Bangkok';
      
      if (startDate != null) {
        url += '&startDate=$startDate';
      }
      if (endDate != null) {
        url += '&endDate=$endDate';
      }
      
      print('DEBUG MEAL_SERVICE: getMealHistory URL: $url');
      print('DEBUG MEAL_SERVICE: startDate: $startDate');
      print('DEBUG MEAL_SERVICE: endDate: $endDate');
      
      final response = await _apiService.makeRequest('GET', url);
      
      print('DEBUG MEAL_SERVICE: getMealHistory status: ${response.statusCode}');
      print('DEBUG MEAL_SERVICE: getMealHistory response: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('DEBUG MEAL_SERVICE: Meals count: ${data['meals']?.length ?? 0}');
        return {
          'success': true,
          'meals': data['meals'] ?? [],
          'total': data['total'] ?? 0,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch meals',
          'meals': [],
        };
      }
    } catch (e) {
      print('DEBUG MEAL_SERVICE: getMealHistory exception: $e');
      return {
        'success': false,
        'message': 'Error: $e',
        'meals': [],
      };
    }
  }
  
  // Get single meal
  Future<Map<String, dynamic>> getMeal(String mealId) async {
    try {
      final response = await _apiService.makeRequest(
        'GET',
        '${ApiConfig.mealDetail}/$mealId',
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'meal': data['meal'],
        };
      } else {
        return {
          'success': false,
          'message': 'Meal not found',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
  
  // Delete meal
  Future<Map<String, dynamic>> deleteMeal(String mealId) async {
    try {
      final response = await _apiService.makeRequest(
        'DELETE',
        '${ApiConfig.mealDelete}/$mealId',
      );
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Meal deleted',
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to delete meal',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
}
