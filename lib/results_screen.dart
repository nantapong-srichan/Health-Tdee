// lib/results_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// (โมเดลข้อมูลสำหรับส่งค่ามาหน้านี้)
class CalculationResult {
  final String imagePath;
  final String foodName;
  final double estimatedWeight;
  final double totalCalories;
  final double totalProtein;
  final double totalFat;
  final double totalCarbs;

  CalculationResult({
    required this.imagePath,
    required this.foodName,
    required this.estimatedWeight,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalFat,
    required this.totalCarbs,
  });
}

class ResultsScreen extends StatelessWidget {
  final CalculationResult result;
  
  const ResultsScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDEFE0), // สีครีมพื้นหลัง
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDEFE0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. รูปภาพ
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                File(result.imagePath),
                height: 300,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 24),
            
            // 2. ชื่ออาหาร
            Text(
              result.foodName,
              textAlign: TextAlign.center,
              style: GoogleFonts.kanit(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'ประมาณ ${result.estimatedWeight.toStringAsFixed(0)} กรัม',
              textAlign: TextAlign.center,
              style: GoogleFonts.kanit(
                fontSize: 18,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 24),

            // 3. การ์ดแคลอรี่
            _buildCaloriesCard(result.totalCalories),
            
            const SizedBox(height: 24),

            // 4. สารอาหาร
            Text(
              'สารอาหาร',
              style: GoogleFonts.kanit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildNutrientRow('โปรตีน', result.totalProtein, Colors.green),
            _buildNutrientRow('ไขมัน', result.totalFat, Colors.orange),
            _buildNutrientRow('คาร์โบไฮเดรต', result.totalCarbs, Colors.blue),
            
            const SizedBox(height: 40),

            // 5. ปุ่มยืนยัน
            ElevatedButton(
              onPressed: () {
                // TODO: บันทึกข้อมูลนี้ลงใน Daily Log
                Navigator.of(context).pop(); // กลับไปหน้า Home
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFABB5A),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'ยืนยัน',
                style: GoogleFonts.kanit(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Widget สำหรับการ์ดแคลอรี่
  Widget _buildCaloriesCard(double calories) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'แคลอรี่ทั้งหมด',
            style: GoogleFonts.kanit(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            calories.toStringAsFixed(0),
            style: GoogleFonts.kanit(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFABB5A),
            ),
          ),
          Text(
            'KCal',
            style: GoogleFonts.kanit(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  // Helper Widget สำหรับแถบสารอาหาร
  Widget _buildNutrientRow(String name, double amount, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Text(
                name,
                style: GoogleFonts.kanit(fontSize: 18),
              ),
            ],
          ),
          Text(
            '${amount.toStringAsFixed(1)} กรัม',
            style: GoogleFonts.kanit(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}