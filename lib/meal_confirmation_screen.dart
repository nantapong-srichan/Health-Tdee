import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'session_data.dart';
import 'services/meal_service.dart';
import 'services/image_upload_service.dart';

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
  late double _estimatedWeight;
  late double _baseCalories;
  late double _baseProtein;
  late double _baseCarbs;
  late double _baseFat;
  bool _isUploading = false;
  late final ImageUploadService _imageUploadService;

  @override
  void initState() {
    super.initState();
    _estimatedWeight = widget.estimatedWeight;
    // Store base nutrition values (for original weight)
    _baseCalories = widget.nutritionValues['calories'] ?? 0;
    _baseProtein = widget.nutritionValues['protein'] ?? 0;
    _baseCarbs = widget.nutritionValues['carbs'] ?? 0;
    _baseFat = widget.nutritionValues['fat'] ?? 0;
    
    _calories = _baseCalories;
    _protein = _baseProtein;
    _carbs = _baseCarbs;
    _fat = _baseFat;
    
    // Initialize image upload service
    _imageUploadService = ImageUploadService();
  }

  void _updateNutritionByWeight(double newWeight) {
    // Calculate ratio of new weight to original weight
    final ratio = newWeight / widget.estimatedWeight;
    
    setState(() {
      _estimatedWeight = newWeight;
      _calories = _baseCalories * ratio;
      _protein = _baseProtein * ratio;
      _carbs = _baseCarbs * ratio;
      _fat = _baseFat * ratio;
    });
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
                        child: _buildFoodImage(),
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

                // Weight Slider
                _buildWeightSlider(
                  kanitTheme,
                  'น้ำหนักโดยประมาณ',
                  'g',
                  _estimatedWeight,
                  50,
                  800,
                  (value) {
                    _updateNutritionByWeight(value);
                  },
                ),
                const SizedBox(height: 20),

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
                  200,
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
                    onPressed: _isUploading ? null : () {
                      print('🔘 BUTTON PRESSED: _saveMeal called');
                      _saveMeal(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFABB5A),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isUploading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
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

  Widget _buildWeightSlider(
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
                  '${value.toStringAsFixed(0)} $unit',
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
              divisions: ((max - min) / 10).toInt(),
              activeColor: const Color(0xFFFABB5A),
              inactiveColor: Colors.grey[200]!,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodImage() {
    // Check if imagePath is URL, local file, or asset
    if (widget.imagePath.isEmpty) {
      // Placeholder if no image
      return Container(
        height: 200,
        width: double.infinity,
        color: Colors.grey[200],
        child: const Icon(Icons.image, size: 50, color: Colors.grey),
      );
    }

    if (widget.imagePath.startsWith('http')) {
      // It's a URL (from GCS)
      return Image.network(
        widget.imagePath,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 200,
            width: double.infinity,
            color: Colors.grey[200],
            child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 200,
            width: double.infinity,
            color: Colors.grey[200],
            child: const Center(child: CircularProgressIndicator()),
          );
        },
      );
    }

    // Check if it's a local file
    File imageFile = File(widget.imagePath);
    if (imageFile.existsSync()) {
      return Image.file(
        imageFile,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 200,
            width: double.infinity,
            color: Colors.grey[200],
            child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
          );
        },
      );
    }

    // Try as asset (fallback)
    return Image.asset(
      widget.imagePath,
      height: 200,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: 200,
          width: double.infinity,
          color: Colors.grey[200],
          child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
        );
      },
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
        estimatedWeight: _estimatedWeight,
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
          'estimatedWeight': _estimatedWeight,
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
      // Create new meal - upload image if it exists
      print('🔵 _saveMeal: Creating new meal');
      
      File imageFile = File(widget.imagePath);
      print('🔵 _saveMeal: Image path: ${imageFile.path}');
      print('🔵 _saveMeal: Image exists: ${imageFile.existsSync()}');
      
      if (imageFile.existsSync()) {
        // Upload image to Google Cloud Storage via Backend
        print('📤 _saveMeal: Uploading image: ${imageFile.path}');
        setState(() => _isUploading = true);
        
        try {
          // อัปโหลดรูปพร้อมข้อมูล meal ในครั้งเดียว
          print('🔵 _saveMeal: Calling uploadFoodImageWithMealData...');
          String? result = await _imageUploadService.uploadFoodImageWithMealData(
            imageFile: imageFile,
            foodName: widget.foodName,
            nutrition: {
              'calories': _calories,
              'protein': _protein,
              'carbohydrates': _carbs,
              'fat': _fat,
            },
            estimatedWeight: _estimatedWeight,
            mealType: 'lunch',
            confidence: 0.0,
          );
          
          if (result != null) {
            print('✅ Image and meal uploaded successfully');
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
              'estimatedWeight': _estimatedWeight,
              'imageUrl': result,
            });
          } else {
            throw Exception('Upload failed');
          }
        } catch (e) {
          print('❌ Error uploading: $e');
          setState(() => _isUploading = false);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('เกิดข้อผิดพลาด: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Image file doesn't exist, just return values
        print('🔵 _saveMeal: No image file, returning values');
        Navigator.pop(context, {
          'calories': _calories,
          'protein': _protein,
          'carbs': _carbs,
          'fat': _fat,
          'estimatedWeight': _estimatedWeight,
        });
      }
    }
  }
}
