import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart'; 
import 'session_data.dart'; 
import 'image_picker_screen.dart'; 

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
                _buildDateSelector(kanitTheme),
                const SizedBox(height: 24),
                _buildDailyMealsCard(kanitTheme),
              ],
            ),
          ),
        ),
      ),
      // Custom Bottom Navigation Bar
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
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  //Helper Widgets

  Widget _buildHeader(TextTheme theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ยินดีต้อนรับ', style: theme.bodyLarge?.copyWith(fontSize: 22)),
            Text(
              'Nantapong',
              style: theme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 34,
              ),
            ),
          ],
        ),
        const CircleAvatar(
          radius: 35,
          backgroundImage: AssetImage('assets/profile_pic.png'), // Your profile image
        ),
      ],
    );
  }

  // รับ goal มาแสดง
  Widget _buildTodayCaloriesCard(TextTheme theme, String goal) {
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
                percent: 1063 / 2000,
                center: Text(
                  "1063/2000\nแคลอรี่",
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
                      goal, // แสดง goal ที่ผู้ใช้เลือก
                      style: theme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'อีกนิดเดียว!',
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
  }

  Widget _buildDateSelector(TextTheme theme) {
    final List<Map<String, String>> dates = [
      {'day': '17', 'weekday': 'อา.'},
      {'day': '18', 'weekday': 'จ.'},
      {'day': '19', 'weekday': 'อ.'},
      {'day': '20', 'weekday': 'พ.'},
      {'day': '21', 'weekday': 'พฤ.'},
      {'day': '22', 'weekday': 'ศ.'},
      {'day': '23', 'weekday': 'ส.'},
    ];
    int selectedIndex = 1; // '18' is selected

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFFFABB5A),
            indicatorWeight: 3,
            labelStyle: theme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'รายวัน'),
              Tab(text: '7 วันย้อนหลัง'),
              Tab(text: '30 วันย้อนหลัง'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 70,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: dates.length,
              itemBuilder: (context, index) {
                bool isSelected = index == selectedIndex;
                return Container(
                  width: 50,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFFABB5A) : Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(dates[index]['day']!,
                          style: theme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : Colors.black)),
                      Text(dates[index]['weekday']!,
                          style: theme.bodySmall?.copyWith(
                              color: isSelected ? Colors.white70 : Colors.grey)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyMealsCard(TextTheme theme) {
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
              Text('1063/1801 kcal', style: theme.bodyMedium?.copyWith(color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: CircularPercentIndicator(
              radius: 65.0,
              lineWidth: 18.0,
              percent: 1063 / 1801,
              center: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("1063 kCal", style: theme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  Text("เหลือ 738", style: theme.bodySmall?.copyWith(color: Colors.grey)),
                ],
              ),
              progressColor: const Color(0xFFFABB5A),
              backgroundColor: Colors.grey[200]!,
              circularStrokeCap: CircularStrokeCap.round,
            ),
          ),
          const SizedBox(height: 20),
          const Divider(),
          _buildFoodItem(theme, 'assets/food1.png', 'แกงจืดเต้าหู้หมูสับ', '180 kCal'),
          _buildFoodItem(theme, 'assets/food2.png', 'คะน้าหมูกรอบ', '883 kCal'),
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