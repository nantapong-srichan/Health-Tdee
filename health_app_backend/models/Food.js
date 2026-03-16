const mongoose = require('mongoose');

const foodSchema = new mongoose.Schema(
  {
    // Food Information
    foodName: {
      type: String,
      required: [true, 'Food name is required'],
      trim: true,
      unique: true,
      index: true,
    },

    // Nutritional Information (per 100g)
    nutrition: {
      calories: {
        type: Number,
        required: [true, 'Calories is required'],
        min: [0, 'Calories cannot be negative'],
        description: 'kcal per 100g',
      },
      protein: {
        type: Number,
        required: [true, 'Protein is required'],
        min: [0, 'Protein cannot be negative'],
        description: 'grams per 100g',
      },
      fat: {
        type: Number,
        required: [true, 'Fat is required'],
        min: [0, 'Fat cannot be negative'],
        description: 'grams per 100g',
      },
      carbohydrates: {
        type: Number,
        required: [true, 'Carbohydrates is required'],
        min: [0, 'Carbohydrates cannot be negative'],
        description: 'grams per 100g',
      },
      sodium: {
        type: Number,
        required: [true, 'Sodium is required'],
        min: [0, 'Sodium cannot be negative'],
        description: 'mg per 100g',
      },
    },

    // Metadata
    createdAt: {
      type: Date,
      default: Date.now,
    },
    updatedAt: {
      type: Date,
      default: Date.now,
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model('Food', foodSchema);
