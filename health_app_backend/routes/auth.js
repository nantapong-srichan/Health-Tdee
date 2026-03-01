const express = require('express');
const router = express.Router();
const multer = require('multer');
const authController = require('../controllers/authController');
const authenticate = require('../middleware/auth');
const { validateRegister, handleValidationErrors } = require('../utils/validators');

// ตั้งค่า multer สำหรับการอัปโหลดไฟล์โปรไฟล์
const storage = multer.memoryStorage(); // เก็บไฟล์ใน memory
const upload = multer({
  storage: storage,
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB max
});

// Public routes
router.post('/register', validateRegister, handleValidationErrors, authController.register);
router.post('/login', authController.login);

// Protected routes
router.get('/me', authenticate, authController.getCurrentUser);
router.put('/profile', authenticate, authController.updateProfile);
router.post('/change-password', authenticate, authController.changePassword);
router.post('/change-email', authenticate, authController.changeEmail);
router.post('/upload-profile-image', authenticate, upload.single('profileImage'), authController.uploadProfileImage);

module.exports = router;
