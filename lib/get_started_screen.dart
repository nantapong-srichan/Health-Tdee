import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'register_screen.dart';
import 'login_screen.dart';

class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDEFE0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              Text(
                "เริ่มต้นกับเรา",
                textAlign: TextAlign.center,
                style: GoogleFonts.kanit(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFABB5A),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "ติดตามสุขภาพและสารอาหารของคุณ",
                textAlign: TextAlign.center,
                style: GoogleFonts.kanit(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 40),
              Icon(
                Icons.restaurant_menu_rounded,
                size: 120,
                color: const Color(0xFFFABB5A).withOpacity(0.3),
              ),
              const Spacer(flex: 2),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegisterScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFABB5A),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'สมัครสมาชิก',
                  style: GoogleFonts.kanit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: GoogleFonts.kanit(fontSize: 14, color: Colors.grey[600]),
                  children: [
                    const TextSpan(text: 'มีบัญชีอยู่แล้ว? '),
                    TextSpan(
                      text: 'เข้าสู่ระบบ',
                      style: GoogleFonts.kanit(
                        color: const Color(0xFFFABB5A),
                        fontWeight: FontWeight.bold,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                          );
                        },
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}