// lib/results_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'meal_confirmation_screen.dart';
import 'recognition_result.dart';
import 'session_data.dart';
import 'nutrition_database.dart';
import 'services/meal_service.dart';

class ResultsScreen extends StatefulWidget {
  final XFile imageFile;
  final RecognitionResult result;
  
  const ResultsScreen({
    super.key, 
    required this.imageFile,
    required this.result,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  late double _calories;
  late double _protein;
  late double _carbs;
  late double _fat;
  late double _estimatedWeight;

  @override
  void initState() {
    super.initState();
    _estimatedWeight = widget.result.estimatedWeight;
    _updateNutrition(_estimatedWeight);
  }

  void _updateNutrition(double weight) {
    final nutritionCalc = NutritionDatabase.calculateNutrition(
      widget.result.foodName,
      weight,
    );
    setState(() {
      _estimatedWeight = weight;
      _calories = nutritionCalc?.calories ?? 0.0;
      _protein = nutritionCalc?.protein ?? 0.0;
      _carbs = nutritionCalc?.carbs ?? 0.0;
      _fat = nutritionCalc?.fat ?? 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFFDEFE0), // สีครีมพื้นหลัง
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDEFE0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. รูปภาพ
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                File(widget.imageFile.path),
                height: 300,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 24),
            
            // 2. ชื่ออาหารและความมั่นใจ
            Text(
              widget.result.foodName,
              textAlign: TextAlign.center,
              style: GoogleFonts.kanit(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'ความมั่นใจ: ${(widget.result.confidence * 100).toStringAsFixed(1)}%',
              textAlign: TextAlign.center,
              style: GoogleFonts.kanit(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            // Weight slider
            Text(
              'น้ำหนักโดยประมาณ: ${_estimatedWeight.toStringAsFixed(0)} กรัม',
              textAlign: TextAlign.center,
              style: GoogleFonts.kanit(
                fontSize: 18,
                color: Colors.grey[700],
              ),
            ),
            Slider(
              value: _estimatedWeight,
              min: 50,
              max: 800,
              divisions: 75,
              label: '${_estimatedWeight.toStringAsFixed(0)}g',
              activeColor: const Color(0xFFFABB5A),
              inactiveColor: Colors.grey[300],
              onChanged: (value) {
                _updateNutrition(value);
              },
            ),
            const SizedBox(height: 24),

            // 3. การ์ดแคลอรี่
            _buildCaloriesCard(_calories),
            
            const SizedBox(height: 24),

            // 4. สารอาหาร
            Text(
              'สารอาหาร',
              style: GoogleFonts.kanit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildNutrientRow('โปรตีน', _protein, Colors.green),
            _buildNutrientRow('ไขมัน', _fat, Colors.orange),
            _buildNutrientRow('คาร์โบไฮเดรต', _carbs, Colors.blue),
            
            const SizedBox(height: 40),

            // 5. ปุ่มยืนยัน และแก้ไข
            Row(
              children: [
                // Edit Button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      // Navigate to meal confirmation screen with slider UI for editing
                      final result = await Navigator.of(context).push<Map<String, double>>(
                        MaterialPageRoute(
                          builder: (context) => MealConfirmationScreen(
                            foodName: widget.result.foodName,
                            imagePath: 'assets/food1.png',
                            nutritionValues: {
                              'calories': _calories,
                              'protein': _protein,
                              'carbs': _carbs,
                              'fat': _fat,
                            },
                            fromResultsScreen: true,
                          ),
                        ),
                      );
                      
                      // Update values if returned from meal_confirmation_screen
                      if (result != null) {
                        setState(() {
                          _calories = result['calories'] ?? _calories;
                          _protein = result['protein'] ?? _protein;
                          _carbs = result['carbs'] ?? _carbs;
                          _fat = result['fat'] ?? _fat;
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[400],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'แก้ไข',
                      style: GoogleFonts.kanit(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Confirm Button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _handleConfirmMeal();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFABB5A),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'ยืนยัน',
                      style: GoogleFonts.kanit(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper Widget สำหรับการ์ดแคลอรี่
  Widget _buildCaloriesCard(double calories) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'แคลอรี่ทั้งหมด',
            style: GoogleFonts.kanit(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            calories.toStringAsFixed(0),
            style: GoogleFonts.kanit(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFABB5A),
            ),
          ),
          Text(
            'KCal',
            style: GoogleFonts.kanit(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  // Helper Widget สำหรับแถบสารอาหาร
  Widget _buildNutrientRow(String name, double amount, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Text(
                name,
                style: GoogleFonts.kanit(fontSize: 18),
              ),
            ],
          ),
          Text(
            '${amount.toStringAsFixed(1)} กรัม',
            style: GoogleFonts.kanit(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // Handle meal confirmation asynchronously to prevent UI freezing
  Future<void> _handleConfirmMeal() async {
    // Show loading indicator
    if (!mounted) return;
    
    // Use current edited nutrition values from state
    final mealService = MealService();
    
    try {
      // Save meal to backend (this happens in background)
      final response = await mealService.saveMeal(
        foodName: widget.result.foodName,
        calories: _calories.toInt(),
        protein: _protein,
        carbs: _carbs,
        fat: _fat,
        fiber: 0.0,
        sodium: 0.0,
        estimatedWeight: _estimatedWeight,
        confidence: widget.result.confidence,
        mealType: 'lunch',
      );

      print('DEBUG RESULTS: saveMeal response: $response');
      
      if (!mounted) return;
      
      if (response['success']) {
        // After saving to backend, reload meals from backend
        // This ensures the data is in sync with database timestamps
        final sessionData = Provider.of<SessionData>(context, listen: false);
        
        // Reload meals for today to get the newly saved meal with correct timestamp
        final today = DateTime.now();
        final startOfDay = DateTime(today.year, today.month, today.day);
        final endOfDay = startOfDay.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
        
        final reloadResponse = await mealService.getMealHistory(
          startDate: startOfDay.toIso8601String(),
          endDate: endOfDay.toIso8601String(),
          limit: 100,
        );
        
        if (!mounted) return;
        
        if (reloadResponse['success']) {
          // Clear today's meals and reload from backend
          sessionData.clearMealsForDate(today);
          final meals = reloadResponse['meals'] as List?;
          if (meals != null && meals.isNotEmpty) {
            for (var meal in meals) {
              sessionData.addMeal({
                'foodName': meal['foodName'],
                'calories': (meal['nutrition']?['calories'] ?? 0).toDouble(),
                'protein': (meal['nutrition']?['protein'] ?? 0).toDouble(),
                'carbs': (meal['nutrition']?['carbohydrates'] ?? 0).toDouble(),
                'fat': (meal['nutrition']?['fat'] ?? 0).toDouble(),
                'fiber': (meal['nutrition']?['fiber'] ?? 0).toDouble(),
                'sodium': (meal['nutrition']?['sodium'] ?? 0).toDouble(),
                'estimatedWeight': meal['estimatedWeight'],
                'confidence': meal['confidence'],
                'mealType': meal['mealType'] ?? 'other',
                'date': DateTime.parse(meal['mealTime'] as String).toString().split(' ')[0],
                'mealId': meal['_id'],
              });
            }
          }
        }
        
        // Show success notification
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('บันทึก${widget.result.foodName}สำเร็จ'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Navigate back to home screen
        if (mounted) {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        }
      } else {
        // Show error notification
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('เกิดข้อผิดพลาด: ${response['message']}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('Error in _handleConfirmMeal: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}