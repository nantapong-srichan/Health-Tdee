/**
 * Seed Script - Initialize Food Database from CSV
 * Add food nutrition data from CSV file (items 12-114)
 */

require('dotenv').config();
const mongoose = require('mongoose');
const Food = require('./models/Food');
const connectDB = require('./config/database');

// Food data from CSV (0-114, skipping empty rows)
const foodsData = [
  // Items 0-11 (original 12 items)
  {
    foodName: 'แกงเขียวหวานไก่',
    nutrition: { calories: 101, protein: 7.9, fat: 6.05, carbohydrates: 3.03, sodium: 420 },
  },
  {
    foodName: 'แกงจืดมะระยัดไส้หมูสับ',
    nutrition: { calories: 52, protein: 4.8, fat: 3.2, carbohydrates: 1, sodium: 380 },
  },
  {
    foodName: 'ไข่ดาว',
    nutrition: { calories: 265, protein: 12.75, fat: 22.76, carbohydrates: 2.46, sodium: 70 },
  },
  {
    foodName: 'ก๋วยจั๊บ',
    nutrition: { calories: 84, protein: 4.55, fat: 3.67, carbohydrates: 8.17, sodium: 360 },
  },
  {
    foodName: 'กุ้งเผา',
    nutrition: { calories: 134, protein: 20.1, fat: 5.8, carbohydrates: 0.4, sodium: 180 },
  },
  {
    foodName: 'กุ้งอบวุ้นเส้น',
    nutrition: { calories: 154, protein: 9.4, fat: 5.6, carbohydrates: 16.5, sodium: 580 },
  },
  {
    foodName: 'แกงจืด',
    nutrition: { calories: 48, protein: 3.5, fat: 3.1, carbohydrates: 1.6, sodium: 350 },
  },
  {
    foodName: 'ไก่ทอด',
    nutrition: { calories: 290, protein: 28.43, fat: 21, carbohydrates: 7, sodium: 450 },
  },
  {
    foodName: 'ไก่ย่าง',
    nutrition: { calories: 210, protein: 22.5, fat: 12.8, carbohydrates: 1.2, sodium: 520 },
  },
  {
    foodName: 'ขนมจีนน้ำยาไก่',
    nutrition: { calories: 95, protein: 4.2, fat: 4.8, carbohydrates: 8.8, sodium: 320 },
  },
  {
    foodName: 'ข้าวคลุกกะปิ',
    nutrition: { calories: 191, protein: 6.61, fat: 7.11, carbohydrates: 25.21, sodium: 614 },
  },
  {
    foodName: 'ข้าวหมูทอดกระเทียม',
    nutrition: { calories: 184, protein: 6.8, fat: 5.8, carbohydrates: 26.2, sodium: 322 },
  },
  // Items 12-114 (from CSV)
  {
    foodName: 'ข้าวผัดอเมริกัน',
    nutrition: { calories: 172, protein: 6.3, fat: 7.4, carbohydrates: 20, sodium: 317 },
  },
  {
    foodName: 'ข้าวหน้าไก่',
    nutrition: { calories: 131, protein: 4.8, fat: 3.6, carbohydrates: 19.8, sodium: 335 },
  },
  {
    foodName: 'ปอเปี๊ยะทอด',
    nutrition: { calories: 284, protein: 4.8, fat: 14.5, carbohydrates: 33.6, sodium: 443 },
  },
  {
    foodName: 'ผัดซีอิ๊ว',
    nutrition: { calories: 174, protein: 5.6, fat: 8.4, carbohydrates: 19, sodium: 385 },
  },
  {
    foodName: 'กระเพาะปลาน้ำแดง',
    nutrition: { calories: 72, protein: 5.1, fat: 3.4, carbohydrates: 5.3, sodium: 425 },
  },
  {
    foodName: 'ไส้กรอกอีสาน',
    nutrition: { calories: 282, protein: 13.6, fat: 22.5, carbohydrates: 6.3, sodium: 785 },
  },
  {
    foodName: 'ลาบคั่ว',
    nutrition: { calories: 175, protein: 13.01, fat: 12.16, carbohydrates: 1.85, sodium: 599 },
  },
  {
    foodName: 'ไก่ผัดเม็ดมะม่วงหิมพานต์',
    nutrition: { calories: 185, protein: 10.2, fat: 13.5, carbohydrates: 5.6, sodium: 512 },
  },
  {
    foodName: 'ผัดพริกแกง',
    nutrition: { calories: 145, protein: 8.2, fat: 11, carbohydrates: 3.3, sodium: 545 },
  },
  {
    foodName: 'ผัดพริกไทยดำ',
    nutrition: { calories: 156, protein: 11.2, fat: 10.4, carbohydrates: 4.4, sodium: 580 },
  },
  {
    foodName: 'ปลานึ่งซีอิ๊ว',
    nutrition: { calories: 98, protein: 15.4, fat: 3.2, carbohydrates: 1.9, sodium: 520 },
  },
  {
    foodName: 'ผัดแขนง',
    nutrition: { calories: 148, protein: 5.4, fat: 11.2, carbohydrates: 6.5, sodium: 485 },
  },
  {
    foodName: 'ไข่กระทะ',
    nutrition: { calories: 192, protein: 12.1, fat: 15.4, carbohydrates: 1.3, sodium: 345 },
  },
  // ข้ามเลข 25 (ว่าง)
  {
    foodName: 'ก๋วยเตี๋ยวเรือ',
    nutrition: { calories: 92, protein: 4.3, fat: 3.6, carbohydrates: 10.6, sodium: 440 },
  },
  {
    foodName: 'ไข่ตุ๋น',
    nutrition: { calories: 65, protein: 6, fat: 4.1, carbohydrates: 1, sodium: 320 },
  },
  {
    foodName: 'โรตี',
    nutrition: { calories: 359, protein: 7.37, fat: 13.3, carbohydrates: 52.37, sodium: 334 },
  },
  {
    foodName: 'หมูฮ้อง',
    nutrition: { calories: 365, protein: 12.5, fat: 32.4, carbohydrates: 6, sodium: 480 },
  },
  {
    foodName: 'น้ำพริกหนุ่ม',
    nutrition: { calories: 56, protein: 2.1, fat: 1.2, carbohydrates: 9.2, sodium: 620 },
  },
  {
    foodName: 'ผัดไทยห่อไข่',
    nutrition: { calories: 215, protein: 7.8, fat: 11.2, carbohydrates: 20.8, sodium: 460 },
  },
  {
    foodName: 'น้ำพริกอ่อง',
    nutrition: { calories: 165, protein: 8.5, fat: 12.4, carbohydrates: 4.8, sodium: 550 },
  },
  {
    foodName: 'ปลาหมึกทอด',
    nutrition: { calories: 275, protein: 14.2, fat: 15.6, carbohydrates: 9.77, sodium: 550 },
  },
  {
    foodName: 'คั่วกลิ้ง',
    nutrition: { calories: 215, protein: 18.4, fat: 13.5, carbohydrates: 19.5, sodium: 640 },
  },
  {
    foodName: 'ผัดคะน้า',
    nutrition: { calories: 168, protein: 6.2, fat: 12.4, carbohydrates: 5, sodium: 490 },
  },
  {
    foodName: 'ปลานึ่งมะนาว',
    nutrition: { calories: 85, protein: 14.1, fat: 1.8, carbohydrates: 7.9, sodium: 510 },
  },
  {
    foodName: 'ต้มข่า',
    nutrition: { calories: 110, protein: 4.5, fat: 8.8, carbohydrates: 3.2, sodium: 395 },
  },
  {
    foodName: 'ยำวุ้นเส้น',
    nutrition: { calories: 92, protein: 5.4, fat: 1.2, carbohydrates: 14.9, sodium: 580 },
  },
  {
    foodName: 'ปลาเผา',
    nutrition: { calories: 95, protein: 19.8, fat: 1.5, carbohydrates: 0.6, sodium: 210 },
  },
  {
    foodName: 'ปลาหมึกผัดน้ำดำ',
    nutrition: { calories: 142, protein: 12.8, fat: 8.4, carbohydrates: 3.8, sodium: 620 },
  },
  {
    foodName: 'เกี๊ยวทอด',
    nutrition: { calories: 345, protein: 5.2, fat: 24.8, carbohydrates: 25.2, sodium: 380 },
  },
  {
    foodName: 'กั้งทอดกระเทียม',
    nutrition: { calories: 178, protein: 16.5, fat: 6.5, carbohydrates: 5.9, sodium: 480 },
  },
  {
    foodName: 'ผัดผักบุ้งไฟแดง',
    nutrition: { calories: 88, protein: 2.3, fat: 6.5, carbohydrates: 5.1, sodium: 530 },
  },
  {
    foodName: 'เต้าหู้ทอด',
    nutrition: { calories: 240, protein: 12, fat: 16.2, carbohydrates: 11.5, sodium: 25 },
  },
  {
    foodName: 'ยำหอย',
    nutrition: { calories: 82, protein: 10.5, fat: 1.1, carbohydrates: 7.5, sodium: 650 },
  },
  {
    foodName: 'สุกี้แห้ง',
    nutrition: { calories: 135, protein: 6.8, fat: 13, carbohydrates: 13, sodium: 590 },
  },
  {
    foodName: 'กุ้งทอด',
    nutrition: { calories: 295, protein: 12.8, fat: 12.8, carbohydrates: 19.5, sodium: 420 },
  },
  {
    foodName: 'ปอเปี๊ยะสด',
    nutrition: { calories: 170, protein: 4.99, fat: 5.57, carbohydrates: 24.13, sodium: 375 },
  },
  {
    foodName: 'ผัดพริกสด',
    nutrition: { calories: 145, protein: 8.5, fat: 11.2, carbohydrates: 2.5, sodium: 535 },
  },
  {
    foodName: 'แกงฮังเล',
    nutrition: { calories: 215, protein: 11.14, fat: 16, carbohydrates: 5.21, sodium: 578 },
  },
  {
    foodName: 'ขนมจีบ',
    nutrition: { calories: 189, protein: 11.3, fat: 10.4, carbohydrates: 11.82, sodium: 521 },
  },
  {
    foodName: 'ก๋วยเตี๋ยวคั่วไก่',
    nutrition: { calories: 168, protein: 7.2, fat: 8.4, carbohydrates: 15.9, sodium: 415 },
  },
  {
    foodName: 'ปูนิ่มทอดกระเทียม',
    nutrition: { calories: 272, protein: 13.5, fat: 20.4, carbohydrates: 8.6, sodium: 460 },
  },
  {
    foodName: 'กะหล่ำปลีผัดน้ำปลา',
    nutrition: { calories: 75, protein: 480, fat: 5.2, carbohydrates: 5.3, sodium: 480 },
  },
  {
    foodName: 'ข้าวหมกไก่',
    nutrition: { calories: 183, protein: 7.3, fat: 6.03, carbohydrates: 24.39, sodium: 221 },
  },
  {
    foodName: 'ผัดกะปิ',
    nutrition: { calories: 172, protein: 12.8, fat: 11.4, carbohydrates: 4.5, sodium: 760 },
  },
  {
    foodName: 'ไส้อั่ว',
    nutrition: { calories: 285, protein: 14.2, fat: 22.8, carbohydrates: 5.8, sodium: 645 },
  },
  {
    foodName: 'ยำปลาดุกฟู',
    nutrition: { calories: 352, protein: 12.4, fat: 28.5, carbohydrates: 11.5, sodium: 520 },
  },
  {
    foodName: 'หอยทอด',
    nutrition: { calories: 255, protein: 7.2, fat: 17.5, carbohydrates: 17.2, sodium: 410 },
  },
  {
    foodName: 'ผัดกะเพรา',
    nutrition: { calories: 168, protein: 12.5, fat: 11.8, carbohydrates: 3, sodium: 540 },
  },
  {
    foodName: 'ข้าวสวย',
    nutrition: { calories: 136, protein: 2.28, fat: 0.24, carbohydrates: 31.1, sodium: 20 },
  },
  {
    foodName: 'หอยจ๊อ',
    nutrition: { calories: 288, protein: 15.9, fat: 20.18, carbohydrates: 9.72, sodium: 429 },
  },
  {
    foodName: 'หอยผัดน้ำพริกเผา',
    nutrition: { calories: 135, protein: 9.2, fat: 8.4, carbohydrates: 5.8, sodium: 858 },
  },
  {
    foodName: 'ข้าวขาหมู',
    nutrition: { calories: 161, protein: 7.19, fat: 5.93, carbohydrates: 19.34, sodium: 324 },
  },
  {
    foodName: 'แกงคั่วหอย',
    nutrition: { calories: 142, protein: 7.8, fat: 11.2, carbohydrates: 3.1, sodium: 510 },
  },
  {
    foodName: 'ข้าวต้ม',
    nutrition: { calories: 65, protein: 4.19, fat: 1.09, carbohydrates: 9.58, sodium: 226 },
  },
  {
    foodName: 'ข้าวหมูแดง',
    nutrition: { calories: 154, protein: 6.29, fat: 4.18, carbohydrates: 22.72, sodium: 284 },
  },
  {
    foodName: 'พะโล้',
    nutrition: { calories: 133, protein: 8.9, fat: 4.23, carbohydrates: 14.13, sodium: 416 },
  },
  {
    foodName: 'คั่วพริกเกลือ',
    nutrition: { calories: 212, protein: 14.5, fat: 15.6, carbohydrates: 3.8, sodium: 690 },
  },
  {
    foodName: 'ราดหน้า',
    nutrition: { calories: 115, protein: 4.6, fat: 4.4, carbohydrates: 14.2, sodium: 395 },
  },
  {
    foodName: 'เต้าเจี้ยวหลน',
    nutrition: { calories: 158, protein: 5.4, fat: 12.8, carbohydrates: 5.2, sodium: 625 },
  },
  {
    foodName: 'เย็นตาโฟ',
    nutrition: { calories: 70, protein: 3.05, fat: 2.67, carbohydrates: 8.23, sodium: 239 },
  },
  {
    foodName: 'ปลาหมึกนึ่งมะนาว',
    nutrition: { calories: 88, protein: 13.5, fat: 2.1, carbohydrates: 3.8, sodium: 540 },
  },
  {
    foodName: 'แกงป่า',
    nutrition: { calories: 47, protein: 5.6, fat: 0.8, carbohydrates: 3.3, sodium: 214 },
  },
  {
    foodName: 'โจ๊ก',
    nutrition: { calories: 55, protein: 3.5, fat: 2.2, carbohydrates: 5.3, sodium: 340 },
  },
  {
    foodName: 'ขนมจีนน้ำเงี้ยว',
    nutrition: { calories: 107, protein: 2.71, fat: 8.41, carbohydrates: 5.2, sodium: 279 },
  },
  // ข้ามเลข 77 (ว่าง)
  {
    foodName: 'แกงส้ม',
    nutrition: { calories: 31, protein: 2.53, fat: 0.16, carbohydrates: 3.93, sodium: 300 },
  },
  {
    foodName: 'หอยนางรม',
    nutrition: { calories: 71, protein: 9, fat: 2.3, carbohydrates: 3.6, sodium: 210 },
  },
  {
    foodName: 'ขนมจีน',
    nutrition: { calories: 95, protein: 0.9, fat: 0.1, carbohydrates: 21, sodium: 15 },
  },
  {
    foodName: 'แกงเหลือง',
    nutrition: { calories: 40, protein: 7.8, fat: 0.14, carbohydrates: 1.32, sodium: 874 },
  },
  {
    foodName: 'กุ้งแช่น้ำปลา',
    nutrition: { calories: 82, protein: 15.2, fat: 0.8, carbohydrates: 3.5, sodium: 1050 },
  },
  {
    foodName: 'กุ้งทอดซอสมะขาม',
    nutrition: { calories: 245, protein: 12, fat: 16.5, carbohydrates: 12, sodium: 410 },
  },
  {
    foodName: 'หมูกรอบ',
    nutrition: { calories: 540, protein: 13.5, fat: 53, carbohydrates: 1, sodium: 320 },
  },
  {
    foodName: 'ปูผัดผงกะหรี่',
    nutrition: { calories: 175, protein: 10.8, fat: 12.5, carbohydrates: 4.8, sodium: 580 },
  },
  {
    foodName: 'ไข่เจียว',
    nutrition: { calories: 275, protein: 10.5, fat: 25.5, carbohydrates: 1, sodium: 450 },
  },
  // ข้ามเลข 87 (ว่าง)
  {
    foodName: 'ผัดฉ่า',
    nutrition: { calories: 135, protein: 11.2, fat: 8.5, carbohydrates: 3.5, sodium: 560 },
  },
  {
    foodName: 'หอยแครงลวก',
    nutrition: { calories: 85, protein: 14.5, fat: 1.2, carbohydrates: 4, sodium: 250 },
  },
  {
    foodName: 'ห่อหมก',
    nutrition: { calories: 146, protein: 11.2, fat: 10.3, carbohydrates: 2.2, sodium: 514 },
  },
  {
    foodName: 'ปลาหมึกผัดไข่เค็ม',
    nutrition: { calories: 168, protein: 12.1, fat: 10.8, carbohydrates: 5.5, sodium: 620 },
  },
  {
    foodName: 'ผัดไทย',
    nutrition: { calories: 171, protein: 6.83, fat: 6.33, carbohydrates: 20.67, sodium: 445 },
  },
  {
    foodName: 'ทอดมันกุ้ง',
    nutrition: { calories: 247, protein: 14.8, fat: 16.78, carbohydrates: 9.17, sodium: 473 },
  },
  {
    foodName: 'สะเต๊ะ',
    nutrition: { calories: 272, protein: 20.07, fat: 14.57, carbohydrates: 15.03, sodium: 342 },
  },
  {
    foodName: 'ข้าวมันไก่',
    nutrition: { calories: 219, protein: 5.36, fat: 9.51, carbohydrates: 28.01, sodium: 483 },
  },
  // ข้ามเลข 96 (ว่าง)
  {
    foodName: 'ลาบ',
    nutrition: { calories: 175, protein: 13.01, fat: 12.16, carbohydrates: 1.85, sodium: 599 },
  },
  {
    foodName: 'ใบเหลียงผัดไข่',
    nutrition: { calories: 145, protein: 5.2, fat: 11.5, carbohydrates: 6.4, sodium: 380 },
  },
  {
    foodName: 'ข้าวซอย',
    nutrition: { calories: 150, protein: 5.83, fat: 10.56, carbohydrates: 7.37, sodium: 416 },
  },
  {
    foodName: 'เกาเหลา',
    nutrition: { calories: 32, protein: 3.01, fat: 1.37, carbohydrates: 1.94, sodium: 371 },
  },
  {
    foodName: 'ทอดมันปลา',
    nutrition: { calories: 174, protein: 14.38, fat: 9.88, carbohydrates: 4.8, sodium: 516 },
  },
  {
    foodName: 'ปูนึ่ง',
    nutrition: { calories: 95, protein: 19.5, fat: 1.2, carbohydrates: 0, sodium: 320 },
  },
  {
    foodName: 'หมูย่าง',
    nutrition: { calories: 215, protein: 22.5, fat: 12.8, carbohydrates: 1.2, sodium: 520 },
  },
  {
    foodName: 'ส้มตำ',
    nutrition: { calories: 105, protein: 4.29, fat: 2.65, carbohydrates: 14.34, sodium: 627 },
  },
  // ข้ามเลข 105 (ว่าง)
  {
    foodName: 'ข้าวผัด',
    nutrition: { calories: 160, protein: 4.56, fat: 4.14, carbohydrates: 24.26, sodium: 335 },
  },
  {
    foodName: 'ต้มยำ',
    nutrition: { calories: 44, protein: 4.67, fat: 1.43, carbohydrates: 2.86, sodium: 521 },
  },
  {
    foodName: 'ปลาทอด',
    nutrition: { calories: 265, protein: 18.2, fat: 19.5, carbohydrates: 2.4, sodium: 350 },
  },
  {
    foodName: 'ปลาหมึกย่าง',
    nutrition: { calories: 110, protein: 18, fat: 1.5, carbohydrates: 1, sodium: 450 },
  },
  {
    foodName: 'หอยลายผัดน้ำพริก',
    nutrition: { calories: 160, protein: 9, fat: 10, carbohydrates: 8.5, sodium: 700 },
  },
  // ข้ามเลข 111 (ว่าง)
  // ข้ามเลข 112 (ว่าง)
  {
    foodName: 'ข้าวเหนียวมะม่วง',
    nutrition: { calories: 200, protein: 2.5, fat: 6.5, carbohydrates: 34, sodium: 120 },
  },
  {
    foodName: 'มัสมั่นไก่',
    nutrition: { calories: 194, protein: 10.28, fat: 10.99, carbohydrates: 12.65, sodium: 313 },
  },
];

async function seedDatabase() {
  try {
    console.log('Connecting to MongoDB...');
    await connectDB();
    console.log('✅ Connected to MongoDB');

    console.log('\nClearing existing food data...');
    await Food.deleteMany({});
    console.log('✅ Cleared existing food data');

console.log(`\nInserting ${foodsData.length} food items (0-114)...`);
    const insertedFoods = await Food.insertMany(foodsData);
    console.log(`✅ Successfully inserted ${insertedFoods.length} food items`);

    console.log('\n📊 Sample Inserted Foods:');
    insertedFoods.slice(0, 5).forEach((food) => {
      console.log(
        `  • ${food.foodName} - ${food.nutrition.calories} kcal, ${food.nutrition.protein}g protein`
      );
    });
    console.log(`  ... and ${insertedFoods.length - 5} more items`);

    console.log('\n✅ Seed complete!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error seeding database:', error.message);
    process.exit(1);
  }
}

seedDatabase();
