// Food Category-based Recommendation System with Smart Nutrient Analysis
// ระบบคำแนะนำอาหารแบบแบ่งหมวดหมู่ + วิเคราะห์สารอาหารอัจฉริยะ

/// ข้อมูลหมวดหมู่อาหาร
class FoodCategory {
  final String categoryId;
  final String categoryNameTh;
  final String baseAdvice;
  final List<String> baseWarnings;

  const FoodCategory({
    required this.categoryId,
    required this.categoryNameTh,
    required this.baseAdvice,
    required this.baseWarnings,
  });
}

/// ข้อมูลเนื่องที่ใช้ในการวิเคราะห์
class NutrientData {
  final double sodiumMg;
  final double carbsG;
  final double fiberG;
  final double fatG;
  final double proteinG;

  NutrientData({
    required this.sodiumMg,
    required this.carbsG,
    required this.fiberG,
    required this.fatG,
    required this.proteinG,
  });
}

/// หมวดหมู่อาหารทั้งหมด
class FoodCategoryDatabase {
  static const Map<String, FoodCategory> categories = {
    'soup_noodles': FoodCategory(
      categoryId: 'soup_noodles',
      categoryNameTh: 'น้ำซุป/เมนูเส้น',
      baseAdvice: 'ควรลดปริมาณน้ำซุป/น้ำหวาน และหลีกเลี่ยงการซดจนหมด',
      baseWarnings: [
        'น้ำซุปมีเกลือและ MSG สูง',
        'คาร์โบไฮเดรตจากเส้นแป้ง',
        'โซเดียมจากน้ำแกง/ปลาเค็ม',
      ],
    ),
    'fried_oily': FoodCategory(
      categoryId: 'fried_oily',
      categoryNameTh: 'อาหารทอด/ไขมันสูง',
      baseAdvice: 'ควรซับน้ำมันออก หรือปลดหนังเพื่อลดไขมัน',
      baseWarnings: [
        'ไขมันอิ่มตัวสูง',
        'แป้งชุบมีคาร์โบไฮเดรต',
        'ไม่ควรรับประทานบ่อย',
      ],
    ),
    'curry_coconut': FoodCategory(
      categoryId: 'curry_coconut',
      categoryNameTh: 'แกงกะทิ',
      baseAdvice: 'ลดน้ำกะทิ เพิ่มผักใบเขียว',
      baseWarnings: [
        ' น้ำกะทิมีไขมันสูง',
        ' เกลือและ MSG จากน้ำพริก',
        ' ความหวานจากการปรุง',
      ],
    ),
    'clear_soup': FoodCategory(
      categoryId: 'clear_soup',
      categoryNameTh: 'แกงจืด/ซุปใส',
      baseAdvice: 'อาหารที่เหมาะสุดสำหรับการควบคุมโรค',
      baseWarnings: [
        ' ใช้เกลือในการปรุง',
        ' ส่วนเนื้อสัตว์มีไขมัน',
      ],
    ),
    'grilled_protein': FoodCategory(
      categoryId: 'grilled_protein',
      categoryNameTh: 'ย่าง/ต้มเนื้อสัตว์',
      baseAdvice: 'โปรตีนสูง ไขมันต่ำ เหมาะสำหรับส่วนใหญ่',
      baseWarnings: [
        ' ปลดหนักออกเพื่อลดไขมัน',
        ' ใช้เกลือในการปรุง',
      ],
    ),
    'starch_high_carb': FoodCategory(
      categoryId: 'starch_high_carb',
      categoryNameTh: 'ข้าว/คาร์บสูง',
      baseAdvice: 'ลดปริมาณ เลือกข้าวสาลี/ข้าวกล้อง',
      baseWarnings: [
        ' คาร์โบไฮเดรตสูง',
        ' กระทบต่อระดับน้ำตาล',
      ],
    ),
    'fish_seafood': FoodCategory(
      categoryId: 'fish_seafood',
      categoryNameTh: 'ปลา/อาหารทะเล',
      baseAdvice: 'โปรตีนดี โอเมก้า 3 สูง',
      baseWarnings: [
        ' ปลาเค็มมีเกลือสูง',
        ' วุ้นเส้นมีคาร์บ',
      ],
    ),
  };

  /// ค้นหาหมวดหมู่ของอาหารตามชื่อ
  static String? getFoodCategory(String foodName) {
    final categoryMap = {
      'ก๋วยจั๊บ': 'soup_noodles',
      'ขนมจีนน้ำยาไก่': 'soup_noodles',
      'กุ้งเผา': 'grilled_protein',
      'ไก่ย่าง': 'grilled_protein',
      'ไข่ดาว': 'grilled_protein',
      'ไก่ทอด': 'fried_oily',
      'ข้าวหมูทอดกระเทียม': 'fried_oily',
      'แกงเขียวหวานไก่': 'curry_coconut',
      'แกงจืดมะระยัดไส้หมูสับ': 'clear_soup',
      'แกงจืด': 'clear_soup',
      'กุ้งอบวุ้นเส้น': 'fish_seafood',
      'ข้าวคลุกกะปิ': 'starch_high_carb',
    };
    return categoryMap[foodName];
  }

  /// ดึงข้อมูลหมวดหมู่
  static FoodCategory? getCategory(String categoryId) {
    return categories[categoryId];
  }
}

/// ฟังก์ชันสร้างคำแนะนำอัจฉริยะตามข้อมูลสารอาหาร
class SmartAdviceGenerator {
  /// สร้างคำแนะนำแบบสมบูรณ์สำหรับอาหาร
  /// Parameters:
  ///   - foodName: ชื่ออาหาร
  ///   - categoryId: ID ของหมวดหมู่อาหาร
  ///   - nutrients: ข้อมูลสารอาหาร
  ///   - userConditions: รายชื่อโรคที่ผู้ใช้มี (เช่น ['diabetes', 'hypertension'])
  ///
  /// Returns:
  ///   - SmartAdviceResult ที่มี suitable, warning, notes สำหรับแต่ละโรค
  static Map<String, SmartAdviceResult> generateAdviceForConditions({
    required String foodName,
    required String categoryId,
    required NutrientData nutrients,
    required List<String> userConditions,
  }) {
    final results = <String, SmartAdviceResult>{};

    final category = FoodCategoryDatabase.getCategory(categoryId);
    if (category == null) {
      return results;
    }

    for (final condition in userConditions) {
      results[condition] = _generateAdviceForCondition(
        foodName: foodName,
        category: category,
        nutrients: nutrients,
        condition: condition,
      );
    }

    return results;
  }

  /// สร้างคำแนะนำสำหรับโรคเดียว
  static SmartAdviceResult _generateAdviceForCondition({
    required String foodName,
    required FoodCategory category,
    required NutrientData nutrients,
    required String condition,
  }) {
    if (condition == 'diabetes') {
      return _generateDiabetesAdvice(
        category: category,
        nutrients: nutrients,
      );
    } else if (condition == 'hypertension') {
      return _generateHypertensionAdvice(
        category: category,
        nutrients: nutrients,
      );
    }

    return SmartAdviceResult(
      suitable: 'ไม่มีข้อมูล',
      warnings: [],
      notes: [],
    );
  }

  /// สร้างคำแนะนำสำหรับผู้ป่วยเบาหวาน
  static SmartAdviceResult _generateDiabetesAdvice({
    required FoodCategory category,
    required NutrientData nutrients,
  }) {
    final warnings = <String>[];
    final notes = <String>[];

    // วิเคราะห์คาร์โบไฮเดรต (สำหรับเบาหวาน)
    bool carbsIsHigh = false;
    if (nutrients.carbsG > 50) {
      warnings.add('🔴 คาร์โบไฮเดรตสูงมาก (${nutrients.carbsG.toStringAsFixed(1)}g) - อันตราย');
      notes.add('ลดปริมาณการรับประทานอย่างมาก');
      carbsIsHigh = true;
    } else if (nutrients.carbsG > 30) {
      warnings.add('🟠 คาร์โบไฮเดรตปานกลาง (${nutrients.carbsG.toStringAsFixed(1)}g)');
      notes.add('ควรดูแลปริมาณให้เข้มงวด');
      carbsIsHigh = true;
    } else {
      notes.add('✅ คาร์โบไฮเดรตต่ำ (${nutrients.carbsG.toStringAsFixed(1)}g) - ปลอดภัย');
    }

    // วิเคราะห์ไขมัน (สำหรับเบาหวาน)
    bool fatIsHigh = false;
    if (nutrients.fatG > 20) {
      warnings.add('🔴 ไขมันสูงมาก (${nutrients.fatG.toStringAsFixed(1)}g) - อันตรายต่อหัวใจ');
      notes.add('ลดปริมาณหรือหลีกเลี่ยงเป็นประจำ');
      fatIsHigh = true;
    } else if (nutrients.fatG > 15) {
      warnings.add('🟠 ไขมันปานกลาง (${nutrients.fatG.toStringAsFixed(1)}g)');
      notes.add('ควรระมัดระวังปริมาณ');
      fatIsHigh = true;
    } else {
      notes.add('✅ ไขมันต่ำ (${nutrients.fatG.toStringAsFixed(1)}g) - ดี');
    }

    // วิเคราะห์เส้นใยอาหาร
    if (nutrients.fiberG < 3) {
      notes.add('เพิ่มเส้นใยอาหาร: ผักใบเขียว ธัญพืช ');
    } else {
      notes.add('✅ เส้นใยอาหารดี (${nutrients.fiberG.toStringAsFixed(1)}g)');
    }

    // สถานะรวม
    String suitable;
    if (carbsIsHigh && fatIsHigh) {
      suitable = 'ไม่เหมาะสม - ทั้งคาร์บและไขมันสูง';
    } else if (carbsIsHigh) {
      suitable = 'ควรระวัง - คาร์บสูง';
    } else if (fatIsHigh) {
      suitable = 'ควรระวัง - ไขมันสูง';
    } else if (category.categoryId == 'clear_soup') {
      suitable = 'เหมาะสมอย่างยิ่ง - คาร์บและไขมันต่ำ';
    } else if (category.categoryId == 'grilled_protein') {
      suitable = 'เหมาะสม - โปรตีนสูง';
    } else {
      suitable = 'เหมาะสมปานกลาง';
    }

    // เพิ่มคำแนะนำจากหมวดหมู่
    notes.add('• ${category.baseAdvice}');

    return SmartAdviceResult(
      suitable: suitable,
      warnings: warnings,
      notes: notes,
    );
  }

  /// สร้างคำแนะนำสำหรับผู้ป่วยความดันสูง
  static SmartAdviceResult _generateHypertensionAdvice({
    required FoodCategory category,
    required NutrientData nutrients,
  }) {
    final warnings = <String>[];
    final notes = <String>[];

    // วิเคราะห์โซเดียม (สำคัญที่สุดสำหรับความดัน)
    bool sodiumIsHigh = false;
    if (nutrients.sodiumMg > 1000) {
      warnings.add('🔴 โซเดียมอันตราย (${nutrients.sodiumMg.toStringAsFixed(0)}mg) - เสี่ยงเพิ่มความดัน');
      notes.add(' หลีกเลี่ยง - อาหารนี้มีเกลือสูงเกินไป');
      sodiumIsHigh = true;
    } else if (nutrients.sodiumMg > 600) {
      warnings.add('🟠 โซเดียมสูง (${nutrients.sodiumMg.toStringAsFixed(0)}mg)');
      notes.add(' ลดปริมาณการรับประทาน');
      notes.add(' ล้างน้ำซุปออก หรือทำด้วยตัวเองโดยลดเกลือ');
      sodiumIsHigh = true;
    } else {
      notes.add('✅ โซเดียมปลอดภัย (${nutrients.sodiumMg.toStringAsFixed(0)}mg)');
    }

    // วิเคราะห์ไขมัน (ส่งผลต่อความดั้น)
    bool fatIsHigh = false;
    if (nutrients.fatG > 20) {
      warnings.add('🔴 ไขมันสูงมาก (${nutrients.fatG.toStringAsFixed(1)}g) - เสี่ยงต่อหัวใจและความดัน');
      notes.add(' ลดปริมาณหรือปลดหนัง ซับน้ำมัน');
      fatIsHigh = true;
    } else if (nutrients.fatG > 15) {
      warnings.add('🟠 ไขมันปานกลาง (${nutrients.fatG.toStringAsFixed(1)}g)');
      notes.add(' ควรระมัดระวัง - อาจเพิ่มความเสี่ยงต่อหัวใจ');
      fatIsHigh = true;
    } else {
      notes.add('✅ ไขมันต่ำ (${nutrients.fatG.toStringAsFixed(1)}g) - ดี');
    }

    // สถานะรวม
    String suitable;
    if (sodiumIsHigh && fatIsHigh) {
      suitable = 'ไม่เหมาะสม - โซเดียมและไขมันสูง';
    } else if (sodiumIsHigh) {
      suitable = 'ไม่เหมาะสม - โซเดียมสูงเกินไป';
    } else if (fatIsHigh) {
      suitable = 'ควรระวัง - ไขมันสูง';
    } else if (category.categoryId == 'clear_soup') {
      suitable = 'เหมาะสมอย่างยิ่ง - โซเดียมและไขมันต่ำ';
    } else if (category.categoryId == 'grilled_protein') {
      suitable = 'เหมาะสม - ปลดหนังให้ลดไขมัน';
    } else {
      suitable = 'เหมาะสมปานกลาง';
    }

    // เพิ่มคำแนะนำจากหมวดหมู่
    notes.add('• ${category.baseAdvice}');

    return SmartAdviceResult(
      suitable: suitable,
      warnings: warnings,
      notes: notes,
    );
  }
}

/// ผลลัพธ์การสร้างคำแนะนำ
class SmartAdviceResult {
  final String suitable;
  final List<String> warnings;
  final List<String> notes;

  SmartAdviceResult({
    required this.suitable,
    required this.warnings,
    required this.notes,
  });
}
