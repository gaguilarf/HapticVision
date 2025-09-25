import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class EmotionTFLiteService {
  late Interpreter _interpreter;
  final List<String> labels = [
    'neutral',
    'happy',
    'sad',
    'angry',
    'surprised',
    'fear',
    'disgust',
  ];

  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset('models/best_model.tflite');
  }

  /// Recibe una imagen recortada de la cara (Uint8List) y devuelve el label de la emoción
  Future<String> predict(img.Image faceImage) async {
    // Preprocesar: redimensionar y normalizar
    final input = _preprocess(faceImage);
    var output = List.filled(labels.length, 0.0).reshape([1, labels.length]);
    _interpreter.run(input, output);
    // Buscar el índice de la mayor probabilidad
    final List<double> out = List<double>.from(output[0]);
    final maxIdx = out.indexOf(out.reduce((a, b) => a > b ? a : b));
    return labels[maxIdx];
  }

  List<List<List<List<double>>>> _preprocess(img.Image image) {
    // Redimensionar a 224x224 (ajusta si tu modelo usa otro tamaño)
    final resized = img.copyResize(image, width: 224, height: 224);
    // Normalizar a [0,1] y convertir a formato [1, 224, 224, 3]
    final input = List.generate(
      1,
      (_) => List.generate(
        224,
        (y) => List.generate(224, (x) {
          return [
            resized.getPixel(x, y).r / 255.0,
            resized.getPixel(x, y).g / 255.0,
            resized.getPixel(x, y).b / 255.0,
          ];
        }),
      ),
    );
    return input;
  }
}
