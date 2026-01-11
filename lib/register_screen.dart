import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'session_data.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _dobController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _authService = AuthService();
  
  XFile? _selectedImage;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;
  bool _agreedToTerms = false;
  String? _selectedGender; // ชาย / หญิง
  String _selectedExerciseFrequency = 'daily'; // ความถี่การออกกำลังกาย
  String _selectedGoal = 'weight_loss'; // เป้าหมายการใช้แอป
  
  // Disease checkboxes
  Map<String, bool> _diseases = {
    'diabetes': false,
    'hypertension': false,
  };

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _dobController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  Future<void> _handleRegister() async {
    // Validate inputs
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty ||
        _dobController.text.isEmpty ||
        _ageController.text.isEmpty ||
        _selectedGender == null ||
        _weightController.text.isEmpty ||
        _heightController.text.isEmpty) {
      setState(() {
        _errorMessage = 'กรุณากรอกข้อมูลให้ครบถ้วน';
      });
      return;
    }

    if (!_emailController.text.contains('@')) {
      setState(() {
        _errorMessage = 'กรุณากรอกอีเมลที่ถูกต้อง';
      });
      return;
    }

    if (_passwordController.text.length < 6) {
      setState(() {
        _errorMessage = 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
      });
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'รหัสผ่านไม่ตรงกัน';
      });
      return;
    }

    if (!_agreedToTerms) {
      setState(() {
        _errorMessage = 'กรุณายอมรับข้อตกลง';
      });
      return;
    }

    // Validate date format dd/mm/yyyy
    if (!RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(_dobController.text)) {
      setState(() {
        _errorMessage = 'วันเกิดต้องเป็นรูปแบบ dd/mm/yyyy เท่านั้น';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final weight = double.parse(_weightController.text);
      final height = double.parse(_heightController.text);
      
      // Collect selected diseases
      List<String> selectedDiseases = [];
      _diseases.forEach((disease, selected) {
        if (selected) {
          selectedDiseases.add(disease);
        }
      });
      
      final result = await _authService.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        dateOfBirth: _dobController.text,
        weight: weight,
        height: height,
        activityLevel: _selectedExerciseFrequency,
        gender: _selectedGender,
        goal: _selectedGoal,
        dailyCalorieGoal: 2000,
      );

      if (result['success']) {
        // Auto login after signup
        final loginResult = await _authService.login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (loginResult['success'] && mounted) {
          // Update SessionData with user information
          final sessionData = Provider.of<SessionData>(context, listen: false);
          sessionData.updateUserName(_nameController.text.trim());
          sessionData.updateDateOfBirth(_dobController.text);
          sessionData.updateHeight(_heightController.text);
          sessionData.updateWeight(_weightController.text);
          sessionData.updateGoal(_selectedGoal);
          sessionData.updateGender(_selectedGender);
          sessionData.updateExerciseStyle(_selectedExerciseFrequency);
          if (_selectedImage != null) {
            sessionData.updateProfileImagePath(_selectedImage!.path);
          }
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'ลงทะเบียนสำเร็จ! ข้อมูลของคุณได้ถูกบันทึกลงฐานข้อมูล',
                style: GoogleFonts.kanit(),
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );

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
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDEFE0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'ลงทะเบียน',
          style: GoogleFonts.kanit(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFFABB5A),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile Image Section
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFFABB5A),
                          width: 3,
                        ),
                      ),
                      child: _selectedImage != null
                          ? ClipOval(
                              child: Image.file(
                                File(_selectedImage!.path),
                                fit: BoxFit.cover,
                              ),
                            )
                          : Icon(
                              Icons.person,
                              size: 70,
                              color: Colors.grey[300],
                            ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _isLoading ? null : _pickImage,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFFFABB5A),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(8),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'เพิ่มรูปโปรไฟล์',
                  style: GoogleFonts.kanit(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              const SizedBox(height: 24),

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

              // Name Field
              _buildLabel('ชื่อสมาชิก'),
              _buildTextField(
                controller: _nameController,
                hintText: 'กรอกชื่อของคุณ',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),

              // Email Field
              _buildLabel('อีเมล'),
              _buildTextField(
                controller: _emailController,
                hintText: 'กรอกอีเมลของคุณ',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // Password Field
              _buildLabel('รหัสผ่าน'),
              _buildPasswordField(
                controller: _passwordController,
                hintText: 'กรอกรหัสผ่าน (อย่างน้อย 6 ตัว)',
                obscure: _obscurePassword,
                onToggle: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Confirm Password Field
              _buildLabel('ยืนยันรหัสผ่าน'),
              _buildPasswordField(
                controller: _confirmPasswordController,
                hintText: 'ยืนยันรหัสผ่านของคุณ',
                obscure: _obscureConfirmPassword,
                onToggle: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Date of Birth Field
              _buildLabel('วันเกิด'),
              _buildTextField(
                controller: _dobController,
                hintText: 'dd/mm/yyyy (เช่น 05/07/2003)',
                keyboardType: TextInputType.datetime,
                icon: Icons.calendar_today_outlined,
              ),
              const SizedBox(height: 16),

              // Age Field
              _buildLabel('อายุ'),
              _buildTextField(
                controller: _ageController,
                hintText: 'อายุ (เช่น 21)',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),

              // Body Information Section
              Text(
                'ข้อมูลร่างกาย',
                style: GoogleFonts.kanit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              // Gender Selection
              _buildLabel('เพศ'),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _isLoading
                          ? null
                          : () {
                              setState(() {
                                _selectedGender = 'male';
                              });
                            },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _selectedGender == 'male'
                              ? const Color(0xFFFABB5A)
                              : Colors.white,
                          border: Border.all(
                            color: _selectedGender == 'male'
                                ? const Color(0xFFFABB5A)
                                : Colors.grey[300]!,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'ชาย',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.kanit(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: _selectedGender == 'male'
                                ? Colors.white
                                : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: _isLoading
                          ? null
                          : () {
                              setState(() {
                                _selectedGender = 'female';
                              });
                            },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _selectedGender == 'female'
                              ? const Color(0xFFFABB5A)
                              : Colors.white,
                          border: Border.all(
                            color: _selectedGender == 'female'
                                ? const Color(0xFFFABB5A)
                                : Colors.grey[300]!,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'หญิง',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.kanit(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: _selectedGender == 'female'
                                ? Colors.white
                                : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Height and Weight Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('ส่วนสูง (ซม)'),
                        _buildTextField(
                          controller: _heightController,
                          hintText: 'ความสูง',
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('น้ำหนัก (กก)'),
                        _buildTextField(
                          controller: _weightController,
                          hintText: 'น้ำหนัก',
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Exercise Frequency Section
              Text(
                'รูปแบบการออกกำลังกาย',
                style: GoogleFonts.kanit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              ..._buildExerciseFrequencyOptions(),
              const SizedBox(height: 24),

              // Goal Section
              _buildLabel('เป้าหมายการใช้แอป'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButton<String>(
                  value: _selectedGoal,
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  items: [
                    DropdownMenuItem(
                      value: 'weight_loss',
                      child: Text('ลดน้ำหนัก', style: GoogleFonts.kanit()),
                    ),
                    DropdownMenuItem(
                      value: 'weight_gain',
                      child: Text('เพิ่มน้ำหนัก', style: GoogleFonts.kanit()),
                    ),
                    DropdownMenuItem(
                      value: 'maintain',
                      child: Text('รักษาน้ำหนัก', style: GoogleFonts.kanit()),
                    ),
                    DropdownMenuItem(
                      value: 'muscle_gain',
                      child: Text('เพิ่มกล้ามเนื้อ', style: GoogleFonts.kanit()),
                    ),
                  ],
                  onChanged: _isLoading
                      ? null
                      : (value) {
                          setState(() {
                            _selectedGoal = value ?? 'weight_loss';
                          });
                        },
                ),
              ),
              const SizedBox(height: 20),

              // Disease Section (Optional)
              Text(
                'โรคประจำตัว (เลือกได้)',
                style: GoogleFonts.kanit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              ..._buildDiseaseCheckboxes(),
              const SizedBox(height: 24),

              // Terms Checkbox
              Row(
                children: [
                  Checkbox(
                    value: _agreedToTerms,
                    onChanged: _isLoading
                        ? null
                        : (value) {
                            setState(() {
                              _agreedToTerms = value ?? false;
                            });
                          },
                    activeColor: const Color(0xFFFABB5A),
                  ),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        text: 'ฉันยอมรับ ',
                        style: GoogleFonts.kanit(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                        children: [
                          TextSpan(
                            text: 'ข้อตกลงการใช้งาน',
                            style: GoogleFonts.kanit(
                              fontSize: 13,
                              color: const Color(0xFFFABB5A),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Register Button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleRegister,
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
                        'ลงทะเบียน',
                        style: GoogleFonts.kanit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
              const SizedBox(height: 16),

              // Login Link
              Center(
                child: RichText(
                  text: TextSpan(
                    text: 'มีบัญชีอยู่แล้ว? ',
                    style: GoogleFonts.kanit(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    children: [
                      TextSpan(
                        text: 'เข้าสู่ระบบ',
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
                                    builder: (context) => const LoginScreen(),
                                  ),
                                );
                              }),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.kanit(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      enabled: !_isLoading,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.kanit(color: Colors.grey[400]),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFFFABB5A),
            width: 2,
          ),
        ),
        prefixIcon:
            icon != null ? Icon(icon, color: const Color(0xFFFABB5A)) : null,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
      style: GoogleFonts.kanit(),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      enabled: !_isLoading,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.kanit(color: Colors.grey[400]),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFFFABB5A),
            width: 2,
          ),
        ),
        prefixIcon:
            const Icon(Icons.lock_outline, color: Color(0xFFFABB5A)),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: const Color(0xFFFABB5A),
          ),
          onPressed: onToggle,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
      style: GoogleFonts.kanit(),
    );
  }

  List<Widget> _buildDiseaseCheckboxes() {
    return [
      _buildDiseaseCheckbox('diabetes', 'เบาหวาน'),
      _buildDiseaseCheckbox('hypertension', 'ความดันสูง'),
    ];
  }

  Widget _buildDiseaseCheckbox(String key, String label) {
    return CheckboxListTile(
      value: _diseases[key] ?? false,
      onChanged: _isLoading
          ? null
          : (value) {
              setState(() {
                _diseases[key] = value ?? false;
              });
            },
      activeColor: const Color(0xFFFABB5A),
      title: Text(
        label,
        style: GoogleFonts.kanit(fontSize: 14),
      ),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
    );
  }

  List<Widget> _buildExerciseFrequencyOptions() {
    final options = [
      {'value': 'daily', 'label': 'ออกกำลังกายทุกวัน'},
      {'value': '6-7', 'label': 'ออกกำลังกาย 6-7 ครั้งต่อสัปดาห์'},
      {'value': '3-5', 'label': 'ออกกำลังกาย 3-5 ครั้งต่อสัปดาห์'},
      {'value': '1-2', 'label': 'ออกกำลังกาย 1-2 ครั้งต่อสัปดาห์'},
    ];

    return options.map((option) {
      final value = option['value'] as String;
      final label = option['label'] as String;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GestureDetector(
          onTap: _isLoading
              ? null
              : () {
                  setState(() {
                    _selectedExerciseFrequency = value;
                  });
                },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: _selectedExerciseFrequency == value
                  ? const Color(0xFFFABB5A).withOpacity(0.1)
                  : Colors.white,
              border: Border.all(
                color: _selectedExerciseFrequency == value
                    ? const Color(0xFFFABB5A)
                    : Colors.grey[300]!,
                width: _selectedExerciseFrequency == value ? 2 : 1,
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
                      color: _selectedExerciseFrequency == value
                          ? const Color(0xFFFABB5A)
                          : Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: _selectedExerciseFrequency == value
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
                    style: GoogleFonts.kanit(
                      fontSize: 15,
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
}
