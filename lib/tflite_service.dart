import 'dart:io';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'recognition_result.dart';

class TFLiteService {
  Interpreter? _foodClassifier;
  List<String>? _labels;

  // Store model IO details
  late List<int> _inShape;
  late List<int> _outShape;

  Future<void> loadModels() async {
    try {
      // Load labels
      final labelsData = await rootBundle.loadString('assets/ml/labels.txt');
      _labels = labelsData
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      // Load model
      _foodClassifier = await Interpreter.fromAsset('assets/ml/best_float16.tflite');

      // Get shapes from model
      final inTensor = _foodClassifier!.getInputTensor(0);
      final outTensor = _foodClassifier!.getOutputTensor(0);
      _inShape = inTensor.shape;    // Should be [1, 640, 640, 3]
      _outShape = outTensor.shape;  // Should be [1, 7, 8400]
 
      print('Food classifier loaded successfully');
      print('Input shape: $_inShape');
      print('Output shape: $_outShape');

    } catch (e) {
      print('Failed to load TFLite models: $e');
    }
  }

  // Preprocess image and return it as a 4D List for the interpreter.
  List<List<List<List<double>>>> _preprocessImage(File imageFile) {
    // 1. Read and Decode image
    final bytes = imageFile.readAsBytesSync();
    final img.Image? decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw Exception('Failed to decode image');
    }

    // 2. Get dimensions from the model's input shape
    final int height = _inShape[1]; // 640
    final int width = _inShape[2]; // 640
    
    // 3. Resize image to match model input size with simple scaling
    final img.Image resized = img.copyResize(
      decoded,
      width: width,
      height: height,
      interpolation: img.Interpolation.nearest
    );
    
    // 4. Reshape the flat list of pixels into a 4D list [1, H, W, C] and normalize
    var shapedInput = List.generate(
      1, // Batch size
      (_) => List.generate(
        height,
        (y) => List.generate(
          width,
          (x) {
            final pixel = resized.getPixel(x, y);
            return [
              pixel.r.toDouble() / 255.0, // R
              pixel.g.toDouble() / 255.0, // G
              pixel.b.toDouble() / 255.0, // B
            ];
          },
        ),
      ),
    );

    return shapedInput;
  }

  // Helper function to resize image while maintaining aspect ratio
  img.Image _resizeWithAspectRatio(img.Image image, int targetWidth, int targetHeight) {
    final aspectRatio = image.width / image.height;
    final targetAspect = targetWidth / targetHeight;
    
    late int resizedWidth;
    late int resizedHeight;
    
    if (aspectRatio > targetAspect) {
      // Image is wider, fit to width
      resizedWidth = targetWidth;
      resizedHeight = (targetWidth / aspectRatio).toInt();
    } else {
      // Image is taller, fit to height
      resizedHeight = targetHeight;
      resizedWidth = (targetHeight * aspectRatio).toInt();
    }
    
    // First resize to preserve aspect ratio
    var resized = img.copyResize(
      image,
      width: resizedWidth,
      height: resizedHeight,
      interpolation: img.Interpolation.nearest
    );
    
    // Then pad with black color to match target size (matching YOLO standard)
    var padded = img.Image(width: targetWidth, height: targetHeight);
    // Fill with black (0, 0, 0)
    for (int y = 0; y < padded.height; y++) {
      for (int x = 0; x < padded.width; x++) {
        padded.setPixelRgba(x, y, 0, 0, 0, 255);
      }
    }
    
    // Paste resized image in center
    final offsetX = (targetWidth - resizedWidth) ~/ 2;
    final offsetY = (targetHeight - resizedHeight) ~/ 2;
    img.compositeImage(padded, resized, dstX: offsetX, dstY: offsetY);
    
    return padded;
  }

  // Final, simplified version of the recognition function
  Future<RecognitionResult?> runFoodRecognition(XFile imageFile) async {
    if (_foodClassifier == null || _labels == null) {
      print('Error: Model or labels not loaded.');
      return null;
    }
    
    try {
      // 1. Preprocess the image and get the 4D input list
      final shapedInput = _preprocessImage(File(imageFile.path));

      // 2. Prepare the output tensor structure correctly for Dart
      // This creates a nested list with shape [1, 7, 8400]
      var outputArray = List.generate(
          _outShape[0], // 1
          (_) => List.generate(
              _outShape[1], // 7
              (_) => List.generate(_outShape[2], (_) => 0.0) // 8400
          )
      );

      // 3. Run inference
      print('Running interpreter...');
      _foodClassifier!.run(shapedInput, outputArray);
      print('Interpreter run completed.');
      
      // 4. Post-process the YOLOv8 Output
      if (_labels!.isEmpty) {
        throw StateError('Labels are not loaded');
      }

      final int numClasses = _labels!.length;
      final int numBoxes = _outShape[2]; // 8400
      
      final int numProperties = _outShape[1]; // 7
      if (numProperties != 4 + numClasses) {
        print('Output shape mismatch! Expected 4 + $numClasses properties, but got $numProperties');
        return null;
      }

      var maxScore = -double.infinity;
      var maxIdx = -1;
      const double CONFIDENCE_THRESHOLD = 0.45; // Lowered threshold to 45%

      // Loop through all 8400 boxes to find the one with the highest confidence
      for (int i = 0; i < numBoxes; i++) {
        // For each box, check the confidence score of each class
        for (int c = 0; c < numClasses; c++) {
          // The output structure is [1, 7, 8400].
          // We access it as: outputArray[batch_index][property_index][box_index]
          // The first 4 properties (0-3) are box coordinates (x,y,w,h).
          // The next properties (4 onwards) are class confidences.
          final score = outputArray[0][4 + c][i];

          // If this score is the highest we've seen so far, update it
          if (score > maxScore) {
            maxScore = score;
            maxIdx = c;
          }
        }
      }
      
      // Debug: Print all class scores for the top detection
      print('=== All class scores ===');
      for (int c = 0; c < numClasses; c++) {
        var classScores = <double>[];
        for (int i = 0; i < numBoxes; i++) {
          classScores.add(outputArray[0][4 + c][i]);
        }
        final maxScore = classScores.reduce((a, b) => a > b ? a : b);
        print('${_labels![c]}: $maxScore');
      }
      print('=== Top detection ===');
      print('Top detection: ${_labels?[maxIdx] ?? "Unknown"} with confidence $maxScore');
      
      // Only return result if confidence exceeds threshold
      if (maxIdx >= 0 && maxIdx < _labels!.length && maxScore >= CONFIDENCE_THRESHOLD) {
        double estimatedWeight = 300.0; // Default average weight
        
        print('Recognition successful: ${_labels![maxIdx]} with confidence $maxScore');
        return RecognitionResult(
          foodName: _labels![maxIdx],
          confidence: maxScore,
          estimatedWeight: estimatedWeight,
        );
      }
      
      print('Recognition failed: Could not find a confident prediction.');
      return null;

    } catch (e, s) {
      print('Error running food classifier: $e');
      print('Stack trace: $s'); // Print stack trace for more details
      return null;
    }
  }

  void dispose() {
    _foodClassifier?.close();
  }
}