/**
 * Seed Script - Initialize Food Database
 * Add initial food nutrition data from nutrition_database.dart
 */

require('dotenv').config();
const mongoose = require('mongoose');
const Food = require('./models/Food');
const connectDB = require('./config/database');

// Food data from nutrition_database.dart (per 100g)
const foodsData = [
  {
    foodName: 'แกงเขียวหวานไก่',
    nutrition: {
      calories: 140,
      protein: 5.1,
      fat: 11.8,
      carbohydrates: 5.4,
      sodium: 450,
    },
  },
  {
    foodName: 'แกงจืดมะระยัดไส้หมูสับ',
    nutrition: {
      calories: 85,
      protein: 7.4,
      fat: 4.8,
      carbohydrates: 3.1,
      sodium: 320,
    },
  },
  {
    foodName: 'ไข่ดาว',
    nutrition: {
      calories: 327,
      protein: 12.8,
      fat: 15.7,
      carbohydrates: 0.8,
      sodium: 140,
    },
  },
  {
    foodName: 'ก๋วยจั๊บ',
    nutrition: {
      calories: 115,
      protein: 4.8,
      fat: 3.2,
      carbohydrates: 16.8,
      sodium: 482,
    },
  },
  {
    foodName: 'กุ้งเผา',
    nutrition: {
      calories: 92,
      protein: 20.4,
      fat: 1.2,
      carbohydrates: 0.0,
      sodium: 110,
    },
  },
  {
    foodName: 'กุ้งอบวุ้นเส้น',
    nutrition: {
      calories: 165,
      protein: 9.2,
      fat: 5.4,
      carbohydrates: 20.0,
      sodium: 450,
    },
  },
  {
    foodName: 'แกงจืด',
    nutrition: {
      calories: 45,
      protein: 3.8,
      fat: 2.5,
      carbohydrates: 1.8,
      sodium: 280,
    },
  },
  {
    foodName: 'ไก่ทอด',
    nutrition: {
      calories: 275,
      protein: 18.5,
      fat: 19.0,
      carbohydrates: 7.5,
      sodium: 320,
    },
  },
  {
    foodName: 'ไก่ย่าง',
    nutrition: {
      calories: 175,
      protein: 22.0,
      fat: 8.5,
      carbohydrates: 1.2,
      sodium: 75,
    },
  },
  {
    foodName: 'ขนมจีนน้ำยาไก่',
    nutrition: {
      calories: 105,
      protein: 4.2,
      fat: 4.5,
      carbohydrates: 12.0,
      sodium: 410,
    },
  },
  {
    foodName: 'ข้าวคลุกกะปิ',
    nutrition: {
      calories: 210,
      protein: 6.8,
      fat: 7.2,
      carbohydrates: 29.5,
      sodium: 550,
    },
  },
  {
    foodName: 'ข้าวหมูทอดกระเทียม',
    nutrition: {
      calories: 265,
      protein: 10.5,
      fat: 11.0,
      carbohydrates: 31.0,
      sodium: 460,
    },
  },
];

async function seedDatabase() {
  try {
    // Connect to MongoDB
    console.log('Connecting to MongoDB...');
    await connectDB();
    console.log('✅ Connected to MongoDB');

    // Clear existing food data
    console.log('\nClearing existing food data...');
    await Food.deleteMany({});
    console.log('✅ Cleared existing food data');

    // Insert new food data
    console.log(`\nInserting ${foodsData.length} food items...`);
    const insertedFoods = await Food.insertMany(foodsData);
    console.log(`✅ Successfully inserted ${insertedFoods.length} food items`);

    // Display inserted data
    console.log('\n📊 Inserted Foods:');
    insertedFoods.forEach((food) => {
      console.log(
        `  • ${food.foodName} - ${food.nutrition.calories} kcal, ${food.nutrition.protein}g protein`
      );
    });

    console.log('\n✅ Seed complete!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error seeding database:', error.message);
    process.exit(1);
  }
}

// Run seed
seedDatabase();
