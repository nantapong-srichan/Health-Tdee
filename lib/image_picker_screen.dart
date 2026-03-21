import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
// import 'package:image/image.dart' as img; // (ไม่จำเป็นต้องใช้แล้ว)
import 'tflite_service.dart';
import 'results_screen.dart';
import 'recognition_result.dart';

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

  // สถานะสิทธิ์ Camera
  PermissionStatus? _cameraPermissionStatus;
  bool _hasCameraPermission = false;

  @override
  void initState() {
    super.initState();
    print('🚀 [ImagePickerScreen] initState called');
    print('🔄 Calling _tfliteService.loadModels()...');
    _tfliteService.loadModels();
    print('✅ loadModels() call completed (async)');
    
    // ขอสิทธิ์ Camera
    _requestCameraPermission();
  }

  @override
  void dispose() {
    _tfliteService.dispose();
    super.dispose();
  }

  /// ███████████ 🎥 CAMERA PERMISSIONS ███████████
  Future<void> _requestCameraPermission() async {
    try {
      final status = await Permission.camera.request();
      setState(() {
        _cameraPermissionStatus = status;
        _hasCameraPermission = status.isGranted;
      });

      if (status.isDenied) {
        print('📸 Camera permission denied');
      } else if (status.isPermanentlyDenied) {
        print('📸 Camera permission permanently denied - opening app settings');
        // เปิดหน้า settings ให้ผู้ใช้อนุญาต
        openAppSettings();
      } else if (status.isGranted) {
        print('✅ Camera permission granted!');
      }
    } catch (e) {
      print('❌ Error requesting camera permission: $e');
    }
  }

  /// ถ่ายรูปด้วย Camera โดยตรง
  Future<void> _pickImageFromCamera() async {
    if (!_hasCameraPermission) {
      print('📸 Camera permission not granted');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ต้องอนุญาตการเข้าถึง Camera ก่อน')),
      );
      await _requestCameraPermission();
      return;
    }

    try {
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.camera);

      if (pickedFile == null) return; // ผู้ใช้ยกเลิก

      setState(() {
        _imageFile = File(pickedFile.path);
      });
    } catch (e) {
      print("Error picking image from camera: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการถ่ายรูป: $e')),
      );
    }
  }
  /// ███████████████████████████████████████████



  Future<void> _pickImageFromGallery() async {
    try {
      // เลือกรูปจากคลัง
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      
      if (pickedFile == null) return; // ผู้ใช้กดยกเลิก

      // --- (แก้ไข) ---
      // ลบโค้ดส่วนที่ปรับขนาดภาพ 224x224 ออกทั้งหมด
      // และใช้ไฟล์ต้นฉบับที่เลือกมาเลย
      setState(() {
        _imageFile = File(pickedFile.path); // บันทึกไฟล์ต้นฉบับ
      });

    } catch (e) {
      print("Error picking image: $e"); // (แก้ไขข้อความ)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการเลือกรูปภาพ: $e')),
      );
    }
  }

  // ฟังก์ชัน Submit
  void _submitImage() async {
    if (_imageFile == null) return;

    setState(() => _isLoading = true);

    // แปลง File -> XFile ชั่วคราวเพื่อให้ service ทำงานได้
    // (หมายเหตุ: TFLiteService ของเราจะอ่าน _imageFile.path โดยตรง)
    final xFileImage = XFile(_imageFile!.path);

    // รันโมเดล
    RecognitionResult? result = await _tfliteService.runFoodRecognition(xFileImage);

    if (result == null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่สามารถประมวลผลรูปภาพได้')),
      );
      return;
    }

    setState(() => _isLoading = false);

    // --- 4. ส่งไปหน้าผลลัพธ์ ---
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultsScreen(
            imageFile: xFileImage,
            result: result,
          ),
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
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 224, maxHeight: 224), // (ยังคงแสดงผลขนาด 224 เพื่อความสวยงาม)
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: _buildImagePreview(),
                        ),
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
      // (เหมือนเดิม) แสดงผลจาก File
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            _imageFile!,
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
          // ปุ่มเลือกรูปจากคลัง
          IconButton(
            icon: const Icon(Icons.photo_library_outlined, size: 32, color: Colors.black87),
            onPressed: _pickImageFromGallery,
            tooltip: 'เลือกจากคลัง',
          ),
          
          // ปุ่มถ่ายรูปด้วย Camera (ใหม่)
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined, size: 32, color: Colors.black87),
            onPressed: _hasCameraPermission ? _pickImageFromCamera : _requestCameraPermission,
            tooltip: 'ถ่ายรูป',
          ),
          
          // ปุ่มส่งไปประมวลผล
          _imageFile != null
              ? IconButton(
                  icon: const Icon(Icons.arrow_forward, size: 32, color: Colors.black87),
                  onPressed: _submitImage,
                  tooltip: 'ส่งประมวลผล',
                )
              : const SizedBox(width: 48),
        ],
      ),
    );
  }
}