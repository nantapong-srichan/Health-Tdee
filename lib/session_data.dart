import 'package:flutter/material.dart';

class SessionData with ChangeNotifier {
  
  // ข้อมูลผู้ใช้
  String? userName;
  String? profileImagePath;
  
  //ข้อมูลจากช่องกรอกข้อความ
  String? dateOfBirth;
  String? gender; // < รับค่า null ได้
  String? height;
  String? weight;
  
  // ข้อมูลจากปุ่มเลือก
  String? exerciseStyle; // < รับค่า null ได้
  String? goal; // < รับค่า null ได้
  String? healthInfo; // < รับค่า null ได้
  
  // ข้อมูลสุขภาพ (BMR, TDEE, Protein)
  double? bmr;
  double? tdee;
  double? dailyCalorieNeed;
  double? proteinGrams;

  // ข้อมูลการรับประทานอาหาร พร้อมวันที่
  List<Map<String, dynamic>> meals = [];
  DateTime? selectedDate; // วันที่ที่เลือกสำหรับแสดงผล

  // ฟังก์ชันอัปเดตข้อมูล Text
  // ฟังก์ชันอัปเดตข้อมูลผู้ใช้
  void updateUserName(String name) {
    userName = name;
    notifyListeners();
  }

  void updateProfileImagePath(String path) {
    profileImagePath = path;
    notifyListeners();
  }

  void updateDateOfBirth(String dob) {
    dateOfBirth = dob;
    notifyListeners();
  }

  void updateHeight(String newHeight) {
    height = newHeight;
    notifyListeners();
  }
  
  void updateWeight(String newWeight) {
    weight = newWeight;
    notifyListeners();
  }

  //  ฟังก์ชันอัปเดต (ปุ่มเลือก) ให้รับค่า null ได้ ---

  void updateGender(String? newGender) { // < เปลี่ยนเป็น String?
    gender = newGender;
    notifyListeners();
  }

  void updateExerciseStyle(String? style) { // < เปลี่ยนเป็น String?
    exerciseStyle = style;
    notifyListeners();
  }

  void updateGoal(String? newGoal) { // < เปลี่ยนเป็น String?
    goal = newGoal;
    notifyListeners();
  }

  void updateHealthInfo(String? info) { // < เปลี่ยนเป็น String?
    healthInfo = info;
    notifyListeners();
  }

  // ฟังก์ชันสำหรับอัปเดตข้อมูลสุขภาพ (BMR, TDEE, Protein)
  void updateBMR(double value) {
    bmr = value;
    notifyListeners();
  }

  void updateTDEE(double value) {
    tdee = value;
    notifyListeners();
  }

  void updateDailyCalorieNeed(double value) {
    dailyCalorieNeed = value;
    notifyListeners();
  }

  void updateProteinGrams(double value) {
    proteinGrams = value;
    notifyListeners();
  }

  // ฟังก์ชันสำหรับเคลียร์ข้อมูล
  void clearData() {
    dateOfBirth = null;
    gender = null;
    height = null;
    weight = null;
    exerciseStyle = null;
    goal = null;
    healthInfo = null;
    bmr = null;
    tdee = null;
    dailyCalorieNeed = null;
    proteinGrams = null;
    notifyListeners();
  }

  // ฟังก์ชันสำหรับจัดการการรับประทานอาหาร
  void addMeal(Map<String, dynamic> meal) {
    // ถ้าไม่มีวันที่ ใช้วันปัจจุบัน
    if (!meal.containsKey('date')) {
      meal['date'] = DateTime.now().toString().split(' ')[0]; // YYYY-MM-DD
    }
    meals.add(meal);
    notifyListeners();
  }

  void removeMeal(int index) {
    if (index >= 0 && index < meals.length) {
      meals.removeAt(index);
      notifyListeners();
    }
  }

  void clearMeals() {
    meals.clear();
    notifyListeners();
  }

  void selectDate(DateTime date) {
    selectedDate = date;
    notifyListeners();
  }

  // Get meals for a specific date
  List<Map<String, dynamic>> getMealsForDate(DateTime date) {
    String dateStr = date.toString().split(' ')[0]; // YYYY-MM-DD
    return meals.where((meal) => meal['date'] == dateStr).toList();
  }

  // Get today's meals
  List<Map<String, dynamic>> getTodayMeals() {
    return getMealsForDate(DateTime.now());
  }

  // Get calories for a specific date
  double getCaloriesForDate(DateTime date) {
    final mealsForDate = getMealsForDate(date);
    double total = 0;
    for (var meal in mealsForDate) {
      total += (meal['calories'] ?? 0) as double;
    }
    return total;
  }

  // Get today's calories
  double getTodayCalories() {
    return getCaloriesForDate(DateTime.now());
  }

  // Get last 7 days meals
  List<Map<String, dynamic>> getLast7DaysMeals() {
    final today = DateTime.now();
    final sevenDaysAgo = today.subtract(const Duration(days: 7));
    return meals.where((meal) {
      try {
        DateTime mealDate = DateTime.parse(meal['date'] ?? '');
        return mealDate.isAfter(sevenDaysAgo) && mealDate.isBefore(today.add(const Duration(days: 1)));
      } catch (e) {
        return false;
      }
    }).toList();
  }

  // Get last 30 days meals
  List<Map<String, dynamic>> getLast30DaysMeals() {
    final today = DateTime.now();
    final thirtyDaysAgo = today.subtract(const Duration(days: 30));
    return meals.where((meal) {
      try {
        DateTime mealDate = DateTime.parse(meal['date'] ?? '');
        return mealDate.isAfter(thirtyDaysAgo) && mealDate.isBefore(today.add(const Duration(days: 1)));
      } catch (e) {
        return false;
      }
    }).toList();
  }

  // Get daily average for last 7 days
  Map<String, double> get7DaysAverageCalories() {
    Map<String, double> dailyCalories = {};
    final today = DateTime.now();
    
    for (int i = 6; i >= 0; i--) {
      DateTime date = today.subtract(Duration(days: i));
      String dateStr = date.toString().split(' ')[0];
      dailyCalories[dateStr] = getCaloriesForDate(date);
    }
    return dailyCalories;
  }

  // Get daily average for last 30 days
  Map<String, double> get30DaysAverageCalories() {
    Map<String, double> dailyCalories = {};
    final today = DateTime.now();
    
    for (int i = 29; i >= 0; i--) {
      DateTime date = today.subtract(Duration(days: i));
      String dateStr = date.toString().split(' ')[0];
      dailyCalories[dateStr] = getCaloriesForDate(date);
    }
    return dailyCalories;
  }

  double getTotalCalories() {
    double total = 0;
    for (var meal in meals) {
      total += (meal['calories'] ?? 0) as double;
    }
    return total;
  }

  double getTotalProtein() {
    double total = 0;
    for (var meal in meals) {
      total += (meal['protein'] ?? 0) as double;
    }
    return total;
  }

  double getTotalCarbs() {
    double total = 0;
    for (var meal in meals) {
      total += (meal['carbs'] ?? 0) as double;
    }
    return total;
  }

  double getTotalFat() {
    double total = 0;
    for (var meal in meals) {
      total += (meal['fat'] ?? 0) as double;
    }
    return total;
  }

  // Get daily calorie goal based on selected goal
  double getDailyCalorieGoal() {
    // Use calculated daily calorie need if available
    if (dailyCalorieNeed != null && dailyCalorieNeed! > 0) {
      return dailyCalorieNeed!;
    }
    
    // Fallback to hardcoded values based on goal
    switch (goal) {
      case 'weight_loss':
        return 1800.0; // For weight loss
      case 'weight_gain':
        return 2500.0; // For weight gain
      case 'maintain':
        return 2000.0; // For maintaining weight
      case 'muscle_gain':
        return 2300.0; // For muscle gain
      default:
        return 2000.0; // Default
    }
  }

  // Get goal label in Thai
  String getGoalLabel() {
    switch (goal) {
      case 'weight_loss':
        return 'ลดน้ำหนัก';
      case 'weight_gain':
        return 'เพิ่มน้ำหนัก';
      case 'maintain':
        return 'รักษาน้ำหนัก';
      case 'muscle_gain':
        return 'เพิ่มกล้ามเนื้อ';
      default:
        return 'ไม่ได้กำหนด';
    }
  }
}