const mongoose = require('mongoose');

const mealSchema = new mongoose.Schema(
  {
    // User Reference
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'User ID is required'],
      index: true, // For faster queries
    },

    // Meal Information
    foodName: {
      type: String,
      required: [true, 'Food name is required'],
      trim: true,
    },
    description: {
      type: String,
      trim: true,
    },

    // Nutritional Information
    nutrition: {
      calories: {
        type: Number,
        required: [true, 'Calories is required'],
        min: [0, 'Calories cannot be negative'],
      },
      protein: {
        type: Number,
        required: [true, 'Protein is required'],
        min: [0, 'Protein cannot be negative'],
        description: 'in grams',
      },
      carbohydrates: {
        type: Number,
        required: [true, 'Carbohydrates is required'],
        min: [0, 'Carbohydrates cannot be negative'],
        description: 'in grams',
      },
      fat: {
        type: Number,
        required: [true, 'Fat is required'],
        min: [0, 'Fat cannot be negative'],
        description: 'in grams',
      },
      fiber: {
        type: Number,
        default: 0,
        description: 'in grams',
      },
      sodium: {
        type: Number,
        default: 0,
        description: 'in mg',
      },
    },

    // Weight Information
    estimatedWeight: {
      type: Number,
      required: [true, 'Estimated weight is required'],
      min: [1, 'Weight must be at least 1 gram'],
      description: 'in grams',
    },

    // Image (optional)
    imageUrl: {
      type: String,
      trim: true,
    },

    // AI Model Confidence (from TFLite)
    confidence: {
      type: Number,
      min: [0, 'Confidence must be between 0 and 1'],
      max: [1, 'Confidence must be between 0 and 1'],
    },

    // Meal Timing
    mealType: {
      type: String,
      enum: ['breakfast', 'lunch', 'dinner', 'snack', 'other'],
      default: 'other',
    },
    mealTime: {
      type: Date,
      required: [true, 'Meal time is required'],
      default: Date.now,
    },

    // Metadata
    notes: {
      type: String,
      trim: true,
    },
    createdAt: {
      type: Date,
      default: Date.now,
      index: true, // For sorting by date
    },
    updatedAt: {
      type: Date,
      default: Date.now,
    },
  },
  { timestamps: true }
);

// Compound index for efficient queries by user and date
mealSchema.index({ userId: 1, mealTime: -1 });
mealSchema.index({ userId: 1, createdAt: -1 });

// Virtual for date only (without time)
mealSchema.virtual('mealDate').get(function () {
  return this.mealTime.toISOString().split('T')[0];
});

// Calculate total macros
mealSchema.methods.getTotalMacros = function () {
  return {
    calories: this.nutrition.calories,
    protein: this.nutrition.protein,
    carbohydrates: this.nutrition.carbohydrates,
    fat: this.nutrition.fat,
  };
};

module.exports = mongoose.model('Meal', mealSchema);
