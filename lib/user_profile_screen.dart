import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/auth_service.dart';
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
    final ageController = TextEditingController(
      text: _userProfile?['age']?.toString() ?? '',
    );
    final weightController = TextEditingController(
      text: _userProfile?['weight']?.toString() ?? '',
    );
    final heightController = TextEditingController(
      text: _userProfile?['height']?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'อัพเดตข้อมูลสุขภาพ',
          style: GoogleFonts.kanit(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ageController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'อายุ',
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
          ],
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
                final result = await _authService.updateProfile(
                  age: int.parse(ageController.text),
                  weight: double.parse(weightController.text),
                  height: double.parse(heightController.text),
                );

                if (mounted) {
                  Navigator.pop(context);
                  if (result['success']) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('อัพเดตข้อมูลสำเร็จ'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    _loadUserProfile();
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
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
