import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart'; 
import 'services/auth_service.dart';
import 'services/meal_service.dart';
import 'services/api_service.dart';
import 'session_data.dart'; 
import 'image_picker_screen.dart';
import 'profile_screen.dart';
import 'meal_confirmation_screen.dart';
import 'insulin_reminder_screen.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTabIndex = 0; // 0: daily, 1: 7days, 2: 30days
  late DateTime _selectedDate;
  final _authService = AuthService();
  final _mealService = MealService();

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sessionData = Provider.of<SessionData>(context, listen: false);
      sessionData.selectedDate = _selectedDate;
    });
    _loadUserDataAndRefresh();
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
        if (userProfile['diseases'] != null) {
          final diseasesList = (userProfile['diseases'] as List?)?.cast<String>() ?? [];
          sessionData.updateDiseases(diseasesList);
        }
        if (userProfile['diabetesCarbLimit'] != null) {
          final carbLimit = userProfile['diabetesCarbLimit'];
          double carbValue = (carbLimit is int) ? carbLimit.toDouble() : (carbLimit as double? ?? 0.0);
          sessionData.updateDiabetesCarbLimit(carbValue);
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
      final startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      final endOfDay = startOfDay.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));

      print('DEBUG: Loading meals for $_selectedDate');
      print('DEBUG: Start: $startOfDay, End: $endOfDay');

      // Check if authenticated
      final apiService = ApiService();
      final token = await apiService.getToken();
      print('DEBUG: Token exists: ${token != null}');

      final response = await _mealService.getMealHistory(
        startDate: startOfDay.toIso8601String(),
        endDate: endOfDay.toIso8601String(),
        limit: 100,
      );

      print('DEBUG: getMealHistory response: $response');

      if (mounted && response['success']) {
        final sessionData = Provider.of<SessionData>(context, listen: false);
        sessionData.selectedDate = _selectedDate;
        
        // Clear meals for this date before adding new ones (prevent duplicates)
        sessionData.clearMealsForDate(_selectedDate);
        
        final meals = response['meals'] as List?;
        print('DEBUG: Meals count: ${meals?.length ?? 0}');
        
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
                // Diabetes carbs card (only for users with diabetes) - show after today calories
                if (sessionData.hasDiabetes()) ...[
                  _buildDiabetesCarbsCard(kanitTheme, sessionData),
                  const SizedBox(height: 16),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const InsulinReminderScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.notifications_active, size: 18),
                      label: Text(
                        'แจ้งเตือนการฉีดอินซูลิน',
                        style: GoogleFonts.kanit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFABB5A),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
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
            // Refresh meal history when returning from ImagePickerScreen
            _loadTodayMeals();
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
              backgroundImage: sessionData.profileImagePath != null
                  ? FileImage(File(sessionData.profileImagePath!))
                  : const AssetImage('assets/profile_pic.png') as ImageProvider,
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
        final today = DateTime.now();
        final datesList = <DateTime>[];
        
        // สร้างลิสต์วันที่สำหรับ "รายวัน"
        for (int i = 6; i >= 0; i--) {
          datesList.add(today.subtract(Duration(days: i)));
        }
        
        // หาวันที่เลือก index
        int selectedIndex = datesList.indexWhere((date) => 
          date.year == _selectedDate.year && 
          date.month == _selectedDate.month && 
          date.day == _selectedDate.day
        );
        
        if (selectedIndex == -1) {
          selectedIndex = 6; // Default to today
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
                  Tab(text: '30 วันย้อนหลัง'),
                ],
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
                SizedBox(
                  height: 70,
                  child: Center(
                    child: Text(
                      _selectedTabIndex == 1 ? '7 วันย้อนหลัง' : '30 วันย้อนหลัง',
                      style: theme.bodyMedium?.copyWith(color: Colors.grey),
                    ),
                  ),
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
                      Text("เหลือ ${(goal - caloriesForDate).toStringAsFixed(0)}", style: theme.bodySmall?.copyWith(color: Colors.grey)),
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
    
    return GestureDetector(
      onTap: () {
        // Navigate to meal confirmation screen for editing
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MealConfirmationScreen(
              foodName: mealName,
              imagePath: meal['imagePath'] ?? '',
              nutritionValues: {
                'calories': (meal['calories'] ?? 0).toDouble(),
                'protein': (meal['protein'] ?? 0).toDouble(),
                'carbs': (meal['carbs'] ?? 0).toDouble(),
                'fat': (meal['fat'] ?? 0).toDouble(),
              },
              mealId: meal['mealId'],
              estimatedWeight: (meal['estimatedWeight'] ?? 100.0).toDouble(),
            ),
          ),
        ).then((_) {
          // Reload meals when returning from edit screen
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
              ),
              child: Icon(Icons.fastfood, color: Colors.grey[600], size: 28),
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
          carbStatus = 'ต่ำกว่าเป้าหมาย';
          carbColor = Colors.blue;
        } else if (currentCarbs >= carbTarget * 0.8 && currentCarbs <= carbTarget) {
          carbStatus = 'อยู่ในเป้าหมายที่ดี!';
          carbColor = Colors.green;
        } else {
          carbStatus = 'เกินเป้าหมายแล้ว!';
          carbColor = Colors.orange;
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
}