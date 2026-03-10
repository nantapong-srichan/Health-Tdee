import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart' as fl_chart;
import 'services/auth_service.dart';
import 'services/meal_service.dart';
import 'services/api_service.dart';
import 'session_data.dart'; 
import 'image_picker_screen.dart';
import 'profile_screen.dart';
import 'meal_edit_screen.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTabIndex = 0; // 0: daily, 1: 7days, 2: 30days
  late DateTime _selectedDate;
  DateTime _weekStartDate = DateTime.now(); // วันเริ่มต้นของสัปดาห์ที่จะแสดง (ล็อคไว้จนกว่าเลือกปฏิทิน)
  final _authService = AuthService();
  final _mealService = MealService();

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _weekStartDate = _selectedDate;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sessionData = Provider.of<SessionData>(context, listen: false);
      sessionData.selectedDate = _selectedDate;
    });
    _loadUserDataAndRefresh();
    _load14DaysMeals(); // โหลด 14 วันข้อมูลอาหาร
  }

  Future<void> _load14DaysMeals() async {
    try {
      final baseDate = _selectedDate; // ใช้ _selectedDate แทน DateTime.now()
      final sessionData = Provider.of<SessionData>(context, listen: false);
      
      // โหลด 14 วันย้อนหลังจาก baseDate
      for (int i = 13; i >= 0; i--) {
        final date = baseDate.subtract(Duration(days: i));
        final startOfDay = DateTime(date.year, date.month, date.day);
        final endOfDay = startOfDay.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));

        final startDateStr = startOfDay.toIso8601String().split('.')[0];
        final endDateStr = endOfDay.toIso8601String().split('.')[0];

        final response = await _mealService.getMealHistory(
          startDate: startDateStr,
          endDate: endDateStr,
          limit: 100,
        );

        if (mounted && response['success']) {
          sessionData.clearMealsForDate(date);
          
          final meals = response['meals'] as List?;
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
                'date': _getMealDateInBangkokTime(meal['mealTime'] as String),
                'mealId': meal['_id'],
                'imageUrl': meal['imageUrl'],
              });
            }
          }
        }
      }
    } catch (e) {
      print('DEBUG: Error loading 14 days meals: $e');
    }
  }

  Future<void> _loadUserDataAndRefresh() async {
    try {
      final profile = await _authService.getCurrentUser();
      if (mounted && profile['user'] != null) {
        final sessionData = Provider.of<SessionData>(context, listen: false);
        final userProfile = profile['user'] as Map<String, dynamic>;

        if (userProfile['name'] != null) {
          sessionData.userName = userProfile['name'] as String;
        }
        // Update SessionData with latest health metrics
        if (userProfile['tdee'] != null) {
          sessionData.updateTDEE((userProfile['tdee'] as num).toDouble());
        }
        if (userProfile['dailyCalorieNeed'] != null) {
          sessionData.updateDailyCalorieNeed(
              (userProfile['dailyCalorieNeed'] as num).toDouble());
        }
        if (userProfile['proteinGrams'] != null) {
          sessionData.updateProteinGrams(
              (userProfile['proteinGrams'] as num).toDouble());
        }
        if (userProfile['bmr'] != null) {
          sessionData.updateBMR((userProfile['bmr'] as num).toDouble());
        }
        if (userProfile['activityLevel'] != null) {
          sessionData.updateActivityLevel(userProfile['activityLevel'] as String);
        }
        if (userProfile['goal'] != null) {
          sessionData.updateGoal(userProfile['goal'] as String);
        }
        if (userProfile['weight'] != null) {
          sessionData.updateWeightDouble(
              (userProfile['weight'] as num).toDouble());
        }
        if (userProfile['height'] != null) {
          sessionData.updateHeightDouble(
              (userProfile['height'] as num).toDouble());
        }
        if (userProfile['profileImageUrl'] != null) {
          sessionData.updateProfileImageUrl(
              userProfile['profileImageUrl'] as String);
        }
        if (userProfile['diseases'] != null) {
          final diseasesList = (userProfile['diseases'] as List?)?.cast<String>() ?? [];
          sessionData.updateDiseases(diseasesList);
        }
        if (userProfile['diabetesCarbLimit'] != null) {
          final carbLimit = userProfile['diabetesCarbLimit'];
          double carbValue = (carbLimit is int) ? carbLimit.toDouble() : (carbLimit as double? ?? 0.0);
          sessionData.updateDiabetesCarbLimit(carbValue);
        }
        if (userProfile['hypertensionSodiumLimit'] != null) {
          final sodiumLimit = userProfile['hypertensionSodiumLimit'];
          double sodiumValue = (sodiumLimit is int) ? sodiumLimit.toDouble() : (sodiumLimit as double? ?? 2000.0);
          sessionData.updateHypertensionSodiumLimit(sodiumValue);
        }
      }
    } catch (e) {
      // Handle error silently - user data refresh failure
    }

    // Load meal history for today
    _loadTodayMeals();
  }

  Future<void> _loadTodayMeals() async {
    try {
      // Create Bangkok midnight times
      final startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      final endOfDay = startOfDay.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));

      print('DEBUG: Loading meals for $_selectedDate');
      print('DEBUG: Start (local): $startOfDay, End (local): $endOfDay');

      // Check if authenticated
      final apiService = ApiService();
      final token = await apiService.getToken();
      print('DEBUG: Token exists: ${token != null}');

      // Send as Bangkok local times (without Z)
      final startDateStr = startOfDay.toIso8601String().split('.')[0]; // 2026-01-28T00:00:00
      final endDateStr = endOfDay.toIso8601String().split('.')[0];     // 2026-01-29T00:00:00

      print('DEBUG: startDate (Bangkok): $startDateStr');
      print('DEBUG: endDate (Bangkok): $endDateStr');

      final response = await _mealService.getMealHistory(
        startDate: startDateStr,
        endDate: endDateStr,
        limit: 100,
      );

      print('DEBUG: getMealHistory response: $response');

      if (mounted && response['success']) {
        final sessionData = Provider.of<SessionData>(context, listen: false);
        sessionData.selectedDate = _selectedDate;
        
        // Clear meals for this date before adding new ones (prevent duplicates)
        print('DEBUG: Clearing meals before load for date: $_selectedDate');
        print('DEBUG: Meals before clear: ${sessionData.getMealsForDate(_selectedDate).length}');
        sessionData.clearMealsForDate(_selectedDate);
        print('DEBUG: Meals after clear: ${sessionData.getMealsForDate(_selectedDate).length}');
        
        final meals = response['meals'] as List?;
        print('DEBUG: Meals count from server: ${meals?.length ?? 0}');
        
        if (meals != null && meals.isNotEmpty) {
          for (var meal in meals) {
            print('DEBUG: Adding meal: ${meal['foodName']}');
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
              'date': _getMealDateInBangkokTime(meal['mealTime'] as String),
              'mealId': meal['_id'],
              'imageUrl': meal['imageUrl'], // ✅ เพิ่มรูปอาหาร
            });
          }
        } else {
          print('DEBUG: No meals found or meals is null');
        }
      } else {
        print('DEBUG: Response not successful or not mounted. Success: ${response['success']}, Mounted: $mounted');
      }
    } catch (e) {
      // Handle error silently - meal history fetch failure
      print('DEBUG: Error loading meals: $e');
    }
  }

  String _getMealDateInBangkokTime(String utcMealTime) {
    // Convert UTC mealTime to Bangkok time (UTC+7)
    final utcTime = DateTime.parse(utcMealTime);
    final bangkokTime = utcTime.add(const Duration(hours: 7));
    return bangkokTime.toString().split(' ')[0]; // YYYY-MM-DD
  }

  // Helper methods to get macro nutrients for selected date
  double _getProteinForDate(SessionData sessionData) {
    final meals = sessionData.getMealsForDate(_selectedDate);
    double total = 0;
    for (var meal in meals) {
      total += (meal['protein'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }

  double _getCarbsForDayForDate(SessionData sessionData) {
    final meals = sessionData.getMealsForDate(_selectedDate);
    double total = 0;
    for (var meal in meals) {
      total += (meal['carbs'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }

  double _getSodiumForDayForDate(SessionData sessionData) {
    final meals = sessionData.getMealsForDate(_selectedDate);
    double total = 0;
    for (var meal in meals) {
      total += (meal['sodium'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }

  double _getCarbsForDate(SessionData sessionData) {
    final meals = sessionData.getMealsForDate(_selectedDate);
    double total = 0;
    for (var meal in meals) {
      total += (meal['carbs'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }

  double _getFatForDate(SessionData sessionData) {
    final meals = sessionData.getMealsForDate(_selectedDate);
    double total = 0;
    for (var meal in meals) {
      total += (meal['fat'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final kanitTheme = GoogleFonts.kanitTextTheme(textTheme);

    // ดึงข้อมูล session มาใช้ เผื่อต้องใช้คำนวณได้
    final sessionData = context.watch<SessionData>();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(kanitTheme),
                const SizedBox(height: 24),
                // ใช้ข้อมูล goal จาก sessionData มาแสดงผล
                _buildTodayCaloriesCard(kanitTheme, sessionData.goal ?? '...'),
                const SizedBox(height: 24),
                // Diabetes carbs card (only for Type 2 diabetes users) - show after today calories
                if (sessionData.hasDiabetes() && sessionData.diabetesType == 'type2') ...[
                  _buildDiabetesCarbsCard(kanitTheme, sessionData),
                  const SizedBox(height: 24),
                ],
                // Hypertension sodium card (only for users with hypertension)
                if (sessionData.hasHypertension()) ...[
                  _buildHypertensionSodiumCard(kanitTheme, sessionData),
                  const SizedBox(height: 24),
                ],
                // Macronutrients cards
                _buildMacronutrientsCards(kanitTheme, sessionData),
                const SizedBox(height: 24),
                _buildDateSelector(kanitTheme, sessionData),
                const SizedBox(height: 24),
                _buildDailyMealsCard(kanitTheme, sessionData),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // --- (แก้ไข) แก้ไขให้ไปหน้า ImagePickerScreen ---
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ImagePickerScreen(),
            ),
          ).then((_) {
            // Reset to today and refresh meal history when returning from ImagePickerScreen
            setState(() {
              _selectedDate = DateTime.now();
            });
            _load14DaysMeals(); // โหลด 14 วันข้อมูลใหม่หลังจากบันทึกอาหาร
          });
        },
        backgroundColor: const Color(0xFFFABB5A),
        shape: const CircleBorder(),
        child: const Icon(Icons.camera_alt, color: Colors.white, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: Icon(Icons.home, color: Colors.grey[800], size: 30), // Active icon
                onPressed: () {},
              ),
              IconButton(
                icon: Icon(Icons.person_outline, color: Colors.grey[400], size: 30),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  ).then((_) {
                    // Refresh user data when returning from ProfileScreen
                    _loadUserDataAndRefresh();
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  //Helper Widgets

  Widget _buildHeader(TextTheme theme) {
    return Consumer<SessionData>(
      builder: (context, sessionData, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ยินดีต้อนรับ', style: theme.bodyLarge?.copyWith(fontSize: 22)),
                Text(
                  sessionData.userName != null && sessionData.userName!.trim().isNotEmpty
                      ? sessionData.userName!
                      : 'โหลดข้อมูล...',
                  style: theme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 34,
                  ),
                ),
              ],
            ),
            CircleAvatar(
              radius: 35,
              backgroundImage: sessionData.profileImageUrl != null
                  ? NetworkImage(sessionData.profileImageUrl!)
                  : (sessionData.profileImagePath != null
                      ? FileImage(File(sessionData.profileImagePath!))
                      : const AssetImage('assets/profile_pic.png')) as ImageProvider,
            ),
          ],
        );
      },
    );
  }

  Widget _buildMacronutrientsCards(TextTheme theme, SessionData sessionData) {
    return Consumer<SessionData>(
      builder: (context, session, _) {
        final protein = _getProteinForDate(session);
        final carbs = _getCarbsForDate(session);
        final fat = _getFatForDate(session);
        final proteinGoal = session.proteinGrams ?? 100;
        final isMuscleBuildGoal = session.goal == 'muscle_gain';
        final isMaintainGoal = session.goal == 'maintain';
        final isWeightGainGoal = session.goal == 'weight_gain';
        final isWeightLossGoal = session.goal == 'weight_loss';
        final goalCalories = session.getDailyCalorieGoal();
        final selectedCalories = session.getCaloriesForDate(_selectedDate);

        if (isWeightLossGoal) {
          // Layout for weight loss goal - Focus on Calorie Deficit
          final percent = (selectedCalories / goalCalories);
          String deficitStatus;
          Color deficitColor;
          
          if (percent < 0.7) {
            deficitStatus = 'ต่ำเกินไป!';
            deficitColor = Colors.red;
          } else if (percent >= 0.5 && percent <= 1.0) {
            deficitStatus = 'อยู่ในเป้าหมายที่ดี!';
            deficitColor = Colors.green;
          } else {
            deficitStatus = 'เกินแคลอรี่แล้ว!';
            deficitColor = Colors.orange;
          }

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: deficitColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.trending_down, color: deficitColor, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('แคลอรี่ส่วนขาดสำหรับลดน้ำหนัก', 
                              style: theme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                            Text(
                              '${selectedCalories.toStringAsFixed(0)} / ${goalCalories.toStringAsFixed(0)} kcal',
                              style: theme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: percent.clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(deficitColor),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        deficitStatus,
                        style: theme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: deficitColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Macro cards for weight loss goal
              Row(
                children: [
                  // Protein Card
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.local_dining, color: Colors.green, size: 20),
                          ),
                          const SizedBox(height: 8),
                          Text('โปรตีน', style: theme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                          Text(
                            '${protein.toStringAsFixed(1)}g',
                            style: theme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Carbs Card
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.grain, color: Colors.orange, size: 20),
                          ),
                          const SizedBox(height: 8),
                          Text('คาร์โบไฮเดรต', style: theme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                          Text(
                            '${carbs.toStringAsFixed(1)}g',
                            style: theme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Fat Card
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.opacity, color: Colors.red, size: 20),
                          ),
                          const SizedBox(height: 8),
                          Text('ไขมัน', style: theme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                          Text(
                            '${fat.toStringAsFixed(1)}g',
                            style: theme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        } else if (isMaintainGoal) {
          // Layout for maintain goal - Focus on Calorie Balance
          final percent = (selectedCalories / goalCalories);
          String balanceStatus;
          Color balanceColor;
          
          if (percent < 0.9) {
            balanceStatus = 'ต่ำกว่าเป้าหมาย';
            balanceColor = Colors.blue;
          } else if (percent >= 0.9 && percent <= 1.0) {
            balanceStatus = 'สมดุลพอดี!';
            balanceColor = Colors.green;
          } else {
            balanceStatus = 'สูงกว่าเป้าหมาย';
            balanceColor = Colors.orange;
          }

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: balanceColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.balance, color: balanceColor, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('สมดุลแคลอรี่รักษาน้ำหนัก', 
                              style: theme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                            Text(
                              '${selectedCalories.toStringAsFixed(0)} / ${goalCalories.toStringAsFixed(0)} kcal',
                              style: theme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: percent.clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(balanceColor),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        balanceStatus,
                        style: theme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: balanceColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Macro cards for maintain goal
              Row(
                children: [
                  // Protein Card
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.local_dining, color: Colors.green, size: 20),
                          ),
                          const SizedBox(height: 8),
                          Text('โปรตีน', style: theme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                          Text(
                            '${protein.toStringAsFixed(1)}g',
                            style: theme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Carbs Card
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.grain, color: Colors.orange, size: 20),
                          ),
                          const SizedBox(height: 8),
                          Text('คาร์โบไฮเดรต', style: theme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                          Text(
                            '${carbs.toStringAsFixed(1)}g',
                            style: theme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Fat Card
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.opacity, color: Colors.red, size: 20),
                          ),
                          const SizedBox(height: 8),
                          Text('ไขมัน', style: theme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                          Text(
                            '${fat.toStringAsFixed(1)}g',
                            style: theme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        } else if (isWeightGainGoal) {
          // Layout for weight gain goal - Focus on Calorie Surplus
          final percent = (selectedCalories / goalCalories);
          String surplusStatus;
          Color surplusColor;
          
          if (percent < 0.9) {
            surplusStatus = 'ต่ำกว่าเป้าหมาย';
            surplusColor = Colors.orange;
          } else if (percent >= 0.9 && percent <= 1.1) {
            surplusStatus = 'อยู่ในเป้าหมายที่ดี!';
            surplusColor = Colors.green;
          } else {
            surplusStatus = 'เกินแคลอรี่มากเกินไป!';
            surplusColor = Colors.red;
          }

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: surplusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.trending_up, color: surplusColor, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('แคลอรี่ส่วนเกินสำหรับเพิ่มน้ำหนัก', 
                              style: theme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                            Text(
                              '${selectedCalories.toStringAsFixed(0)} / ${goalCalories.toStringAsFixed(0)} kcal',
                              style: theme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: (selectedCalories / goalCalories).clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(surplusColor),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        surplusStatus,
                        style: theme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: surplusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Macro cards for weight gain goal
              Row(
                children: [
                  // Protein Card
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.local_dining, color: Colors.green, size: 20),
                          ),
                          const SizedBox(height: 8),
                          Text('โปรตีน', style: theme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                          Text(
                            '${protein.toStringAsFixed(1)}g',
                            style: theme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Carbs Card
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.grain, color: Colors.orange, size: 20),
                          ),
                          const SizedBox(height: 8),
                          Text('คาร์โบไฮเดรต', style: theme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                          Text(
                            '${carbs.toStringAsFixed(1)}g',
                            style: theme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Fat Card
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.opacity, color: Colors.red, size: 20),
                          ),
                          const SizedBox(height: 8),
                          Text('ไขมัน', style: theme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                          Text(
                            '${fat.toStringAsFixed(1)}g',
                            style: theme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        } else if (isMuscleBuildGoal) {
          // Layout for muscle building goal
          return Column(
            children: [
              // Protein Card - Full width with progress
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.fitness_center, color: Colors.green, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('โปรตีนที่ต้องได้รับต่อวันสำหรับสร้างกล้ามเนื้อ', 
                              style: theme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                            Text(
                              '${protein.toStringAsFixed(1)}g / ${proteinGoal.toStringAsFixed(0)}g',
                              style: theme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: (protein / proteinGoal).clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          protein >= proteinGoal ? Colors.green : Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Carbs and Fat Cards - Side by side
              Row(
                children: [
                  // Carbs Card
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.grain, color: Colors.orange, size: 20),
                          ),
                          const SizedBox(height: 8),
                          Text('คาร์โบไฮเดรต', style: theme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                          Text(
                            '${carbs.toStringAsFixed(1)}g',
                            style: theme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Fat Card
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.opacity, color: Colors.red, size: 20),
                          ),
                          const SizedBox(height: 8),
                          Text('ไขมัน', style: theme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                          Text(
                            '${fat.toStringAsFixed(1)}g',
                            style: theme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        } else {
          // Default layout - 3 cards in a row
          return Row(
            children: [
              // Protein Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.local_dining, color: Colors.green, size: 20),
                      ),
                      const SizedBox(height: 8),
                      Text('โปรตีน', style: theme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                      Text(
                        '${protein.toStringAsFixed(1)}g',
                        style: theme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Carbs Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.grain, color: Colors.orange, size: 20),
                      ),
                      const SizedBox(height: 8),
                      Text('คาร์โบไฮเดรต', style: theme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                      Text(
                        '${carbs.toStringAsFixed(1)}g',
                        style: theme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Fat Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.opacity, color: Colors.red, size: 20),
                      ),
                      const SizedBox(height: 8),
                      Text('ไขมัน', style: theme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                      Text(
                        '${fat.toStringAsFixed(1)}g',
                        style: theme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }
      },
    );
  }

  // รับ goal มาแสดง
  Widget _buildTodayCaloriesCard(TextTheme theme, String goal) {
    return Consumer<SessionData>(
      builder: (context, sessionData, _) {
        // Use selected date instead of today
        final selectedCalories = sessionData.getCaloriesForDate(_selectedDate);
        final goalCalories = sessionData.getDailyCalorieGoal();
        final goalLabel = sessionData.getGoalLabel();
        
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('แคลอรี่วันนี้', style: theme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircularPercentIndicator(
                    radius: 50.0,
                    lineWidth: 12.0,
                    percent: (selectedCalories / goalCalories).clamp(0.0, 1.0),
                    center: Text(
                      "${selectedCalories.toStringAsFixed(0)}/${goalCalories.toStringAsFixed(0)}\nแคลอรี่",
                      textAlign: TextAlign.center,
                      style: theme.bodySmall,
                    ),
                    progressColor: const Color(0xFFFABB5A),
                    backgroundColor: const Color(0xFFFDEFE0),
                    circularStrokeCap: CircularStrokeCap.round,
                    startAngle: 180,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goalLabel, // แสดง goal label ในภาษาไทย
                          style: theme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Builder(
                          builder: (context) {
                            final percent = (selectedCalories / goalCalories).clamp(0.0, 2.0);
                            String message;
                            if (percent <= 0.3) {
                              message = 'พยายามเข้า!';
                            } else if (percent <= 0.5) {
                              message = 'เครื่องติดแล้ว!';
                            } else if (percent <= 0.8) {
                              message = 'มาครึ่งทางแล้ว!';
                            } else if (percent < 1.0) {
                              message = 'อีกนิดเดียว!';
                            } else {
                              message = 'เกินแล้วนะ!';
                            }
                            return Text(
                              message,
                              style: theme.bodyMedium?.copyWith(color: Colors.grey[600]),
                            );
                          },
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDateSelector(TextTheme theme, SessionData sessionData) {
    return StatefulBuilder(
      builder: (context, setState) {
        // สร้างลิสต์วันที่ย้อนหลัง 6 วัน + วันเริ่มต้นสัปดาห์ (7 วันทั้งหมด) - ล็อคไว้
        final datesList = <DateTime>[];
        
        for (int i = 6; i >= 0; i--) {
          datesList.add(_weekStartDate.subtract(Duration(days: i)));
        }
        
        // หาวันที่เลือก index
        int selectedIndex = datesList.indexWhere((date) => 
          date.year == _selectedDate.year && 
          date.month == _selectedDate.month && 
          date.day == _selectedDate.day
        );
        
        if (selectedIndex == -1) {
          selectedIndex = 0;
        }
        
        return DefaultTabController(
          length: 3,
          initialIndex: _selectedTabIndex,
          child: Column(
            children: [
              TabBar(
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFFFABB5A),
                indicatorWeight: 3,
                labelStyle: theme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                onTap: (index) {
                  setState(() {
                    _selectedTabIndex = index;
                  });
                },
                tabs: const [
                  Tab(text: 'รายวัน'),
                  Tab(text: '7 วันย้อนหลัง'),
                  Tab(text: '14 วันย้อนหลัง'),
                ],
              ),
              const SizedBox(height: 12),
              // Display selected date - centered below tabs with calendar icon
              Consumer<SessionData>(
                builder: (context, data, _) {
                  final selectedDate = data.selectedDate ?? DateTime.now();
                  final months = ['มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
                                  'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'];
                  final monthName = months[selectedDate.month - 1];
                  final thaiYear = selectedDate.year + 543;
                  
                  return Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${selectedDate.day} $monthName $thaiYear',
                          style: theme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.calendar_today, size: 20),
                          onPressed: () {
                            showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            ).then((pickedDate) {
                              if (pickedDate != null) {
                                final sessionData = Provider.of<SessionData>(context, listen: false);
                                this.setState(() {
                                  _selectedDate = pickedDate;
                                  _weekStartDate = pickedDate; // อัปเดต _weekStartDate เมื่อเลือกปฏิทิน
                                  sessionData.selectedDate = pickedDate;
                                });
                                _load14DaysMeals(); // โหลด 14 วันข้อมูลใหม่
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              // รายวัน - calendar date picker
              if (_selectedTabIndex == 0)
                SizedBox(
                  height: 70,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: datesList.length,
                    itemBuilder: (context, index) {
                      final date = datesList[index];
                      bool isSelected = date.year == _selectedDate.year && 
                                       date.month == _selectedDate.month && 
                                       date.day == _selectedDate.day;
                      final dayName = ['อา.', 'จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.', 'ส.'];
                      
                      return GestureDetector(
                        onTap: () {
                          final sessionData = Provider.of<SessionData>(context, listen: false);
                          this.setState(() {
                            _selectedDate = date;
                            sessionData.selectedDate = date;
                          });
                          _loadTodayMeals();
                        },
                        child: Container(
                          width: 50,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFFABB5A) : Colors.white,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(date.day.toString(),
                                  style: theme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? Colors.white : Colors.black)),
                              Text(dayName[date.weekday % 7],
                                  style: theme.bodySmall?.copyWith(
                                      color: isSelected ? Colors.white70 : Colors.grey)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: _selectedTabIndex == 1
                      ? _build7DaysChart(theme, sessionData)
                      : _build14DaysChart(theme, sessionData),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDailyMealsCard(TextTheme theme, SessionData sessionData) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('แคลอรี่ต่อวัน', style: theme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              Consumer<SessionData>(
                builder: (context, data, _) {
                  final selectedDate = data.selectedDate ?? DateTime.now();
                  final caloriesForDate = data.getCaloriesForDate(selectedDate);
                  final goal = (data.dailyCalorieNeed ?? data.tdee ?? 2000).round();
                  print('DEBUG HOME: selectedDate: $selectedDate');
                  print('DEBUG HOME: caloriesForDate: $caloriesForDate');
                  print('DEBUG HOME: meals for date: ${data.getMealsForDate(selectedDate).length}');
                  return Text(
                    '${caloriesForDate.toStringAsFixed(0)}/$goal kcal',
                    style: theme.bodyMedium?.copyWith(color: Colors.grey),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          Consumer<SessionData>(
            builder: (context, data, _) {
              final selectedDate = data.selectedDate ?? DateTime.now();
              final caloriesForDate = data.getCaloriesForDate(selectedDate);
              final goal = (data.dailyCalorieNeed ?? data.tdee ?? 2000).round();
              final percent = (caloriesForDate / goal).clamp(0.0, 1.0);
              
              return Center(
                child: CircularPercentIndicator(
                  radius: 65.0,
                  lineWidth: 18.0,
                  percent: percent,
                  center: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("${caloriesForDate.toStringAsFixed(0)} kCal", style: theme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 19)),
                      Text(caloriesForDate > goal ? "เกิน ${(caloriesForDate - goal).toStringAsFixed(0)}" : "เหลือ ${(goal - caloriesForDate).toStringAsFixed(0)}", style: theme.bodySmall?.copyWith(color: Colors.grey)),
                    ],
                  ),
                  progressColor: const Color(0xFFFABB5A),
                  backgroundColor: Colors.grey[200]!,
                  circularStrokeCap: CircularStrokeCap.round,
                  startAngle: 180,
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          const Divider(),
          Consumer<SessionData>(
            builder: (context, data, _) {
              final selectedDate = data.selectedDate ?? DateTime.now();
              final mealsForDate = data.getMealsForDate(selectedDate);
              
              print('DEBUG MEALS CARD: selectedDate: $selectedDate');
              print('DEBUG MEALS CARD: mealsForDate count: ${mealsForDate.length}');
              print('DEBUG MEALS CARD: all mealsByDate keys: ${data.mealsByDate.keys.toList()}');
              
              if (mealsForDate.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Text(
                      'ยังไม่มีอาหารที่บันทึก',
                      style: theme.bodyMedium?.copyWith(color: Colors.grey),
                    ),
                  ),
                );
              }
              
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: mealsForDate.length,
                itemBuilder: (context, index) {
                  final meal = mealsForDate[index];
                  return _buildFoodItem(
                    theme,
                    meal,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFoodItem(TextTheme theme, Map<String, dynamic> meal) {
    final mealName = meal['foodName'] ?? 'ไม่ระบุชื่อ';
    final calories = (meal['calories'] ?? 0).toStringAsFixed(0);
    final imageUrl = meal['imageUrl'] as String?;
    
    print('DEBUG FOOD ITEM: meal data: $meal');
    print('DEBUG FOOD ITEM: imageUrl value: $imageUrl');
    
    return GestureDetector(
      onTap: () {
        // Navigate to meal edit screen for editing
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MealEditScreen(
              mealId: meal['mealId'] as String,
              foodName: mealName,
              imagePath: imageUrl ?? meal['imagePath'] ?? '', // ✅ ส่ง imageUrl
              nutritionValues: {
                'calories': (meal['calories'] ?? 0).toDouble(),
                'protein': (meal['protein'] ?? 0).toDouble(),
                'carbs': (meal['carbs'] ?? 0).toDouble(),
                'fat': (meal['fat'] ?? 0).toDouble(),
                'sodium': (meal['sodium'] ?? 0).toDouble(),
              },
              estimatedWeight: (meal['estimatedWeight'] ?? 100.0).toDouble(),
            ),
          ),
        ).then((_) {
          // Reload meals after edit to show updated nutrition values
          _loadTodayMeals();
        });
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey[200]!, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
                image: imageUrl != null && imageUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: imageUrl == null || imageUrl.isEmpty
                  ? Icon(Icons.fastfood, color: Colors.grey[600], size: 28)
                  : null,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(mealName, style: theme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                  Text(
                    'กด เพื่อแก้ไข',
                    style: theme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('$calories kCal', style: theme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                Icon(Icons.edit, color: Colors.grey[400], size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Card for diabetes users - show carbs target for the day
  Widget _buildDiabetesCarbsCard(TextTheme theme, SessionData sessionData) {
    return Consumer<SessionData>(
      builder: (context, session, _) {
        final currentCarbs = _getCarbsForDayForDate(session);
        final carbTarget = session.diabetesCarbLimit ?? 150.0; // Default 150g if not set
        final carbPercent = (currentCarbs / carbTarget).clamp(0.0, 1.5);
        
        // Determine status and color
        String carbStatus;
        Color carbColor;
        
        if (currentCarbs < carbTarget * 0.8) {
          carbStatus = 'ปลอดภัย - คาร์บต่ำ';
          carbColor = Colors.green;
        } else if (currentCarbs >= carbTarget * 0.8 && currentCarbs <= carbTarget) {
          carbStatus = 'ควบคุมได้ดี - อยู่ในเป้าหมาย';
          carbColor = Colors.green;
        } else if (currentCarbs > carbTarget && currentCarbs <= carbTarget * 1.2) {
          carbStatus = 'เกินเป้าหมาย - ระวัง!';
          carbColor = Colors.orange;
        } else {
          carbStatus = 'อันตราย! - อาจมีผลเสียต่อระดับน้ำตาลในเลือด';
          carbColor = Colors.red;
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.grain, color: Colors.purple, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ควบคุมคาร์โบไฮเดรตสำหรับเบาหวาน',
                        style: theme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                      Text(
                        '${currentCarbs.toStringAsFixed(1)} / ${carbTarget.toStringAsFixed(1)} g',
                        style: theme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: carbPercent,
                  minHeight: 8,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(carbColor),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  carbStatus,
                  style: theme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: carbColor,
                  ),
                ),
              ),

            ],
          ),
        );
      },
    );
  }

  Widget _buildHypertensionSodiumCard(TextTheme theme, SessionData sessionData) {
    return Consumer<SessionData>(
      builder: (context, session, _) {
        final currentSodium = _getSodiumForDayForDate(session);
        final sodiumTarget = session.hypertensionSodiumLimit ?? 2000.0; // Default 2000mg if not set
        final sodiumPercent = (currentSodium / sodiumTarget).clamp(0.0, 1.5);
        
        // Determine status and color
        String sodiumStatus;
        Color sodiumColor;
        
        if (currentSodium < sodiumTarget * 0.8) {
          sodiumStatus = 'ปลอดภัย - โซเดียมต่ำ';
          sodiumColor = Colors.green;
        } else if (currentSodium >= sodiumTarget * 0.8 && currentSodium <= sodiumTarget) {
          sodiumStatus = 'ควบคุมได้ดี - อยู่ในเป้าหมาย';
          sodiumColor = Colors.green;
        } else if (currentSodium > sodiumTarget && currentSodium <= sodiumTarget * 1.2) {
          sodiumStatus = 'เกินเป้าหมาย - ระวัง!';
          sodiumColor = Colors.orange;
        } else {
          sodiumStatus = 'อันตราย! - อาจมีผลเสียต่อความดันโลหิต';
          sodiumColor = Colors.red;
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.favorite, color: Colors.red, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ควบคุมโซเดียมสำหรับความดันโลหิตสูง',
                        style: theme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                      Text(
                        '${currentSodium.toStringAsFixed(1)} / ${sodiumTarget.toStringAsFixed(1)} mg',
                        style: theme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: sodiumPercent,
                  minHeight: 8,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(sodiumColor),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  sodiumStatus,
                  style: theme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: sodiumColor,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper method to get 7 days calorie data
  List<fl_chart.FlSpot> _get7DaysChartData(SessionData sessionData) {
    final caloriesList = <fl_chart.FlSpot>[];
    
    for (int i = 6; i >= 0; i--) {
      final date = _selectedDate.subtract(Duration(days: i));
      final calories = sessionData.getCaloriesForDate(date);
      caloriesList.add(fl_chart.FlSpot(6 - i.toDouble(), calories));
    }
    
    return caloriesList;
  }

  // Helper method to get 14 days calorie data
  List<fl_chart.FlSpot> _get14DaysChartData(SessionData sessionData) {
    final caloriesList = <fl_chart.FlSpot>[];
    
    for (int i = 13; i >= 0; i--) {
      final date = _selectedDate.subtract(Duration(days: i));
      final calories = sessionData.getCaloriesForDate(date);
      caloriesList.add(fl_chart.FlSpot(13 - i.toDouble(), calories));
    }
    
    return caloriesList;
  }

  // Helper method to get 7 days carbs data
  List<fl_chart.FlSpot> _get7DaysCarbsData(SessionData sessionData) {
    final carbsList = <fl_chart.FlSpot>[];
    
    for (int i = 6; i >= 0; i--) {
      final date = _selectedDate.subtract(Duration(days: i));
      final carbs = _getCarbsForDateByDate(sessionData, date);
      carbsList.add(fl_chart.FlSpot(6 - i.toDouble(), carbs));
    }
    
    return carbsList;
  }

  // Helper method to get 14 days carbs data
  List<fl_chart.FlSpot> _get14DaysCarbsData(SessionData sessionData) {
    final carbsList = <fl_chart.FlSpot>[];
    
    for (int i = 13; i >= 0; i--) {
      final date = _selectedDate.subtract(Duration(days: i));
      final carbs = _getCarbsForDateByDate(sessionData, date);
      carbsList.add(fl_chart.FlSpot(13 - i.toDouble(), carbs));
    }
    
    return carbsList;
  }

  // Helper method to get carbs for specific date
  double _getCarbsForDateByDate(SessionData sessionData, DateTime date) {
    final meals = sessionData.getMealsForDate(date);
    double total = 0;
    for (var meal in meals) {
      total += (meal['carbs'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }

  // Helper method to get 7 days sodium data
  List<fl_chart.FlSpot> _get7DaysSodiumData(SessionData sessionData) {
    final sodiumList = <fl_chart.FlSpot>[];
    
    for (int i = 6; i >= 0; i--) {
      final date = _selectedDate.subtract(Duration(days: i));
      final sodium = _getSodiumForDateByDate(sessionData, date);
      sodiumList.add(fl_chart.FlSpot(6 - i.toDouble(), sodium));
    }
    
    return sodiumList;
  }

  // Helper method to get 14 days sodium data
  List<fl_chart.FlSpot> _get14DaysSodiumData(SessionData sessionData) {
    final sodiumList = <fl_chart.FlSpot>[];
    
    for (int i = 13; i >= 0; i--) {
      final date = _selectedDate.subtract(Duration(days: i));
      final sodium = _getSodiumForDateByDate(sessionData, date);
      sodiumList.add(fl_chart.FlSpot(13 - i.toDouble(), sodium));
    }
    
    return sodiumList;
  }

  // Helper method to get sodium for specific date
  double _getSodiumForDateByDate(SessionData sessionData, DateTime date) {
    final meals = sessionData.getMealsForDate(date);
    double total = 0;
    for (var meal in meals) {
      total += (meal['sodium'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }

  // Widget to display 7 days chart
  Widget _build7DaysChart(TextTheme theme, SessionData sessionData) {
    return Consumer<SessionData>(
      builder: (context, data, _) {
        final chartData = _get7DaysChartData(data);
        final goalCalories = data.getDailyCalorieGoal();
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('7 วันย้อนหลัง', style: theme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              // Legend
              Wrap(
                spacing: 20,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFABB5A),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('แคลอรี่ที่บริโภค', style: theme.bodySmall),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF1744),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('แคลอรี่ที่เกิน', style: theme.bodySmall),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 250,
                child: fl_chart.BarChart(
                  fl_chart.BarChartData(
                    gridData: fl_chart.FlGridData(show: true, drawVerticalLine: false),
                    titlesData: fl_chart.FlTitlesData(
                      rightTitles: fl_chart.AxisTitles(),
                      topTitles: fl_chart.AxisTitles(),
                      bottomTitles: fl_chart.AxisTitles(
                        sideTitles: fl_chart.SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < 7) {
                              final date = _selectedDate.subtract(Duration(days: 6 - index));
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Transform.rotate(
                                  angle: -0.785,
                                  child: Text(
                                    '${date.day}/${date.month}',
                                    style: theme.bodySmall?.copyWith(fontSize: 11, fontWeight: FontWeight.w600),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: fl_chart.AxisTitles(
                        sideTitles: fl_chart.SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            // ซ่อนตัวเลขสูงสุด (maxY)
                            if (value == goalCalories * 1.2) {
                              return const Text('');
                            }
                            return Text('${value.toInt()}', style: theme.bodySmall, textAlign: TextAlign.center);
                          },
                          reservedSize: 40,
                        ),
                      ),
                    ),
                    borderData: fl_chart.FlBorderData(show: false),
                    minY: 0,
                    maxY: goalCalories * 1.2,
                    barTouchData: fl_chart.BarTouchData(
                      enabled: true,
                      handleBuiltInTouches: true,
                      touchTooltipData: fl_chart.BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return fl_chart.BarTooltipItem(
                            '${rod.toY.toStringAsFixed(1)}kcal',
                            const TextStyle(color: Colors.white),
                          );
                        },
                      ),
                    ),
                    barGroups: List.generate(
                      chartData.length,
                      (index) => fl_chart.BarChartGroupData(
                        x: index,
                        barRods: [
                          fl_chart.BarChartRodData(
                            fromY: 0,
                            toY: chartData[index].y,
                            color: chartData[index].y > goalCalories ? const Color(0xFFFF1744) : const Color(0xFFFABB5A),
                            width: 16,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Display carbs chart for Type 2 diabetes patients (7-day view)
              if (data.hasDiabetes() && data.diabetesType == 'type2') ...[
                _build7DaysCarbsChart(theme, data),
              ],
              // Display sodium charts for hypertension patients (7-day view)
              if (data.hasHypertension()) ...[
                _build7DaysSodiumChart(theme, data),
              ],
            ],
          ),
        );
      },
    );
  }

  // Widget to display 7 days carbs chart for diabetes patients
  Widget _build7DaysCarbsChart(TextTheme theme, SessionData sessionData) {
    return Consumer<SessionData>(
      builder: (context, data, _) {
        if (!data.hasDiabetes()) {
          return const SizedBox.shrink();
        }
        
        final chartData = _get7DaysCarbsData(data);
        final carbLimit = data.diabetesCarbLimit ?? 150.0;
        
        return Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(top: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('คาร์โบไฮเดรต 7 วันย้อนหลัง (โรคเบาหวาน)', 
                  style: theme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              // Legend
              Wrap(
                spacing: 20,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.purple,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('คาร์โบไฮเดรตที่บริโภค', style: theme.bodySmall),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF1744),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('เกินเกณฑ์', style: theme.bodySmall),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 200,
                child: fl_chart.BarChart(
                  fl_chart.BarChartData(
                    gridData: fl_chart.FlGridData(show: true, drawVerticalLine: false),
                    titlesData: fl_chart.FlTitlesData(
                      rightTitles: fl_chart.AxisTitles(),
                      topTitles: fl_chart.AxisTitles(),
                      bottomTitles: fl_chart.AxisTitles(
                        sideTitles: fl_chart.SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < 7) {
                              final date = _selectedDate.subtract(Duration(days: 6 - index));
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Transform.rotate(
                                  angle: -0.785,
                                  child: Text(
                                    '${date.day}/${date.month}',
                                    style: theme.bodySmall?.copyWith(fontSize: 11, fontWeight: FontWeight.w600),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: fl_chart.AxisTitles(
                        sideTitles: fl_chart.SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value == carbLimit * 1.2) {
                              return const Text('');
                            }
                            return Text('${value.toInt()}', style: theme.bodySmall, textAlign: TextAlign.center);
                          },
                          reservedSize: 40,
                        ),
                      ),
                    ),
                    borderData: fl_chart.FlBorderData(show: false),
                    minY: 0,
                    maxY: carbLimit * 1.2,
                    barTouchData: fl_chart.BarTouchData(
                      enabled: true,
                      handleBuiltInTouches: true,
                      touchTooltipData: fl_chart.BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return fl_chart.BarTooltipItem(
                            '${rod.toY.toStringAsFixed(2)}g',
                            const TextStyle(color: Colors.white),
                          );
                        },
                      ),
                    ),
                    barGroups: List.generate(
                      chartData.length,
                      (index) => fl_chart.BarChartGroupData(
                        x: index,
                        barRods: [
                          fl_chart.BarChartRodData(
                            fromY: 0,
                            toY: chartData[index].y,
                            color: chartData[index].y > carbLimit ? const Color(0xFFFF1744) : Colors.purple,
                            width: 16,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'เกณฑ์คาร์โบไฮเดรต: ${carbLimit.toStringAsFixed(0)}g ต่อวัน',
                  style: theme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Widget to display 14 days chart
  Widget _build14DaysChart(TextTheme theme, SessionData sessionData) {
    return Consumer<SessionData>(
      builder: (context, data, _) {
        final chartData = _get14DaysChartData(data);
        final goalCalories = data.getDailyCalorieGoal();
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('14 วันย้อนหลัง', style: theme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              // Legend
              Wrap(
                spacing: 20,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFABB5A),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('แคลอรี่ที่บริโภค', style: theme.bodySmall),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF1744),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('แคลอรี่ที่เกิน', style: theme.bodySmall),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 250,
                child: fl_chart.BarChart(
                  fl_chart.BarChartData(
                    gridData: fl_chart.FlGridData(show: true, drawVerticalLine: false),
                    titlesData: fl_chart.FlTitlesData(
                      rightTitles: fl_chart.AxisTitles(),
                      topTitles: fl_chart.AxisTitles(),
                      bottomTitles: fl_chart.AxisTitles(
                        sideTitles: fl_chart.SideTitles(
                          showTitles: true,
                          interval: 2,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < chartData.length) {
                              final date = _selectedDate.subtract(Duration(days: 13 - index));
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Transform.rotate(
                                  angle: -0.785,
                                  child: Text(
                                    '${date.day}/${date.month}',
                                    style: theme.bodySmall?.copyWith(fontSize: 11, fontWeight: FontWeight.w600),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: fl_chart.AxisTitles(
                        sideTitles: fl_chart.SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            // ซ่อนตัวเลขสูงสุด (maxY)
                            if (value == goalCalories * 1.2) {
                              return const Text('');
                            }
                            return Text('${value.toInt()}', style: theme.bodySmall, textAlign: TextAlign.center);
                          },
                          reservedSize: 40,
                        ),
                      ),
                    ),
                    borderData: fl_chart.FlBorderData(show: false),
                    minY: 0,
                    maxY: goalCalories * 1.2,
                    barTouchData: fl_chart.BarTouchData(
                      enabled: true,
                      handleBuiltInTouches: true,
                      touchTooltipData: fl_chart.BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return fl_chart.BarTooltipItem(
                            '${rod.toY.toStringAsFixed(1)}kcal',
                            const TextStyle(color: Colors.white),
                          );
                        },
                      ),
                    ),
                    barGroups: List.generate(
                      chartData.length,
                      (index) => fl_chart.BarChartGroupData(
                        x: index,
                        barRods: [
                          fl_chart.BarChartRodData(
                            fromY: 0,
                            toY: chartData[index].y,
                            color: chartData[index].y > goalCalories ? const Color(0xFFFF1744) : const Color(0xFFFABB5A),
                            width: 8,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Display carbs chart for Type 2 diabetes patients (14-day view)
              if (data.hasDiabetes() && data.diabetesType == 'type2') ...[
                _build14DaysCarbsChart(theme, data),
              ],
              // Display sodium charts for hypertension patients (14-day view)
              if (data.hasHypertension()) ...[
                _build14DaysSodiumChart(theme, data),
              ],
            ],
          ),
        );
      },
    );
  }

  // Widget to display 14 days carbs chart for diabetes patients
  Widget _build14DaysCarbsChart(TextTheme theme, SessionData sessionData) {
    return Consumer<SessionData>(
      builder: (context, data, _) {
        if (!data.hasDiabetes()) {
          return const SizedBox.shrink();
        }
        
        final chartData = _get14DaysCarbsData(data);
        final carbLimit = data.diabetesCarbLimit ?? 150.0;
        
        return Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(top: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('คาร์โบไฮเดรต 14 วันย้อนหลัง (โรคเบาหวาน)', 
                  style: theme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              // Legend
              Wrap(
                spacing: 20,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.purple,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('คาร์โบไฮเดรตที่บริโภค', style: theme.bodySmall),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF1744),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('เกินเกณฑ์', style: theme.bodySmall),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Calculate chart height proportional to calorie chart
              SizedBox(
                height: 200,
                child: fl_chart.BarChart(
                  fl_chart.BarChartData(
                    gridData: fl_chart.FlGridData(show: true, drawVerticalLine: false),
                    titlesData: fl_chart.FlTitlesData(
                      rightTitles: fl_chart.AxisTitles(),
                      topTitles: fl_chart.AxisTitles(),
                      bottomTitles: fl_chart.AxisTitles(
                        sideTitles: fl_chart.SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < chartData.length) {
                              final date = _selectedDate.subtract(Duration(days: 13 - index));
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Transform.rotate(
                                  angle: -0.785,
                                  child: Text(
                                    '${date.day}/${date.month}',
                                    style: theme.bodySmall?.copyWith(fontSize: 11, fontWeight: FontWeight.w600),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: fl_chart.AxisTitles(
                        sideTitles: fl_chart.SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value == carbLimit * 1.2) {
                              return const Text('');
                            }
                            return Text('${value.toInt()}', style: theme.bodySmall, textAlign: TextAlign.center);
                          },
                          reservedSize: 40,
                        ),
                      ),
                    ),
                    borderData: fl_chart.FlBorderData(show: false),
                    minY: 0,
                    maxY: carbLimit * 1.2,
                    barTouchData: fl_chart.BarTouchData(
                      enabled: true,
                      handleBuiltInTouches: true,
                      touchTooltipData: fl_chart.BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return fl_chart.BarTooltipItem(
                            '${rod.toY.toStringAsFixed(2)}g',
                            const TextStyle(color: Colors.white),
                          );
                        },
                      ),
                    ),
                    barGroups: List.generate(
                      chartData.length,
                      (index) => fl_chart.BarChartGroupData(
                        x: index,
                        barRods: [
                          fl_chart.BarChartRodData(
                            fromY: 0,
                            toY: chartData[index].y,
                            color: chartData[index].y > carbLimit ? const Color(0xFFFF1744) : Colors.purple,
                            width: 10,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'เกณฑ์คาร์โบไฮเดรต: ${carbLimit.toStringAsFixed(0)}g ต่อวัน',
                  style: theme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Widget to display 7 days sodium chart for hypertension
  Widget _build7DaysSodiumChart(TextTheme theme, SessionData sessionData) {
    return Consumer<SessionData>(
      builder: (context, data, _) {
        if (!data.hasHypertension()) {
          return const SizedBox.shrink();
        }
        
        final chartData = _get7DaysSodiumData(data);
        final sodiumLimit = data.hypertensionSodiumLimit ?? 2000.0;
        
        return Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(top: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('โซเดียม 7 วันย้อนหลัง (ความดันโลหิตสูง)', 
                  style: theme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              // Legend
              Wrap(
                spacing: 20,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('โซเดียมที่บริโภค', style: theme.bodySmall),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF1744),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('เกินเกณฑ์', style: theme.bodySmall),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 200,
                child: fl_chart.BarChart(
                  fl_chart.BarChartData(
                    gridData: fl_chart.FlGridData(show: true, drawVerticalLine: false),
                    titlesData: fl_chart.FlTitlesData(
                      rightTitles: fl_chart.AxisTitles(),
                      topTitles: fl_chart.AxisTitles(),
                      bottomTitles: fl_chart.AxisTitles(
                        sideTitles: fl_chart.SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < 7) {
                              final date = _selectedDate.subtract(Duration(days: 6 - index));
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Transform.rotate(
                                  angle: -0.785,
                                  child: Text(
                                    '${date.day}/${date.month}',
                                    style: theme.bodySmall?.copyWith(fontSize: 11, fontWeight: FontWeight.w600),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: fl_chart.AxisTitles(
                        sideTitles: fl_chart.SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value == sodiumLimit * 1.2) {
                              return const Text('');
                            }
                            return Text('${value.toInt()}', style: theme.bodySmall, textAlign: TextAlign.center);
                          },
                          reservedSize: 40,
                        ),
                      ),
                    ),
                    borderData: fl_chart.FlBorderData(show: false),
                    minY: 0,
                    maxY: sodiumLimit * 1.2,
                    barTouchData: fl_chart.BarTouchData(
                      enabled: true,
                      handleBuiltInTouches: true,
                      touchTooltipData: fl_chart.BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return fl_chart.BarTooltipItem(
                            '${rod.toY.toStringAsFixed(2)}mg',
                            const TextStyle(color: Colors.white),
                          );
                        },
                      ),
                    ),
                    barGroups: List.generate(
                      chartData.length,
                      (index) => fl_chart.BarChartGroupData(
                        x: index,
                        barRods: [
                          fl_chart.BarChartRodData(
                            fromY: 0,
                            toY: chartData[index].y,
                            color: chartData[index].y > sodiumLimit ? const Color(0xFFFF1744) : Colors.blue,
                            width: 16,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'เกณฑ์โซเดียม: ${sodiumLimit.toStringAsFixed(0)}mg ต่อวัน',
                  style: theme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Widget to display 14 days sodium chart for hypertension
  Widget _build14DaysSodiumChart(TextTheme theme, SessionData sessionData) {
    return Consumer<SessionData>(
      builder: (context, data, _) {
        if (!data.hasHypertension()) {
          return const SizedBox.shrink();
        }
        
        final chartData = _get14DaysSodiumData(data);
        final sodiumLimit = data.hypertensionSodiumLimit ?? 2000.0;
        
        return Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(top: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('โซเดียม 14 วันย้อนหลัง (ความดันโลหิตสูง)', 
                  style: theme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              // Legend
              Wrap(
                spacing: 20,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('โซเดียมที่บริโภค', style: theme.bodySmall),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF1744),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('เกินเกณฑ์', style: theme.bodySmall),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 200,
                child: fl_chart.BarChart(
                  fl_chart.BarChartData(
                    gridData: fl_chart.FlGridData(show: true, drawVerticalLine: false),
                    titlesData: fl_chart.FlTitlesData(
                      rightTitles: fl_chart.AxisTitles(),
                      topTitles: fl_chart.AxisTitles(),
                      bottomTitles: fl_chart.AxisTitles(
                        sideTitles: fl_chart.SideTitles(
                          showTitles: true,
                          interval: 2,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < chartData.length) {
                              final date = _selectedDate.subtract(Duration(days: 13 - index));
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Transform.rotate(
                                  angle: -0.785,
                                  child: Text(
                                    '${date.day}/${date.month}',
                                    style: theme.bodySmall?.copyWith(fontSize: 11, fontWeight: FontWeight.w600),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: fl_chart.AxisTitles(
                        sideTitles: fl_chart.SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value == sodiumLimit * 1.2) {
                              return const Text('');
                            }
                            return Text('${value.toInt()}', style: theme.bodySmall, textAlign: TextAlign.center);
                          },
                          reservedSize: 40,
                        ),
                      ),
                    ),
                    borderData: fl_chart.FlBorderData(show: false),
                    minY: 0,
                    maxY: sodiumLimit * 1.2,
                    barTouchData: fl_chart.BarTouchData(
                      enabled: true,
                      handleBuiltInTouches: true,
                      touchTooltipData: fl_chart.BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return fl_chart.BarTooltipItem(
                            '${rod.toY.toStringAsFixed(2)}mg',
                            const TextStyle(color: Colors.white),
                          );
                        },
                      ),
                    ),
                    barGroups: List.generate(
                      chartData.length,
                      (index) => fl_chart.BarChartGroupData(
                        x: index,
                        barRods: [
                          fl_chart.BarChartRodData(
                            fromY: 0,
                            toY: chartData[index].y,
                            color: chartData[index].y > sodiumLimit ? const Color(0xFFFF1744) : Colors.blue,
                            width: 10,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'เกณฑ์โซเดียม: ${sodiumLimit.toStringAsFixed(0)}mg ต่อวัน',
                  style: theme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}