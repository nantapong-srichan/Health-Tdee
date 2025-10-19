import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart'; 
import 'tflite_service.dart';
import 'food_database.dart';
import 'results_screen.dart';

class ImagePickerScreen extends StatefulWidget {
  const ImagePickerScreen({super.key});

  @override
  State<ImagePickerScreen> createState() => _ImagePickerScreenState();
}

class _ImagePickerScreenState extends State<ImagePickerScreen> {
  // เก็บรูปที่ครอบแล้ว
  File? _imageFile; 
  final ImagePicker _picker = ImagePicker();
  
  final TFLiteService _tfliteService = TFLiteService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tfliteService.loadModels();
  }

  @override
  void dispose() {
    _tfliteService.dispose();
    super.dispose();
  }


  Future<void> _pickImageFromGallery() async {
    try {
      // เลือกรูปจากคลัง
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      
      if (pickedFile == null) return; // ผู้ใช้กดยกเลิก

      //เรียกเครื่องมือครอบรูป
      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path, // đường dẫn của ảnh vừa chọn
        aspectRatioPresets: [
          CropAspectRatioPreset.square, // บังคับ 1:1
          CropAspectRatioPreset.ratio3x2,
          CropAspectRatioPreset.original,
          CropAspectRatioPreset.ratio4x3,
          CropAspectRatioPreset.ratio16x9
        ],
        uiSettings: [
          AndroidUiSettings(
              toolbarTitle: 'ครอบตัดรูปภาพ',
              toolbarColor: const Color(0xFFFABB5A), // สีส้ม
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square, // เริ่มที่ 1:1
              lockAspectRatio: false), // อนุญาตให้ผู้ใช้เปลี่ยนอัตราส่วนได้
          IOSUiSettings(
            title: 'ครอบตัดรูปภาพ',
            aspectRatioLockEnabled: false,
          ),
        ],
      );

      // เอารูปที่ครอบแล้วมาใช้งาน
      if (croppedFile != null) {
        setState(() {
          _imageFile = File(croppedFile.path); // <-- บันทึกเป็น File
        });
      }

    } catch (e) {
      print("Error picking/cropping image: $e");
    }
  }

  // ฟังก์ชัน Submit
  void _submitImage() async {
    if (_imageFile == null) return;

    setState(() => _isLoading = true);

    // แปลง File -> XFile ชั่วคราวเพื่อให้ service ทำงานได้
    final xFileImage = XFile(_imageFile!.path);

    // รันโมเดล
    String? foodName = await _tfliteService.runFoodRecognition(xFileImage);
    double? estimatedWeight = await _tfliteService.runWeightEstimation(xFileImage);

    if (foodName == null || estimatedWeight == null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่สามารถประมวลผลรูปภาพได้')),
      );
      return;
    }

    // ค้นหาฐานข้อมูล 
    NutrientInfo? baseNutrients = foodDatabase[foodName];

    if (baseNutrients == null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ไม่พบข้อมูลโภชนาการสำหรับ: $foodName')),
      );
      return;
    }

    // --- 3. คำนวณ (เหมือนเดิม) ---
    double weightRatio = estimatedWeight / 100.0;
    CalculationResult result = CalculationResult(
      imagePath: _imageFile!.path, // ส่ง path ของรูปที่ "ครอบแล้ว"
      foodName: foodName,
      estimatedWeight: estimatedWeight,
      totalCalories: baseNutrients.calories * weightRatio,
      totalProtein: baseNutrients.protein * weightRatio,
      totalFat: baseNutrients.fat * weightRatio,
      totalCarbs: baseNutrients.carbs * weightRatio,
    );

    setState(() => _isLoading = false);

    // --- 4. ส่งไปหน้าผลลัพธ์ (เหมือนเดิม) ---
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultsScreen(result: result),
        ),
      );
    }
  }

  void _clearImage() {
    setState(() {
      _imageFile = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // --- 1. แถบ "กลับ" ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              color: const Color(0xFFFDEFE0),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    child: Text("กลับ", style: GoogleFonts.kanit(fontSize: 17)),
                  ),
                ],
              ),
            ),

            // --- 2. พื้นที่แสดงผล ---
            Expanded(
              child: Container(
                width: double.infinity,
                color: Colors.white,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: AspectRatio(
                      aspectRatio: 1 / 1,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: _buildImagePreview(), // (แก้ไขแล้ว)
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // --- 3. แถบควบคุมด้านล่าง ---
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 36.0),
                child: CircularProgressIndicator(color: Color(0xFFFABB5A)),
              )
            else
              _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  // --- (แก้ไข) Widget แสดงผล ---
  Widget _buildImagePreview() {
    if (_imageFile == null) {
      return Container(
        color: Colors.grey[200],
        width: double.infinity,
        height: double.infinity,
        child: Icon(Icons.photo_library_outlined, size: 100, color: Colors.grey[400]),
      );
    } else {
      // (แก้ไข) แสดงผลจาก File แทน XFile
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            _imageFile!, // <-- (แก้ไข)
            fit: BoxFit.cover,
          ),
          Positioned(
            top: 10,
            right: 10,
            child: GestureDetector(
              onTap: _clearImage,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.white, size: 24),
              ),
            ),
          )
        ],
      );
    }
  }

  // (เหมือนเดิม)
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.photo_library_outlined, size: 32, color: Colors.black87),
            onPressed: _pickImageFromGallery,
          ),
          _imageFile != null
              ? IconButton(
                  icon: const Icon(Icons.arrow_forward, size: 32, color: Colors.black87),
                  onPressed: _submitImage,
                )
              : const SizedBox(width: 48),
        ],
      ),
    );
  }
}