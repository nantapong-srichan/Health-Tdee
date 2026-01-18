const Meal = require('../models/Meal');

// Save meal result
exports.saveMeal = async (req, res, next) => {
  try {
    const { foodName, nutrition, estimatedWeight, mealType, confidence, imageUrl, notes } =
      req.body;

    console.log('DEBUG: saveMeal request body:', req.body);
    console.log('DEBUG: userId:', req.userId);
    console.log('DEBUG: foodName:', foodName);
    console.log('DEBUG: nutrition:', nutrition);

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

    console.log('DEBUG: Meal created successfully:', meal._id);

    res.status(201).json({
      success: true,
      message: 'Meal saved successfully',
      meal,
    });
  } catch (error) {
    console.error('DEBUG: saveMeal error:', error.message);
    console.error('DEBUG: saveMeal error details:', error);
    next(error);
  }
};

// Get user meal history
exports.getMealHistory = async (req, res, next) => {
  try {
    const { startDate, endDate, limit = 50, offset = 0, timezone = 'Asia/Bangkok' } = req.query;

    console.log('DEBUG: getMealHistory called');
    console.log('DEBUG: userId:', req.userId);
    console.log('DEBUG: startDate:', startDate);
    console.log('DEBUG: endDate:', endDate);
    console.log('DEBUG: timezone:', timezone);

    let filter = { userId: req.userId };

    // Date filtering - Convert local date to UTC for MongoDB
    if (startDate || endDate) {
      filter.mealTime = {};
      
      // Bangkok is UTC+7
      // Frontend sends Bangkok local time, JS parses it as UTC, so we ADD 7 hours to get true UTC
      // Example: Local Bangkok 2026-01-18T00:00:00 parsed as UTC = 2026-01-18T00:00:00Z
      //         True UTC should be: 2026-01-17T17:00:00Z (subtract 7 from local time)
      // So: localStart (parsed as UTC) + 7 hours = true UTC? NO!
      // Correct: true UTC = localStart - 7 hours, so offset should be -7
      // But JS parsed it wrong as UTC, so we need to ADD 7 to get back to what it really is
      // Actually: Frontend sends as Bangkok local "2026-01-18T00:00:00"
      //         We need to find UTC times that = this Bangkok time
      //         Bangkok 2026-01-18T00:00:00 = UTC 2026-01-17T17:00:00
      // JS new Date("2026-01-18T00:00:00.000") = 2026-01-18T00:00:00.000Z (assumes UTC)
      // To get true UTC: subtract 7 hours = 2026-01-17T17:00:00.000Z
      const timezoneOffsets = {
        'Asia/Bangkok': -7,  // Offset to convert from what JS parsed to true UTC
      };
      const offsetHours = timezoneOffsets[timezone] || -7;
      const offsetMs = offsetHours * 60 * 60 * 1000;
      
      if (startDate) {
        // startDate is in Bangkok local time (e.g., "2026-01-18T00:00:00.000")
        // JS new Date(startDate) parses this as UTC automatically
        // We subtract 7 hours to get the true UTC time that equals this Bangkok local time
        const localStart = new Date(startDate);
        const utcStart = new Date(localStart.getTime() + offsetMs);
        filter.mealTime.$gte = utcStart;
        console.log('DEBUG: startDate (Bangkok local):', startDate);
        console.log('DEBUG: startDate (true UTC):', utcStart.toISOString());
      }
      
      if (endDate) {
        // endDate is in Bangkok local time
        const localEnd = new Date(endDate);
        const utcEnd = new Date(localEnd.getTime() + offsetMs);
        filter.mealTime.$lte = utcEnd;
        console.log('DEBUG: endDate (Bangkok local):', endDate);
        console.log('DEBUG: endDate (true UTC):', utcEnd.toISOString());
      }
    }

    console.log('DEBUG: Query filter:', JSON.stringify(filter, null, 2));

    const meals = await Meal.find(filter)
      .sort({ mealTime: -1 })
      .limit(parseInt(limit))
      .skip(parseInt(offset));

    console.log('DEBUG: Meals found count:', meals.length);
    console.log('DEBUG: Meals:', JSON.stringify(meals, null, 2));

    const total = await Meal.countDocuments(filter);

    res.json({
      success: true,
      total,
      count: meals.length,
      meals,
    });
  } catch (error) {
    console.error('DEBUG: getMealHistory error:', error.message);
    console.error('DEBUG: getMealHistory error details:', error);
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
