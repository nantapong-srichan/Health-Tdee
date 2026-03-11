// ข้อมูลสารอาหารต่อ 100 กรัม
// ผลลัพธ์การคำนวณสารอาหาร
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
  final String description; // คำอธิบายเพิ่มเติม

  const NutritionInfo({
    required this.foodName,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.sodium,
    required this.description,
  });
}

class NutritionDatabase {
  static const Map<String, NutritionInfo> database = {
    'แกงเขียวหวานไก่': NutritionInfo(
      foodName: 'แกงเขียวหวานไก่',
      calories: 140,
      protein: 5.1, 
      fat: 11.8,    
      carbs: 5.4,
      sodium: 450,
      description: 'แกงเขียวหวานไก่ อาหารไทยรสจัดจ้าน สารอาหารต่อ 100 กรัม ตามมาตรฐานกรมอนามัย',
    ),
    'แกงจืดมะระยัดไส้หมูสับ': NutritionInfo(
      foodName: 'แกงจืดมะระยัดไส้หมูสับ',
      calories: 85,
      protein: 7.4,  
      fat: 4.8,
      carbs: 3.1,
      sodium: 320,
      description: 'แกงจืดมะระยัดไส้หมูสับ ให้คุณค่าทางโภชนาการสูง พลังงานต่ำต่อหน่วยน้ำหนัก',
    ),
    'ไข่ดาว': NutritionInfo(
      foodName: 'ไข่ดาว',
      calories: 327,
      protein: 12.8,
      fat: 15.7,
      carbs: 0.8,
      sodium: 140,
      description: 'ไข่ดาวทอดน้ำมัน ข้อมูลต่อ 100 กรัม (ประมาณ 2 ฟองเบอร์ 2)',
    ),
    'ก๋วยจั๊บ': NutritionInfo(
      foodName: 'ก๋วยจั๊บ',
      calories: 115,
      protein: 4.8,
      fat: 3.2,
      carbs: 16.8,
      sodium: 482,
      description: 'ก๋วยจั๊บน้ำข้น สารอาหารเฉลี่ยรวมเส้น เครื่องใน และน้ำซุป',
    ),
    'กุ้งเผา': NutritionInfo(
      foodName: 'กุ้งเผา',
      calories: 92,
      protein: 20.4,
      fat: 1.2,      
      carbs: 0.0,
      sodium: 110,
      description: 'กุ้งก้ามกรามเผาสด โปรตีนสูง ไขมันต่ำ (เฉพาะส่วนเนื้อ)',
    ),
    'กุ้งอบวุ้นเส้น': NutritionInfo(
      foodName: 'กุ้งอบวุ้นเส้น',
      calories: 165,
      protein: 9.2, 
      fat: 5.4,      
      carbs: 20.0,
      sodium: 450,
      description: 'กุ้งอบวุ้นเส้น สารอาหารเฉลี่ยต่อ 100 กรัม (รวมเครื่องปรุง)',
    ),
    'แกงจืด': NutritionInfo(
      foodName: 'แกงจืด',
      calories: 45,
      protein: 3.8,
      fat: 2.5,
      carbs: 1.8,
      sodium: 280,
      description: 'แกงจืดผักรวม สารอาหารเฉลี่ยต่อ 100 กรัม (เน้นน้ำซุป)',
    ),
    'ไก่ทอด': NutritionInfo(
      foodName: 'ไก่ทอด',
      calories: 275,
      protein: 18.5, 
      fat: 19.0,     
      carbs: 7.5,
      sodium: 320,     
      description: 'ไก่ทอดกรอบ ข้อมูลรวมแป้งชุบทอดและน้ำมันที่ดูดซับ',
    ),
    'ไก่ย่าง': NutritionInfo(
      foodName: 'ไก่ย่าง',
      calories: 175,
      protein: 22.0, 
      fat: 8.5,      
      carbs: 1.2,
      sodium: 75,
      description: 'ไก่ย่าง สารอาหารหลักจากเนื้อและหนังไก่',
    ),
    'ขนมจีนน้ำยาไก่': NutritionInfo(
      foodName: 'ขนมจีนน้ำยาไก่',
      calories: 105,
      protein: 4.2,
      fat: 4.5,
      carbs: 12.0,
      sodium: 410,   
      description: 'ขนมจีนน้ำยากะทิ สารอาหารเฉลี่ยต่อ 100 กรัม',
    ),
    'ข้าวคลุกกะปิ': NutritionInfo(
      foodName: 'ข้าวคลุกกะปิ',
      calories: 210,
      protein: 6.8,
      fat: 7.2,
      carbs: 29.5,
      sodium: 550,   
      description: 'ข้าวคลุกกะปิ รวมเครื่องเคียงตามสัดส่วนมาตรฐาน',
    ),
    'ข้าวหมูทอดกระเทียม': NutritionInfo(
      foodName: 'ข้าวหมูทอดกระเทียม',
      calories: 265,
      protein: 10.5,
      fat: 11.0,
      carbs: 31.0,
      sodium: 460,   
      description: 'ข้าวหมูทอดกระเทียม สารอาหารเฉลี่ยต่อ 100 กรัม',
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
          sodium: 0,
        );
      }

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