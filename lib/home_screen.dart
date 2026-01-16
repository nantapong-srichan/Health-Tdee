import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart'; 
import 'session_data.dart'; 
import 'image_picker_screen.dart';
import 'profile_screen.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTabIndex = 0; // 0: daily, 1: 7days, 2: 30days

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
          );
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
                  );
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
                  sessionData.userName ?? 'ผู้ใช้',
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

  // รับ goal มาแสดง
  Widget _buildTodayCaloriesCard(TextTheme theme, String goal) {
    return Consumer<SessionData>(
      builder: (context, sessionData, _) {
        final todayCalories = sessionData.getTodayCalories();
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
                    percent: (todayCalories / goalCalories).clamp(0.0, 1.0),
                    center: Text(
                      "${todayCalories.toStringAsFixed(0)}/${goalCalories.toStringAsFixed(0)}\nแคลอรี่",
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
                        Text(
                          todayCalories < goalCalories ? 'อีกนิดเดียว!' : 'เกินแล้ว',
                          style: theme.bodyMedium?.copyWith(color: Colors.grey[600]),
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
        
        int selectedIndex = 6; // เลือกวันนี้เป็นค่าเริ่มต้น
        
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
                      bool isSelected = index == selectedIndex;
                      final dayName = ['อา.', 'จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.', 'ส.'];
                      
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedIndex = index;
                            sessionData.selectDate(date);
                          });
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
                      Text("${caloriesForDate.toStringAsFixed(0)} kCal", style: theme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      Text("เหลือ ${(goal - caloriesForDate).toStringAsFixed(0)}", style: theme.bodySmall?.copyWith(color: Colors.grey)),
                    ],
                  ),
                  progressColor: const Color(0xFFFABB5A),
                  backgroundColor: Colors.grey[200]!,
                  circularStrokeCap: CircularStrokeCap.round,
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
                    meal['imagePath'] ?? 'assets/food1.png',
                    meal['name'] ?? 'ไม่ระบุชื่อ',
                    '${(meal['calories'] ?? 0).toStringAsFixed(0)} kCal',
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFoodItem(TextTheme theme, String imagePath, String name, String calories) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundImage: AssetImage(imagePath), // Food image
          ),
          const SizedBox(width: 15),
          Text(name, style: theme.bodyLarge),
          const Spacer(),
          Text(calories, style: theme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}