// lib/food_database.dart

// (คลาสนี้ไม่ต้องแก้)
class NutrientInfo {
  final double calories; // แคลอรี่ (kcal) ต่อ 100 กรัม
  final double protein;  // โปรตีน (g) ต่อ 100 กรัม
  final double fat;      // ไขมัน (g) ต่อ 100 กรัม
  final double carbs;    // คาร์โบไฮเดรต (g) ต่อ 100 กรัม

  NutrientInfo({
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
  });
}

//
// --- ฐานข้อมูลโภชนาการ (ต่อ 100 กรัม) ---
// (หมายเหตุ: นี่คือข้อมูลโดยประมาณ คุณสามารถแก้ไขตัวเลขได้เอง)
//
final Map<String, NutrientInfo> foodDatabase = {

  

  'แกงจืดมะระยัดไส้หมูสับ': NutrientInfo(
    calories: 40,  // (ประมาณ)
    protein: 3,    // (ประมาณ)
    fat: 2,        // (ประมาณ)
    carbs: 3,      // (ประมาณ)
  ),

  'แกงเขียวหวานไก่': NutrientInfo(
    calories: 120, // (ประมาณ)
    protein: 10,   // (ประมาณ)
    fat: 7,        // (ประมาณ)
    carbs: 5,      // (ประมาณ)
  ),
  'ไข่ดาว': NutrientInfo(
    calories: 196, // (ประมาณ)
    protein: 13.6, // (ประมาณ)
    fat: 15.3,     // (ประมาณ)
    carbs: 0.9,      // (ประมาณ)
    ),

};