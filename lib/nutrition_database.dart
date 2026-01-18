// ข้อมูลสารอาหารต่อ 100 กรัม
// ผลลัพธ์การคำนวณสารอาหาร
class CalculationResult {
  final double calories;
  final double protein;
  final double fat;
  final double carbs;

  const CalculationResult({
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
  });
}

class NutritionInfo {
  final String foodName;
  final double calories;     // kcal
  final double protein;      // g
  final double fat;         // g
  final double carbs;       // g
  final String description; // คำอธิบายเพิ่มเติม

  const NutritionInfo({
    required this.foodName,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.description,
  });
}

class NutritionDatabase {
  static const Map<String, NutritionInfo> database = {
    'แกงเขียวหวานไก่': NutritionInfo(
      foodName: 'แกงเขียวหวานไก่',
      calories: 250,
      protein: 18.5,
      fat: 15.8,
      carbs: 10.2,
      description: 'แกงเขียวหวานไก่ อาหารไทยรสจัดจ้าน ทำจากพริกแกงเขียวหวาน กะทิ และเนื้อไก่',
    ),
    'แกงจืดมะระยัดไส้หมูสับ': NutritionInfo(
      foodName: 'แกงจืดมะระยัดไส้หมูสับ',
      calories: 180,
      protein: 15.2,
      fat: 8.5,
      carbs: 12.3,
      description: 'แกงจืดมะระยัดไส้หมูสับ เมนูอาหารไทยที่ให้คุณค่าทางโภชนาการสูง มีรสชาติกลมกล่อม',
    ),
    'ไข่ดาว': NutritionInfo(
      foodName: 'ไข่ดาว',
      calories: 155,
      protein: 6.5,
      fat: 12.0,
      carbs: 0.5,
      description: 'ไข่ดาว หรือไข่เจียว เมนูอาหารพื้นฐานที่อุดมไปด้วยโปรตีน',
    ),
  };

    // ข้อมูลสารอาหารสำหรับปริมาณ 100 กรัม
  static NutritionInfo? getNutritionInfo(String foodName) {
    // ทำให้การค้นหาไม่ต้องตรงตัวอักษรทั้งหมด
    final normalizedSearch = foodName.trim().toLowerCase();
    
    // หาเมนูที่ใกล้เคียงที่สุด
    String? closestMatch;
    int maxSimilarity = 0;

    for (var key in database.keys) {
      final normalizedKey = key.toLowerCase();
      int similarity = _calculateSimilarity(normalizedSearch, normalizedKey);
      if (similarity > maxSimilarity) {
        maxSimilarity = similarity;
        closestMatch = key;
      }
    }

    // ถ้าความใกล้เคียงมากพอ (มากกว่า 50%) ให้คืนค่าข้อมูลสารอาหาร
    if (closestMatch != null && maxSimilarity > 50) {
      return database[closestMatch];
    }
    return null;
  }

  // คำนวณสารอาหารตามน้ำหนักจริง
  static CalculationResult calculateNutrition(String foodName, double weightInGrams) {
    // หาข้อมูลสารอาหารพื้นฐาน (ต่อ 100 กรัม)
    final info = getNutritionInfo(foodName);
    
    // ถ้าไม่พบข้อมูล ให้คืนค่าเป็น 0
    if (info == null) {
      return CalculationResult(
        calories: 0,
        protein: 0,
        fat: 0,
        carbs: 0,
      );
    }

    // คำนวณตามสัดส่วนน้ำหนัก
    final ratio = weightInGrams / 100.0;
    return CalculationResult(
      calories: info.calories * ratio,
      protein: info.protein * ratio,
      fat: info.fat * ratio,
      carbs: info.carbs * ratio,
    );
  }

  // คำนวณความคล้ายคลึงระหว่างข้อความ (อย่างง่าย)
  static int _calculateSimilarity(String s1, String s2) {
    if (s1.isEmpty || s2.isEmpty) return 0;
    if (s1 == s2) return 100;
    
    // นับจำนวนตัวอักษรที่เหมือนกัน
    int matches = 0;
    int length = s1.length < s2.length ? s1.length : s2.length;
    
    for (int i = 0; i < length; i++) {
      if (s1[i] == s2[i]) matches++;
    }
    
    return (matches * 100 ~/ length);
  }
}