/// BMR (Basal Metabolic Rate) Calculator
/// 
/// ใช้สูตร Mifflin-St Jeor ซึ่งแม่นยำที่สุดในปัจจุบัน
/// 
/// สำหรับผู้ชาย:
/// BMR = (10 × น้ำหนัก kg) + (6.25 × ส่วนสูง cm) - (5 × อายุ ปี) + 5
/// 
/// สำหรับผู้หญิง:
/// BMR = (10 × น้ำหนัก kg) + (6.25 × ส่วนสูง cm) - (5 × อายุ ปี) - 161

class BMRCalculator {
  /// คำนวณค่า BMR (Basal Metabolic Rate)
  /// 
  /// [gender] - เพศ: 'male' หรือ 'female'
  /// [weight] - น้ำหนัก (กิโลกรัม)
  /// [height] - ส่วนสูง (เซนติเมตร)
  /// [age] - อายุ (ปี)
  /// 
  /// Return: ค่า BMR (kcal/day) ปัดเศษเป็นทศนิยม 2 ตำแหน่ง
  static double calculate({
    required String gender,
    required double weight,
    required double height,
    required int age,
  }) {
    double bmr;

    if (gender.toLowerCase() == 'male') {
      // สูตรสำหรับผู้ชาย
      bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5;
    } else {
      // สูตรสำหรับผู้หญิง
      bmr = (10 * weight) + (6.25 * height) - (5 * age) - 161;
    }

    // ปัดเศษเป็นทศนิยม 2 ตำแหน่ง
    return double.parse(bmr.toStringAsFixed(2));
  }

  /// คำนวณ TDEE (Total Daily Energy Expenditure)
  /// โดยอิงจาก BMR และ activity level
  /// 
  /// Activity Multipliers:
  /// - sedentary: 1.2 (ไม่ออกกำลัง)
  /// - light: 1.375 (ออกกำลังน้อย 1-3 วันต่อสัปดาห์)
  /// - moderate: 1.55 (ออกกำลังปานกลาง 3-5 วันต่อสัปดาห์)
  /// - active: 1.725 (ออกกำลังสูง 6-7 วันต่อสัปดาห์)
  /// - veryActive: 1.9 (ออกกำลังมากเลย หรือเป็นนักกีฬา)
  static double calculateTDEE({
    required double bmr,
    required String activityLevel,
  }) {
    double multiplier;

    switch (activityLevel.toLowerCase()) {
      case 'sedentary':
        multiplier = 1.2;
        break;
      case 'light':
        multiplier = 1.375;
        break;
      case 'moderate':
        multiplier = 1.55;
        break;
      case 'active':
        multiplier = 1.725;
        break;
      case 'veryactive':
        multiplier = 1.9;
        break;
      default:
        multiplier = 1.55; // default moderate
    }

    double tdee = bmr * multiplier;
    return double.parse(tdee.toStringAsFixed(2));
  }

  /// ตรวจสอบว่าข้อมูลเพียงพอในการคำนวณ BMR
  static bool isValidInput({
    required String? gender,
    required double? weight,
    required double? height,
    required int? age,
  }) {
    return gender != null &&
        gender.isNotEmpty &&
        weight != null &&
        weight > 0 &&
        height != null &&
        height > 0 &&
        age != null &&
        age > 0;
  }

  /// ได้ข้อมูล BMR ที่แสดงให้ผู้ใช้อ่าน พร้อม interpretation
  static Map<String, dynamic> getBMRInfo({
    required double bmr,
    required double tdee,
  }) {
    return {
      'bmr': bmr,
      'tdee': tdee,
      'description': 'BMR คือจำนวนแคลอรี่ที่ร่างกายของคุณใช้ในการทำงานพื้นฐาน',
      'interpretation': 'TDEE คือจำนวนแคลอรี่ทั้งหมดที่คุณต้องการในแต่ละวัน',
    };
  }
}
