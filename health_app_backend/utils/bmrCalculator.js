/**
 * BMR (Basal Metabolic Rate) Calculator
 * 
 * ใช้สูตร Mifflin-St Jeor ซึ่งแม่นยำที่สุดในปัจจุบัน
 * 
 * สำหรับผู้ชาย:
 * BMR = (10 × น้ำหนัก kg) + (6.25 × ส่วนสูง cm) - (5 × อายุ ปี) + 5
 * 
 * สำหรับผู้หญิง:
 * BMR = (10 × น้ำหนัก kg) + (6.25 × ส่วนสูง cm) - (5 × อายุ ปี) - 161
 */

/**
 * คำนวณค่า BMR (Basal Metabolic Rate)
 * 
 * @param {string} gender - เพศ: 'male' หรือ 'female'
 * @param {number} weight - น้ำหนัก (กิโลกรัม)
 * @param {number} height - ส่วนสูง (เซนติเมตร)
 * @param {number} age - อายุ (ปี)
 * @returns {number} ค่า BMR (kcal/day) ปัดเศษเป็นทศนิยม 2 ตำแหน่ง
 */
function calculateBMR(gender, weight, height, age) {
  if (!gender || !weight || !height || !age) {
    throw new Error('Missing required parameters: gender, weight, height, age');
  }

  let bmr;

  if (gender.toLowerCase() === 'male') {
    // สูตรสำหรับผู้ชาย
    bmr = 10 * weight + 6.25 * height - 5 * age + 5;
  } else if (gender.toLowerCase() === 'female') {
    // สูตรสำหรับผู้หญิง
    bmr = 10 * weight + 6.25 * height - 5 * age - 161;
  } else {
    throw new Error('Invalid gender. Must be "male" or "female"');
  }

  // ปัดเศษเป็นทศนิยม 2 ตำแหน่ง
  return Math.round(bmr * 100) / 100;
}

/**
 * คำนวณ TDEE (Total Daily Energy Expenditure)
 * โดยอิงจาก BMR และ activity level
 * 
 * Activity Multipliers:
 * - sedentary: 1.2 (ไม่ออกกำลัง)
 * - light: 1.375 (ออกกำลังน้อย 1-3 วันต่อสัปดาห์)
 * - moderate: 1.55 (ออกกำลังปานกลาง 3-5 วันต่อสัปดาห์)
 * - active: 1.725 (ออกกำลังสูง 6-7 วันต่อสัปดาห์)
 * - veryActive: 1.9 (ออกกำลังมากเลย หรือเป็นนักกีฬา)
 * 
 * @param {number} bmr - ค่า BMR
 * @param {string} activityLevel - ระดับการออกกำลัง
 * @returns {number} ค่า TDEE (kcal/day)
 */
function calculateTDEE(bmr, activityLevel = 'moderate') {
  const activityMultipliers = {
    sedentary: 1.2,
    light: 1.375,
    moderate: 1.55,
    active: 1.725,
    veryactive: 1.9,
  };

  const multiplier = activityMultipliers[activityLevel?.toLowerCase()] || 1.55;
  const tdee = bmr * multiplier;

  return Math.round(tdee * 100) / 100;
}

/**
 * ตรวจสอบว่าข้อมูลเพียงพอในการคำนวณ BMR
 * 
 * @param {string} gender - เพศ
 * @param {number} weight - น้ำหนัก
 * @param {number} height - ส่วนสูง
 * @param {number} age - อายุ
 * @returns {boolean}
 */
function isValidInput(gender, weight, height, age) {
  return (
    gender &&
    typeof gender === 'string' &&
    gender.length > 0 &&
    weight &&
    typeof weight === 'number' &&
    weight > 0 &&
    height &&
    typeof height === 'number' &&
    height > 0 &&
    age &&
    typeof age === 'number' &&
    age > 0
  );
}

module.exports = {
  calculateBMR,
  calculateTDEE,
  isValidInput,
  calculateDailyCalories,
  calculateProtein,
};

/**
 * คำนวณ Daily Calorie Needs ตามเป้าหมาย
 * โดยปรับค่า TDEE ตามเป้าหมายการออกกำลัง
 * 
 * @param {number} tdee - ค่า TDEE (kcal/day)
 * @param {string} goal - เป้าหมาย: 'weight_loss', 'weight_gain', 'maintain', 'muscle_gain'
 * @returns {number} Daily Calorie Need ปรับแล้ว
 * 
 * Adjustments:
 * - weight_loss: TDEE - 500 (deficit 500 cal/day = 0.5 kg/week)
 * - weight_gain: TDEE + 500 (surplus 500 cal/day = 0.5 kg/week)
 * - maintain: TDEE (maintain)
 * - muscle_gain: TDEE + 300 (small surplus for muscle building)
 */
function calculateDailyCalories(tdee, goal = 'maintain') {
  const goalAdjustments = {
    weight_loss: -500,
    weight_gain: 500,
    maintain: 0,
    muscle_gain: 300,
  };

  const adjustment = goalAdjustments[goal] || 0;
  const dailyCalories = tdee + adjustment;

  return Math.max(Math.round(dailyCalories * 100) / 100, 1000); // Minimum 1000 kcal/day
}

/**
 * คำนวณ Protein Requirement
 * 
 * @param {number} weight - น้ำหนัก (kg)
 * @param {string} goal - เป้าหมาย: 'weight_loss', 'weight_gain', 'maintain', 'muscle_gain'
 * @returns {number} Protein requirement (grams/day)
 * 
 * Protein Multipliers:
 * - weight_loss: 2.2 g/kg (สูงสุด เพื่อรักษากล้ามเนื้อขณะลดน้ำหนัก)
 * - muscle_gain: 2.0 g/kg (เพิ่มกล้ามเนื้อ)
 * - weight_gain: 1.8 g/kg (เพิ่มน้ำหนัก)
 * - maintain: 1.6 g/kg (รักษาน้ำหนัก)
 */
function calculateProtein(weight, goal = 'maintain') {
  const proteinMultipliers = {
    weight_loss: 2.2,
    muscle_gain: 2.0,
    weight_gain: 1.8,
    maintain: 1.6,
  };

  const multiplier = proteinMultipliers[goal] || 1.6;
  const protein = weight * multiplier;

  return Math.round(protein * 10) / 10; // Round to 1 decimal place
}
