import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'home_screen.dart'; 
import 'session_data.dart';

class InformationFormScreen extends StatefulWidget {
  const InformationFormScreen({super.key});

  @override
  State<InformationFormScreen> createState() => _InformationFormScreenState();
}

class _InformationFormScreenState extends State<InformationFormScreen> {
  // Controllers 
  late TextEditingController _dobController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;

  // รายการตัวเลือก 
  final List<String> exerciseStyles = [
    'ออกกำลังกายทุกวัน', 'ออกกำลังกาย 6-7 ครั้งต่อสัปดาห์', 'ออกกำลังกาย 3-5 ครั้งต่อสัปดาห์',
    'ออกกำลังกาย 1-2 ครั้งต่อสัปดาห์', 'ออกกำลังกายเป็นครั้งคราว'
  ];
  final List<String> goals = [
    'รักษาน้ำหนักเท่าเดิม', 'ต้องการเพิ่มน้ำหนัก', 'ต้องการลดน้ำหนัก', 'ต้องการเพิ่มกล้ามเนื้อ'
  ];
  final List<String> healthInfo = ['เบาหวาน', 'ความดันโลหิต'];

  @override
  void initState() {
    super.initState();
    final sessionData = Provider.of<SessionData>(context, listen: false);
    
    _dobController = TextEditingController(text: sessionData.dateOfBirth);
    _heightController = TextEditingController(text: sessionData.height);
    _weightController = TextEditingController(text: sessionData.weight);
  }

  @override
  void dispose() {
    _dobController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionData = Provider.of<SessionData>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xFFFDEFE0),
      body: Column(
        children: [
          Image.asset('assets/form_banner.png', fit: BoxFit.cover, width: double.infinity),
          Expanded(
            child: Container(
              transform: Matrix4.translationValues(0, -30, 0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  // --- ส่วนหัว (Header) ---
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          child: Text(
                            "กลับ", 
                            style: GoogleFonts.kanit(fontSize: 17),
                          ), 
                        ),
                      ],
                    ),
                  ),

                  // ส่วนฟอร์มที่เลื่อนได้
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          
                          // ข้อมูลส่วนตัว
                          _buildSectionTitle('ข้อมูลส่วนตัว'),
                          _buildTextFieldInput(
                            controller: _dobController,
                            hintText: 'dd/mm/yyyy (เช่น 05/07/2003)',
                            keyboardType: TextInputType.datetime,
                          ),

                          // ข้อมูลร่างกาย (เพศ/สูง/หนัก) 
                          _buildSectionTitle('ข้อมูลร่างกาย'),
                          _buildGenderButtons(),
                          _buildTextFieldInput(
                            controller: _heightController,
                            hintText: 'ส่วนสูง (ซม.)',
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          ),
                          _buildTextFieldInput(
                            controller: _weightController,
                            hintText: 'น้ำหนัก (กก.)',
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          ),

                          // ส่วนการออกกำลังกาย 
                          _buildSectionTitle('รูปแบบการออกกำลังกาย'),
                          _buildChoiceList(
                            options: exerciseStyles,
                            onSelected: (value) => sessionData.updateExerciseStyle(value),
                            isSelectedCheck: (option) => sessionData.exerciseStyle == option,
                          ),

                          // ส่วนเป้าหมาย 
                          _buildSectionTitle('เป้าหมายของคุณ'),
                          _buildChoiceList(
                            options: goals,
                            onSelected: (value) => sessionData.updateGoal(value),
                            isSelectedCheck: (option) => sessionData.goal == option,
                          ),

                          // ส่วนข้อมูลสุขภาพ อันนี้เลือกก็ได้ ไม่เลือกก็ได้
                          _buildSectionTitle('ข้อมูลสุขภาพ (ถ้ามี)'),
                          _buildChoiceList(
                            options: healthInfo,
                            onSelected: (value) => sessionData.updateHealthInfo(value),
                            isSelectedCheck: (option) => sessionData.healthInfo == option,
                          ),

                          // ปุ่มบันทึกข้อมูล 
                          const SizedBox(height: 20),
                          _buildNextButton('บันทึกข้อมูล', 
                            onPressed: () {
                              
                              // validation 
                              
                              final dob = _dobController.text;
                              final height = _heightController.text;
                              final weight = _weightController.text;
                              
                              final gender = sessionData.gender;
                              final exercise = sessionData.exerciseStyle;
                              final goal = sessionData.goal;
                              // final health = sessionData.healthInfo; // ไม่ต้องดึงมาเช็คแล้ว

                              // (ลบ || health == null ออกจากเงื่อนไข)
                              if (dob.isEmpty || height.isEmpty || weight.isEmpty ||
                                  gender == null || exercise == null || goal == null) {
                                  
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        // ข้อความแจ้งเตือน
                                        'กรุณากรอกข้อมูลให้ครบ (ยกเว้นข้อมูลสุขภาพ)',
                                        style: GoogleFonts.kanit(fontSize: 16),
                                      ),
                                      backgroundColor: Colors.redAccent,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                  return;
                              }
                              
                              // ตรวจสอบรูปแบบวันเกิด dd/mm/yyyy
                              if (!RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(dob)) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'วันเกิดต้องเป็นรูปแบบ dd/mm/yyyy เท่านั้น',
                                        style: GoogleFonts.kanit(fontSize: 16),
                                      ),
                                      backgroundColor: Colors.redAccent,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                  return;
                              }
                              
                              // ข้อมูลครบถ้วน (ให้ผ่าน)
                              sessionData.updateDateOfBirth(dob);
                              sessionData.updateHeight(height);
                              sessionData.updateWeight(weight);
                              
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (context) => const HomeScreen()),
                                (Route<dynamic> route) => false,
                              );
                            }
                          ),
                          const SizedBox(height: 30),

                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper Widget สำหรับหัวข้อ 
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0, bottom: 16.0),
      child: Text(
        title, 
        style: GoogleFonts.kanit(fontSize: 24, fontWeight: FontWeight.bold)
      ),
    );
  }

  // Helper Widget สำหรับปุ่มเลือกเพศ 
  Widget _buildGenderButtons() {
    return Consumer<SessionData>(
      builder: (context, sessionData, child) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            children: [
              Expanded(
                child: _buildChoiceChip(
                  text: 'ชาย',
                  isSelected: sessionData.gender == 'ชาย',
                  onTap: () {
                    String? newValue = (sessionData.gender == 'ชาย') ? null : 'ชาย';
                    sessionData.updateGender(newValue);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildChoiceChip(
                  text: 'หญิง',
                  isSelected: sessionData.gender == 'หญิง',
                  onTap: () {
                    String? newValue = (sessionData.gender == 'หญิง') ? null : 'หญิง';
                    sessionData.updateGender(newValue);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper Widget สำหรับสร้าง "กลุ่ม" ของปุ่มตัวเลือก 
  Widget _buildChoiceList({
    required List<String> options, 
    required ValueChanged<String?> onSelected,
    required bool Function(String) isSelectedCheck
  }) {
    return Consumer<SessionData>(
      builder: (context, sessionData, child) {
        return Column(
          children: options.map((option) {
            final isSelected = isSelectedCheck(option);
            return _buildChoiceChip(
              text: option,
              isSelected: isSelected,
              onTap: () {
                String? newValue = isSelected ? null : option;
                onSelected(newValue);
              }, 
            );
          }).toList(),
        );
      },
    );
  }

  // Helper Widget สร้างช่อง TextField 
  Widget _buildTextFieldInput({
    required TextEditingController controller,
    required String hintText,
    required TextInputType keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0), 
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: GoogleFonts.kanit(fontSize: 17, color: Colors.black87),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.kanit(fontSize: 17, color: Colors.grey[500]),
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  // Helper Widget สร้างปุ่ม "บันทึก" 
  Widget _buildNextButton(String text, {required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFABB5A),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          text, 
          style: GoogleFonts.kanit(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.white)
        ),
      ),
    );
  }
  
  // Helper Widget สร้างปุ่มตัวเลือก 
  Widget _buildChoiceChip({required String text, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFABB5A) : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.kanit(
              fontSize: 17,
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}