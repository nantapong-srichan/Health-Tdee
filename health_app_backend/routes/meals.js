const express = require('express');
const router = express.Router();
const mealController = require('../controllers/mealController');
const authenticate = require('../middleware/auth');
const { validateMeal, handleValidationErrors } = require('../utils/validators');

// All meal routes require authentication
router.use(authenticate);

// Create meal
router.post('/', validateMeal, handleValidationErrors, mealController.saveMeal);

// Get meal history
router.get('/', mealController.getMealHistory);

// Get single meal
router.get('/:id', mealController.getMeal);

// Update meal
router.put('/:id', validateMeal, handleValidationErrors, mealController.updateMeal);

// Delete meal
router.delete('/:id', mealController.deleteMeal);

module.exports = router;
