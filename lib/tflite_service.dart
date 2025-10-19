import 'dart:io';
import 'dart:typed_data';
import 'dart:isolate';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'recognition_result.dart';

// Data class to pass to isolate for tensor construction
class TensorConstructionData {
  final List<int> shape;
  final Float32List flatData;
  TensorConstructionData(this.shape, this.flatData);
}

// Worker function for building nested input tensor (runs in isolate)
List<List<List<List<double>>>> _buildNestedInput(TensorConstructionData data) {
  final dims = data.shape;
  final batch = dims[0];
  final height = dims[1];
  final width = dims[2];
  final channels = dims[3];
  final flatInput = data.flatData;

  int idx = 0;
  return List.generate(batch, (_) {
    return List.generate(height, (_) {
      return List.generate(width, (_) {
        return List.generate(channels, (_) {
          return flatInput[idx++];
        });
      });
    });
  });
}

// Worker function for building nested output tensor (runs in isolate)
dynamic _buildNestedOutput(List<int> shape) {
  if (shape.length == 3) {
    final b = shape[0];
    final dim1 = shape[1];
    final dim2 = shape[2];
    return List.generate(b, (_) {
      return List.generate(dim1, (_) {
        return List.generate(dim2, (_) => 0.0);
      });
    });
  } else if (shape.length == 2) {
    final b = shape[0];
    final dim1 = shape[1];
    return List.generate(b, (_) {
      return List.generate(dim1, (_) => 0.0);
    });
  } else {
    final size = shape.reduce((a, b) => a * b);
    return Float32List(size);
  }
}

// Worker function for flattening nested output (runs in isolate)
void _flattenOutput(Map<String, dynamic> args) {
  final outputArray = args['outputArray'] as Float32List;
  final nestedOutput = args['nestedOutput'];
  var k = 0;
  
  void walk(dynamic node) {
    if (node is List) {
      for (var e in node) walk(e);
    } else if (node is num) {
      if (k < outputArray.length) outputArray[k++] = node.toDouble();
    }
  }
  walk(nestedOutput);
}

class TFLiteService {
  Interpreter? _foodClassifier;
  Interpreter? _weightPredictor;
  List<String>? _labels;

  // Store model IO details
  late List<int> _inShape;     // e.g. [1,224,224,3]
  late List<int> _outShape;    // e.g. [1, numClasses]
  


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
      _inShape = inTensor.shape;    // [1,224,224,3]
      _outShape = outTensor.shape;  // [1, num_classes]
 
      print('Food classifier loaded successfully');
      print('Input shape: $_inShape');
      print('Output shape: $_outShape');

      // Load additional models if needed:
      // _weightPredictor = await Interpreter.fromAsset('assets/ml/weight_predictor_v2.tflite');

    } catch (e) {
      print('Failed to load TFLite models: $e');
    }
  }

  // Process image into normalized float array
  Float32List _preprocessImage(File imageFile) {
    final List<double> inputData = _preprocessImageToList(imageFile);
    return Float32List.fromList(inputData);
  }

  // Helper method to process image into list of normalized RGB values
  List<double> _preprocessImageToList(File imageFile) {
    final bytes = imageFile.readAsBytesSync();
    final img.Image? decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw Exception('Failed to decode image');
    }

    // Get dimensions from model input shape
    int h = _inShape[1]; // Assuming NHWC format [1,H,W,3]
    int w = _inShape[2];
    
    // Resize image to match model input size
    final img.Image resized = img.copyResize(
      decoded,
      width: w,
      height: h,
      interpolation: img.Interpolation.linear
    );
    
    // Convert to float array and normalize to [0,1]
    var inputData = List<double>.filled(h * w * 3, 0);
    var index = 0;
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final pixel = resized.getPixel(x, y);
        final r = pixel.r.toDouble();
        final g = pixel.g.toDouble();
        final b = pixel.b.toDouble();
        inputData[index++] = r / 255.0;  // R
        inputData[index++] = g / 255.0;  // G
        inputData[index++] = b / 255.0;  // B
      }
    }
    return inputData;
  }

  // Classification with weight estimation
  Future<RecognitionResult?> runFoodRecognition(XFile imageFile) async {
    if (_foodClassifier == null || _labels == null) return null;
    try {
      // Get raw processed image data (as floats 0..1)
      final floatInput = _preprocessImage(File(imageFile.path));

      // Inspect expected input tensor
      final inTensor = _foodClassifier!.getInputTensor(0);
      print('Interpreter expects input type: ${inTensor.type}, shape: ${inTensor.shape}');
      final outT = _foodClassifier!.getOutputTensor(0);
      print('Interpreter output type: ${outT.type}, shape: ${outT.shape}');

      // Prepare input depending on expected tensor type
      dynamic preparedInput;
      if (inTensor.type == TensorType.uint8) {
        // Convert to uint8 bytes (0-255)
        final uint8 = Uint8List(floatInput.length);
        for (var i = 0; i < floatInput.length; i++) {
          var v = (floatInput[i] * 255.0).round();
          if (v < 0) v = 0;
          if (v > 255) v = 255;
          uint8[i] = v;
        }
        // If model expects [1,H,W,C], the flat Uint8List is acceptable.
        preparedInput = uint8;
      } else {
        // Assume float32 input (common for float models)
        preparedInput = floatInput; // Float32List
      }
      
      // Create output tensor
      final outputTensor = _foodClassifier!.getOutputTensor(0);
      final outputShape = outputTensor.shape;
      final outputSize = outputShape.reduce((a, b) => a * b);
      final outputArray = Float32List(outputSize);
      bool ran = false;
      List<String> attemptLogs = [];

      // Try resizing input tensor explicitly to the model's expected shape.
      // This helps the interpreter know the exact rank/dimensions and avoids
      // PAD op prepare errors caused by ambiguous shapes.
      try {
        _foodClassifier!.resizeInputTensor(0, _inShape);
        attemptLogs.add('resizeInputTensor called with $_inShape');
      } catch (e) {
        attemptLogs.add('resizeInputTensor not available or failed: $e');
      }

      // Ensure interpreter tensors are allocated if API is available
      try {
        _foodClassifier!.allocateTensors();
        attemptLogs.add('allocateTensors() called');
      } catch (_) {
        // allocateTensors may not be supported on older plugin versions; ignore
      }

      // Re-fetch and log input tensor shape after any resize/allocate
      try {
        final afterIn = _foodClassifier!.getInputTensor(0);
        attemptLogs.add('Input tensor shape after resize/allocate: ${afterIn.shape}');
        print('Input tensor after resize/allocate: ${afterIn.shape}');
      } catch (_) {}

      // After resize+allocate, prefer trying the flat preparedInput first —
      // if interpreter now knows the expected shape this should succeed and
      // avoid PAD/rank mismatches.
      try {
        try {
          final debugIn = _foodClassifier!.getInputTensor(0);
          print('Attempt before run(preparedInput) — inTensor: ${debugIn.shape}');
        } catch (_) {}
        _foodClassifier!.run(preparedInput, outputArray);
        ran = true;
        attemptLogs.add('run(preparedInput) succeeded after resize/allocate');
      } catch (e) {
        attemptLogs.add('run(preparedInput) failed after resize/allocate: $e');
      }

      // Additional dynamic fallbacks: try runForMultipleInputs / runForMultipleOutputs
      if (!ran) {
        try {
          ( _foodClassifier! as dynamic ).runForMultipleInputs([preparedInput], {0: outputArray});
          ran = true;
          attemptLogs.add('runForMultipleInputs([preparedInput], {0:outputArray}) succeeded');
        } catch (e) {
          attemptLogs.add('runForMultipleInputs(...) failed: $e');
        }
      }

      if (!ran) {
        try {
          // Try runForMultipleInputs with nestedOutput if available
          dynamic nestedOutputTry;
          try {
            final odims = List<int>.from(_outShape);
            if (odims.length == 3) {
              final b = odims[0];
              final dim1 = odims[1];
              final dim2 = odims[2];
              nestedOutputTry = List.generate(b, (_) {
                return List.generate(dim1, (_) {
                  return List.generate(dim2, (_) => 0.0);
                });
              });
            } else if (odims.length == 2) {
              final b = odims[0];
              final dim1 = odims[1];
              nestedOutputTry = List.generate(b, (_) {
                return List.generate(dim1, (_) => 0.0);
              });
            } else {
              nestedOutputTry = Float32List(outputArray.length);
            }
          } catch (_) {
            nestedOutputTry = Float32List(outputArray.length);
          }

          ( _foodClassifier! as dynamic ).runForMultipleInputs([preparedInput], {0: nestedOutputTry});
          // flatten if needed
          if (nestedOutputTry is Float32List) {
            for (var i = 0; i < nestedOutputTry.length && i < outputArray.length; i++) outputArray[i] = nestedOutputTry[i];
          } else {
            int kk = 0;
            void walk(dynamic node) {
              if (node is List) for (var e in node) walk(e);
              else if (node is num) if (kk < outputArray.length) outputArray[kk++] = node.toDouble();
            }
            walk(nestedOutputTry);
          }
          ran = true;
          attemptLogs.add('runForMultipleInputs([preparedInput], {0:nestedOutput}) succeeded');
        } catch (e) {
          attemptLogs.add('runForMultipleInputs with nestedOutput failed: $e');
        }
      }

      // Build nested input/output tensors in isolate to avoid blocking main thread


      // If interpreter supports setInputTensorData, try using it directly to avoid
      // ambiguous shape inference. Otherwise fall back to run() with nested input.
      try {
        // Use typed setInputTensorData if available (newer plugin versions)
        // This is a no-op if method doesn't exist; guard with try/catch.
        final inTensorIdx = 0;
        if (preparedInput is Uint8List) {
          try {
            ( _foodClassifier! as dynamic ).setInputTensorData(inTensorIdx, preparedInput);
            attemptLogs.add('setInputTensorData(uint8) succeeded');
            // Run normally
            ( _foodClassifier! as dynamic ).invoke();
            attemptLogs.add('invoke() succeeded after setInputTensorData');
            ran = true;
          } catch (e) {
            attemptLogs.add('setInputTensorData(uint8) failed: $e');
          }
        } else if (preparedInput is Float32List) {
          try {
            ( _foodClassifier! as dynamic ).setInputTensorData(inTensorIdx, preparedInput);
            attemptLogs.add('setInputTensorData(float32) succeeded');
            ( _foodClassifier! as dynamic ).invoke();
            attemptLogs.add('invoke()Succeeded after setInputTensorData');
            ran = true;
          } catch (e) {
            attemptLogs.add('setInputTensorData(float32) failed: $e');
          }
        }
      } catch (_) {
        // setInputTensorData / invoke may not exist; proceed to run() fallbacks
      }

      // Try nested input/output path with isolate-based construction
      if (!ran) {
        try {
          // Build input and output tensors in isolates
          final tensorData = TensorConstructionData(_inShape, preparedInput as Float32List);
          final nestedInput = await compute(_buildNestedInput, tensorData);
          attemptLogs.add('nestedInput constructed in isolate');

          final nestedOutput = await compute(_buildNestedOutput, _outShape);
          attemptLogs.add('nestedOutput constructed in isolate');

          // Run inference with nested tensors
          _foodClassifier!.run(nestedInput, nestedOutput);
          
          // Flatten output in isolate
          await compute(_flattenOutput, {
            'outputArray': outputArray,
            'nestedOutput': nestedOutput,
          });

          ran = true;
          attemptLogs.add('run with isolate-constructed tensors succeeded');
        } catch (e) {
          attemptLogs.add('run with isolate-constructed tensors failed: $e');
        }
      }

      if (!ran) {
        try {
          // Try flat preparedInput (legacy) as a last resort
          _foodClassifier!.run(preparedInput, outputArray);
          ran = true;
          attemptLogs.add('run(preparedInput) succeeded (fallback)');
        } catch (e) {
          attemptLogs.add('run(preparedInput) failed (fallback): $e');
        }
      }

      if (!ran) {
        final logMsg = attemptLogs.join('\n');
        print('All run attempts failed:\n$logMsg');
        throw StateError('Failed to run interpreter with tried input formats');
      }

      // Find class with highest score
      var maxScore = -double.infinity;
      var maxIdx = -1;
      for (var i = 0; i < outputArray.length; i++) {
        if (outputArray[i] > maxScore) {
          maxScore = outputArray[i];
          maxIdx = i;
        }
      }
      
      if (maxIdx >= 0 && maxIdx < _labels!.length) {
        // ประมาณน้ำหนักอาหารจากขนาดภาพ (สามารถปรับให้แม่นยำขึ้นได้)
        // โดยเฉลี่ยอาหารจานเดียว ~ 250-350g
        double estimatedWeight = 300.0;  // ค่าเฉลี่ยเริ่มต้น
        
        return RecognitionResult(
          foodName: _labels![maxIdx],
          confidence: maxScore,
          estimatedWeight: estimatedWeight,
        );
      }
      return null;
    } catch (e) {
      print('Error running food classifier: $e');
      return null;
    }
  }

  // Weight estimation (if implemented)
  Future<double?> runWeightEstimation(XFile imageFile) async {
    if (_weightPredictor == null) return null;
    try {
      // Get normalized float data
      final inputData = _preprocessImage(File(imageFile.path));
      
      // Create output tensor
      final outputTensor = _weightPredictor!.getOutputTensor(0);
      final outputShape = outputTensor.shape;
      final outputSize = outputShape.reduce((a, b) => a * b);
      final outputArray = Float32List(outputSize);

      // Run inference
      _weightPredictor!.run(inputData, outputArray);
      
      // Return first value as weight prediction
      return outputArray[0].toDouble();
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
