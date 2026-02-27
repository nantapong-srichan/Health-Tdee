const express = require('express');
const router = express.Router();
const multer = require('multer');
const mealController = require('../controllers/mealController');
const authenticate = require('../middleware/auth');
const { validateMeal, handleValidationErrors } = require('../utils/validators');

// ตั้งค่า multer สำหรับการอัปโหลดไฟล์
const storage = multer.memoryStorage(); // เก็บไฟล์ใน memory
const upload = multer({
  storage: storage,
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB max
  // ไม่ตรวจสอบ MIME type เพราะ Flutter multipart request ไม่ส่ง content-type มา
  // Backend จะตรวจสอบประเภทไฟล์ผ่าน extension แทน
});

// All meal routes require authentication
router.use(authenticate);

// Create meal with image upload
router.post('/', upload.single('image'), validateMeal, handleValidationErrors, mealController.saveMeal);

// Get meal history
router.get('/', mealController.getMealHistory);

// Get single meal
router.get('/:id', mealController.getMeal);

// Update meal with image upload
router.put('/:id', upload.single('image'), validateMeal, handleValidationErrors, mealController.updateMeal);

// Delete meal
router.delete('/:id', mealController.deleteMeal);

module.exports = router;
