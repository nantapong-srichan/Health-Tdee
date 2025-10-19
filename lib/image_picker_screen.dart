import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
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

      // อ่านไฟล์รูปภาพ
      final File originalFile = File(pickedFile.path);
      final img.Image? originalImage = img.decodeImage(await originalFile.readAsBytes());
      
      if (originalImage == null) {
        throw Exception('ไม่สามารถอ่านรูปภาพได้');
      }

      // ปรับขนาดเป็น 224x224 โดยรักษาสัดส่วน
      final img.Image resizedImage = img.copyResize(
        originalImage,
        width: 224,
        height: 224,
        interpolation: img.Interpolation.linear
      );

      // บันทึกรูปที่ปรับขนาดแล้ว
      final String tempPath = originalFile.path.replaceAll(
        RegExp(r'\.[^.]*$'), 
        '_resized.jpg'
      );
      final File resizedFile = File(tempPath);
      await resizedFile.writeAsBytes(img.encodeJpg(resizedImage));

      setState(() {
        _imageFile = resizedFile; // บันทึกไฟล์ที่ปรับขนาดแล้ว
      });

    } catch (e) {
      print("Error resizing image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ไม่สามารถปรับขนาดรูปภาพได้: $e')),
      );
    }
  }

  // ฟังก์ชัน Submit
  void _submitImage() async {
    if (_imageFile == null) return;

    setState(() => _isLoading = true);

    // แปลง File -> XFile ชั่วคราวเพื่อให้ service ทำงานได้
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
                      constraints: const BoxConstraints(maxWidth: 224, maxHeight: 224),
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