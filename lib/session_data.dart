import 'package:flutter/material.dart';

class SessionData with ChangeNotifier {
  
  //ข้อมูลจากช่องกรอกข้อความ
  String? dateOfBirth;
  String? age;
  String? gender; // < รับค่า null ได้
  String? height;
  String? weight;
  
  // ข้อมูลจากปุ่มเลือก
  String? exerciseStyle; // < รับค่า null ได้
  String? goal; // < รับค่า null ได้
  String? healthInfo; // < รับค่า null ได้

  // ฟังก์ชันอัปเดตข้อมูล Text
  void updateDateOfBirth(String dob) {
    dateOfBirth = dob;
    notifyListeners();
  }
  
  void updateAge(String newAge) {
    age = newAge;
    notifyListeners();
  }

  void updateHeight(String newHeight) {
    height = newHeight;
    notifyListeners();
  }
  
  void updateWeight(String newWeight) {
    weight = newWeight;
    notifyListeners();
  }

  //  ฟังก์ชันอัปเดต (ปุ่มเลือก) ให้รับค่า null ได้ ---

  void updateGender(String? newGender) { // < เปลี่ยนเป็น String?
    gender = newGender;
    notifyListeners();
  }

  void updateExerciseStyle(String? style) { // < เปลี่ยนเป็น String?
    exerciseStyle = style;
    notifyListeners();
  }

  void updateGoal(String? newGoal) { // < เปลี่ยนเป็น String?
    goal = newGoal;
    notifyListeners();
  }

  void updateHealthInfo(String? info) { // < เปลี่ยนเป็น String?
    healthInfo = info;
    notifyListeners();
  }

  // ฟังก์ชันสำหรับเคลียร์ข้อมูล
  void clearData() {
    dateOfBirth = null;
    age = null;
    gender = null;
    height = null;
    weight = null;
    exerciseStyle = null;
    goal = null;
    healthInfo = null;
    notifyListeners();
  }
}