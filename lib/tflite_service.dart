import 'dart:io';
import 'dart:math' as math;
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
    print('[TFLiteService] Starting loadModels()...');
    try {
      // Load labels
      print('Loading labels from assets/ml/labels.txt...');
      final labelsData = await rootBundle.loadString('assets/ml/labels.txt');
      _labels = labelsData
          .split('\n')
          .map((e) => e.trim())
          .where((line) {
            // Remove only the FINAL empty string from split
            // Keep empty strings that are part of the training data (marked with "")
            return true; // Keep all for now, we'll filter later
          })
          .toList();
      
      // Remove only the FINAL empty string if it exists (artifact of split)
      if (_labels!.isNotEmpty && _labels!.last.isEmpty) {
        // Only remove if it's truly the last artifact, not a training label
        _labels!.removeLast();
      }
      
      print('Labels loaded: ${_labels!.length} food types');
      
      // Debug: Show last few labels
      print('===== DEBUG: Last 5 labels =====');
      int startIdx = (_labels!.length - 5).clamp(0, _labels!.length);
      for (int i = startIdx; i < _labels!.length; i++) {
        print('Label[$i]: "${_labels![i]}" (length: ${_labels![i].length})');
      }

      // Load food classifier model
      print('Loading food classifier: best_float16.tflite...');
      _foodClassifier = await Interpreter.fromAsset('assets/ml/best_float16.tflite');

      // Get shapes from food classifier
      final inTensor = _foodClassifier!.getInputTensor(0);
      final outTensor = _foodClassifier!.getOutputTensor(0);
      _inShape = inTensor.shape;    // Should be [1, 416, 416, 3]
      _outShape = outTensor.shape;  // Should be [1, 7, 8400]
      
      print('Food classifier loaded successfully');
      print('   Input shape: $_inShape');
      print('   Output shape: $_outShape');
      
      // Load weight predictor model with error handling
      print('Loading weight predictor: weight_predictor_v2.tflite...');
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
        
        print('Weight predictor loaded successfully');
        print('   Weight input shape: $_weightInShape');
        print('   Weight output shape: $_weightOutShape');
      } catch (e) {
        print('WARNING: Failed to load weight predictor model: $e');
        print('Stack trace: $e');
        _weightPredictor = null; // Set to null so we can handle it later
      }

    } catch (e) {
      print('CRITICAL: Failed to load TFLite models: $e');
    }
  }

  // Preprocess image for YOLO (416x416)
  List<List<List<List<double>>>> _preprocessImageForYOLO(img.Image imageData) {
    // 1. Image already decoded, resize to 416x416 for YOLO
    final int height = 416;
    final int width = 416;
    
    final img.Image resized = img.copyResize(
      imageData,
      width: width,
      height: height,
      interpolation: img.Interpolation.nearest
    );
    
    // 3. Normalize to [0,1] range and reshape to [1, 416, 416, 3]
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
  List<List<List<List<double>>>> _preprocessImageForWeightPredictor(img.Image imageData) {
    // 1. Image already decoded, resize to 224x224 for CNN Weight Predictor
    final int height = 224;
    final int width = 224;
    
    final img.Image resized = img.copyResize(
      imageData,
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

  // Helper function to extract bounding box from YOLO detection output
  Map<String, dynamic>? _extractBoundingBoxFromYOLO(
    List<List<List<double>>> outputArray,
    int detectedClassIndex,
    int originalImageWidth,
    int originalImageHeight,
  ) {
    try {
      // YOLO output format: [1, 7, 8400]
      // outputArray[0][0-3][box_idx] = x, y, w, h (normalized to 640x640)
      // outputArray[0][4+class][box_idx] = confidence score for each class
      
      final int numBoxes = outputArray[0][0].length; // 8400
      var maxConfidence = -double.infinity;
      int maxBoxIdx = -1;
      
      // Find the box with highest confidence for the detected class
      for (int i = 0; i < numBoxes; i++) {
        final confidence = outputArray[0][4 + detectedClassIndex][i];
        if (confidence > maxConfidence) {
          maxConfidence = confidence;
          maxBoxIdx = i;
        }
      }
      
      if (maxBoxIdx == -1) return null;
      
      // Extract box coordinates from YOLO output
      final double xCenter = outputArray[0][0][maxBoxIdx]; // normalized [0, 1]
      final double yCenter = outputArray[0][1][maxBoxIdx]; // normalized [0, 1]
      final double boxWidth = outputArray[0][2][maxBoxIdx];  // normalized [0, 1]
      final double boxHeight = outputArray[0][3][maxBoxIdx]; // normalized [0, 1]
      
      // Convert from normalized coordinates to pixel coordinates
      // YOLO operates on 640x640 internally
      final double x1 = ((xCenter - boxWidth / 2) * originalImageWidth).clamp(0.0, originalImageWidth.toDouble());
      final double y1 = ((yCenter - boxHeight / 2) * originalImageHeight).clamp(0.0, originalImageHeight.toDouble());
      final double x2 = ((xCenter + boxWidth / 2) * originalImageWidth).clamp(0.0, originalImageWidth.toDouble());
      final double y2 = ((yCenter + boxHeight / 2) * originalImageHeight).clamp(0.0, originalImageHeight.toDouble());
      
      return {
        'x1': x1.toInt(),
        'y1': y1.toInt(),
        'x2': x2.toInt(),
        'y2': y2.toInt(),
        'confidence': maxConfidence,
      };
    } catch (e) {
      print('Error extracting bounding box: $e');
      return null;
    }
  }

  // Helper function to crop image based on bounding box
  img.Image? _cropImageByBoundingBox(
    img.Image originalImage,
    int x1,
    int y1,
    int x2,
    int y2,
  ) {
    try {
      final width = (x2 - x1).abs();
      final height = (y2 - y1).abs();
      
      // Add 10% padding around the detection
      final paddingX = (width * 0.1).toInt();
      final paddingY = (height * 0.1).toInt();
      
      final cropX1 = (x1 - paddingX).clamp(0, originalImage.width);
      final cropY1 = (y1 - paddingY).clamp(0, originalImage.height);
      final cropX2 = (x2 + paddingX).clamp(0, originalImage.width);
      final cropY2 = (y2 + paddingY).clamp(0, originalImage.height);
      
      final cropWidth = cropX2 - cropX1;
      final cropHeight = cropY2 - cropY1;
      
      if (cropWidth <= 0 || cropHeight <= 0) {
        print('Invalid crop dimensions: $cropWidth x $cropHeight');
        return null;
      }
      
      return img.copyCrop(
        originalImage,
        x: cropX1,
        y: cropY1,
        width: cropWidth,
        height: cropHeight,
      );
    } catch (e) {
      print('Error cropping image: $e');
      return null;
    }
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

  // Final, optimized version of the recognition function
  Future<RecognitionResult?> runFoodRecognition(XFile imageFile) async {
    if (_foodClassifier == null || _labels == null) {
      print('Error: Model or labels not loaded.');
      return null;
    }
    
    try {
      print('[TFLiteService.runFoodRecognition] Starting food recognition...');
      
      // 1. Decode image ONCE - store as img.Image
      print('Decoding image file...');
      final bytes = File(imageFile.path).readAsBytesSync();
      final img.Image? decodedImage = img.decodeImage(bytes);
      if (decodedImage == null) {
        throw Exception('Failed to decode image');
      }
      print('Image decoded successfully: ${decodedImage.width}x${decodedImage.height}');
      final int originalImageWidth = decodedImage.width;
      final int originalImageHeight = decodedImage.height;

      // 2. Preprocess the decoded image for YOLO (416x416)
      print('Preprocessing image for YOLO (416x416)...');
      final shapedInput = _preprocessImageForYOLO(decodedImage);

      // 3. Prepare the output tensor structure correctly for Dart
      // This creates a nested list with shape [1, 7, 8400]
      var outputArray = List.generate(
          _outShape[0], // 1
          (_) => List.generate(
              _outShape[1], // 7
              (_) => List.generate(_outShape[2], (_) => 0.0) // 8400
          )
      );

      // 4. Run YOLO inference
      print('Running YOLO interpreter...');
      print('DEBUG: Input shape: [1, 416, 416, 3], shaped input rank: ${shapedInput.length}');
      print('DEBUG: Model output shape from metadata: $_outShape');
      print('DEBUG: Labels count: ${_labels!.length}');
      
      try {
        _foodClassifier!.run(shapedInput, outputArray);
        print('YOLO inference completed.');
      } catch (e) {
        print('ERROR during inference: $e');
        rethrow;
      }
      
      // 5. Post-process the YOLOv8 Output
      if (_labels!.isEmpty) {
        throw StateError('Labels are not loaded');
      }

      final int numClasses = _labels!.length;
      final int numBoxes = _outShape[2]; // 8400
      
      final int numProperties = _outShape[1]; // 119
      print('DEBUG: Checking output structure - numProperties: $numProperties, numClasses: $numClasses');
      print('DEBUG: Expected: 4 + $numClasses = ${4 + numClasses}, Got: $numProperties');
      
      if (numProperties != 4 + numClasses) {
        print('Output shape mismatch! Expected 4 + $numClasses properties, but got $numProperties');
        return null;
      }

      var maxScore = -double.infinity;
      var maxIdx = -1;
      const double CONFIDENCE_THRESHOLD = 0.25; // Lowered threshold to 25% for better detection

      // Loop through all 8400 boxes to find the one with the highest confidence
      for (int i = 0; i < numBoxes; i++) {
        // For each box, check the confidence score of each class
        for (int c = 0; c < numClasses; c++) {
          // The output structure is [1, 119, 8400].
          // The first 4 properties (0-3) are box coordinates (x,y,w,h).
          // The next properties (4 onwards) are class confidences (raw logits).
          final rawScore = outputArray[0][4 + c][i];
          // Apply sigmoid to convert raw logits to probabilities [0, 1]
          final score = _sigmoid(rawScore);

          // If this score is the highest we've seen so far, update it
          if (score > maxScore) {
            maxScore = score;
            maxIdx = c;
          }
        }
      }
      
      // Debug: Print all class scores for the top detection
      print('=== All class scores (after sigmoid) ===');
      for (int c = 0; c < numClasses; c++) {
        var classScores = <double>[];
        for (int i = 0; i < numBoxes; i++) {
          final rawScore = outputArray[0][4 + c][i];
          classScores.add(_sigmoid(rawScore));
        }
        final maxScore = classScores.reduce((a, b) => a > b ? a : b);
        print('${_labels![c]}: $maxScore');
      }
      print('=== Top detection ===');
      print('Top detection: ${_labels?[maxIdx] ?? "Unknown"} with confidence $maxScore');
      
      // Only return result if confidence exceeds threshold
      if (maxIdx >= 0 && maxIdx < _labels!.length && maxScore >= CONFIDENCE_THRESHOLD) {
        // 6. Extract bounding box from YOLO output
        print('Extracting bounding box from YOLO detection...');
        final boundingBox = _extractBoundingBoxFromYOLO(
          outputArray,
          maxIdx,
          originalImageWidth,
          originalImageHeight,
        );
        
        if (boundingBox == null) {
          print('Warning: Could not extract bounding box, using full image for weight prediction');
        } else {
          print('Bounding box extracted: (${boundingBox['x1']}, ${boundingBox['y1']}) to (${boundingBox['x2']}, ${boundingBox['y2']})');
        }
        
        // 7. Crop image to detected food area
        img.Image? croppedImage = decodedImage;
        if (boundingBox != null) {
          print('Cropping image to detected food area...');
          croppedImage = _cropImageByBoundingBox(
            decodedImage,
            boundingBox['x1'],
            boundingBox['y1'],
            boundingBox['x2'],
            boundingBox['y2'],
          );
          if (croppedImage != null) {
            print('Image cropped successfully: ${croppedImage.width}x${croppedImage.height}');
          } else {
            print('Warning: Cropping failed, using full image');
            croppedImage = decodedImage;
          }
        }
        
        // 8. Use weight predictor to estimate weight (with cropped image)
        print('Predicting food weight from detected area...');
        double estimatedWeight = await predictFoodWeight(croppedImage);
        
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
  // imageData can be either full image or cropped image (from YOLO detection)
  Future<double> predictFoodWeight(img.Image imageData) async {
    if (_weightPredictor == null) {
      print('[TFLiteService.predictFoodWeight] Warning: Weight predictor model not loaded.');
      return 300.0; // Return default if model not loaded
    }

    try {
      // Preprocess image for weight predictor (224x224)
      print('[TFLiteService.predictFoodWeight] Preprocessing image for weight predictor (224x224)...');
      final shapedInput = _preprocessImageForWeightPredictor(imageData);
      print('[TFLiteService.predictFoodWeight] Image preprocessed successfully');

      // Prepare output array with robust handling
      // Try multiple allocation strategies for compatibility
      dynamic outputArray;
      bool allocationSuccess = false;
      
      // Strategy 1: Try [1, 1] first (most common case)
      print('[TFLiteService.predictFoodWeight] Creating output array with shape [1, 1]...');
      outputArray = [[0.0]];
      
      try {
        _weightPredictor!.run(shapedInput, outputArray);
        allocationSuccess = true;
        print('[TFLiteService.predictFoodWeight] [1,1] allocation succeeded');
      } catch (e) {
        print('[TFLiteService.predictFoodWeight] [1,1] allocation failed: $e');
        
        // Strategy 2: Try reported shape from model metadata
        if (_weightOutShape.isNotEmpty && _weightOutShape.length >= 2) {
          print('[TFLiteService.predictFoodWeight] Trying reported shape: ${_weightOutShape}');
          
          try {
            if (_weightOutShape.length == 1) {
              // Flat output
              outputArray = List<double>.filled(_weightOutShape[0], 0.0);
            } else {
              // Multidimensional output
              outputArray = List.generate(
                _weightOutShape[0],
                (_) => List<double>.filled(_weightOutShape[1], 0.0)
              );
            }
            
            _weightPredictor!.run(shapedInput, outputArray);
            allocationSuccess = true;
            print('[TFLiteService.predictFoodWeight] Reported shape succeeded');
          } catch (e2) {
            print('[TFLiteService.predictFoodWeight] Reported shape failed: $e2');
          }
        }
      }
      
      if (!allocationSuccess) {
        throw Exception('Failed to allocate output array with any strategy');
      }

      print('[TFLiteService.predictFoodWeight] Raw output: $outputArray');

      // Extract weight value with robust handling
      double predictedWeight = 300.0;
      
      try {
        if (outputArray is List<double>) {
          // Flat output
          if (outputArray.isNotEmpty) {
            predictedWeight = outputArray[0];
            print('[TFLiteService.predictFoodWeight] Extracted weight from flat output: $predictedWeight grams');
          }
        } else if (outputArray is List<List<double>>) {
          // 2D output
          if (outputArray.isNotEmpty && outputArray[0].isNotEmpty) {
            predictedWeight = outputArray[0][0];
            print('[TFLiteService.predictFoodWeight] Extracted weight from 2D output: $predictedWeight grams');
          }
        } else if (outputArray is List<List<List<double>>>) {
          // 3D output (shouldn't happen but handle it)
          if (outputArray.isNotEmpty && outputArray[0].isNotEmpty && outputArray[0][0].isNotEmpty) {
            predictedWeight = outputArray[0][0][0];
            print('[TFLiteService.predictFoodWeight] Extracted weight from 3D output: $predictedWeight grams');
          }
        }
      } catch (e) {
        print('[TFLiteService.predictFoodWeight] Error extracting weight value: $e');
      }

      // Validate and clamp weight
      if (predictedWeight <= 0 || predictedWeight.isNaN || predictedWeight.isInfinite) {
        print('[TFLiteService.predictFoodWeight] Invalid weight value: $predictedWeight, using default 300g');
        predictedWeight = 300.0;
      }
      predictedWeight = predictedWeight.clamp(50.0, 800.0);
      
      print('[TFLiteService.predictFoodWeight] Final predicted weight: ${predictedWeight.toStringAsFixed(1)}g');
      return predictedWeight;

    } catch (e, s) {
      print('[TFLiteService.predictFoodWeight] Error predicting weight: $e');
      print('[TFLiteService.predictFoodWeight] Stack trace: $s');
      return 300.0; // Return default on error
    }
  }

  // Sigmoid function to convert raw logits to probabilities [0, 1]
  double _sigmoid(double x) {
    return 1.0 / (1.0 + math.exp(-x));
  }
}