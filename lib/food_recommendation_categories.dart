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
    'stir_fried': FoodCategory(
      categoryId: 'stir_fried',
      categoryNameTh: 'ผัด/อาหารคลุกเคล้า',
      baseAdvice: 'ลดน้ำมันในการปรุง เพิ่มผักใบเขียว',
      baseWarnings: [
        ' ใช้น้ำมันเยอะในการทำ',
        ' โซเดียมจากน้ำปลา/ซีอิ๊ว',
        ' ควรหลีกเลี่ยงขนมหนมมาก',
      ],
    ),
    'salad': FoodCategory(
      categoryId: 'salad',
      categoryNameTh: 'ยำ/สลัด',
      baseAdvice: 'อาหารที่เหมาะสำหรับส่วนใหญ่ แต่เกลือเยอะ',
      baseWarnings: [
        ' เกลือและ MSG สูง',
        ' น้ำพริกมีไขมัน',
        ' ใช้ปลาเค็มในการปรุง',
      ],
    ),
    'other': FoodCategory(
      categoryId: 'other',
      categoryNameTh: 'อื่นๆ',
      baseAdvice: 'ตรวจสอบสารอาหารก่อนรับประทาน',
      baseWarnings: [
        ' โปรดดูข้อมูลโภคนาแต่ละรายการ',
        ' อาจมีความเสี่ยงสูงตามประเภทของอาหาร',
      ],
    ),
  };

  /// ค้นหาหมวดหมู่ของอาหารตามชื่อ
  static String? getFoodCategory(String foodName) {
    final categoryMap = {
      'ก๋วยจั๊บ': 'soup_noodles',
      'ขนมจีนน้ำยาไก่': 'soup_noodles',
      'ก๋วยเตี๋ยวเรือ': 'soup_noodles',
      'ก๋วยเตี๋ยวคั่วไก่': 'soup_noodles',
      'ขนมจีนน้ำเงี้ยว': 'soup_noodles',
      'ขนมจีน': 'soup_noodles',
      'ข้าวซอย': 'soup_noodles',
      'ไข่ดาว': 'fried_oily',
      'ไก่ทอด': 'fried_oily',
      'ข้าวหมูทอดกระเทียม': 'fried_oily',
      'ปอเปี๊ยะทอด': 'fried_oily',
      'ไส้กรอกอีสาน': 'fried_oily',
      'ปลาหมึกทอด': 'fried_oily',
      'เกี๊ยวทอด': 'fried_oily',
      'กั้งทอดกระเทียม': 'fried_oily',
      'เต้าหู้ทอด': 'fried_oily',
      'ผัดพริกสด': 'fried_oily',
      'ปูนิ่มทอดกระเทียม': 'fried_oily',
      'กะหล่ำปลีผัดน้ำปลา': 'fried_oily',
      'หอยทอด': 'fried_oily',
      'หอยจ๊อ': 'fried_oily',
      'ทอดมันกุ้ง': 'fried_oily',
      'ทอดมันปลา': 'fried_oily',
      'ปลาทอด': 'fried_oily',
      'แกงเขียวหวานไก่': 'curry_coconut',
      'ต้มข่า': 'curry_coconut',
      'แกงฮังเล': 'curry_coconut',
      'แกงคั่วหอย': 'curry_coconut',
      'แกงจืดมะระยัดไส้หมูสับ': 'clear_soup',
      'แกงจืด': 'clear_soup',
      'แกงป่า': 'clear_soup',
      'แกงส้ม': 'clear_soup',
      'แกงเหลือง': 'clear_soup',
      'กุ้งเผา': 'grilled_protein',
      'ไก่ย่าง': 'grilled_protein',
      'ปูนึ่ง': 'grilled_protein',
      'หมูย่าง': 'grilled_protein',
      'ปลาหมึกย่าง': 'grilled_protein',
      'ข้าวคลุกกะปิ': 'starch_high_carb',
      'ข้าวผัดอเมริกัน': 'starch_high_carb',
      'ข้าวหน้าไก่': 'starch_high_carb',
      'โรตี': 'starch_high_carb',
      'ข้าวหมกไก่': 'starch_high_carb',
      'ข้าวสวย': 'starch_high_carb',
      'ข้าวขาหมู': 'starch_high_carb',
      'ข้าวต้ม': 'starch_high_carb',
      'ข้าวหมูแดง': 'starch_high_carb',
      'ข้าวมันไก่': 'starch_high_carb',
      'ข้าวผัด': 'starch_high_carb',
      'กุ้งอบวุ้นเส้น': 'fish_seafood',
      'กระเพาะปลาน้ำแดง': 'fish_seafood',
      'ปลานึ่งซีอิ๊ว': 'fish_seafood',
      'ปลานึ่งมะนาว': 'fish_seafood',
      'ปลาเผา': 'fish_seafood',
      'ปลาหมึกผัดน้ำดำ': 'fish_seafood',
      'กุ้งทอด': 'fish_seafood',
      'ปลาหมึกนึ่งมะนาว': 'fish_seafood',
      'หอยนางรม': 'fish_seafood',
      'กุ้งแช่น้ำปลา': 'fish_seafood',
      'กุ้งทอดซอสมะขาม': 'fish_seafood',
      'หอยแครงลวก': 'fish_seafood',
      'ปลาหมึกผัดไข่เค็ม': 'fish_seafood',
      'หอยลายผัดน้ำพริก': 'fish_seafood',
      'ผัดซีอิ๊ว': 'stir_fried',
      'ลาบคั่ว': 'stir_fried',
      'ไก่ผัดเม็ดมะม่วงหิมพานต์': 'stir_fried',
      'ผัดพริกแกง': 'stir_fried',
      'ผัดพริกไทยดำ': 'stir_fried',
      'ผัดแขนง': 'stir_fried',
      'ผัดคะน้า': 'stir_fried',
      'ผัดผักบุ้งไฟแดง': 'stir_fried',
      'ผัดกะปิ': 'stir_fried',
      'ผัดกะเพรา': 'stir_fried',
      'ราดหน้า': 'stir_fried',
      'ผัดฉ่า': 'stir_fried',
      'ผัดไทย': 'stir_fried',
      'ยำวุ้นเส้น': 'salad',
      'ยำหอย': 'salad',
      'ลาบ': 'salad',
      'ใบเหลียงผัดไข่': 'salad',
      'ส้มตำ': 'salad',
      'ไข่กระทะ': 'other',
      'ไข่ตุ๋น': 'other',
      'หมูฮ้อง': 'other',
      'น้ำพริกหนุ่ม': 'other',
      'ผัดไทยห่อไข่': 'other',
      'น้ำพริกอ่อง': 'other',
      'คั่วกลิ้ง': 'other',
      'สุกี้แห้ง': 'other',
      'ปอเปี๊ยะสด': 'other',
      'ขนมจีบ': 'other',
      'ไส้อั่ว': 'other',
      'ยำปลาดุกฟู': 'other',
      'หอยผัดน้ำพริกเผา': 'other',
      'พะโล้': 'other',
      'คั่วพริกเกลือ': 'other',
      'เต้าเจี้ยวหลน': 'other',
      'เย็นตาโฟ': 'other',
      'โจ๊ก': 'other',
      'หมูกรอบ': 'other',
      'ปูผัดผงกะหรี่': 'other',
      'ไข่เจียว': 'other',
      'ห่อหมก': 'other',
      'สะเต๊ะ': 'other',
      'เกาเหลา': 'other',
      'ต้มยำ': 'other',
      'ข้าวเหนียวมะม่วง': 'other',
      'มัสมั่นไก่': 'other',
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
  ///   - diabetesType: ประเภทเบาหวาน ('type1' หรือ 'type2') - ถ้า null ถือว่าไม่มีเบาหวาน
  ///
  /// Returns:
  ///   - SmartAdviceResult ที่มี suitable, warning, notes สำหรับแต่ละโรค
  static Map<String, SmartAdviceResult> generateAdviceForConditions({
    required String foodName,
    required String categoryId,
    required NutrientData nutrients,
    required List<String> userConditions,
    String? diabetesType,
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
        diabetesType: diabetesType,
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
    String? diabetesType,
  }) {
    if (condition == 'diabetes') {
      // แยกตาม Type 1 vs Type 2
      if (diabetesType == 'type1') {
        return _generateType1DiabetesAdvice(
          category: category,
          nutrients: nutrients,
        );
      } else if (diabetesType == 'type2') {
        return _generateType2DiabetesAdvice(
          category: category,
          nutrients: nutrients,
        );
      } else {
        // ค่าเริ่มต้น (ถ้าไม่ระบุ type)
        return _generateDiabetesAdvice(
          category: category,
          nutrients: nutrients,
        );
      }
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

  /// สร้างคำแนะนำสำหรับผู้ป่วยเบาหวาน Type 1
  /// Type 1: Insulin-dependent - ต้องนับ carbs อย่างแม่นยำ ส่วนไขมันเป็นรองลงมา
  static SmartAdviceResult _generateType1DiabetesAdvice({
    required FoodCategory category,
    required NutrientData nutrients,
  }) {
    final warnings = <String>[];
    final notes = <String>[];

    // สำหรับ Type 1 - Carb counting เป็นแบบ strict
    bool carbsIsHigh = false;
    if (nutrients.carbsG > 40) {
      warnings.add('🔴 คาร์โบไฮเดรตสูง (${nutrients.carbsG.toStringAsFixed(1)}g) - ต้องนับแม่นยำ');
      notes.add('⚠️ ต้องมีการวางแผน insulin ให้แม่นยำ');
      carbsIsHigh = true;
    } else if (nutrients.carbsG > 25) {
      warnings.add('🟠 คาร์โบไฮเดรตปานกลาง (${nutrients.carbsG.toStringAsFixed(1)}g)');
      notes.add('ต้องนับให้แม่นยำในการจ่าย insulin');
      carbsIsHigh = true;
    } else {
      notes.add('✅ คาร์โบไฮเดรตต่ำ (${nutrients.carbsG.toStringAsFixed(1)}g) - ปลอดภัย');
    }

    // วิเคราะห์โปรตีน (carb-to-protein ratio สำคัญต่อ insulin dosing)
    bool proteinIsLow = false;
    if (nutrients.proteinG < 10) {
      warnings.add('🟠 โปรตีนต่ำ (${nutrients.proteinG.toStringAsFixed(1)}g) - ยากต่อการควบคุมน้ำตาล');
      notes.add('เพิ่มโปรตีนช่วยชะลอการขึ้นน้ำตาล');
      proteinIsLow = true;
    } else if (nutrients.proteinG >= 15) {
      notes.add('✅ โปรตีนดี (${nutrients.proteinG.toStringAsFixed(1)}g) - ช่วยชะลอการดูดซึมคาร์บ');
    } else {
      notes.add('✅ โปรตีนปานกลาง (${nutrients.proteinG.toStringAsFixed(1)}g)');
    }

    // วิเคราะห์ไขมัน (สำหรับ Type 1 เป็นรองลงมา)
    bool fatIsHigh = false;
    if (nutrients.fatG > 20) {
      warnings.add('🔴 ไขมันสูง (${nutrients.fatG.toStringAsFixed(1)}g) - อันตรายต่อหัวใจ');
      notes.add('ลดปริมาณหรือหลีกเลี่ยง');
      fatIsHigh = true;
    } else if (nutrients.fatG > 15) {
      warnings.add('🟠 ไขมันปานกลาง (${nutrients.fatG.toStringAsFixed(1)}g)');
      fatIsHigh = true;
    } else {
      notes.add('✅ ไขมันต่ำ (${nutrients.fatG.toStringAsFixed(1)}g) - ดี');
    }

    // วิเคราะห์เส้นใยอาหาร (ช่วยชะลอการดูดซึมคาร์บ)
    if (nutrients.fiberG < 3) {
      notes.add('💡 เพิ่มเส้นใยอาหารช่วยให้ดูดซึมคาร์บช้าลง');
    } else {
      notes.add('✅ เส้นใยอาหารดี (${nutrients.fiberG.toStringAsFixed(1)}g)');
    }

    // สถานะรวม
    String suitable;
    if (carbsIsHigh && (proteinIsLow || fatIsHigh)) {
      suitable = 'ควรระวัง - คาร์บสูง + อัตราส่วนคาร์บต่อโปรตีนไม่ดี';
    } else if (carbsIsHigh) {
      suitable = 'ควรระวัง - คาร์บสูง (ต้องนับแม่นยำเพื่อปรับปริมาณยา)';
    } else if (fatIsHigh) {
      suitable = 'ควรระวัง - ไขมันสูง';
    } else if (proteinIsLow) {
      suitable = 'ควรระวัง - เพิ่มโปรตีน';
    } else if (category.categoryId == 'clear_soup') {
      suitable = 'เหมาะสม - คาร์บต่ำ + อัตราส่วนคาร์บต่อโปรตีนดี';
    } else if (category.categoryId == 'grilled_protein') {
      suitable = 'เหมาะสมดี - โปรตีนสูง คาร์บต่ำ (ง่ายต่อการปรับปริมาณยา)';
    } else {
      suitable = 'เหมาะสมปานกลาง';
    }

    notes.add('• ${category.baseAdvice}');
    notes.add('💡 สำคัญ: ต้องนับคาร์บให้แม่นยำเพื่อปรับปริมาณยา (นับอัตราส่วนคาร์บต่อโปรตีนด้วย)');

    return SmartAdviceResult(
      suitable: suitable,
      warnings: warnings,
      notes: notes,
    );
  }

  /// สร้างคำแนะนำสำหรับผู้ป่วยเบาหวาน Type 2
  /// Type 2: Non-insulin dependent - ลดคาร์บและไขมัน + weight management + sodium control
  static SmartAdviceResult _generateType2DiabetesAdvice({
    required FoodCategory category,
    required NutrientData nutrients,
  }) {
    final warnings = <String>[];
    final notes = <String>[];

    // สำหรับ Type 2 - Focus on ลดคาร์บโดยทั่วไป (ไม่ต้องแยกแต่ละมื้อ)
    bool carbsIsHigh = false;
    if (nutrients.carbsG > 50) {
      warnings.add('🔴 คาร์โบไฮเดรตสูงมาก (${nutrients.carbsG.toStringAsFixed(1)}g) - อันตราย');
      notes.add('ลดปริมาณการรับประทานอย่างมาก (ส่งผลต่อลดน้ำหนัก)');
      carbsIsHigh = true;
    } else if (nutrients.carbsG > 30) {
      warnings.add('🟠 คาร์โบไฮเดรตปานกลาง (${nutrients.carbsG.toStringAsFixed(1)}g)');
      notes.add('ควรดูแลปริมาณให้เข้มงวด (อันตรายต่อการลดน้ำหนัก)');
      carbsIsHigh = true;
    } else {
      notes.add('✅ คาร์โบไฮเดรตต่ำ (${nutrients.carbsG.toStringAsFixed(1)}g) - โอเค');
    }

    // วิเคราะห์ไขมัน (สำหรับ Type 2 อันตรายต่อหัวใจ)
    bool fatIsHigh = false;
    if (nutrients.fatG > 20) {
      warnings.add('🔴 ไขมันสูงมาก (${nutrients.fatG.toStringAsFixed(1)}g) - อันตรายต่อหัวใจ');
      notes.add('ลดปริมาณหรือหลีกเลี่ยงเป็นประจำ (ส่วนใหญ่ไปกับการลดน้ำหนัก)');
      fatIsHigh = true;
    } else if (nutrients.fatG > 15) {
      warnings.add('🟠 ไขมันปานกลาง (${nutrients.fatG.toStringAsFixed(1)}g)');
      notes.add('ควรระมัดระวังปริมาณ');
      fatIsHigh = true;
    } else {
      notes.add('✅ ไขมันต่ำ (${nutrients.fatG.toStringAsFixed(1)}g) - ดี');
    }

    // วิเคราะห์โซเดียม (Type 2 มักมี hypertension comorbidity)
    bool sodiumIsHigh = false;
    if (nutrients.sodiumMg > 800) {
      warnings.add('🔴 โซเดียมสูงมาก (${nutrients.sodiumMg.toStringAsFixed(0)}mg) - อันตรายต่อความดันโลหิต');
      notes.add('ลดการรับประทานอาหารเค็ม (ทำให้ความดันสูง + ลดน้ำหนักได้ยาก)');
      sodiumIsHigh = true;
    } else if (nutrients.sodiumMg > 500) {
      warnings.add('🟠 โซเดียมปานกลาง (${nutrients.sodiumMg.toStringAsFixed(0)}mg)');
      notes.add('ควรระวังการรับเกลือเพิ่มเติม');
      sodiumIsHigh = true;
    } else {
      notes.add('✅ โซเดียมต่ำ (${nutrients.sodiumMg.toStringAsFixed(0)}mg) - ดีสำหรับควบคุมความดัน');
    }

    // วิเคราะห์เส้นใยอาหาร
    if (nutrients.fiberG < 3) {
      notes.add('💡 เพิ่มเส้นใยอาหาร: ผักใบเขียว ธัญพืช - ช่วยควบคุมคาร์บและลดน้ำหนัก');
    } else {
      notes.add('✅ เส้นใยอาหารดี (${nutrients.fiberG.toStringAsFixed(1)}g) - ช่วยอิ่มนานและลดแคลอรี่');
    }

    // สถานะรวม
    String suitable;
    if (carbsIsHigh && fatIsHigh && sodiumIsHigh) {
      suitable = 'ไม่เหมาะสม - คาร์บ/ไขมัน/เกลือสูง (ต้องหลีกเลี่ยง)';
    } else if (carbsIsHigh && fatIsHigh) {
      suitable = 'ไม่เหมาะสม - ทั้งคาร์บและไขมันสูง (อันตรายต่อลดน้ำหนัก)';
    } else if (sodiumIsHigh) {
      suitable = 'ควรระวัง - โซเดียมสูง (กระทบความดัน)';
    } else if (carbsIsHigh) {
      suitable = 'ควรระวัง - คาร์บสูง (ลดเพื่อลดน้ำหนัก)';
    } else if (fatIsHigh) {
      suitable = 'ควรระวัง - ไขมันสูง (ลดเพื่อเพิ่มสุขภาพหัวใจ)';
    } else if (category.categoryId == 'clear_soup') {
      suitable = 'เหมาะสมอย่างยิ่ง - คาร์บ/ไขมัน/เกลือต่ำ (ดีต่อลดน้ำหนัก)';
    } else if (category.categoryId == 'grilled_protein') {
      suitable = 'เหมาะสม - โปรตีนสูง คาร์บต่ำ (ช่วยอิ่มและลดน้ำหนัก)';
    } else {
      suitable = 'เหมาะสมปานกลาง';
    }

    notes.add('• ${category.baseAdvice}');
    notes.add('💡 สำคัญ: ลดคาร์บ ไขมัน เกลือ + ออกกำลังกาย + ลดน้ำหนัก');

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
