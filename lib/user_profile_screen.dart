import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/bmr_calculator.dart';
import 'session_data.dart';
import 'login_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _authService = AuthService();
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await _authService.getCurrentUser();
      setState(() {
        _userProfile = profile;
        _isLoading = false;
      });
      
      // Update SessionData with health metrics
      if (mounted && profile?['user'] != null) {
        final sessionData = Provider.of<SessionData>(context, listen: false);
        final userProfile = profile['user'] as Map<String, dynamic>;
        
        if (userProfile['tdee'] != null) {
          sessionData.updateTDEE((userProfile['tdee'] as num).toDouble());
        }
        if (userProfile['dailyCalorieNeed'] != null) {
          sessionData.updateDailyCalorieNeed((userProfile['dailyCalorieNeed'] as num).toDouble());
        }
        if (userProfile['proteinGrams'] != null) {
          sessionData.updateProteinGrams((userProfile['proteinGrams'] as num).toDouble());
        }
        if (userProfile['bmr'] != null) {
          sessionData.updateBMR((userProfile['bmr'] as num).toDouble());
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'ออกจากระบบ',
          style: GoogleFonts.kanit(),
        ),
        content: Text(
          'คุณแน่ใจหรือว่าต้องการออกจากระบบ?',
          style: GoogleFonts.kanit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'ยกเลิก',
              style: GoogleFonts.kanit(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _authService.logout();
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
            child: Text(
              'ออกจากระบบ',
              style: GoogleFonts.kanit(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFFDEFE0),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFABB5A)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFDEFE0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDEFE0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'ตั้งค่า',
          style: GoogleFonts.kanit(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile Section Header
              Text(
                'ข้อมูลส่วนตัว',
                style: GoogleFonts.kanit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),

              // Profile Option
              _buildProfileOption(
                icon: Icons.person_outline,
                title: 'รูปโปรไฟล์',
                trailing: Icons.arrow_forward_ios,
                onTap: () {
                  // TODO: Implement profile photo edit
                },
              ),
              _buildProfileOption(
                icon: Icons.email_outlined,
                title: 'อีเมล',
                subtitle: _userProfile?['email'] ?? 'ไม่มีข้อมูล',
                trailing: Icons.arrow_forward_ios,
                onTap: () {
                  // TODO: Implement email edit
                },
              ),
              _buildProfileOption(
                icon: Icons.lock_outline,
                title: 'เปลี่ยนรหัสผ่าน',
                trailing: Icons.arrow_forward_ios,
                onTap: () {
                  // TODO: Implement password change
                },
              ),

              const SizedBox(height: 32),

              // Health Information Section
              Text(
                'ข้อมูลสุขภาพ',
                style: GoogleFonts.kanit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),

              // Health Information Option
              _buildProfileOption(
                icon: Icons.favorite_outline,
                title: 'อัพเดตข้อมูลสุขภาพ',
                subtitle: _userProfile?['bmr'] != null 
                  ? 'BMR: ${_userProfile?['bmr']} kcal | TDEE: ${_userProfile?['tdee']} kcal | Protein: ${_userProfile?['proteinGrams']}g'
                  : 'ยังไม่มีข้อมูล',
                trailing: Icons.arrow_forward_ios,
                onTap: () {
                  _showHealthEditDialog();
                },
              ),

              const SizedBox(height: 32),

              // Other Section
              Text(
                'อื่นๆ',
                style: GoogleFonts.kanit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),

              _buildProfileOption(
                icon: Icons.help_outline,
                title: 'ติดต่อเรา',
                trailing: Icons.arrow_forward_ios,
                onTap: () {
                  // TODO: Implement contact us
                },
              ),

              const SizedBox(height: 32),

              // Logout Button
              ElevatedButton(
                onPressed: _handleLogout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'ออกจากระบบ',
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

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    String? subtitle,
    IconData? trailing,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFFABB5A), size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.kanit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: GoogleFonts.kanit(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null)
              Icon(trailing, color: Colors.grey[400], size: 18),
          ],
        ),
      ),
    );
  }

  void _showHealthEditDialog() {
    final nameController = TextEditingController(
      text: _userProfile?['name']?.toString() ?? '',
    );
    final ageController = TextEditingController(
      text: _userProfile?['age']?.toString() ?? '',
    );
    final weightController = TextEditingController(
      text: _userProfile?['weight']?.toString() ?? '',
    );
    final heightController = TextEditingController(
      text: _userProfile?['height']?.toString() ?? '',
    );
    final activityLevelController = TextEditingController(
      text: _userProfile?['activityLevel']?.toString() ?? 'moderate',
    );
    // ตั้ง default gender และ goal เพื่อให้ dropdown มีค่าตั้งแต่ต้น
    String? selectedGender = _userProfile?['gender'] ?? 'male';
    String? selectedGoal = _userProfile?['goal'] ?? 'maintain';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'อัพเดตข้อมูลสุขภาพ',
          style: GoogleFonts.kanit(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'ชื่อ',
                  labelStyle: GoogleFonts.kanit(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Gender Dropdown
              StatefulBuilder(
                builder: (context, setState) {
                  return DropdownButtonFormField<String>(
                    value: selectedGender,
                    items: const [
                      DropdownMenuItem(value: 'male', child: Text('ชาย')),
                      DropdownMenuItem(value: 'female', child: Text('หญิง')),
                      DropdownMenuItem(value: 'other', child: Text('อื่นๆ')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedGender = value;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'เพศ',
                      labelStyle: GoogleFonts.kanit(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ageController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'อายุ (ปี)',
                  labelStyle: GoogleFonts.kanit(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: weightController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'น้ำหนัก (กก)',
                  labelStyle: GoogleFonts.kanit(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: heightController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'ความสูง (ซม)',
                  labelStyle: GoogleFonts.kanit(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: activityLevelController,
                decoration: InputDecoration(
                  labelText: 'ระดับการออกกำลัง',
                  labelStyle: GoogleFonts.kanit(),
                  hintText: 'moderate, light, active, sedentary',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Goal Dropdown
              StatefulBuilder(
                builder: (context, setState) {
                  return DropdownButtonFormField<String>(
                    value: selectedGoal,
                    items: const [
                      DropdownMenuItem(value: 'weight_loss', child: Text('ลดน้ำหนัก')),
                      DropdownMenuItem(value: 'weight_gain', child: Text('เพิ่มน้ำหนัก')),
                      DropdownMenuItem(value: 'maintain', child: Text('รักษาน้ำหนัก')),
                      DropdownMenuItem(value: 'muscle_gain', child: Text('เพิ่มกล้ามเนื้อ')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedGoal = value;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'เป้าหมาย',
                      labelStyle: GoogleFonts.kanit(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'ยกเลิก',
              style: GoogleFonts.kanit(),
            ),
          ),
          TextButton(
            onPressed: () async {
              try {
                // Validate inputs
                if (nameController.text.isEmpty ||
                    selectedGender == null ||
                    selectedGoal == null ||
                    ageController.text.isEmpty ||
                    weightController.text.isEmpty ||
                    heightController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('กรุณากรอกข้อมูลให้ครบถ้วน'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final age = int.parse(ageController.text);
                final weight = double.parse(weightController.text);
                final height = double.parse(heightController.text);
                final activityLevel = activityLevelController.text;

                // Calculate BMR using Mifflin-St Jeor formula
                final bmr = BMRCalculator.calculate(
                  gender: selectedGender!,
                  weight: weight,
                  height: height,
                  age: age,
                );

                // Update profile
                final result = await _authService.updateProfile(
                  name: nameController.text,
                  age: age,
                  weight: weight,
                  height: height,
                  gender: selectedGender!,
                  bmr: bmr,
                  activityLevel: activityLevel,
                  goal: selectedGoal!,
                  dailyCalorieGoal: _userProfile?['dailyCalorieGoal'] ?? 2000,
                );

                if (mounted) {
                  Navigator.pop(context);
                  if (result['success']) {
                    // Reload profile and update SessionData
                    _loadUserProfile();
                    
                    // Update SessionData with new health metrics
                    final sessionData = Provider.of<SessionData>(context, listen: false);
                    final updatedProfile = result['user'] as Map<String, dynamic>?;
                    if (updatedProfile != null) {
                      if (updatedProfile['tdee'] != null) {
                        sessionData.updateTDEE((updatedProfile['tdee'] as num).toDouble());
                      }
                      if (updatedProfile['dailyCalorieNeed'] != null) {
                        sessionData.updateDailyCalorieNeed((updatedProfile['dailyCalorieNeed'] as num).toDouble());
                      }
                      if (updatedProfile['proteinGrams'] != null) {
                        sessionData.updateProteinGrams((updatedProfile['proteinGrams'] as num).toDouble());
                      }
                      if (updatedProfile['bmr'] != null) {
                        sessionData.updateBMR((updatedProfile['bmr'] as num).toDouble());
                      }
                    }
                    
                    final tdee = _userProfile?['tdee'];
                    final protein = _userProfile?['proteinGrams'];
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('อัพเดตข้อมูลสำเร็จ!\nBMR: $bmr kcal/day | TDEE: $tdee kcal | Protein: $protein g'),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('ข้อผิดพลาด: ${result['message']}'),
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
              }
            },
            child: Text(
              'บันทึก',
              style: GoogleFonts.kanit(color: const Color(0xFFFABB5A)),
            ),
          ),
        ],
      ),
    );
  }
}
