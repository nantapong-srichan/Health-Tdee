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
import 'food_recommendations_v2.dart' as food_rec;
import 'services/meal_service.dart';
import 'services/image_upload_service.dart';

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
  String? _uploadedImageUrl; // Store image URL if uploaded from meal_confirmation_screen

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
      backgroundColor: const Color(0xFFFAF6F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. รูปภาพ
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Image.file(
                  File(widget.imageFile.path),
                  height: 320,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 28),
            
            // 2. ชื่ออาหารและความมั่นใจ
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    widget.result.foodName,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.kanit(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2C2C2C),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFABB5A).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'ความมั่นใจ: ${(widget.result.confidence * 100).toStringAsFixed(1)}%',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.kanit(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFFABB5A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3. Weight Slider
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'ปรับน้ำหนักอาหาร',
                    style: GoogleFonts.kanit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2C2C2C),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${_estimatedWeight.toStringAsFixed(0)} กรัม',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.kanit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFABB5A),
                    ),
                  ),
                  const SizedBox(height: 12),
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
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 4. การ์ดแคลอรี่
            _buildCaloriesCard(_calories),
            
            const SizedBox(height: 20),

            // 5. สารอาหาร
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'สารอาหาร',
                    style: GoogleFonts.kanit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2C2C2C),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildNutrientRow('โปรตีน', _protein, Colors.green),
                  const SizedBox(height: 12),
                  _buildNutrientRow('ไขมัน', _fat, Colors.orange),
                  const SizedBox(height: 12),
                  _buildNutrientRow('คาร์โบไฮเดรต', _carbs, Colors.blue),
                ],
              ),
            ),
            
            const SizedBox(height: 28),

            // 6. คำแนะนำสำหรับโรค (แสดงเฉพาะโรคที่ผู้ใช้มี)
            _buildDiseaseRecommendations(),
            
            const SizedBox(height: 20),

            // 7. ปุ่มยืนยัน และแก้ไข
            Row(
              children: [
                // Edit Button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      // Navigate to meal confirmation screen with slider UI for editing
                      final result = await Navigator.of(context).push<Map<String, dynamic>>(
                        MaterialPageRoute(
                          builder: (context) => MealConfirmationScreen(
                            foodName: widget.result.foodName,
                            imagePath: widget.imageFile.path,
                            nutritionValues: {
                              'calories': _calories,
                              'protein': _protein,
                              'carbs': _carbs,
                              'fat': _fat,
                            },
                            estimatedWeight: _estimatedWeight,
                            fromResultsScreen: true,
                          ),
                        ),
                      );
                      
                      // Update values if returned from meal_confirmation_screen
                      if (result != null) {
                        print('DEBUG RESULTS: Received result from meal_confirmation_screen: $result');
                        setState(() {
                          _calories = result['calories'] ?? _calories;
                          _protein = result['protein'] ?? _protein;
                          _carbs = result['carbs'] ?? _carbs;
                          _fat = result['fat'] ?? _fat;
                          _estimatedWeight = result['estimatedWeight'] ?? _estimatedWeight;
                          // Check if image was uploaded to GCS
                          if (result['imageUrl'] != null) {
                            _uploadedImageUrl = result['imageUrl'].toString();
                            print('DEBUG RESULTS: Image uploaded! URL: $_uploadedImageUrl');
                          }
                        });
                      }
                    },
                    icon: const Icon(Icons.edit),
                    label: Text(
                      'แก้ไข',
                      style: GoogleFonts.kanit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[400],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Confirm Button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _handleConfirmMeal();
                    },
                    icon: const Icon(Icons.check_circle),
                    label: Text(
                      'ยืนยัน',
                      style: GoogleFonts.kanit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFABB5A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Helper Widget สำหรับการ์ดแคลอรี่
  Widget _buildCaloriesCard(double calories) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'แคลอรี่ทั้งหมด',
            style: GoogleFonts.kanit(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            calories.toStringAsFixed(0),
            style: GoogleFonts.kanit(
              fontSize: 54,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFABB5A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'KCal',
            style: GoogleFonts.kanit(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Helper Widget สำหรับแถบสารอาหาร
  Widget _buildNutrientRow(String name, double amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Text(
              name,
              style: GoogleFonts.kanit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2C2C2C),
              ),
            ),
          ],
        ),
        Text(
          '${amount.toStringAsFixed(1)}g',
          style: GoogleFonts.kanit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // Widget สำหรับแสดงคำแนะนำตามโรค (เฉพาะโรคที่ผู้ใช้มี)
  Widget _buildDiseaseRecommendations() {
    final sessionData = Provider.of<SessionData>(context, listen: false);
    final userDiseases = sessionData.diseases ?? [];

    // ถ้าผู้ใช้ไม่มีโรค ไม่แสดงส่วนนี้
    if (userDiseases.isEmpty) {
      return const SizedBox.shrink();
    }

    // สร้าง list ของ recommendations ที่มีข้อมูล (filter out null)
    final diseaseRecommendationPairs = <MapEntry<String, food_rec.FoodRecommendation?>>[];
    
    for (final disease in userDiseases) {
      final recommendation = food_rec.FoodRecommendationDatabase
          .getRecommendation(widget.result.foodName, disease);
      diseaseRecommendationPairs.add(MapEntry(disease, recommendation));
    }

    // ถ้าไม่มีข้อมูลคำแนะนำสำหรับอาหารนี้เลย ไม่แสดง
    if (diseaseRecommendationPairs.every((e) => e.value == null)) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // หัวข้อคำแนะนำ
        Text(
          'แนะนำสำหรับสุขภาพของคุณ',
          style: GoogleFonts.kanit(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // แสดงคำแนะนำสำหรับแต่ละโรค
        ...diseaseRecommendationPairs.map((entry) {
          final disease = entry.key;
          final recommendation = entry.value;

          // ถ้าไม่มีคำแนะนำสำหรับโรคนี้ ข้ามไป
          if (recommendation == null) {
            return const SizedBox.shrink();
          }

          // ชื่อโรค
          String diseaseName = 'โรค';
          if (disease == 'diabetes') {
            diseaseName = 'เบาหวาน';
          } else if (disease == 'hypertension') {
            diseaseName = 'ความดันโลหิตสูง';
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ชื่อโรค
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFABB5A),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        diseaseName,
                        style: GoogleFonts.kanit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ✅ เหมาะสม or ❌ ไม่เหมาะสม (Dynamic)
                    Builder(
                      builder: (context) {
                        final isNotSuitable = recommendation.suitable.contains('ไม่เหมาะสม');
                        final bgColor = isNotSuitable ? Colors.red[50] : Colors.green[50];
                        final borderColor = isNotSuitable ? Colors.red[200] : Colors.green[200];
                        final iconColor = isNotSuitable ? Colors.red[600] : Colors.green[600];
                        final textColor = isNotSuitable ? Colors.red[800] : Colors.green[800];
                        final headerColor = isNotSuitable ? Colors.red[700] : Colors.green[700];
                        final icon = isNotSuitable ? Icons.cancel : Icons.check_circle;
                        final label = isNotSuitable ? 'ไม่เหมาะสม' : 'เหมาะสม';

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: borderColor!,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(icon, color: iconColor, size: 22),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      label,
                                      style: GoogleFonts.kanit(
                                        fontSize: 13,
                                        color: headerColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      recommendation.suitable,
                                      style: GoogleFonts.kanit(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    // ⚠️ ข้อควรระวัง
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange[200]!,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.warning_amber,
                              color: Colors.orange[700], size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ข้อควรระวัง',
                                  style: GoogleFonts.kanit(
                                    fontSize: 13,
                                    color: Colors.orange[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  recommendation.warning,
                                  style: GoogleFonts.kanit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange[800],
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 💡 คำแนะนำเพิ่มเติม
                    if (recommendation.notes.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blue[200]!,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info,
                                    color: Colors.blue[700], size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'คำแนะนำเพิ่มเติม',
                                  style: GoogleFonts.kanit(
                                    fontSize: 13,
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...recommendation.notes.map((note) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '• ',
                                      style: GoogleFonts.kanit(
                                        fontSize: 15,
                                        color: Colors.blue[600],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        note,
                                        style: GoogleFonts.kanit(
                                          fontSize: 14,
                                          color: Colors.blue[800],
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // Handle meal confirmation asynchronously to prevent UI freezing
  Future<void> _handleConfirmMeal() async {
    // Show loading indicator
    if (!mounted) return;
    
    // Use current edited nutrition values from state
    final mealService = MealService();
    final imageUploadService = ImageUploadService();
    
    try {
      String? finalImageUrl = _uploadedImageUrl;
      
      // If image not yet uploaded and we have an image file, upload it now
      if (finalImageUrl == null && widget.imageFile != null) {
        print('DEBUG RESULTS: Uploading image directly from results_screen...');
        try {
          finalImageUrl = await imageUploadService.uploadFoodImageWithMealData(
            imageFile: File(widget.imageFile.path),
            foodName: widget.result.foodName,
            nutrition: {
              'calories': _calories,
              'protein': _protein,
              'carbohydrates': _carbs,
              'fat': _fat,
            },
            estimatedWeight: _estimatedWeight,
            mealType: 'lunch',
            confidence: widget.result.confidence,
          );
          print('DEBUG RESULTS: Image upload result: $finalImageUrl');
          print('DEBUG RESULTS: uploadFoodImageWithMealData already saved the meal, no need to call saveMeal again');
          
          // uploadFoodImageWithMealData() already saved the meal, so we're done
          if (!mounted) return;
          
          // Just reload meals from backend and navigate back
          final sessionData = Provider.of<SessionData>(context, listen: false);
          final today = DateTime.now();
          final startOfDay = DateTime(today.year, today.month, today.day);
          final endOfDay = startOfDay.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
          
          final startDateStr = startOfDay.toIso8601String().split('.')[0];
          final endDateStr = endOfDay.toIso8601String().split('.')[0];
          
          final reloadResponse = await mealService.getMealHistory(
            startDate: startDateStr,
            endDate: endDateStr,
            limit: 100,
          );
          
          if (!mounted) return;
          
          if (reloadResponse['success']) {
            sessionData.clearMealsForDate(today);
            final meals = reloadResponse['meals'] as List?;
            if (meals != null && meals.isNotEmpty) {
              for (var meal in meals) {
                final mealDate = DateTime.parse(meal['mealTime'] as String).add(const Duration(hours: 7));
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
                  'date': mealDate.toString().split(' ')[0],
                  'mealId': meal['_id'],
                  'imageUrl': meal['imageUrl'],
                });
              }
            }
          }
          
          if (!mounted) return;
          // Pop twice: once for results_screen, once for image_picker_screen
          Navigator.of(context).pop();
          Navigator.of(context).pop();
          return;
        } catch (uploadError) {
          print('❌ Error uploading image: $uploadError');
          // If upload fails, fall back to saveMeal without image
        }
      }
      
      // If image already uploaded via edit, don't call saveMeal again
      Map<String, dynamic>? response;
      if (_uploadedImageUrl == null && finalImageUrl == null) {
        // Only call saveMeal if we didn't upload image
        print('DEBUG RESULTS: _handleConfirmMeal - Saving meal with imageUrl: $finalImageUrl');
        response = await mealService.saveMeal(
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
          imageUrl: finalImageUrl,
        );

        print('DEBUG RESULTS: saveMeal response: $response');
      } else {
        // Meal already saved via upload, just reload from backend
        print('DEBUG RESULTS: Meal already saved via upload, skipping saveMeal call');
        response = {'success': true};
      }
      
      if (!mounted) return;
      
      if (response != null && response['success']) {
        // After saving to backend, reload meals from backend
        // This ensures the data is in sync with database timestamps
        final sessionData = Provider.of<SessionData>(context, listen: false);
        
        // Reload meals for today to get the newly saved meal with correct timestamp
        final today = DateTime.now();
        final startOfDay = DateTime(today.year, today.month, today.day);
        final endOfDay = startOfDay.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
        
        // Send as Bangkok local times (without Z)
        final startDateStr = startOfDay.toIso8601String().split('.')[0]; // 2026-01-28T00:00:00
        final endDateStr = endOfDay.toIso8601String().split('.')[0];     // 2026-01-29T00:00:00
        
        final reloadResponse = await mealService.getMealHistory(
          startDate: startDateStr,
          endDate: endDateStr,
          limit: 100,
        );
        
        if (!mounted) return;
        
        if (reloadResponse['success']) {
          // Clear today's meals and reload from backend
          sessionData.clearMealsForDate(today);
          final meals = reloadResponse['meals'] as List?;
          if (meals != null && meals.isNotEmpty) {
            for (var meal in meals) {
              // Convert UTC to Bangkok time (UTC+7) before extracting date
              final utcTime = DateTime.parse(meal['mealTime'] as String);
              final bangkokTime = utcTime.add(const Duration(hours: 7));
              final dateInBangkokTime = bangkokTime.toString().split(' ')[0]; // YYYY-MM-DD
              
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
                'date': dateInBangkokTime,
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