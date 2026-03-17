// lib/results_screen.dart
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'meal_confirmation_screen.dart';
import 'recognition_result.dart';
import 'session_data.dart';
import 'nutrition_database.dart';
import 'food_recommendations_v2.dart' as food_rec;
import 'food_recommendation_categories.dart';
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
  late double _sodium;
  late double _estimatedWeight;
  late String _currentFoodName; // ชื่ออาหารที่อาจเปลี่ยนแปลง
  bool _isLoading = true;
  String? _uploadedImageUrl;

  @override
  void initState() {
    super.initState();
    _estimatedWeight = widget.result.estimatedWeight;
    _currentFoodName = widget.result.foodName; // เก็บชื่อเริ่มต้น
    _updateNutrition(_estimatedWeight);
  }

  Future<void> _updateNutrition(double weight) async {
    try {
      // ดึงข้อมูลสารอาหารจาก API ใช้ชื่อปัจจุบัน
      final info = await NutritionDatabase.getNutritionInfo(
        _currentFoodName,
      );

      if (info != null) {
        // คำนวณสารอาหารตามน้ำหนัก
        final nutritionCalc = NutritionDatabase.calculateNutrition(info, weight);
        
        setState(() {
          _estimatedWeight = weight;
          _calories = nutritionCalc.calories;
          _protein = nutritionCalc.protein;
          _carbs = nutritionCalc.carbs;
          _fat = nutritionCalc.fat;
          _sodium = nutritionCalc.sodium;
          _isLoading = false;
        });
      } else {
        // ไม่พบข้อมูล
        setState(() {
          _isLoading = false;
          _calories = 0;
          _protein = 0;
          _carbs = 0;
          _fat = 0;
          _sodium = 0;
        });
      }
    } catch (e) {
      print('Error updating nutrition: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ค้นหาเมนูอาหารจาก API ตามคำค้นหา
  Future<List<String>> _searchFoodNames(String query) async {
    if (query.isEmpty) return [];
    
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:5000/api/foods'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] is List) {
          final foods = data['data'] as List;
          final queryLower = query.toLowerCase();
          
          // ค้นหาเมนูที่มีชื่อเริ่มต้นหรือมีคำค้นหาอยู่
          final results = <String>[];
          for (var food in foods) {
            final foodName = (food['foodName'] ?? '').toString();
            if (foodName.toLowerCase().contains(queryLower)) {
              results.add(foodName);
            }
          }
          return results;
        }
      }
      return [];
    } catch (e) {
      print('Error searching foods: $e');
      return [];
    }
  }

  // แสดง dialog สำหรับแก้ไขชื่ออาหาร
  void _showFoodSearchDialog() {
    final searchController = TextEditingController(text: _currentFoodName);
    final searchResults = <String>[];
    
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'แก้ไขชื่ออาหาร',
                      style: GoogleFonts.kanit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // ช่องค้นหา
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'พิมพ์ชื่ออาหาร...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.search),
                      ),
                      onChanged: (value) async {
                        final results = await _searchFoodNames(value);
                        setState(() {
                          searchResults.clear();
                          searchResults.addAll(results);
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // รายการผลลัพธ์
                    if (searchResults.isNotEmpty)
                      Container(
                        constraints: const BoxConstraints(maxHeight: 250),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: searchResults.length,
                          itemBuilder: (context, index) {
                            final foodName = searchResults[index];
                            return ListTile(
                              title: Text(
                                foodName,
                                style: GoogleFonts.kanit(),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                // อัปเดตชื่ออาหารและดึงข้อมูลใหม่
                                this.setState(() {
                                  _currentFoodName = foodName;
                                });
                                _updateNutrition(_estimatedWeight);
                              },
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 16),
                    // ปุ่มยืนยัน/ยกเลิก
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[400],
                          ),
                          child: Text(
                            'ยกเลิก',
                            style: GoogleFonts.kanit(),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            // ใช้ชื่อที่พิมพ์แม้ไม่มีในรายการ
                            this.setState(() {
                              _currentFoodName = searchController.text;
                            });
                            _updateNutrition(_estimatedWeight);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFABB5A),
                          ),
                          child: Text(
                            'ตกลง',
                            style: GoogleFonts.kanit(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFFFABB5A),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'กำลังดึงข้อมูลสารอาหาร...',
                    style: GoogleFonts.kanit(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
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
                  // ชื่ออาหารพร้อมปุ่มแก้ไข
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          _currentFoodName,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.kanit(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2C2C2C),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Color(0xFFFABB5A)),
                        onPressed: _showFoodSearchDialog,
                        tooltip: 'แก้ไขชื่ออาหาร',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
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
                  const SizedBox(height: 12),
                  _buildNutrientRow('โซเดียม', _sodium, const Color(0xFF0288D1), unit: 'mg'),
                ],
              ),
            ),

            const SizedBox(height: 28),
            // 5.5. Carb/Sodium Quota Card (เพื่อแสดงการใช้โควตารายวัน)
            _buildCarbSodiumQuotaCard(),

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
                      final result = await Navigator.of(context)
                          .push<Map<String, dynamic>>(
                            MaterialPageRoute(
                              builder: (context) => MealConfirmationScreen(
                                foodName: _currentFoodName,
                                imagePath: widget.imageFile.path,
                                nutritionValues: {
                                  'calories': _calories,
                                  'protein': _protein,
                                  'carbs': _carbs,
                                  'fat': _fat,
                                  'sodium': _sodium,
                                },
                                estimatedWeight: _estimatedWeight,
                                fromResultsScreen: true,
                              ),
                            ),
                          );

                      // Update values if returned from meal_confirmation_screen
                      if (result != null) {
                        print(
                          'DEBUG RESULTS: Received result from meal_confirmation_screen: $result',
                        );
                        setState(() {
                          _calories = result['calories'] ?? _calories;
                          _protein = result['protein'] ?? _protein;
                          _carbs = result['carbs'] ?? _carbs;
                          _fat = result['fat'] ?? _fat;
                          _sodium = result['sodium'] ?? _sodium;
                          _estimatedWeight =
                              result['estimatedWeight'] ?? _estimatedWeight;
                          // Check if image was uploaded to GCS
                          if (result['imageUrl'] != null) {
                            _uploadedImageUrl = result['imageUrl'].toString();
                            print(
                              'DEBUG RESULTS: Image uploaded! URL: $_uploadedImageUrl',
                            );
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
  Widget _buildNutrientRow(String name, double amount, Color color, {String unit = 'g'}) {
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
          '${amount.toStringAsFixed(1)}$unit',
          style: GoogleFonts.kanit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // Helper method to get today's total carbs
  double _getTodayTotalCarbs() {
    final sessionData = Provider.of<SessionData>(context, listen: false);
    final meals = sessionData.getMealsForDate(DateTime.now());
    double total = 0;
    for (var meal in meals) {
      total += (meal['carbs'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }

  // Helper method to get today's total sodium
  double _getTodayTotalSodium() {
    final sessionData = Provider.of<SessionData>(context, listen: false);
    final meals = sessionData.getMealsForDate(DateTime.now());
    double total = 0;
    for (var meal in meals) {
      total += (meal['sodium'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }

  // Widget สำหรับแสดง Carb/Sodium Quota เทียบกับเป้าหมายวันนี้
  Widget _buildCarbSodiumQuotaCard() {
    final sessionData = Provider.of<SessionData>(context, listen: false);
    final userDiseases = sessionData.diseases ?? [];

    // ถ้าไม่มีโรค ไม่แสดง
    if (userDiseases.isEmpty) {
      return const SizedBox.shrink();
    }

    final todayCarbsTotal = _getTodayTotalCarbs();
    final todaySodiumTotal = _getTodayTotalSodium();
    final carbTarget = sessionData.diabetesCarbLimit ?? 150.0;
    final sodiumTarget = sessionData.hypertensionSodiumLimit ?? 2000.0;

    final hasDiabetes = userDiseases.contains('diabetes');
    final hasHypertension = userDiseases.contains('hypertension');

    // ถ้าไม่มี diabetes หรือ hypertension ไม่แสดง
    if (!hasDiabetes && !hasHypertension) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Carbs Quota Card (for Type 2 diabetes only)
        if (hasDiabetes && sessionData.diabetesType == 'type2') ...[
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'โควตาคาร์บประจำวัน',
                      style: GoogleFonts.kanit(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2C2C2C),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${(todayCarbsTotal + _carbs).toStringAsFixed(1)} / ${carbTarget.toStringAsFixed(1)} g',
                        style: GoogleFonts.kanit(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple[700],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'วันนี้: ${todayCarbsTotal.toStringAsFixed(1)}g + อาหารนี้: ${_carbs.toStringAsFixed(1)}g',
                  style: GoogleFonts.kanit(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: ((todayCarbsTotal + _carbs) / carbTarget).clamp(
                      0.0,
                      1.5,
                    ),
                    minHeight: 8,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getCarbStatusColor(todayCarbsTotal + _carbs, carbTarget),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Builder(
                  builder: (context) {
                    final remainingCarbs = carbTarget - (todayCarbsTotal + _carbs);
                    return Text(
                      remainingCarbs >= 0 
                        ? 'หลังจากทานมื้อนี้แล้ว วันนี้คุณเหลือโควตาคาร์บอีกเพียง ${remainingCarbs.toStringAsFixed(1)}g'
                        : 'หลังจากทานมื้อนี้แล้ว วันนี้คุณเกินโควตาคาร์บแล้ว ${(-remainingCarbs).toStringAsFixed(1)}g',
                      style: GoogleFonts.kanit(
                        fontSize: 13,
                        color: remainingCarbs >= 0 ? Colors.green[700] : Colors.red[700],
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Sodium Quota Card (for hypertension)
        if (hasHypertension) ...[
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'โควตาโซเดียมประจำวัน',
                      style: GoogleFonts.kanit(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2C2C2C),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${(todaySodiumTotal + _sodium).toStringAsFixed(1)} / ${sodiumTarget.toStringAsFixed(1)} mg',
                        style: GoogleFonts.kanit(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.red[700],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'วันนี้: ${todaySodiumTotal.toStringAsFixed(1)}mg + อาหารนี้: ${_sodium.toStringAsFixed(1)}mg',
                  style: GoogleFonts.kanit(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: ((todaySodiumTotal + _sodium) / sodiumTarget).clamp(0.0, 1.5),
                    minHeight: 8,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getSodiumStatusColor(todaySodiumTotal + _sodium, sodiumTarget),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Builder(
                  builder: (context) {
                    final remainingSodium = sodiumTarget - (todaySodiumTotal + _sodium);
                    return Text(
                      remainingSodium >= 0 
                        ? 'หลังจากทานมื้อนี้แล้ว วันนี้คุณเหลือโควตาโซเดียมอีกเพียง ${remainingSodium.toStringAsFixed(1)}mg'
                        : 'หลังจากทานมื้อนี้แล้ว วันนี้คุณเกินโควตาโซเดียมแล้ว ${(-remainingSodium).toStringAsFixed(1)}mg',
                      style: GoogleFonts.kanit(
                        fontSize: 13,
                        color: remainingSodium >= 0 ? Colors.green[700] : Colors.red[700],
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // Helper method to determine carb status color
  Color _getCarbStatusColor(double current, double target) {
    if (current < target * 0.8) {
      return Colors.green;
    } else if (current >= target * 0.8 && current <= target) {
      return Colors.green;
    } else if (current > target && current <= target * 1.2) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  // Helper method to determine sodium status color
  Color _getSodiumStatusColor(double current, double target) {
    if (current < target * 0.8) {
      return Colors.green;
    } else if (current >= target * 0.8 && current <= target) {
      return Colors.green;
    } else if (current > target && current <= target * 1.2) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  // Widget สำหรับแสดงคำแนะนำตามโรค (เฉพาะโรคที่ผู้ใช้มี)
  Widget _buildDiseaseRecommendations() {
    final sessionData = Provider.of<SessionData>(context, listen: false);
    final userDiseases = sessionData.diseases ?? [];

    // ถ้าผู้ใช้ไม่มีโรค ไม่แสดงส่วนนี้
    if (userDiseases.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // หัวข้อคำแนะนำ
        Text(
          'แนะนำสำหรับสุขภาพของคุณ',
          style: GoogleFonts.kanit(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // แสดงคำแนะนำแบบอัจฉริยะสำหรับแต่ละโรค
        ...userDiseases.map((disease) {
          final advice = _getSmartAdvice(
            _currentFoodName,
            _carbs,
            _fat,
            _protein,
            _sodium,
            disease,
            sessionData.diabetesType, // ส่ง diabetesType
          );

          if (advice == null) {
            return const SizedBox.shrink() as Widget;
          }

          return _buildSmartAdviceCard(disease, advice, sessionData.diabetesType);
        }).toList(),
      ],
    );
  }

  // Helper method: สร้างคำแนะนำแบบอัจฉริยะ
  SmartAdviceResult? _getSmartAdvice(
    String foodName,
    double carbs,
    double fat,
    double protein,
    double sodium,
    String disease,
    String? diabetesType,
  ) {
    final categoryId = FoodCategoryDatabase.getFoodCategory(foodName);
    if (categoryId == null) return null;

    final nutrients = NutrientData(
      sodiumMg: sodium,
      carbsG: carbs,
      fiberG: 2.0,
      fatG: fat,
      proteinG: protein,
    );

    final results = SmartAdviceGenerator.generateAdviceForConditions(
      foodName: foodName,
      categoryId: categoryId,
      nutrients: nutrients,
      userConditions: [disease],
      diabetesType: diabetesType,
    );

    return results[disease];
  }

  // Helper method: UI card สำหรับแสดงคำแนะนำ
  Widget _buildSmartAdviceCard(String disease, SmartAdviceResult advice, String? diabetesType) {
    final diseaseLabel = disease == 'diabetes'
        ? (diabetesType == 'type1'
            ? 'เบาหวานประเภทที่ 1'
            : diabetesType == 'type2'
                ? 'เบาหวานประเภทที่ 2'
                : 'เบาหวาน')
        : 'ความดันโลหิตสูง';
    final statusColor = _getStatusColor(advice.suitable);
    final statusIcon = _getStatusIcon(advice.suitable);

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
              // ชื่อโรค (Type 1: orange badge ขึ้นต้น)
              if (disease == 'diabetes' && diabetesType == 'type1')
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFABB5A),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    diseaseLabel,
                    style: GoogleFonts.kanit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                )
              else if (disease != 'diabetes' || diabetesType != 'type1')
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFABB5A),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    diseaseLabel,
                    style: GoogleFonts.kanit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              if (disease == 'diabetes' && diabetesType == 'type1')
                const SizedBox(height: 16)
              else
                const SizedBox(height: 16),

              // สถานะ (Type 1 + Type 2 ทั้งคู่ใช้ statusColor ที่เปลี่ยนตามสถานะ)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor, width: 1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(statusIcon, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getStatusLabel(advice.suitable),
                            style: GoogleFonts.kanit(
                              fontSize: 13,
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            advice.suitable,
                            style: GoogleFonts.kanit(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ข้อควรระวัง
              if (advice.warnings.isNotEmpty) ...[
                const SizedBox(height: 12),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.warning_amber,
                            color: Colors.orange[700],
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'ข้อควรระวัง',
                            style: GoogleFonts.kanit(
                              fontSize: 13,
                              color: Colors.orange[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...advice.warnings.map((warning) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '• ',
                                style: GoogleFonts.kanit(
                                  fontSize: 15,
                                  color: Colors.orange[600],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  warning,
                                  style: GoogleFonts.kanit(
                                    fontSize: 14,
                                    color: Colors.orange[800],
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

              // คำแนะนำเพิ่มเติม
              if (advice.notes.isNotEmpty) ...[
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
                          Icon(
                            Icons.info,
                            color: Colors.blue[700],
                            size: 20,
                          ),
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
                      ...advice.notes.map((note) {
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
  }

  Color _getStatusColor(String suitable) {
    if (suitable.contains('ไม่เหมาะสม')) return Colors.red;
    if (suitable.contains('ต้องนับแม่นยำ')) return Colors.orange;
    if (suitable.contains('ระวัง')) return Colors.orange;
    if (suitable.contains('ควรระวัง')) return Colors.orange;
    if (suitable.contains('เหมาะสมอย่างยิ่ง')) return Colors.green;
    if (suitable.contains('เหมาะสม')) return Colors.blue;
    return Colors.grey;
  }

  String _getStatusIcon(String suitable) {
    if (suitable.contains('ไม่เหมาะสม')) return '🔴';
    if (suitable.contains('ควรระวัง')) return '🟠';
    if (suitable.contains('เหมาะสมอย่างยิ่ง')) return '🟢';
    if (suitable.contains('เหมาะสม')) return '🟡';
    return '🟡';
  }

  String _getStatusLabel(String suitable) {
    if (suitable.contains('ไม่เหมาะสม')) return 'ไม่เหมาะสม';
    if (suitable.contains('ควรระวัง')) return 'ควรระวัง';
    if (suitable.contains('เหมาะสมอย่างยิ่ง')) return 'เหมาะสมอย่างยิ่ง';
    if (suitable.contains('เหมาะสม')) return 'เหมาะสม';
    return '';
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
            foodName: _currentFoodName,
            nutrition: {
              'calories': _calories,
              'protein': _protein,
              'carbohydrates': _carbs,
              'fat': _fat,
              'sodium': _sodium,
            },
            estimatedWeight: _estimatedWeight,
            mealType: 'lunch',
            confidence: widget.result.confidence,
          );
          print('DEBUG RESULTS: Image upload result: $finalImageUrl');
          print(
            'DEBUG RESULTS: uploadFoodImageWithMealData already saved the meal, no need to call saveMeal again',
          );

          // uploadFoodImageWithMealData() already saved the meal, so we're done
          if (!mounted) return;

          // Just reload meals from backend and navigate back
          final sessionData = Provider.of<SessionData>(context, listen: false);
          final today = DateTime.now();
          final startOfDay = DateTime(today.year, today.month, today.day);
          final endOfDay = startOfDay
              .add(const Duration(days: 1))
              .subtract(const Duration(seconds: 1));

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
                final mealDate = DateTime.parse(
                  meal['mealTime'] as String,
                ).add(const Duration(hours: 7));
                sessionData.addMeal({
                  'foodName': meal['foodName'],
                  'calories': (meal['nutrition']?['calories'] ?? 0).toDouble(),
                  'protein': (meal['nutrition']?['protein'] ?? 0).toDouble(),
                  'carbs': (meal['nutrition']?['carbohydrates'] ?? 0)
                      .toDouble(),
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
        print(
          'DEBUG RESULTS: _handleConfirmMeal - Saving meal with imageUrl: $finalImageUrl',
        );
        response = await mealService.saveMeal(
          foodName: _currentFoodName,
          calories: _calories.toInt(),
          protein: _protein,
          carbs: _carbs,
          fat: _fat,
          fiber: 0.0,
          sodium: _sodium,
          estimatedWeight: _estimatedWeight,
          confidence: widget.result.confidence,
          mealType: 'lunch',
          imageUrl: finalImageUrl,
        );

        print('DEBUG RESULTS: saveMeal response: $response');
      } else {
        // Meal already saved via upload, just reload from backend
        print(
          'DEBUG RESULTS: Meal already saved via upload, skipping saveMeal call',
        );
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
        final endOfDay = startOfDay
            .add(const Duration(days: 1))
            .subtract(const Duration(seconds: 1));

        // Send as Bangkok local times (without Z)
        final startDateStr = startOfDay.toIso8601String().split(
          '.',
        )[0]; // 2026-01-28T00:00:00
        final endDateStr = endOfDay.toIso8601String().split(
          '.',
        )[0]; // 2026-01-29T00:00:00

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
              final dateInBangkokTime = bangkokTime.toString().split(
                ' ',
              )[0]; // YYYY-MM-DD

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
            content: Text('บันทึก${_currentFoodName}สำเร็จ'),
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
