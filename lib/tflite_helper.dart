import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class WaterQualityModel {
  late Interpreter _interpreter;

  /// Create model instance and load TFLite from assets
  static Future<WaterQualityModel> create() async {
    final model = WaterQualityModel._();

    // IMPORTANT: only filename, NOT "assets/..."
    model._interpreter = await Interpreter.fromAsset('assets/water_model.tflite');

    print("✅ MODEL LOADED SUCCESSFULLY");
    return model;
  }

  WaterQualityModel._();

  /// Predict raw probabilities
  List<double> predict(String imagePath) {
    final bytes = File(imagePath).readAsBytesSync();
    img.Image? image = img.decodeImage(bytes);

    if (image == null) {
      throw Exception("❌ Could not decode image at $imagePath");
    }

    // Resize to model input size
    image = img.copyResize(image, width: 224, height: 224);

    // Build 4D input tensor
    final input = List.generate(
      1,
          (_) => List.generate(
        224,
            (y) => List.generate(
          224,
              (x) {
            final pixel = image!.getPixel(x, y);
            return [
              pixel.r / 255.0,
              pixel.g / 255.0,
              pixel.b / 255.0,
            ];
          },
        ),
      ),
    );

    // Output shape [1,3]
    var output = List.filled(3, 0.0).reshape([1, 3]);

    _interpreter.run(input, output);

    return List<double>.from(output[0]);
  }

  /// Predict class name
  String predictClass(String imagePath) {
    final p = predict(imagePath);

    final labels = ["safe", "moderate", "unsafe"];

    final maxIndex = p.indexOf(p.reduce((a, b) => a > b ? a : b));

    return labels[maxIndex];
  }
}
