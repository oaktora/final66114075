import 'dart:io';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class AIResult {
  final String label;
  final double confidence;
  AIResult(this.label, this.confidence);
}

class TfliteHelper {
  static final TfliteHelper instance = TfliteHelper._init();
  TfliteHelper._init();

  Interpreter? _interpreter;
  final List<String> _labels = ['Money', 'Crowd', 'Poster', 'Normal'];
  bool _loaded = false;

  Future<void> loadModel() async {
    if (_loaded) return;
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/model.tflite');
      _loaded = true;
    } catch (e) {
      print('TFLite load error: $e');
    }
  }

  Future<AIResult?> classify(String imagePath) async {
    if (!_loaded) await loadModel();
    if (_interpreter == null) return null;

    try {
      final rawBytes = File(imagePath).readAsBytesSync();
      final originalImage = img.decodeImage(rawBytes);
      if (originalImage == null) return null;

      final resized = img.copyResize(originalImage, width: 224, height: 224);

      var input = List.generate(
        1,
        (_) => List.generate(
          224,
          (y) => List.generate(224, (x) {
            final pixel = resized.getPixel(x, y);
            return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
          }),
        ),
      );

      var output = List.generate(1, (_) => List.filled(_labels.length, 0.0));
      _interpreter!.run(input, output);

      final scores = output[0];
      double maxScore = scores[0];
      int maxIdx = 0;
      for (int i = 1; i < scores.length; i++) {
        if (scores[i] > maxScore) {
          maxScore = scores[i];
          maxIdx = i;
        }
      }

      return AIResult(_labels[maxIdx], maxScore);
    } catch (e) {
      return null;
    }
  }

  void dispose() {
    _interpreter?.close();
    _loaded = false;
  }
}
