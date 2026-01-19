import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/bmr_calculator.dart';
import 'session_data.dart';
import 'get_started_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  Map<String, dynamic>? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await _authService.getCurrentUser();
      print('=== DEBUG: Profile loaded ===');
      print('Full profile: $profile');
      final userProfile = profile['user'] as Map<String, dynamic>?;
      if (userProfile != null) {
        print('User diseases: ${userProfile['diseases']}');
        print('User diseases type: ${userProfile['diseases'].runtimeType}');
        print('Diseases is empty: ${(userProfile['diseases'] as List?)?.isEmpty}');
        print('Diabetes in diseases: ${(userProfile['diseases'] as List?)?.contains('diabetes')}');
      }
      setState(() {
        _userProfile = profile;
      });
    } catch (e) {
      // Handle error silently
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final kanitTheme = GoogleFonts.kanitTextTheme(textTheme);
    final sessionData = context.watch<SessionData>();

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
          'โปรไฟล์',
          style: kanitTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Card
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 260), // ปรับ 240-320 ได้
                  child: Container(
                    width: double.infinity, // ให้การ์ดเต็มความกว้างตาม maxWidth
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const CircleAvatar(
                          radius: 50,
                          backgroundImage: AssetImage('assets/profile_pic.png'),
                        ),
                        const SizedBox(height: 16),
                        // Show username from database
                        Text(
                          _userProfile != null && _userProfile!['user'] != null
                              ? _userProfile!['user']['name'] ?? 'ผู้ใช้'
                              : 'โหลดข้อมูล...',
                          textAlign: TextAlign.center,
                          style: kanitTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Show email from database
                        Text(
                          _userProfile != null && _userProfile!['user'] != null
                              ? _userProfile!['user']['email'] ?? 'ไม่มีอีเมล'
                              : 'โหลดข้อมูล...',
                          textAlign: TextAlign.center,
                          style: kanitTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

                const SizedBox(height: 24),

                // Menu Items
                _buildMenuSection(kanitTheme, [
                  {
                    'icon': Icons.person_outline,
                    'title': 'ข้อมูลโปรไฟล์',
                    'onTap': () => _editProfile(context, kanitTheme, sessionData),
                  },
                  {
                    'icon': Icons.email_outlined,
                    'title': 'อีเมล',
                    'onTap': () => _editEmail(context, kanitTheme),
                  },
                  {
                    'icon': Icons.lock_outline,
                    'title': 'เปลี่ยนรหัสผ่าน',
                    'onTap': () => _changePassword(context, kanitTheme),
                  },
                  {
                    'icon': Icons.health_and_safety,
                    'title': 'ข้อมูลสุขภาพ',
                    'onTap': () => _editHealthInfo(context, kanitTheme, sessionData),
                  },
                  {
                    'icon': Icons.medical_information_outlined,
                    'title': 'โรคประจำตัว',
                    'onTap': () => _editDiseases(context, kanitTheme),
                  },
                ]),
                const SizedBox(height: 24),

                // Logout Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _showLogoutDialog(context, kanitTheme);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'ออกจากระบบ',
                      style: kanitTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
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

  Widget _buildMenuSection(
    TextTheme theme,
    List<Map<String, dynamic>> items,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: List.generate(
          items.length,
          (index) {
            final item = items[index];
            final isLast = index == items.length - 1;
            return Column(
              children: [
                ListTile(
                  leading: Icon(
                    item['icon'] as IconData,
                    color: const Color(0xFFFABB5A),
                    size: 24,
                  ),
                  title: Text(
                    item['title'] as String,
                    style: theme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey[400],
                    size: 16,
                  ),
                  onTap: item['onTap'] as VoidCallback,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                if (!isLast)
                  Divider(
                    height: 1,
                    indent: 20,
                    endIndent: 20,
                    color: Colors.grey[200],
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _editProfile(BuildContext context, TextTheme theme, SessionData sessionData) {
    final nameController = TextEditingController();
    final lastNameController = TextEditingController();
    final dobController = TextEditingController(text: sessionData.dateOfBirth ?? '');
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            String? dobError;
            
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'แก้ไขข้อมูลโปรไฟล์',
                    style: theme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'ชื่อ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: lastNameController,
                    decoration: InputDecoration(
                      labelText: 'นามสกุล',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: dobController,
                    keyboardType: TextInputType.datetime,
                    decoration: InputDecoration(
                      labelText: 'วันเกิด (dd/mm/yyyy)',
                      hintText: 'เช่น 05/07/2003',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        if (value.isEmpty) {
                          dobError = null;
                        } else if (!RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(value)) {
                          dobError = 'รูปแบบต้อง dd/mm/yyyy เท่านั้น';
                        } else {
                          dobError = null;
                        }
                      });
                    },
                  ),
                  if (dobError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        dobError!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: dobError == null && dobController.text.isNotEmpty ? () {
                        sessionData.updateDateOfBirth(dobController.text);
                        nameController.dispose();
                        lastNameController.dispose();
                        dobController.dispose();
                        Navigator.pop(context);
                      } : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (dobError == null && dobController.text.isNotEmpty) ? const Color(0xFFFABB5A) : Colors.grey[400],
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'บันทึก',
                        style: theme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _editEmail(BuildContext context, TextTheme theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'แก้ไขอีเมล',
                style: theme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                decoration: InputDecoration(
                  labelText: 'อีเมลใหม่',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFABB5A),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'บันทึก',
                    style: theme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _changePassword(BuildContext context, TextTheme theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'เปลี่ยนรหัสผ่าน',
                style: theme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'รหัสผ่านเก่า',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'รหัสผ่านใหม่',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'ยืนยันรหัสผ่าน',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFABB5A),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'บันทึก',
                    style: theme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _editHealthInfo(BuildContext context, TextTheme theme, SessionData sessionData) {
    if (_userProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ยังไม่สามารถโหลดข้อมูลได้'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final userProfile = _userProfile!['user'] as Map<String, dynamic>?;
    if (userProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ไม่พบข้อมูลผู้ใช้'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final weightController = TextEditingController(
      text: userProfile['weight']?.toString() ?? '',
    );
    final heightController = TextEditingController(
      text: userProfile['height']?.toString() ?? '',
    );
    final ageController = TextEditingController(
      text: userProfile['age']?.toString() ?? '',
    );
    
    String _selectedActivityLevel = userProfile['activityLevel'] ?? 'moderate';
    String _selectedGoal = userProfile['goal'] ?? 'maintain';
    String _selectedGender = userProfile['gender'] ?? 'male';
    bool _isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ข้อมูลสุขภาพ',
                      style: theme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'อายุ (ปี)',
                      style: theme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: ageController,
                      keyboardType: TextInputType.number,
                      enabled: !_isLoading,
                      decoration: InputDecoration(
                        hintText: 'กรอกอายุ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'น้ำหนัก (กก)',
                      style: theme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: weightController,
                      keyboardType: TextInputType.number,
                      enabled: !_isLoading,
                      decoration: InputDecoration(
                        hintText: 'กรอกน้ำหนัก',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'ส่วนสูง (ซม)',
                      style: theme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: heightController,
                      keyboardType: TextInputType.number,
                      enabled: !_isLoading,
                      decoration: InputDecoration(
                        hintText: 'กรอกส่วนสูง',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'เพศ',
                      style: theme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedGender,
                        isExpanded: true,
                        underline: const SizedBox.shrink(),
                        items: const [
                          DropdownMenuItem(
                            value: 'male',
                            child: Text('ชาย'),
                          ),
                          DropdownMenuItem(
                            value: 'female',
                            child: Text('หญิง'),
                          ),
                          DropdownMenuItem(
                            value: 'other',
                            child: Text('อื่นๆ'),
                          ),
                        ],
                        onChanged: _isLoading
                            ? null
                            : (value) {
                                setState(() {
                                  _selectedGender = value ?? 'male';
                                });
                              },
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'รูปแบบการออกกำลังกาย',
                      style: theme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ..._buildActivityLevelOptions(
                      selectedValue: _selectedActivityLevel,
                      onChanged: _isLoading
                          ? null
                          : (value) {
                              setState(() {
                                _selectedActivityLevel = value;
                              });
                            },
                      theme: theme,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'เป้าหมาย',
                      style: theme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedGoal,
                        isExpanded: true,
                        underline: const SizedBox.shrink(),
                        items: [
                          DropdownMenuItem(
                            value: 'weight_loss',
                            child: Text('ลดน้ำหนัก', style: theme.bodyMedium),
                          ),
                          DropdownMenuItem(
                            value: 'weight_gain',
                            child: Text('เพิ่มน้ำหนัก', style: theme.bodyMedium),
                          ),
                          DropdownMenuItem(
                            value: 'maintain',
                            child: Text('รักษาน้ำหนัก', style: theme.bodyMedium),
                          ),
                          DropdownMenuItem(
                            value: 'muscle_gain',
                            child: Text('เพิ่มกล้ามเนื้อ', style: theme.bodyMedium),
                          ),
                        ],
                        onChanged: _isLoading
                            ? null
                            : (value) {
                                setState(() {
                                  _selectedGoal = value ?? 'maintain';
                                });
                              },
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () async {
                                if (weightController.text.isEmpty ||
                                    heightController.text.isEmpty ||
                                    ageController.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('กรุณากรอกข้อมูลให้ครบถ้วน'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                setState(() {
                                  _isLoading = true;
                                });

                                try {
                                  final age = int.parse(ageController.text);
                                  final weight = double.parse(weightController.text);
                                  final height = double.parse(heightController.text);

                                  // Calculate BMR
                                  final bmr = BMRCalculator.calculate(
                                    gender: _selectedGender,
                                    weight: weight,
                                    height: height,
                                    age: age,
                                  );

                                  // Update profile via API
                                  final result = await _authService.updateProfile(
                                    name: userProfile['name'] ?? 'User',
                                    age: age,
                                    weight: weight,
                                    height: height,
                                    gender: _selectedGender,
                                    bmr: bmr,
                                    activityLevel: _selectedActivityLevel,
                                    goal: _selectedGoal,
                                    dailyCalorieGoal: 2000,
                                  );

                                  if (mounted) {
                                    if (result['success']) {
                                      // Update SessionData
                                      sessionData.updateWeightDouble(weight);
                                      sessionData.updateHeightDouble(height);
                                      sessionData.updateActivityLevel(_selectedActivityLevel);
                                      sessionData.updateGoal(_selectedGoal);
                                      sessionData.updateGender(_selectedGender);
                                      sessionData.updateBMR(bmr);

                                      // Reload user profile
                                      await _loadUserProfile();

                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('บันทึกข้อมูลสำเร็จ'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                        Navigator.pop(context);
                                      }
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(result['message'] ?? 'เกิดข้อผิดพลาด'),
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
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isLoading
                              ? Colors.grey[400]
                              : const Color(0xFFFABB5A),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.grey[600]!,
                                  ),
                                ),
                              )
                            : Text(
                                'บันทึก',
                                style: theme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> _buildActivityLevelOptions({
    required String selectedValue,
    required Function(String)? onChanged,
    required TextTheme theme,
  }) {
    final options = [
      {'value': 'veryActive', 'label': 'ออกกำลังกายทุกวัน'},
      {'value': 'active', 'label': 'ออกกำลังกาย 6-7 ครั้งต่อสัปดาห์'},
      {'value': 'moderate', 'label': 'ออกกำลังกาย 3-5 ครั้งต่อสัปดาห์'},
      {'value': 'light', 'label': 'ออกกำลังกาย 1-2 ครั้งต่อสัปดาห์'},
    ];

    return options.map((option) {
      final value = option['value'] as String;
      final label = option['label'] as String;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GestureDetector(
          onTap: onChanged == null
              ? null
              : () {
                  onChanged(value);
                },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: selectedValue == value
                  ? const Color(0xFFFABB5A).withOpacity(0.1)
                  : Colors.white,
              border: Border.all(
                color: selectedValue == value
                    ? const Color(0xFFFABB5A)
                    : Colors.grey[300]!,
                width: selectedValue == value ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selectedValue == value
                          ? const Color(0xFFFABB5A)
                          : Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: selectedValue == value
                      ? Center(
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFFABB5A),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: theme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  void _showLogoutDialog(BuildContext context, TextTheme theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'ออกจากระบบ',
          style: theme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'คุณต้องการออกจากระบบหรือไม่?',
          style: theme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              // Clear session data
              final sessionData = context.read<SessionData>();
              sessionData.clearData();
              sessionData.userName = null;
              sessionData.profileImagePath = null;
              sessionData.clearAllMeals(); // Clear all meals for all dates
              
              // Navigate to Get Started Screen
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const GetStartedScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('ออกจากระบบ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _editDiseases(BuildContext context, TextTheme theme) {
    if (_userProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ยังไม่สามารถโหลดข้อมูลได้'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final userProfile = _userProfile!['user'] as Map<String, dynamic>?;
    if (userProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ไม่พบข้อมูลผู้ใช้'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _DiseasesEditModal(
          theme: theme,
          userProfile: userProfile,
          authService: _authService,
          onProfileLoaded: _loadUserProfile,
        );
      },
    );
  }
}

// Separate stateful widget for disease editing modal
class _DiseasesEditModal extends StatefulWidget {
  final TextTheme theme;
  final Map<String, dynamic> userProfile;
  final AuthService authService;
  final Future<void> Function() onProfileLoaded;

  const _DiseasesEditModal({
    required this.theme,
    required this.userProfile,
    required this.authService,
    required this.onProfileLoaded,
  });

  @override
  State<_DiseasesEditModal> createState() => _DiseasesEditModalState();
}

class _DiseasesEditModalState extends State<_DiseasesEditModal> {
  late Map<String, bool> diseases;
  late TextEditingController diabetesCarbController;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize state from current profile
    print('=== DEBUG: _DiseasesEditModal initState ===');
    print('Raw diseases from profile: ${widget.userProfile['diseases']}');
    print('Diseases type: ${widget.userProfile['diseases']?.runtimeType}');
    print('Diseases is list: ${widget.userProfile['diseases'] is List}');
    
    final diseasesList = widget.userProfile['diseases'] as List?;
    print('Diseases list: $diseasesList');
    print('Diseases list length: ${diseasesList?.length}');
    print('Contains diabetes: ${diseasesList?.contains('diabetes')}');
    
    diseases = {
      'diabetes': diseasesList?.contains('diabetes') ?? false,
      'hypertension': diseasesList?.contains('hypertension') ?? false,
    };
    
    print('Initialized diseases map: $diseases');
    
    // Convert to double in case database returns int
    dynamic carbValue = widget.userProfile['diabetesCarbLimit'];
    String carbText = '';
    if (carbValue != null) {
      double carbDouble = (carbValue is int) ? carbValue.toDouble() : (carbValue as double? ?? 0.0);
      carbText = carbDouble.toString();
    }
    
    print('Diabetes carb limit: $carbValue, text: $carbText');
    
    diabetesCarbController = TextEditingController(text: carbText);
  }

  @override
  void dispose() {
    diabetesCarbController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'โรคประจำตัว',
              style: widget.theme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // Diabetes Checkbox
            CheckboxListTile(
              value: diseases['diabetes'] ?? false,
              onChanged: isLoading
                  ? null
                  : (value) {
                      setState(() {
                        diseases['diabetes'] = value ?? false;
                      });
                    },
              activeColor: const Color(0xFFFABB5A),
              title: Text(
                'เบาหวาน',
                style: widget.theme.bodyMedium,
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            // Carbs input if diabetes selected
            if (diseases['diabetes'] == true) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ปริมาณคาร์โบไฮเดรตต่อวัน (กรัม)',
                      style: widget.theme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: diabetesCarbController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      enabled: !isLoading,
                      decoration: InputDecoration(
                        hintText: 'เช่น 150 หรือ 150.5',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            // Hypertension Checkbox
            CheckboxListTile(
              value: diseases['hypertension'] ?? false,
              onChanged: isLoading
                  ? null
                  : (value) {
                      setState(() {
                        diseases['hypertension'] = value ?? false;
                      });
                    },
              activeColor: const Color(0xFFFABB5A),
              title: Text(
                'ความดันสูง',
                style: widget.theme.bodyMedium,
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        setState(() {
                          isLoading = true;
                        });

                        try {
                          // Debug: print current state
                          print('=== DEBUG: Saving diseases ===');
                          print('Diabetes checkbox: ${diseases['diabetes']}');
                          print('Hypertension checkbox: ${diseases['hypertension']}');
                          print('Carb input value: ${diabetesCarbController.text}');
                          print('Carb input type: ${diabetesCarbController.text.runtimeType}');

                          // Collect selected diseases
                          List<String> selectedDiseases = [];
                          diseases.forEach((disease, selected) {
                            if (selected) {
                              selectedDiseases.add(disease);
                            }
                          });
                          print('Selected diseases: $selectedDiseases');

                          // Always send the list (empty if no diseases selected)
                          print('Diseases to send: $selectedDiseases (empty array to clear)');

                          // Get diabetes carbs if diabetes is selected
                          double? diabetesCarbLimit;
                          if (diseases['diabetes'] == true &&
                              diabetesCarbController.text.isNotEmpty) {
                            try {
                              diabetesCarbLimit = double.parse(diabetesCarbController.text);
                              print('Parsed carb limit: $diabetesCarbLimit (type: ${diabetesCarbLimit.runtimeType})');
                            } catch (e) {
                              print('ERROR parsing carb limit: $e');
                              diabetesCarbLimit = null;
                            }
                          } else {
                            print('Diabetes not selected or carb field empty - setting carbLimit to null');
                            diabetesCarbLimit = null;
                          }
                          print('Final diabetesCarbLimit: $diabetesCarbLimit (will be null if no diabetes)');
                          print('Sending to API - diseases: $selectedDiseases, carbLimit: $diabetesCarbLimit');

                          // Debug: print current profile data
                          print('Current profile name: ${widget.userProfile['name']}');
                          print('Current profile age: ${widget.userProfile['age']}');

                          // Update profile via API
                          print('Calling updateProfile API...');
                          
                          // Ensure correct types from database
                          int ageValue = (widget.userProfile['age'] is double) 
                            ? (widget.userProfile['age'] as double).toInt() 
                            : (widget.userProfile['age'] ?? 20) as int;
                          
                          double bmrValue = (widget.userProfile['bmr'] is int)
                            ? (widget.userProfile['bmr'] as int).toDouble()
                            : (widget.userProfile['bmr'] ?? 1500.0) as double;
                          
                          int dailyCalorieValue = (widget.userProfile['dailyCalorieNeed'] is double)
                            ? (widget.userProfile['dailyCalorieNeed'] as double).toInt()
                            : (widget.userProfile['dailyCalorieNeed'] ?? 2000) as int;
                          
                          print('Converted age: $ageValue (type: ${ageValue.runtimeType})');
                          print('Converted bmr: $bmrValue (type: ${bmrValue.runtimeType})');
                          print('Converted dailyCalorie: $dailyCalorieValue (type: ${dailyCalorieValue.runtimeType})');
                          
                          final result = await widget.authService.updateProfile(
                            name: widget.userProfile['name'] ?? 'User',
                            age: ageValue,
                            weight: (widget.userProfile['weight'] ?? 70).toDouble(),
                            height: (widget.userProfile['height'] ?? 170).toDouble(),
                            gender: widget.userProfile['gender'] ?? 'male',
                            bmr: bmrValue,
                            activityLevel: widget.userProfile['activityLevel'] ?? 'moderate',
                            goal: widget.userProfile['goal'] ?? 'maintain',
                            dailyCalorieGoal: dailyCalorieValue,
                            diseases: selectedDiseases,
                            diabetesCarbLimit: diabetesCarbLimit,
                          );

                          print('API Response: $result');
                          print('Success: ${result['success']}');
                          print('Message: ${result['message']}');

                          if (mounted) {
                            if (result['success']) {
                              print('Profile updated successfully');
                              // Reload user profile
                              await widget.onProfileLoaded();

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('บันทึกข้อมูลสำเร็จ'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                Navigator.pop(context);
                              }
                            } else {
                              print('Update failed: ${result['message']}');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text(result['message'] ?? 'เกิดข้อผิดพลาด'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          print('EXCEPTION during save: $e');
                          print('Stack trace: ${StackTrace.current}');
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
                              isLoading = false;
                            });
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLoading
                      ? Colors.grey[400]
                      : const Color(0xFFFABB5A),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.grey[600]!,
                          ),
                        ),
                      )
                    : Text(
                        'บันทึก',
                        style: widget.theme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

