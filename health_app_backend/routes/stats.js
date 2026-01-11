const express = require('express');
const router = express.Router();
const statsController = require('../controllers/statsController');
const authenticate = require('../middleware/auth');

// All stats routes require authentication
router.use(authenticate);

// Get daily stats
router.get('/daily', statsController.getDailyStats);

// Get weekly stats
router.get('/weekly', statsController.getWeeklyStats);

// Get calorie summary for charts
router.get('/summary', statsController.getCalorieSummary);

// Get nutritional insights
router.get('/insights', statsController.getNutritionalInsights);

module.exports = router;
