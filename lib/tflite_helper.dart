import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class WaterQualityModel {
  late Interpreter _interpreter;

  /// Async factory constructor to initialize interpreter
  static Future<WaterQualityModel> create() async {
    final model = WaterQualityModel._();
    model._interpreter = await Interpreter.fromAsset('assets/water_quality_model.tflite');
    return model;
  }

  // Private constructor
  WaterQualityModel._();

  /// Predicts class probabilities for an image
  List<double> predict(String imagePath) {
    // Load and resize image
    final bytes = File(imagePath).readAsBytesSync();
    img.Image? image = img.decodeImage(bytes);
    if (image == null) {
      throw Exception("Could not decode image at $imagePath");
    }
    image = img.copyResize(image, width: 224, height: 224);

    // Convert image to 4D tensor [1, 224, 224, 3]
    var input = List.generate(1, (_) => List.generate(224, (i) => List.generate(224, (j) {
      final pixel = image!.getPixel(j, i); // Pixel object
      return [
        pixel.r / 255.0, // R
        pixel.g / 255.0, // G
        pixel.b / 255.0, // B
      ];
    })));

    // Output tensor [1, 3]
    var output = List.filled(1 * 3, 0.0).reshape([1, 3]);

    // Run inference
    _interpreter.run(input, output);

    return List<double>.from(output[0]);
  }

  /// Returns predicted class name
  String predictClass(String imagePath) {
    final probabilities = predict(imagePath);
    final classNames = ['safe', 'moderate', 'unsafe'];
    final maxIndex = probabilities.indexOf(probabilities.reduce((a, b) => a > b ? a : b));
    return classNames[maxIndex];
  }
}
