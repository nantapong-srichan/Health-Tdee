// ข้อมูลสารอาหารต่อ 100 กรัม
// ผลลัพธ์การคำนวณสารอาหาร
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

const String API_BASE_URL = 'http://10.0.2.2:5000/api';

class CalculationResult {
  final double calories;
  final double protein;
  final double fat;
  final double carbs;
  final double sodium;

  const CalculationResult({
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.sodium,
  });
}

class NutritionInfo {
  final String foodName;
  final double calories;     // kcal
  final double protein;      // g
  final double fat;         // g
  final double carbs;       // g
  final double sodium;      // mg

  const NutritionInfo({
    required this.foodName,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.sodium,
  });

  // Factory constructor for JSON parsing
  factory NutritionInfo.fromJson(Map<String, dynamic> json) {
    return NutritionInfo(
      foodName: json['foodName'] ?? '',
      calories: (json['nutrition']['calories'] as num).toDouble(),
      protein: (json['nutrition']['protein'] as num).toDouble(),
      fat: (json['nutrition']['fat'] as num).toDouble(),
      carbs: (json['nutrition']['carbohydrates'] as num).toDouble(),
      sodium: (json['nutrition']['sodium'] as num).toDouble(),
    );
  }
}

class NutritionDatabase {
  // ค้นหาข้อมูลสารอาหารจาก API
  static Future<NutritionInfo?> getNutritionInfo(String foodName) async {
    try {
      print('DEBUG: Fetching nutrition for: $foodName');
      // ลองค้นหาด้วยชื่อเมนูที่แน่นอนก่อน (encode URL properly)
      final encodedName = Uri.encodeComponent(foodName);
      print('DEBUG: Encoded name: $encodedName');
      final url = '$API_BASE_URL/foods/$encodedName';
      print('DEBUG: Full URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('API timeout'),
      );

      print('DEBUG: Response status code: ${response.statusCode}');
      print('DEBUG: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('DEBUG: Decoded data: $data');
        if (data['success'] == true) {
          final info = NutritionInfo.fromJson(data['data']);
          print('DEBUG: Successfully parsed nutrition info: ${info.foodName}');
          return info;
        }
      }

      // ถ้าไม่พบ ลองค้นหาแบบ fuzzy matching จากรายการอาหารทั้งหมด
      print('DEBUG: Exact match failed, trying fuzzy match...');
      return _searchFuzzyMatch(foodName);
    } catch (e) {
      print('ERROR fetching nutrition info: $e');
      return null;
    }
  }

  // ค้นหาแบบ fuzzy matching จากทั้งหมด
  static Future<NutritionInfo?> _searchFuzzyMatch(String foodName) async {
    try {
      final response = await http.get(
        Uri.parse('$API_BASE_URL/foods'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('API timeout'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] is List) {
          final foods = data['data'] as List;
          
          // ค้นหาเมนูที่ใกล้เคียงที่สุด
          NutritionInfo? closestMatch;
          int maxSimilarity = 0;
          final normalizedSearch = foodName.trim().toLowerCase();

          for (var foodData in foods) {
            final foodNameKey = (foodData['foodName'] ?? '').toString().toLowerCase();
            int similarity = _calculateSimilarity(normalizedSearch, foodNameKey);
            
            if (similarity > maxSimilarity) {
              maxSimilarity = similarity;
              closestMatch = NutritionInfo.fromJson(foodData);
            }
          }

          // คืนค่าถ้าความใกล้เคียงมากกว่า 50%
          if (closestMatch != null && maxSimilarity > 50) {
            return closestMatch;
          }
        }
      }
      return null;
    } catch (e) {
      print('Error searching foods: $e');
      return null;
    }
  }

  // คำนวณสารอาหารตามน้ำหนักจริง
  static CalculationResult calculateNutrition(NutritionInfo info, double weightInGrams) {
    // คำนวณตามสัดส่วนน้ำหนัก
    final ratio = weightInGrams / 100.0;
    return CalculationResult(
      calories: info.calories * ratio,
      protein: info.protein * ratio,
      fat: info.fat * ratio,
      carbs: info.carbs * ratio,
      sodium: info.sodium * ratio,
    );
  }

  // คำนวณความคล้ายคลึงระหว่างข้อความ
  static int _calculateSimilarity(String s1, String s2) {
    if (s1.isEmpty || s2.isEmpty) return 0;
    if (s1 == s2) return 100;
    
    int matches = 0;
    int length = s1.length < s2.length ? s1.length : s2.length;
    
    for (int i = 0; i < length; i++) {
      if (s1[i] == s2[i]) matches++;
    }
    
    return (matches * 100 ~/ length);
  }
}