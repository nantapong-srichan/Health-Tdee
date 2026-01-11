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

class ResultsScreen extends StatelessWidget {
  final XFile imageFile;
  final RecognitionResult result;
  
  const ResultsScreen({
    super.key, 
    required this.imageFile,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    // คำนวณข้อมูลสารอาหาร
    final nutritionCalc = NutritionDatabase.calculateNutrition(
      result.foodName,
      result.estimatedWeight,
    );

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
                File(imageFile.path),
                height: 300,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 24),
            
            // 2. ชื่ออาหารและความมั่นใจ
            Text(
              result.foodName,
              textAlign: TextAlign.center,
              style: GoogleFonts.kanit(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'ความมั่นใจ: ${(result.confidence * 100).toStringAsFixed(1)}%',
              textAlign: TextAlign.center,
              style: GoogleFonts.kanit(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            Text(
              'น้ำหนักโดยประมาณ: ${result.estimatedWeight.toStringAsFixed(0)} กรัม',
              textAlign: TextAlign.center,
              style: GoogleFonts.kanit(
                fontSize: 18,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 24),

            // 3. การ์ดแคลอรี่
            if (nutritionCalc != null) 
              _buildCaloriesCard(nutritionCalc.calories)
            else
              _buildCaloriesCard(0),
            
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
            if (nutritionCalc != null) ...[
              _buildNutrientRow('โปรตีน', nutritionCalc.protein, Colors.green),
              _buildNutrientRow('ไขมัน', nutritionCalc.fat, Colors.orange),
              _buildNutrientRow('คาร์โบไฮเดรต', nutritionCalc.carbs, Colors.blue),
            ] else ...[
              _buildNutrientRow('โปรตีน', 0, Colors.green),
              _buildNutrientRow('ไขมัน', 0, Colors.orange),
              _buildNutrientRow('คาร์โบไฮเดรต', 0, Colors.blue),
            ],
            
            const SizedBox(height: 40),

            // 5. ปุ่มยืนยัน และแก้ไข
            Row(
              children: [
                // Edit Button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Calculate nutrition values
                      final nutritionCalc = NutritionDatabase.calculateNutrition(
                        result.foodName,
                        result.estimatedWeight,
                      );
                      
                      // Navigate to meal confirmation screen with slider UI for editing
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => MealConfirmationScreen(
                            foodName: result.foodName,
                            imagePath: 'assets/food1.png', // Use appropriate asset or food name
                            nutritionValues: {
                              'calories': nutritionCalc?.calories ?? 0.0,
                              'protein': nutritionCalc?.protein ?? 0.0,
                              'carbs': nutritionCalc?.carbs ?? 0.0,
                              'fat': nutritionCalc?.fat ?? 0.0,
                            },
                          ),
                        ),
                      );
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
                      // Calculate nutrition values and save directly
                      final nutritionCalc = NutritionDatabase.calculateNutrition(
                        result.foodName,
                        result.estimatedWeight,
                      );
                      
                      // Save meal directly to SessionData
                      final sessionData = Provider.of<SessionData>(context, listen: false);
                      sessionData.addMeal({
                        'name': result.foodName,
                        'imagePath': 'assets/food1.png',
                        'calories': nutritionCalc?.calories ?? 0.0,
                        'protein': nutritionCalc?.protein ?? 0.0,
                        'carbs': nutritionCalc?.carbs ?? 0.0,
                        'fat': nutritionCalc?.fat ?? 0.0,
                        'timestamp': DateTime.now(),
                      });
                      
                      // Show success notification
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('บันทึก${result.foodName}สำเร็จ'),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                      
                      // Navigate back to home
                      Navigator.of(context).pop();
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
}