const Meal = require('../models/Meal');
const User = require('../models/User');

// Get daily calorie statistics
exports.getDailyStats = async (req, res, next) => {
  try {
    const { date } = req.query;

    // Default to today if no date provided
    const targetDate = date ? new Date(date) : new Date();
    targetDate.setHours(0, 0, 0, 0);

    const nextDate = new Date(targetDate);
    nextDate.setDate(nextDate.getDate() + 1);

    // Get all meals for the day
    const meals = await Meal.find({
      userId: req.userId,
      mealTime: {
        $gte: targetDate,
        $lt: nextDate,
      },
    }).sort({ mealTime: 1 });

    // Calculate totals
    const totals = {
      calories: 0,
      protein: 0,
      carbohydrates: 0,
      fat: 0,
      meals: [],
    };

    meals.forEach((meal) => {
      totals.calories += meal.nutrition.calories;
      totals.protein += meal.nutrition.protein;
      totals.carbohydrates += meal.nutrition.carbohydrates;
      totals.fat += meal.nutrition.fat;
      totals.meals.push({
        id: meal._id,
        foodName: meal.foodName,
        calories: meal.nutrition.calories,
        mealType: meal.mealType,
        mealTime: meal.mealTime,
      });
    });

    // Get user's daily goal
    const user = await User.findById(req.userId);
    const dailyGoal = user.dailyCalorieGoal || 2000;

    res.json({
      success: true,
      date: targetDate.toISOString().split('T')[0],
      dailyGoal,
      totals,
      remaining: Math.max(0, dailyGoal - totals.calories),
      percentageReached: Math.round((totals.calories / dailyGoal) * 100),
    });
  } catch (error) {
    next(error);
  }
};

// Get weekly statistics
exports.getWeeklyStats = async (req, res, next) => {
  try {
    const { startDate } = req.query;

    // Default to this week if no date provided
    let targetDate = startDate ? new Date(startDate) : new Date();
    targetDate.setHours(0, 0, 0, 0);

    // Get Monday of the week
    const day = targetDate.getDay();
    const diff = targetDate.getDate() - day + (day === 0 ? -6 : 1);
    const monday = new Date(targetDate.setDate(diff));

    // Get next Sunday
    const sunday = new Date(monday);
    sunday.setDate(sunday.getDate() + 6);
    sunday.setHours(23, 59, 59, 999);

    // Get all meals for the week
    const meals = await Meal.find({
      userId: req.userId,
      mealTime: {
        $gte: monday,
        $lte: sunday,
      },
    });

    // Group by date
    const dailyStats = {};

    for (let i = 0; i < 7; i++) {
      const currentDate = new Date(monday);
      currentDate.setDate(currentDate.getDate() + i);
      const dateKey = currentDate.toISOString().split('T')[0];

      dailyStats[dateKey] = {
        date: dateKey,
        dayName: currentDate.toLocaleDateString('en-US', { weekday: 'short' }),
        calories: 0,
        protein: 0,
        carbohydrates: 0,
        fat: 0,
        meals: [],
      };
    }

    // Populate with actual meals
    meals.forEach((meal) => {
      const dateKey = meal.mealTime.toISOString().split('T')[0];

      if (dailyStats[dateKey]) {
        dailyStats[dateKey].calories += meal.nutrition.calories;
        dailyStats[dateKey].protein += meal.nutrition.protein;
        dailyStats[dateKey].carbohydrates += meal.nutrition.carbohydrates;
        dailyStats[dateKey].fat += meal.nutrition.fat;
        dailyStats[dateKey].meals.push({
          foodName: meal.foodName,
          calories: meal.nutrition.calories,
        });
      }
    });

    // Get user's daily goal
    const user = await User.findById(req.userId);
    const dailyGoal = user.dailyCalorieGoal || 2000;

    // Calculate weekly totals
    const weeklyTotals = {
      calories: 0,
      protein: 0,
      carbohydrates: 0,
      fat: 0,
    };

    Object.values(dailyStats).forEach((day) => {
      weeklyTotals.calories += day.calories;
      weeklyTotals.protein += day.protein;
      weeklyTotals.carbohydrates += day.carbohydrates;
      weeklyTotals.fat += day.fat;
    });

    res.json({
      success: true,
      weekStart: monday.toISOString().split('T')[0],
      weekEnd: sunday.toISOString().split('T')[0],
      dailyGoal,
      dailyStats: Object.values(dailyStats),
      weeklyTotals,
      averageDailyCalories: Math.round(weeklyTotals.calories / 7),
    });
  } catch (error) {
    next(error);
  }
};

// Get calorie summary for donut chart
exports.getCalorieSummary = async (req, res, next) => {
  try {
    const { date } = req.query;

    const targetDate = date ? new Date(date) : new Date();
    targetDate.setHours(0, 0, 0, 0);

    const nextDate = new Date(targetDate);
    nextDate.setDate(nextDate.getDate() + 1);

    // Get meals for the day
    const meals = await Meal.find({
      userId: req.userId,
      mealTime: {
        $gte: targetDate,
        $lt: nextDate,
      },
    });

    // Group by macronutrient
    const summary = {
      protein: 0,
      carbohydrates: 0,
      fat: 0,
    };

    meals.forEach((meal) => {
      summary.protein += meal.nutrition.protein;
      summary.carbohydrates += meal.nutrition.carbohydrates;
      summary.fat += meal.nutrition.fat;
    });

    // Calculate macronutrient percentages (calories)
    const proteinCalories = summary.protein * 4;
    const carbCalories = summary.carbohydrates * 4;
    const fatCalories = summary.fat * 9;
    const totalCalories = proteinCalories + carbCalories + fatCalories;

    res.json({
      success: true,
      date: targetDate.toISOString().split('T')[0],
      macros: summary,
      calorieBreakdown: {
        protein: {
          grams: summary.protein,
          calories: proteinCalories,
          percentage: totalCalories > 0 ? Math.round((proteinCalories / totalCalories) * 100) : 0,
        },
        carbohydrates: {
          grams: summary.carbohydrates,
          calories: carbCalories,
          percentage: totalCalories > 0 ? Math.round((carbCalories / totalCalories) * 100) : 0,
        },
        fat: {
          grams: summary.fat,
          calories: fatCalories,
          percentage: totalCalories > 0 ? Math.round((fatCalories / totalCalories) * 100) : 0,
        },
      },
      totalCalories,
    });
  } catch (error) {
    next(error);
  }
};

// Get nutritional insights
exports.getNutritionalInsights = async (req, res, next) => {
  try {
    const { days = 7 } = req.query;

    // Calculate date range
    const endDate = new Date();
    endDate.setHours(23, 59, 59, 999);

    const startDate = new Date();
    startDate.setDate(startDate.getDate() - (days - 1));
    startDate.setHours(0, 0, 0, 0);

    // Get all meals in the period
    const meals = await Meal.find({
      userId: req.userId,
      mealTime: {
        $gte: startDate,
        $lte: endDate,
      },
    });

    if (meals.length === 0) {
      return res.json({
        success: true,
        message: 'No meal data available for the selected period',
        insights: [],
      });
    }

    // Calculate averages
    const avgCalories = Math.round(
      meals.reduce((sum, meal) => sum + meal.nutrition.calories, 0) / meals.length
    );
    const avgProtein = Math.round(
      meals.reduce((sum, meal) => sum + meal.nutrition.protein, 0) / meals.length
    );
    const avgCarbs = Math.round(
      meals.reduce((sum, meal) => sum + meal.nutrition.carbohydrates, 0) / meals.length
    );
    const avgFat = Math.round(
      meals.reduce((sum, meal) => sum + meal.nutrition.fat, 0) / meals.length
    );

    // Generate insights
    const insights = [];

    if (avgCalories > 2500) {
      insights.push({
        type: 'warning',
        message: `Your average calorie intake (${avgCalories} KCal) is higher than recommended.`,
      });
    }

    if (avgProtein < 50) {
      insights.push({
        type: 'info',
        message: `Consider increasing protein intake (current: ${avgProtein}g/meal).`,
      });
    }

    if (avgFat > 80) {
      insights.push({
        type: 'warning',
        message: `Your average fat intake (${avgFat}g) might be high.`,
      });
    }

    insights.push({
      type: 'success',
      message: `You've logged ${meals.length} meals in the last ${days} days.`,
    });

    res.json({
      success: true,
      period: `Last ${days} days`,
      mealCount: meals.length,
      averages: {
        calories: avgCalories,
        protein: avgProtein,
        carbohydrates: avgCarbs,
        fat: avgFat,
      },
      insights,
    });
  } catch (error) {
    next(error);
  }
};
