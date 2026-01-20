import 'dart:io';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'recognition_result.dart';

class TFLiteService {
  Interpreter? _foodClassifier;
  Interpreter? _weightPredictor;
  List<String>? _labels;

  // Store model IO details
  late List<int> _inShape;
  late List<int> _outShape;
  late List<int> _weightInShape;
  late List<int> _weightOutShape;

  Future<void> loadModels() async {
    print('🔄 [TFLiteService] Starting loadModels()...');
    try {
      // Load labels
      print('📂 Loading labels from assets/ml/labels.txt...');
      final labelsData = await rootBundle.loadString('assets/ml/labels.txt');
      _labels = labelsData
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      print('✅ Labels loaded: ${_labels!.length} food types');

      // Load food classifier model
      print('🧠 Loading food classifier: best_float16.tflite...');
      _foodClassifier = await Interpreter.fromAsset('assets/ml/best_float16.tflite');

      // Get shapes from food classifier
      final inTensor = _foodClassifier!.getInputTensor(0);
      final outTensor = _foodClassifier!.getOutputTensor(0);
      _inShape = inTensor.shape;    // Should be [1, 640, 640, 3]
      _outShape = outTensor.shape;  // Should be [1, 7, 8400]
      
      print('✅ Food classifier loaded successfully');
      print('   Input shape: $_inShape');
      print('   Output shape: $_outShape');
      
      // Load weight predictor model with error handling
      print('🔧 Loading weight predictor: weight_predictor_v2.tflite...');
      try {
        _weightPredictor = await Interpreter.fromAsset('assets/ml/weight_predictor_v2.tflite');
        
        // Get shapes from weight predictor
        final weightInTensor = _weightPredictor!.getInputTensor(0);
        final weightOutTensor = _weightPredictor!.getOutputTensor(0);
        _weightInShape = weightInTensor.shape;
        _weightOutShape = weightOutTensor.shape;
        
        // Debug: Check all output tensors
        print('DEBUG: Weight predictor output tensor count: ${_weightPredictor!.getOutputTensors().length}');
        for (int i = 0; i < _weightPredictor!.getOutputTensors().length; i++) {
          final tensor = _weightPredictor!.getOutputTensor(i);
          print('DEBUG: Output tensor $i shape: ${tensor.shape}');
        }
        
        print('✅ Weight predictor loaded successfully');
        print('   Weight input shape: $_weightInShape');
        print('   Weight output shape: $_weightOutShape');
      } catch (e) {
        print('❌ WARNING: Failed to load weight predictor model: $e');
        print('Stack trace: $e');
        _weightPredictor = null; // Set to null so we can handle it later
      }

    } catch (e) {
      print('❌ CRITICAL: Failed to load TFLite models: $e');
    }
  }

  // Preprocess image for YOLO (640x640)
  List<List<List<List<double>>>> _preprocessImageForYOLO(File imageFile) {
    // 1. Read and Decode image
    final bytes = imageFile.readAsBytesSync();
    final img.Image? decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw Exception('Failed to decode image');
    }

    // 2. Resize to 640x640 for YOLO
    final int height = 640;
    final int width = 640;
    
    final img.Image resized = img.copyResize(
      decoded,
      width: width,
      height: height,
      interpolation: img.Interpolation.nearest
    );
    
    // 3. Normalize to [0,1] range and reshape to [1, 640, 640, 3]
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

  // Preprocess image for Weight Predictor (224x224)
  List<List<List<List<double>>>> _preprocessImageForWeightPredictor(File imageFile) {
    // 1. Read and Decode image
    final bytes = imageFile.readAsBytesSync();
    final img.Image? decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw Exception('Failed to decode image');
    }

    // 2. Resize to 224x224 for CNN Weight Predictor
    final int height = 224;
    final int width = 224;
    
    final img.Image resized = img.copyResize(
      decoded,
      width: width,
      height: height,
      interpolation: img.Interpolation.linear
    );
    
    // 3. Normalize to [0,1] range and reshape to [1, 224, 224, 3]
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
      // 1. Preprocess the image for YOLO (640x640)
      final shapedInput = _preprocessImageForYOLO(File(imageFile.path));

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
      print('Running YOLO interpreter...');
      _foodClassifier!.run(shapedInput, outputArray);
      print('YOLO inference completed.');
      
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
        // Use weight predictor to estimate weight
        double estimatedWeight = await predictFoodWeight(File(imageFile.path));
        
        print('Recognition successful: ${_labels![maxIdx]} with confidence $maxScore, estimated weight: ${estimatedWeight.toStringAsFixed(0)}g');
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
    _weightPredictor?.close();
  }

  // Predict estimated weight from food image
  Future<double> predictFoodWeight(File imageFile) async {
    if (_weightPredictor == null) {
      print('❌ Error: Weight predictor model not loaded.');
      return 300.0; // Return default if model not loaded
    }

    try {
      // Preprocess image for weight predictor (224x224)
      print('📸 Preprocessing image for weight predictor (224x224)...');
      final shapedInput = _preprocessImageForWeightPredictor(imageFile);
      print('✅ Image preprocessed successfully');

      // Create output array - try [1, 1] first
      print('📊 Creating output array with shape [1, 1]...');
      List<List<double>> outputArray = [
        [0.0] // Batch 1, Output value 1
      ];

      // Run weight prediction
      print('🚀 Running weight predictor inference...');
      print('   Input shape: [1, 224, 224, 3]');
      print('   Expected output shape: ${_weightOutShape}');
      
      try {
        _weightPredictor!.run(shapedInput, outputArray);
        print('✅ Weight prediction inference completed successfully');
      } catch (e) {
        // If [1,1] fails, try allocating as reported shape
        print('⚠️  [1,1] allocation failed, trying reported shape: ${_weightOutShape}');
        
        if (_weightOutShape.length == 2) {
          outputArray = List.generate(
            _weightOutShape[0],
            (_) => List<double>.filled(_weightOutShape[1], 0.0)
          );
          _weightPredictor!.run(shapedInput, outputArray);
          print('✅ Using reported shape ${_weightOutShape} succeeded');
        } else {
          throw Exception('Cannot allocate output with shape ${_weightOutShape}');
        }
      }

      print('📋 Raw output: $outputArray');

      // Extract weight value
      double predictedWeight = 300.0;
      
      if (outputArray.isNotEmpty && outputArray[0].isNotEmpty) {
        predictedWeight = outputArray[0][0];
        print('🎯 Extracted weight: $predictedWeight grams');
      } else {
        print('❌ Output array is empty!');
      }

      // Validate and clamp weight
      if (predictedWeight <= 0 || predictedWeight.isNaN) {
        print('⚠️  Invalid weight value: $predictedWeight, using default 300g');
        predictedWeight = 300.0;
      }
      predictedWeight = predictedWeight.clamp(50.0, 800.0);
      
      print('✅ Final predicted weight: ${predictedWeight.toStringAsFixed(1)}g');
      return predictedWeight;

    } catch (e, s) {
      print('❌ Error predicting weight: $e');
      print('   Stack trace: $s');
      return 300.0; // Return default on error
    }
  }
}