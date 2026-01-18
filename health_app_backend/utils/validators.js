const { body, validationResult } = require('express-validator');

const validateEmail = () => {
  return body('email')
    .isEmail()
    .normalizeEmail()
    .withMessage('Please provide a valid email');
};

const validatePassword = () => {
  return body('password')
    .isLength({ min: 6 })
    .withMessage('Password must be at least 6 characters');
};

const validateRegister = [
  body('name')
    .trim()
    .notEmpty()
    .withMessage('Name is required')
    .isLength({ min: 2 })
    .withMessage('Name must be at least 2 characters'),

  body('email')
    .isEmail()
    .normalizeEmail()
    .withMessage('Please provide a valid email'),

  body('password')
    .isLength({ min: 6 })
    .withMessage('Password must be at least 6 characters'),
];

const validateMeal = [
  body('foodName')
    .trim()
    .notEmpty()
    .withMessage('Food name is required'),

  body('nutrition.calories')
    .isNumeric()
    .isInt({ min: 0 })
    .withMessage('Calories must be a non-negative integer'),

  body('nutrition.protein')
    .isNumeric()
    .withMessage('Protein must be a valid number'),

  body('nutrition.carbohydrates')
    .isNumeric()
    .withMessage('Carbohydrates must be a valid number'),

  body('nutrition.fat')
    .isNumeric()
    .withMessage('Fat must be a valid number'),

  body('estimatedWeight')
    .isNumeric()
    .isInt({ min: 1 })
    .withMessage('Weight must be at least 1 gram'),
];

const handleValidationErrors = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    console.error('DEBUG: Validation errors:', errors.array());
    return res.status(400).json({
      success: false,
      message: 'Validation errors',
      errors: errors.array(),
    });
  }
  next();
};

module.exports = {
  validateEmail,
  validatePassword,
  validateRegister,
  validateMeal,
  handleValidationErrors,
};
