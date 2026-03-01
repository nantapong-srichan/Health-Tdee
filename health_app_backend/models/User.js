const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema(
  {
    // Basic Information
    name: {
      type: String,
      required: [true, 'Please provide a name'],
      trim: true,
      minlength: [2, 'Name must be at least 2 characters'],
    },
    email: {
      type: String,
      required: [true, 'Please provide an email'],
      unique: true,
      lowercase: true,
      match: [
        /^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,3})+$/,
        'Please provide a valid email',
      ],
    },
    password: {
      type: String,
      required: [true, 'Please provide a password'],
      minlength: [6, 'Password must be at least 6 characters'],
      select: false, // Don't return password by default
    },

    // User Profile
    gender: {
      type: String,
      enum: ['male', 'female', 'other'],
      description: 'User gender for BMR calculation',
    },
    age: {
      type: Number,
      min: [1, 'Age must be at least 1'],
      max: [150, 'Age must be less than 150'],
    },
    weight: {
      type: Number,
      description: 'Weight in kg',
    },
    height: {
      type: Number,
      description: 'Height in cm',
    },
    bmr: {
      type: Number,
      description: 'Basal Metabolic Rate in kcal/day',
      default: null,
    },
    tdee: {
      type: Number,
      description: 'Total Daily Energy Expenditure in kcal/day',
      default: null,
    },
    goal: {
      type: String,
      enum: ['weight_loss', 'weight_gain', 'maintain', 'muscle_gain'],
      default: 'maintain',
      description: 'User fitness goal',
    },
    dailyCalorieNeed: {
      type: Number,
      description: 'Adjusted daily calorie need based on goal in kcal/day',
      default: null,
    },
    proteinGrams: {
      type: Number,
      description: 'Protein requirement in grams per day',
      default: null,
    },
    activityLevel: {
      type: String,
      enum: ['sedentary', 'light', 'moderate', 'active', 'veryActive'],
      default: 'moderate',
    },

    // Profile Image
    profileImageUrl: {
      type: String,
      default: null,
      description: 'URL to user profile image in GCS',
    },

    // Dietary Goals
    dailyCalorieGoal: {
      type: Number,
      default: 2000,
      description: 'Target daily calories in KCal',
    },

    // Health Conditions
    diseases: {
      type: [String],
      default: [],
      description: 'List of chronic diseases (e.g., diabetes, hypertension)',
    },
    diabetesCarbLimit: {
      type: Number,
      description: 'Daily carbohydrate limit in grams for diabetic users',
      default: null,
    },

    // Account Status
    isVerified: {
      type: Boolean,
      default: false,
    },
    createdAt: {
      type: Date,
      default: Date.now,
    },
    updatedAt: {
      type: Date,
      default: Date.now,
    },
  },
  { timestamps: true }
);

// Hash password before saving
userSchema.pre('save', async function (next) {
  // Only hash if password is modified
  if (!this.isModified('password')) {
    return next();
  }

  try {
    const salt = await bcrypt.genSalt(10);
    this.password = await bcrypt.hash(this.password, salt);
    next();
  } catch (error) {
    next(error);
  }
});

// Method to compare passwords
userSchema.methods.comparePassword = async function (inputPassword) {
  return await bcrypt.compare(inputPassword, this.password);
};

// Remove sensitive data before response
userSchema.methods.toJSON = function () {
  const obj = this.toObject();
  delete obj.password;
  return obj;
};

module.exports = mongoose.model('User', userSchema);
