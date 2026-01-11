const Meal = require('../models/Meal');

// Save meal result
exports.saveMeal = async (req, res, next) => {
  try {
    const { foodName, nutrition, estimatedWeight, mealType, confidence, imageUrl, notes } =
      req.body;

    const meal = await Meal.create({
      userId: req.userId,
      foodName,
      nutrition,
      estimatedWeight,
      mealType: mealType || 'other',
      confidence,
      imageUrl,
      notes,
      mealTime: new Date(),
    });

    res.status(201).json({
      success: true,
      message: 'Meal saved successfully',
      meal,
    });
  } catch (error) {
    next(error);
  }
};

// Get user meal history
exports.getMealHistory = async (req, res, next) => {
  try {
    const { startDate, endDate, limit = 50, offset = 0 } = req.query;

    let filter = { userId: req.userId };

    // Date filtering
    if (startDate || endDate) {
      filter.mealTime = {};
      if (startDate) {
        filter.mealTime.$gte = new Date(startDate);
      }
      if (endDate) {
        filter.mealTime.$lte = new Date(endDate);
      }
    }

    const meals = await Meal.find(filter)
      .sort({ mealTime: -1 })
      .limit(parseInt(limit))
      .skip(parseInt(offset));

    const total = await Meal.countDocuments(filter);

    res.json({
      success: true,
      total,
      count: meals.length,
      meals,
    });
  } catch (error) {
    next(error);
  }
};

// Get single meal
exports.getMeal = async (req, res, next) => {
  try {
    const meal = await Meal.findById(req.params.id);

    if (!meal) {
      return res.status(404).json({
        success: false,
        message: 'Meal not found',
      });
    }

    // Check authorization
    if (meal.userId.toString() !== req.userId) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to access this meal',
      });
    }

    res.json({
      success: true,
      meal,
    });
  } catch (error) {
    next(error);
  }
};

// Update meal
exports.updateMeal = async (req, res, next) => {
  try {
    let meal = await Meal.findById(req.params.id);

    if (!meal) {
      return res.status(404).json({
        success: false,
        message: 'Meal not found',
      });
    }

    // Check authorization
    if (meal.userId.toString() !== req.userId) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to update this meal',
      });
    }

    const { foodName, nutrition, estimatedWeight, mealType, notes } = req.body;

    meal = await Meal.findByIdAndUpdate(
      req.params.id,
      {
        foodName,
        nutrition,
        estimatedWeight,
        mealType,
        notes,
        updatedAt: Date.now(),
      },
      { new: true, runValidators: true }
    );

    res.json({
      success: true,
      message: 'Meal updated successfully',
      meal,
    });
  } catch (error) {
    next(error);
  }
};

// Delete meal
exports.deleteMeal = async (req, res, next) => {
  try {
    const meal = await Meal.findById(req.params.id);

    if (!meal) {
      return res.status(404).json({
        success: false,
        message: 'Meal not found',
      });
    }

    // Check authorization
    if (meal.userId.toString() !== req.userId) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to delete this meal',
      });
    }

    await Meal.findByIdAndDelete(req.params.id);

    res.json({
      success: true,
      message: 'Meal deleted successfully',
    });
  } catch (error) {
    next(error);
  }
};
