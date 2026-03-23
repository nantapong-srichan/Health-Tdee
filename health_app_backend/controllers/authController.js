const jwt = require('jsonwebtoken');
const User = require('../models/User');
const { 
  calculateBMR, 
  isValidInput, 
  calculateTDEE, 
  calculateDailyCalories,
  calculateProtein 
} = require('../utils/bmrCalculator');

// Generate JWT Token
const generateToken = (userId) => {
  return jwt.sign({ userId }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRE || '7d',
  });
};

// Register - Create new user
exports.register = async (req, res, next) => {
  try {
    const { name, email, password, gender, age, weight, height, activityLevel, goal, dailyCalorieGoal, diseases, diabetesType, diabetesCarbLimit } = req.body;

    // Check if user already exists
    const userExists = await User.findOne({ email });
    if (userExists) {
      return res.status(400).json({
        success: false,
        message: 'Email already registered',
      });
    }

    // Prepare user data
    const userData = {
      name,
      email,
      password,
    };

    // If health data is provided, calculate BMR, TDEE, and nutrition info
    if (gender && age && weight && height) {
      if (!isValidInput(gender, weight, height, age)) {
        return res.status(400).json({
          success: false,
          message: 'Invalid health information. Gender, age, weight, and height are required and must be positive numbers.',
        });
      }

      // Calculate BMR and related values
      try {
        const bmr = calculateBMR(gender, weight, height, age);
        const activityLvl = activityLevel || 'moderate';
        const tdee = calculateTDEE(bmr, activityLvl);
        const userGoal = goal || 'maintain';
        const dailyCalorieNeed = calculateDailyCalories(tdee, userGoal);
        const proteinGrams = calculateProtein(weight, userGoal);

        userData.gender = gender;
        userData.age = age;
        userData.weight = weight;
        userData.height = height;
        userData.bmr = bmr;
        userData.tdee = tdee;
        userData.goal = userGoal;
        userData.dailyCalorieNeed = dailyCalorieNeed;
        userData.proteinGrams = proteinGrams;
        userData.activityLevel = activityLvl;
        userData.dailyCalorieGoal = dailyCalorieGoal || dailyCalorieNeed;
      } catch (error) {
        return res.status(400).json({
          success: false,
          message: `Calculation Error: ${error.message}`,
        });
      }
    }

    // Add disease data if provided
    if (diseases && Array.isArray(diseases) && diseases.length > 0) {
      userData.diseases = diseases;
    }
    if (diabetesType !== undefined && diabetesType !== null) {
      userData.diabetesType = diabetesType;
    }
    if (diabetesCarbLimit) {
      userData.diabetesCarbLimit = diabetesCarbLimit;
    }

    // Create new user
    const user = await User.create(userData);

    // Generate token
    const token = generateToken(user._id);

    res.status(201).json({
      success: true,
      message: 'User registered successfully',
      token,
      user: user.toJSON(),
    });
  } catch (error) {
    next(error);
  }
};

// Login - Authenticate user
exports.login = async (req, res, next) => {
  try {
    const { email, password } = req.body;

    // Validate input
    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Email and password are required',
      });
    }

    // Find user and include password field
    const user = await User.findOne({ email }).select('+password');

    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password',
      });
    }

    // Compare passwords
    const isPasswordCorrect = await user.comparePassword(password);

    if (!isPasswordCorrect) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password',
      });
    }

    // Generate token
    const token = generateToken(user._id);

    // If user doesn't have BMR but has health data, calculate it
    if (!user.bmr && user.gender && user.weight && user.height && user.age) {
      try {
        user.bmr = calculateBMR(user.gender, user.weight, user.height, user.age);
      } catch (error) {
        console.log('Could not calculate BMR:', error.message);
      }
    }

    // If user doesn't have TDEE, calculate it
    if (!user.tdee && user.bmr && user.activityLevel) {
      user.tdee = calculateTDEE(user.bmr, user.activityLevel);
    }
    
    // If user doesn't have dailyCalorieNeed, calculate it
    if (!user.dailyCalorieNeed && user.tdee && user.goal) {
      user.dailyCalorieNeed = calculateDailyCalories(user.tdee, user.goal);
    }
    
    // If user doesn't have proteinGrams, calculate it
    if (!user.proteinGrams && user.weight && user.goal) {
      user.proteinGrams = calculateProtein(user.weight, user.goal);
    }

    res.json({
      success: true,
      message: 'Login successful',
      token,
      user: user.toJSON(),
    });
  } catch (error) {
    next(error);
  }
};

// Get Current User
exports.getCurrentUser = async (req, res, next) => {
  try {
    const user = await User.findById(req.userId);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    // If user doesn't have BMR but has health data, calculate it
    if (!user.bmr && user.gender && user.weight && user.height && user.age) {
      try {
        user.bmr = calculateBMR(user.gender, user.weight, user.height, user.age);
      } catch (error) {
        console.log('Could not calculate BMR:', error.message);
      }
    }

    // If user doesn't have TDEE, calculate it
    if (!user.tdee && user.bmr && user.activityLevel) {
      user.tdee = calculateTDEE(user.bmr, user.activityLevel);
    }
    
    // If user doesn't have dailyCalorieNeed, calculate it
    if (!user.dailyCalorieNeed && user.tdee && user.goal) {
      user.dailyCalorieNeed = calculateDailyCalories(user.tdee, user.goal);
    }
    
    // If user doesn't have proteinGrams, calculate it
    if (!user.proteinGrams && user.weight && user.goal) {
      user.proteinGrams = calculateProtein(user.weight, user.goal);
    }

    res.json({
      success: true,
      user: user.toJSON(),
    });
  } catch (error) {
    next(error);
  }
};

// Update User Profile
exports.updateProfile = async (req, res, next) => {
  try {
    const { name, age, weight, height, gender, bmr, activityLevel, goal, dailyCalorieGoal, diseases, diabetesType, diabetesCarbLimit, hypertensionSodiumLimit } =
      req.body;

    console.log('=== DEBUG: updateProfile ===');
    console.log('Received diseases from frontend:', diseases);
    console.log('Diseases type:', typeof diseases);
    console.log('Is array:', Array.isArray(diseases));
    console.log('Diseases length:', diseases?.length);

    const updateData = {
      updatedAt: Date.now(),
    };

    // Add optional fields if provided
    if (name) updateData.name = name;
    if (age) updateData.age = age;
    if (weight) updateData.weight = weight;
    if (height) updateData.height = height;
    if (gender) updateData.gender = gender;
    if (activityLevel) updateData.activityLevel = activityLevel;
    if (goal) updateData.goal = goal;
    if (dailyCalorieGoal) updateData.dailyCalorieGoal = dailyCalorieGoal;

    // Add disease data if provided
    if (diseases !== undefined) {
      // If diseases is null or empty array, set to empty array to clear diseases
      updateData.diseases = (Array.isArray(diseases) && diseases.length > 0) ? diseases : [];
      console.log('Setting updateData.diseases to:', updateData.diseases);
    }
    if (diabetesType !== undefined) {
      updateData.diabetesType = diabetesType || null;
    }
    if (diabetesCarbLimit !== undefined) {
      updateData.diabetesCarbLimit = diabetesCarbLimit || null;
    }
    if (hypertensionSodiumLimit !== undefined) {
      updateData.hypertensionSodiumLimit = hypertensionSodiumLimit || null;
    }

    console.log('UpdateData to apply:', JSON.stringify(updateData, null, 2));

    // Calculate all nutrition metrics if we have health data
    if (age && weight && height && gender) {
      if (!isValidInput(gender, weight, height, age)) {
        return res.status(400).json({
          success: false,
          message: 'Invalid health information for calculation.',
        });
      }

      try {
        const calculatedBmr = calculateBMR(gender, weight, height, age);
        const activityLvl = activityLevel || 'moderate';
        const tdee = calculateTDEE(calculatedBmr, activityLvl);
        const userGoal = goal || 'maintain';
        const dailyCalorieNeed = calculateDailyCalories(tdee, userGoal);
        const proteinGrams = calculateProtein(weight, userGoal);

        updateData.bmr = calculatedBmr;
        updateData.tdee = tdee;
        updateData.dailyCalorieNeed = dailyCalorieNeed;
        updateData.proteinGrams = proteinGrams;
        
        // Set dailyCalorieGoal from calculated value if not provided
        if (!dailyCalorieGoal) {
          updateData.dailyCalorieGoal = dailyCalorieNeed;
        }
      } catch (error) {
        return res.status(400).json({
          success: false,
          message: `Calculation Error: ${error.message}`,
        });
      }
    }

    const user = await User.findByIdAndUpdate(
      req.userId,
      updateData,
      { new: true, runValidators: true }
    );

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    console.log('User after update:', JSON.stringify(user, null, 2));
    console.log('User diseases after update:', user.diseases);

    res.json({
      success: true,
      message: 'Profile updated successfully',
      user: user.toJSON(),
    });
  } catch (error) {
    next(error);
  }
};

// Change Password
exports.changePassword = async (req, res, next) => {
  try {
    const { currentPassword, newPassword } = req.body;

    const user = await User.findById(req.userId).select('+password');

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    // Verify current password
    const isPasswordCorrect = await user.comparePassword(currentPassword);

    if (!isPasswordCorrect) {
      return res.status(401).json({
        success: false,
        message: 'Current password is incorrect',
      });
    }

    // Update password
    user.password = newPassword;
    await user.save();

    res.json({
      success: true,
      message: 'Password changed successfully',
    });
  } catch (error) {
    next(error);
  }
};

// Change Email
exports.changeEmail = async (req, res, next) => {
  try {
    const { newEmail, password } = req.body;

    const user = await User.findById(req.userId).select('+password');

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    // Check if new email is already in use
    const emailExists = await User.findOne({ email: newEmail });
    if (emailExists) {
      return res.status(400).json({
        success: false,
        message: 'Email already in use',
      });
    }

    // Verify password
    const isPasswordCorrect = await user.comparePassword(password);

    if (!isPasswordCorrect) {
      return res.status(401).json({
        success: false,
        message: 'Password is incorrect',
      });
    }

    // Update email
    user.email = newEmail;
    await user.save();

    res.json({
      success: true,
      message: 'Email changed successfully',
    });
  } catch (error) {
    next(error);
  }
};

// Upload Profile Image
exports.uploadProfileImage = async (req, res, next) => {
  try {
    const { Storage } = require('@google-cloud/storage');
    
    // Initialize GCS
    const storage = new Storage({
      projectId: process.env.GCP_PROJECT_ID,
      keyFilename: process.env.GCP_KEY_FILE,
    });

    const bucket = storage.bucket(process.env.GCP_BUCKET_NAME);

    // Check if file exists
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'No image provided',
      });
    }

    const user = await User.findById(req.userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    // Generate filename: imgprofile/{userId}_{timestamp}_{originalname}
    const timestamp = Date.now();
    const originalName = req.file.originalname;
    const filename = `imgprofile/${req.userId}_${timestamp}_${originalName}`;

    // Create file object
    const file = bucket.file(filename);

    // Upload to GCS
    await new Promise((resolve, reject) => {
      const stream = file.createWriteStream({
        metadata: {
          contentType: req.file.mimetype,
        },
      });

      stream.on('error', (err) => {
        console.error('Upload error:', err);
        reject(err);
      });

      stream.on('finish', () => {
        resolve();
      });

      stream.end(req.file.buffer);
    });

    // Generate public URL
    const publicUrl = `https://storage.googleapis.com/${process.env.GCP_BUCKET_NAME}/${filename}`;

    // Update user profile image URL
    user.profileImageUrl = publicUrl;
    await user.save();

    res.json({
      success: true,
      message: 'Profile image uploaded successfully',
      profileImageUrl: publicUrl,
    });
  } catch (error) {
    console.error('Profile image upload error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to upload profile image',
      error: error.message,
    });
  }
};

module.exports.generateToken = generateToken;