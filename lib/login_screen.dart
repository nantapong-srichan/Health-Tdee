import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'session_data.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // Validate inputs
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'กรุณากรอกอีเมลและรหัสผ่าน';
      });
      return;
    }

    if (!_emailController.text.contains('@')) {
      setState(() {
        _errorMessage = 'กรุณากรอกอีเมลที่ถูกต้อง';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (result['success']) {
        if (mounted) {
          // Clear old session data before updating with new user data
          final sessionData = Provider.of<SessionData>(context, listen: false);
          sessionData.clearData();
          
          // Update SessionData with user health metrics from login response
          final userProfile = result['user'] as Map<String, dynamic>?;
          if (userProfile != null) {
            if (userProfile['name'] != null) {
              sessionData.updateUserName(userProfile['name'] as String);
            }
            if (userProfile['profileImageUrl'] != null) {
              sessionData.updateProfileImageUrl(userProfile['profileImageUrl'] as String);
            }
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
          
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'เกิดข้อผิดพลาด';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'เกิดข้อผิดพลาด: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDEFE0),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              SizedBox(height: MediaQuery.of(context).size.height * 0.05),
              Center(
                child: Text(
                  'เข้าสู่ระบบ',
                  style: GoogleFonts.kanit(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFABB5A),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'ยินดีต้อนรับกลับ',
                  style: GoogleFonts.kanit(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              const SizedBox(height: 48),

              // Error Message
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: GoogleFonts.kanit(
                      color: Colors.red.shade800,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Email Field
              Text(
                'อีเมล',
                style: GoogleFonts.kanit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  hintText: 'กรอกอีเมลของคุณ',
                  hintStyle: GoogleFonts.kanit(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFFFABB5A),
                      width: 2,
                    ),
                  ),
                  prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFFFABB5A)),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                style: GoogleFonts.kanit(),
              ),
              const SizedBox(height: 24),

              // Password Field
              Text(
                'รหัสผ่าน',
                style: GoogleFonts.kanit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  hintText: 'กรอกรหัสผ่านของคุณ',
                  hintStyle: GoogleFonts.kanit(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFFFABB5A),
                      width: 2,
                    ),
                  ),
                  prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFFFABB5A)),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: const Color(0xFFFABB5A),
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                style: GoogleFonts.kanit(),
              ),
              const SizedBox(height: 32),

              // Login Button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFABB5A),
                  disabledBackgroundColor: Colors.grey[300],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.grey[700]!,
                          ),
                        ),
                      )
                    : Text(
                        'เข้าสู่ระบบ',
                        style: GoogleFonts.kanit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
              const SizedBox(height: 20),

              // Sign Up Link
              Center(
                child: RichText(
                  text: TextSpan(
                    text: 'ยังไม่มีบัญชี? ',
                    style: GoogleFonts.kanit(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    children: [
                      TextSpan(
                        text: 'สมัครสมาชิก',
                        style: GoogleFonts.kanit(
                          fontSize: 14,
                          color: const Color(0xFFFABB5A),
                          fontWeight: FontWeight.bold,
                        ),
                        recognizer: _isLoading
                            ? null
                            : (TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (context) => const RegisterScreen(),
                                  ),
                                );
                              }),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
