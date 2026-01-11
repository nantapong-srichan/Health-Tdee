import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'services/meal_service.dart';
import 'services/api_service.dart';
import 'home_screen.dart';

class MealEditScreen extends StatefulWidget {
  final XFile imageFile;
  final String foodName;
  final double confidence;
  final double estimatedWeight;

  const MealEditScreen({
    super.key,
    required this.imageFile,
    required this.foodName,
    required this.confidence,
    required this.estimatedWeight,
  });

  @override
  State<MealEditScreen> createState() => _MealEditScreenState();
}

class _MealEditScreenState extends State<MealEditScreen> {
  late double _calories;
  late double _protein;
  late double _carbs;
  late double _fat;
  late double _fiber;
  late double _sodium;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Default values - you can calculate these from nutrition database
    _calories = 280.0;
    _protein = 15.0;
    _carbs = 28.0;
    _fat = 10.0;
    _fiber = 2.0;
    _sodium = 400.0;
  }

  Future<void> _saveMeal() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = ApiService();
      final isAuthenticated = await apiService.isAuthenticated();

      if (!isAuthenticated) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('กรุณาเข้าสู่ระบบก่อน'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final mealService = MealService();
      final response = await mealService.saveMeal(
        foodName: widget.foodName,
        calories: _calories.toInt(),
        protein: _protein,
        carbs: _carbs,
        fat: _fat,
        fiber: _fiber,
        sodium: _sodium,
        estimatedWeight: widget.estimatedWeight,
        confidence: widget.confidence,
        mealType: 'lunch',
        mealTime: DateTime.now(),
      );

      if (mounted) {
        if (response['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('บันทึกอาหารสำเร็จ'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'เกิดข้อผิดพลาด'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDEFE0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDEFE0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'แก้ไขข้อมูลอาหาร',
          style: GoogleFonts.kanit(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Food Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(widget.imageFile.path),
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 20),

              // Food Name and Confidence
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ชื่ออาหาร',
                      style: GoogleFonts.kanit(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.foodName,
                      style: GoogleFonts.kanit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'ความมั่นใจ: ${(widget.confidence * 100).toStringAsFixed(1)}%',
                      style: GoogleFonts.kanit(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Nutrition Sliders
              Text(
                'ปรับปรุงข้อมูลโภคนำ',
                style: GoogleFonts.kanit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              // Calories
              _buildNutrientSlider(
                label: 'แคลอรี่',
                value: _calories,
                max: 1000,
                unit: 'kcal',
                onChanged: (value) {
                  setState(() {
                    _calories = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Protein
              _buildNutrientSlider(
                label: 'โปรตีน',
                value: _protein,
                max: 100,
                unit: 'กรัม',
                onChanged: (value) {
                  setState(() {
                    _protein = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Carbs
              _buildNutrientSlider(
                label: 'คาร์โบไฮเดรต',
                value: _carbs,
                max: 100,
                unit: 'กรัม',
                onChanged: (value) {
                  setState(() {
                    _carbs = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Fat
              _buildNutrientSlider(
                label: 'ไขมัน',
                value: _fat,
                max: 100,
                unit: 'กรัม',
                onChanged: (value) {
                  setState(() {
                    _fat = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Fiber
              _buildNutrientSlider(
                label: 'เส้นใย',
                value: _fiber,
                max: 50,
                unit: 'กรัม',
                onChanged: (value) {
                  setState(() {
                    _fiber = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Sodium
              _buildNutrientSlider(
                label: 'โซเดียม',
                value: _sodium,
                max: 2000,
                unit: 'มก.',
                onChanged: (value) {
                  setState(() {
                    _sodium = value;
                  });
                },
              ),
              const SizedBox(height: 32),

              // Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'สรุปข้อมูล',
                      style: GoogleFonts.kanit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'แคลอรี่รวม:',
                          style: GoogleFonts.kanit(fontSize: 13),
                        ),
                        Text(
                          '${_calories.toInt()} kcal',
                          style: GoogleFonts.kanit(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFABB5A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'โปรตีน:',
                          style: GoogleFonts.kanit(fontSize: 13),
                        ),
                        Text(
                          '${_protein.toStringAsFixed(1)} ก.',
                          style: GoogleFonts.kanit(fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'คาร์โบไฮเดรต:',
                          style: GoogleFonts.kanit(fontSize: 13),
                        ),
                        Text(
                          '${_carbs.toStringAsFixed(1)} ก.',
                          style: GoogleFonts.kanit(fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ไขมัน:',
                          style: GoogleFonts.kanit(fontSize: 13),
                        ),
                        Text(
                          '${_fat.toStringAsFixed(1)} ก.',
                          style: GoogleFonts.kanit(fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Save Button
              ElevatedButton(
                onPressed: _isLoading ? null : _saveMeal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFABB5A),
                  disabledBackgroundColor: Colors.grey[300],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.grey[700]!,
                          ),
                        ),
                      )
                    : Text(
                        'บันทึกอาหาร',
                        style: GoogleFonts.kanit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNutrientSlider({
    required String label,
    required double value,
    required double max,
    required String unit,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.kanit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFABB5A).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${value.toStringAsFixed(1)} $unit',
                style: GoogleFonts.kanit(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFABB5A),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: const Color(0xFFFABB5A),
            inactiveTrackColor: Colors.grey[200],
            thumbColor: const Color(0xFFFABB5A),
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 12,
              elevation: 2,
            ),
            trackHeight: 6,
          ),
          child: Slider(
            value: value,
            max: max,
            min: 0,
            divisions: (max / 5).toInt(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
