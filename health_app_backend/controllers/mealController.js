const Meal = require('../models/Meal');
const { uploadImageToGCS, deleteImageFromGCS } = require('../utils/uploadService');

// Save meal result
exports.saveMeal = async (req, res, next) => {
  try {
    const { foodName, nutrition, estimatedWeight, mealType, confidence, notes, imageUrl: bodyImageUrl } = req.body;
    
    console.log('DEBUG: saveMeal request body:', req.body);
    console.log('DEBUG: userId:', req.userId);
    console.log('DEBUG: foodName:', foodName);
    console.log('DEBUG: File uploaded:', req.file ? 'Yes' : 'No');
    console.log('DEBUG: imageUrl from body:', bodyImageUrl);

    let imageUrl = bodyImageUrl || null;

    // Handle image upload if file is provided
    if (req.file) {
      try {
        // อัปโหลดรูปภาพไปยัง Google Cloud Storage
        imageUrl = await uploadImageToGCS(
          req.file.buffer,
          req.file.originalname,
          req.file.mimetype
        );
        console.log('✅ Image uploaded successfully:', imageUrl);
      } catch (uploadError) {
        console.error('❌ Error uploading image:', uploadError.message);
        // ดำเนินการต่อแม้การอัปโหลดรูปล้มเหลว แต่บันทึกไว้
        console.log('⚠️ Continuing meal save without image');
      }
    }

    const meal = await Meal.create({
      userId: req.userId,
      foodName,
      nutrition,
      estimatedWeight,
      mealType: mealType || 'other',
      confidence,
      imageUrl, // บันทึก URL ของรูปภาพ (จาก body หรืออัปโหลด)
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

    // Date filtering - Query for meals in Bangkok timezone
    if (startDate || endDate) {
      filter.mealTime = {};
      
      // Frontend sends dates as Bangkok local time strings (e.g., "2026-01-28T00:00:00")
      // We need to convert to UTC for querying MongoDB
      // Bangkok is UTC+7, so:
      // Bangkok 2026-01-28T00:00:00 = UTC 2026-01-27T17:00:00 (subtract 7 hours)
      
      const parseAsLocalTime = (dateString) => {
        // Parse the string as if it's UTC first, then subtract 7 hours
        // to get the UTC equivalent of Bangkok local time
        const utcDate = new Date(dateString + 'Z'); // Force UTC parse
        return new Date(utcDate.getTime() - (7 * 60 * 60 * 1000));
      };
      
      if (startDate) {
        const utcStart = parseAsLocalTime(startDate);
        filter.mealTime.$gte = utcStart;
        console.log('DEBUG: startDate (Bangkok):', startDate);
        console.log('DEBUG: startDate (UTC):', utcStart.toISOString());
      }
      
      if (endDate) {
        const utcEnd = parseAsLocalTime(endDate);
        filter.mealTime.$lte = utcEnd;
        console.log('DEBUG: endDate (Bangkok):', endDate);
        console.log('DEBUG: endDate (UTC):', utcEnd.toISOString());
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
    
    let imageUrl = meal.imageUrl; // เก็บ URL รูปเก่าไว้ก่อน

    // Handle image replacement if new file is uploaded
    if (req.file) {
      try {
        // ลบรูปเก่าหากมี
        if (meal.imageUrl) {
          await deleteImageFromGCS(meal.imageUrl);
        }
        
        // อัปโหลดรูปใหม่
        imageUrl = await uploadImageToGCS(
          req.file.buffer,
          req.file.originalname,
          req.file.mimetype
        );
        console.log('✅ Image updated successfully:', imageUrl);
      } catch (uploadError) {
        console.error('❌ Error updating image:', uploadError.message);
        // ยังคงใช้รูปเก่า
        imageUrl = meal.imageUrl;
      }
    }

    meal = await Meal.findByIdAndUpdate(
      req.params.id,
      {
        foodName,
        nutrition,
        estimatedWeight,
        mealType,
        imageUrl,
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

    // ลบรูปภาพจาก Google Cloud Storage หากมี
    if (meal.imageUrl) {
      try {
        await deleteImageFromGCS(meal.imageUrl);
        console.log('✅ Image deleted successfully');
      } catch (deleteError) {
        console.error('⚠️ Error deleting image:', deleteError.message);
        // ดำเนินการต่อแม้การลบรูปล้มเหลว
      }
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
