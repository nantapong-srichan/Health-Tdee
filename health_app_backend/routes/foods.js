const express = require('express');
const router = express.Router();
const Food = require('../models/Food');

// Get all foods
router.get('/', async (req, res) => {
  try {
    const foods = await Food.find().sort({ foodName: 1 });
    res.json({
      success: true,
      count: foods.length,
      data: foods,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching foods',
      error: error.message,
    });
  }
});

// Get food by name (with fuzzy matching fallback)
router.get('/:foodName', async (req, res) => {
  try {
    const searchName = decodeURIComponent(req.params.foodName).trim();
    console.log('DEBUG: Searching for food:', searchName);
    
    // Try exact match first (case-insensitive)
    let food = await Food.findOne({ 
      foodName: { $regex: `^${searchName}$`, $options: 'i' } 
    });
    
    console.log('DEBUG: Exact match result:', food ? 'found' : 'not found');
    
    if (!food) {
      // Fuzzy matching: search for similar food names
      const allFoods = await Food.find();
      const searchNameLower = searchName.toLowerCase();
      let closestMatch = null;
      let maxSimilarity = 0;
      
      for (const f of allFoods) {
        const similarity = calculateSimilarity(searchNameLower, f.foodName.toLowerCase());
        console.log(`DEBUG: Comparing "${searchName}" with "${f.foodName}" = ${similarity}%`);
        if (similarity > maxSimilarity && similarity > 50) {
          maxSimilarity = similarity;
          closestMatch = f;
        }
      }
      
      console.log('DEBUG: Fuzzy match result:', closestMatch ? `found "${closestMatch.foodName}"` : 'not found');
      
      if (!closestMatch) {
        return res.status(404).json({
          success: false,
          message: 'Food not found',
        });
      }
      food = closestMatch;
    }
    
    res.json({
      success: true,
      data: food,
    });
  } catch (error) {
    console.error('ERROR fetching food:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching food',
      error: error.message,
    });
  }
});

// Helper function to calculate string similarity
function calculateSimilarity(s1, s2) {
  if (s1 === s2) return 100;
  if (s1.length === 0 || s2.length === 0) return 0;
  
  // Check if one string contains the other
  if (s1.includes(s2) || s2.includes(s1)) return 80;
  
  let matches = 0;
  const minLen = Math.min(s1.length, s2.length);
  
  for (let i = 0; i < minLen; i++) {
    if (s1[i] === s2[i]) matches++;
  }
  
  return Math.round((matches * 100) / minLen);
}

// Create food (admin only - optional)
router.post('/', async (req, res) => {
  try {
    const food = new Food(req.body);
    await food.save();
    res.status(201).json({
      success: true,
      message: 'Food created successfully',
      data: food,
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      message: 'Error creating food',
      error: error.message,
    });
  }
});

// Update food (admin only - optional)
router.put('/:id', async (req, res) => {
  try {
    const food = await Food.findByIdAndUpdate(req.params.id, req.body, {
      new: true,
      runValidators: true,
    });
    if (!food) {
      return res.status(404).json({
        success: false,
        message: 'Food not found',
      });
    }
    res.json({
      success: true,
      message: 'Food updated successfully',
      data: food,
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      message: 'Error updating food',
      error: error.message,
    });
  }
});

// Delete food (admin only - optional)
router.delete('/:id', async (req, res) => {
  try {
    const food = await Food.findByIdAndDelete(req.params.id);
    if (!food) {
      return res.status(404).json({
        success: false,
        message: 'Food not found',
      });
    }
    res.json({
      success: true,
      message: 'Food deleted successfully',
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error deleting food',
      error: error.message,
    });
  }
});

module.exports = router;
