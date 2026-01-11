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
      final response = await _apiService.makeRequest(
        'POST',
        ApiConfig.mealSave,
        body: {
          'foodName': foodName,
          'nutrition': {
            'calories': calories,
            'protein': protein,
            'carbs': carbs,
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
        },
      );
      
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'Meal saved successfully',
          'mealId': data['meal']?['_id'],
          'meal': data['meal'],
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to save meal',
        };
      }
    } catch (e) {
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
      url += '?limit=$limit&offset=$offset';
      
      if (startDate != null) {
        url += '&startDate=$startDate';
      }
      if (endDate != null) {
        url += '&endDate=$endDate';
      }
      
      final response = await _apiService.makeRequest('GET', url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
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
  
  // Update meal
  Future<Map<String, dynamic>> updateMeal({
    required String mealId,
    String? foodName,
    Map<String, dynamic>? nutrition,
    double? estimatedWeight,
    double? confidence,
    String? mealType,
    DateTime? mealTime,
    String? notes,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (foodName != null) body['foodName'] = foodName;
      if (nutrition != null) body['nutrition'] = nutrition;
      if (estimatedWeight != null) body['estimatedWeight'] = estimatedWeight;
      if (confidence != null) body['confidence'] = confidence;
      if (mealType != null) body['mealType'] = mealType;
      if (mealTime != null) body['mealTime'] = mealTime.toIso8601String();
      if (notes != null) body['notes'] = notes;
      
      final response = await _apiService.makeRequest(
        'PUT',
        '${ApiConfig.mealUpdate}/$mealId',
        body: body,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'Meal updated',
          'meal': data['meal'],
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to update meal',
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
