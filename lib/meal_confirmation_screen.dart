import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'session_data.dart';
import 'services/meal_service.dart';

class MealConfirmationScreen extends StatefulWidget {
  final String foodName;
  final String imagePath;
  final Map<String, double> nutritionValues; // {calories, protein, carbs, fat}
  final String? mealId; // For editing existing meals
  final double estimatedWeight; // Weight in grams
  final bool fromResultsScreen; // True if called from results_screen

  const MealConfirmationScreen({
    super.key,
    required this.foodName,
    required this.imagePath,
    required this.nutritionValues,
    this.mealId,
    this.estimatedWeight = 100.0, // Default 100g
    this.fromResultsScreen = false,
  });

  @override
  State<MealConfirmationScreen> createState() => _MealConfirmationScreenState();
}

class _MealConfirmationScreenState extends State<MealConfirmationScreen> {
  late double _calories;
  late double _protein;
  late double _carbs;
  late double _fat;

  @override
  void initState() {
    super.initState();
    _calories = widget.nutritionValues['calories'] ?? 0;
    _protein = widget.nutritionValues['protein'] ?? 0;
    _carbs = widget.nutritionValues['carbs'] ?? 0;
    _fat = widget.nutritionValues['fat'] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final kanitTheme = GoogleFonts.kanitTextTheme(textTheme);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'ยืนยันอาหาร',
          style: kanitTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        actions: [
          // Delete button - only show if editing existing meal
          if (widget.mealId != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _showDeleteConfirmDialog(context),
            )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Food Image and Name
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          widget.imagePath,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.foodName,
                        style: kanitTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Nutrition Sliders
                Text(
                  'ปรับปริมาณอาหาร',
                  style: kanitTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Calories Slider
                _buildNutritionSlider(
                  kanitTheme,
                  'แคลอรี่',
                  'kcal',
                  _calories,
                  0,
                  5000,
                  (value) {
                    setState(() => _calories = value);
                  },
                ),
                const SizedBox(height: 20),

                // Protein Slider
                _buildNutritionSlider(
                  kanitTheme,
                  'โปรตีน',
                  'g',
                  _protein,
                  0,
                  100,
                  (value) {
                    setState(() => _protein = value);
                  },
                ),
                const SizedBox(height: 20),

                // Carbs Slider
                _buildNutritionSlider(
                  kanitTheme,
                  'คาร์โบไฮเดรต',
                  'g',
                  _carbs,
                  0,
                  300,
                  (value) {
                    setState(() => _carbs = value);
                  },
                ),
                const SizedBox(height: 20),

                // Fat Slider
                _buildNutritionSlider(
                  kanitTheme,
                  'ไขมัน',
                  'g',
                  _fat,
                  0,
                  150,
                  (value) {
                    setState(() => _fat = value);
                  },
                ),
                const SizedBox(height: 40),

                // Action Buttons
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _saveMeal(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFABB5A),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'บันทึกอาหาร',
                      style: kanitTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(
                        color: Color(0xFFFABB5A),
                        width: 2,
                      ),
                    ),
                    child: Text(
                      'ยกเลิก',
                      style: kanitTheme.titleMedium?.copyWith(
                        color: const Color(0xFFFABB5A),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNutritionSlider(
    TextTheme theme,
    String label,
    String unit,
    double value,
    double min,
    double max,
    Function(double) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: theme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFABB5A),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${value.toStringAsFixed(1)} $unit',
                  style: theme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 8.0,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 12.0,
              ),
              overlayShape: const RoundSliderOverlayShape(
                overlayRadius: 20.0,
              ),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              activeColor: const Color(0xFFFABB5A),
              inactiveColor: Colors.grey[200]!,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context) {
    final kanitTheme = GoogleFonts.kanitTextTheme(Theme.of(context).textTheme);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'ลบอาหาร',
          style: kanitTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'คุณแน่ใจหรือว่าต้องการลบ${widget.foodName}?',
          style: kanitTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'ยกเลิก',
              style: kanitTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => _deleteMeal(context),
            child: Text(
              'ลบ',
              style: kanitTheme.bodyMedium?.copyWith(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMeal(BuildContext context) async {
    try {
      final mealService = MealService();
      final response = await mealService.deleteMeal(widget.mealId!);

      if (mounted) {
        Navigator.pop(context); // Close dialog

        if (response['success']) {
          // Remove from SessionData
          final sessionData = Provider.of<SessionData>(context, listen: false);
          sessionData.removeMealById(widget.mealId!);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ลบ${widget.foodName}สำเร็จ'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );

          // Navigate back to home screen
          Navigator.pop(context);
        } else {
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

  void _saveMeal(BuildContext context) async {
    final sessionData = Provider.of<SessionData>(context, listen: false);

    // Check if editing existing meal or creating new one
    if (widget.mealId != null) {
      // Edit existing meal
      print('DEBUG MEAL_CONFIRMATION: Updating meal ${widget.mealId}');
      
      final mealService = MealService();
      final response = await mealService.updateMeal(
        mealId: widget.mealId!,
        foodName: widget.foodName,
        calories: _calories.toInt(),
        protein: _protein,
        carbs: _carbs,
        fat: _fat,
        fiber: 0.0,
        sodium: 0.0,
        estimatedWeight: widget.estimatedWeight,
      );

      print('DEBUG MEAL_CONFIRMATION: Update response: $response');

      if (response['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('แก้ไข${widget.foodName}สำเร็จ'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        // Return updated nutrition values
        Navigator.pop(context, {
          'calories': _calories,
          'protein': _protein,
          'carbs': _carbs,
          'fat': _fat,
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: ${response['message']}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      // If coming from results_screen, only return values without saving
      // results_screen will handle the saving
      if (widget.fromResultsScreen) {
        Navigator.pop(context, {
          'calories': _calories,
          'protein': _protein,
          'carbs': _carbs,
          'fat': _fat,
        });
        return;
      }

      // Create new meal (not from results_screen)
      // Save to backend first
      final mealService = MealService();
      final response = await mealService.saveMeal(
        foodName: widget.foodName,
        calories: _calories.toInt(),
        protein: _protein,
        carbs: _carbs,
        fat: _fat,
        fiber: 0.0,
        sodium: 0.0,
        estimatedWeight: widget.estimatedWeight,
        confidence: 0.0,
        mealType: 'lunch',
      );

      print('DEBUG MEAL_CONFIRMATION: saveMeal response: $response');

      if (response['success']) {
        // Also save to SessionData for local display
        final mealData = {
          'name': widget.foodName,
          'imagePath': widget.imagePath,
          'calories': _calories,
          'protein': _protein,
          'carbs': _carbs,
          'fat': _fat,
          'timestamp': DateTime.now(),
          'mealId': response['mealId'],
        };

        sessionData.addMeal(mealData);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('บันทึก${widget.foodName}สำเร็จ'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Return nutrition values for results_screen
        Navigator.pop(context, {
          'calories': _calories,
          'protein': _protein,
          'carbs': _carbs,
          'fat': _fat,
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: ${response['message']}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
