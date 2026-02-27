import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ImageUploadService {
  final String baseUrl;
  // ใช้ 10.0.2.2 สำหรับ Android emulator (ชี้ไปที่ host machine)
  // ใช้ localhost สำหรับ iOS emulator และ web
  const ImageUploadService({this.baseUrl = 'http://10.0.2.2:5000'}); // Backend port 5000

  /// อัปโหลดรูปภาพไปยัง backend พร้อมข้อมูล meal
  /// ส่งคืน URL ของรูปภาพที่อัปโหลด หรือ null หากล้มเหลว
  Future<String?> uploadFoodImage(File imageFile) async {
    try {
      print('🔄 [ImageUploadService] Starting image upload...');
      print('📁 Image file: ${imageFile.path}');
      print('📦 File size: ${imageFile.lengthSync()} bytes');

      // สร้าง multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/meals'), // Endpoint สำหรับบันทึก meal
      );

      // เพิ่ม token สำหรับ authentication
      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'jwt_token');

      if (token == null) {
        throw Exception('No authentication token found');
      }

      request.headers['Authorization'] = 'Bearer $token';

      // เพิ่มไฟล์รูปภาพ
      request.files.add(
        await http.MultipartFile.fromPath(
          'image', // ชื่อ field ต้องตรงกับที่ backend คาดหวัง
          imageFile.path,
        ),
      );

      print('✅ Image file added to request');

      // ส่ง request ไปยัง server
      var response = await request.send();

      print('📡 Server responded with status: ${response.statusCode}');

      // ตรวจสอบ response
      if (response.statusCode == 201) {
        final responseBody = await response.stream.bytesToString();
        print('✅ Image uploaded successfully');
        print('📨 Response: $responseBody');
        
        // แยก URL จาก response (ต้องปรับตามโครงสร้าง response ของ backend)
        // ถ้า backend ส่ง JSON เช่น { "meal": { "imageUrl": "..." } }
        // ให้ parse ตรงนี้
        
        return 'Success'; // ส่งคืน success เพื่อให้ UI ทราบว่าอัปโหลดสำเร็จ
      } else {
        final errorBody = await response.stream.bytesToString();
        print('❌ Upload failed with status ${response.statusCode}');
        print('📨 Error: $errorBody');
        throw Exception('Upload failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [ImageUploadService] Error: $e');
      return null;
    }
  }

  /// อัปโหลดรูปภาพพร้อมข้อมูล meal (ใช้เมื่อต้องการอัปโหลดรูปและบันทึก meal ในครั้งเดียว)
  Future<String?> uploadFoodImageWithMealData({
    required File imageFile,
    required String foodName,
    required Map<String, double> nutrition,
    required double estimatedWeight,
    required String mealType,
    double? confidence,
    String? notes,
  }) async {
    try {
      print('🔄 [ImageUploadService] Starting image + meal data upload...');
      print('📁 Image file path: ${imageFile.path}');
      print('📦 File exists: ${imageFile.existsSync()}');
      print('📦 File size: ${imageFile.lengthSync()} bytes');

      // สร้าง multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/meals'),
      );

      print('🔗 Request URL: $baseUrl/api/meals');

      // เพิ่ม token สำหรับ authentication
      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'jwt_token');

      print('🔐 Token exists: ${token != null}');

      if (token == null) {
        throw Exception('No authentication token found');
      }

      request.headers['Authorization'] = 'Bearer $token';

      // เพิ่มไฟล์รูปภาพ
      print('📤 Adding image file to request...');
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
        ),
      );

      print('✅ Image file added successfully');

      // เพิ่มข้อมูล meal เป็น form fields
      request.fields['foodName'] = foodName;
      request.fields['nutrition[calories]'] = (nutrition['calories']?.toInt() ?? 0).toString();
      request.fields['nutrition[protein]'] = nutrition['protein']?.toString() ?? '0';
      request.fields['nutrition[carbohydrates]'] = nutrition['carbohydrates']?.toString() ?? '0';
      request.fields['nutrition[fat]'] = nutrition['fat']?.toString() ?? '0';
      request.fields['estimatedWeight'] = estimatedWeight.toString();
      request.fields['mealType'] = mealType;

      if (confidence != null) {
        request.fields['confidence'] = confidence.toString();
      }

      if (notes != null) {
        request.fields['notes'] = notes;
      }

      print('✅ All data added to request');
      print('📊 Request fields: ${request.fields}');
      print('📊 Request files: ${request.files.map((f) => f.filename).toList()}');

      // ส่ง request ไปยัง server
      print('🚀 Sending request to server...');
      var response = await request.send();

      print('📡 Server responded with status: ${response.statusCode}');

      if (response.statusCode == 201) {
        final responseBody = await response.stream.bytesToString();
        print('✅ Meal with image uploaded successfully');
        print('📨 Response: $responseBody');
        
        // Parse response to extract imageUrl
        try {
          final json = jsonDecode(responseBody) as Map<String, dynamic>;
          final imageUrl = json['meal']?['imageUrl'] as String?;
          print('🖼️ Image URL from response: $imageUrl');
          return imageUrl ?? 'Success'; // Return actual URL or Success if not present
        } catch (e) {
          print('⚠️ Could not parse imageUrl from response: $e');
          return 'Success';
        }
      } else {
        final errorBody = await response.stream.bytesToString();
        print('❌ Upload failed with status ${response.statusCode}');
        print('📨 Error: $errorBody');
        throw Exception('Upload failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [ImageUploadService] Error: $e');
      print('🔍 Stack trace: ${StackTrace.current}');
      return null;
    }
  }
}
