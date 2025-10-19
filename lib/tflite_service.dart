import 'dart:io';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_processing/tflite_flutter_processing.dart';
import 'package:image/image.dart' as img; 

class TFLiteService {
  Interpreter? _foodClassifier;
  Interpreter? _weightPredictor;
  List<String>? _labels;

  //โหลดโมเดล 
  Future<void> loadModels() async {
    try {
      final labelsData = await rootBundle.loadString('assets/ml/labels.txt');
      _labels = labelsData.split('\n');

      _foodClassifier = await Interpreter.fromAsset('assets/ml/best_float16.tflite');
      print('Food classifier loaded successfully.');

      _weightPredictor = await Interpreter.fromAsset('assets/ml/weight_predictor_v2.tflite');
      print('Weight predictor loaded successfully.');

    } catch (e) {
      print('Failed to load TFLite models: $e');
    }
  }

  // ประมวลผลภาพก่อนป้อนเข้าโมเดล
  TensorImage _preprocessImage(File imageFile, int inputSize) {
    
    // อ่านไฟล์รูปภาพ
    final imageBytes = imageFile.readAsBytesSync();
    final img.Image? decodedImage = img.decodeImage(imageBytes);

    
    // ตรวจสอบว่ารูปภาพ
    if (decodedImage == null) {
      // ถ้าถอดรหัสไม่ได้ (เช่น รูป .gif หรือไฟล์เสีย) ให้โยน Error
      // (Error นี้จะถูกจับโดย try-catch ในฟังก์ชัน runFoodRecognition)
      throw Exception('ไม่สามารถถอดรหัสรูปภาพได้ กรุณาลองรูปอื่น');
    }
    

    // imageProcessor 
    var imageProcessor = ImageProcessorBuilder()
        .add(ResizeOp(inputSize, inputSize, ResizeMethod.BILINEAR))
        .add(NormalizeOp(0, 255)) 
        .build();
        
    // (4) ประมวลผลรูปภาพ 
    var tensorImage = imageProcessor.process(decodedImage); 
    
    return tensorImage;
  }

  // รันโมเดลจำแนกอาหาร 
  Future<String?> runFoodRecognition(XFile imageFile) async {
    if (_foodClassifier == null || _labels == null) return null;

    var inputSize = 224; // กุต้องแก้Inputก่อน เอ๋อควยไรไม่รู้
    var outputShape = [1, 3]; // (Output Shape [1, 3 เมนู])
    var outputType = TfLiteType.float32;

    try {
      // (ฟังก์ชันโยนerrorถ้า _preprocessImage ล้มเหลว)
      var tensorImage = _preprocessImage(File(imageFile.path), inputSize);
      var outputBuffer = TensorBuffer.createFixedSize(outputShape, outputType);
      
      _foodClassifier!.run(tensorImage.buffer, outputBuffer.buffer);

      var results = outputBuffer.getDoubleList();
      double maxScore = 0;
      int maxIndex = -1;
      for (int i = 0; i < results.length; i++) {
        if (results[i] > maxScore) {
          maxScore = results[i];
          maxIndex = i;
        }
      }
      return (maxIndex != -1) ? _labels![maxIndex] : null;

    } catch (e) {
      // (จับerrorที่โยนมาจาก _preprocessImage)
      print('Error running food classifier: $e');
      return null;
    }
  }

  // รันโมเดลประเมินน้ำหนัก cnn
  Future<double?> runWeightEstimation(XFile imageFile) async {
    if (_weightPredictor == null) return null;

    var inputSize = 224; // (แก้ขนาด Input ของคุณตรงนี้)
    var outputShape = [1, 1]; // (แก้ Output Shape ของคุณตรงนี้)
    var outputType = TfLiteType.float32;

    try {
      var tensorImage = _preprocessImage(File(imageFile.path), inputSize);
      var outputBuffer = TensorBuffer.createFixedSize(outputShape, outputType);

      _weightPredictor!.run(tensorImage.buffer, outputBuffer.buffer);

      return outputBuffer.getDoubleValue(0);

    } catch (e) {
      print('Error running weight predictor: $e');
      return null;
    }
  }

  void dispose() {
    _foodClassifier?.close();
    _weightPredictor?.close();
  }
}