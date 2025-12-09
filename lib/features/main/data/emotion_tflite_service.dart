import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:onnxruntime/onnxruntime.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';

class EmotionOnnxService {
  OrtSession? _session;
  final List<String> labels = ['neutral', 'happy', 'sad', 'angry'];

  Future<void> loadModel() async {
    try {
      OrtEnv.instance.init();
      final rawAssetFile = await rootBundle.load(
        'assets/models/model_training.onnx',
      );
      final bytes = rawAssetFile.buffer.asUint8List();

      final sessionOptions = OrtSessionOptions();
      _session = OrtSession.fromBuffer(bytes, sessionOptions);

      debugPrint('[EmotionOnnxService] Model loaded successfully');
    } catch (e) {
      debugPrint('[EmotionOnnxService] loadModel error: $e');
      rethrow;
    }
  }

  /// Recibe una imagen recortada de la cara y devuelve el label de la emoción
  Future<String> predict(img.Image faceImage) async {
    try {
      if (_session == null) {
        debugPrint('[EmotionOnnxService] ERROR: Model not loaded');
        throw Exception('Model not loaded');
      }

      debugPrint(
        '[EmotionOnnxService] Starting prediction for image ${faceImage.width}x${faceImage.height}',
      );

      // Preprocesar: redimensionar y normalizar
      final input = _preprocess(faceImage);
      debugPrint(
        '[EmotionOnnxService] Input preprocessed, size: ${input.length}',
      );

      // Crear tensor de entrada con Float32List
      final inputOrt = OrtValueTensor.createTensorWithDataList(
        Float32List.fromList(input),
        [1, 1, 48, 48], // [batch, channels, height, width] - grayscale 48x48
      );
      debugPrint('[EmotionOnnxService] Input tensor created');

      // Ejecutar inferencia - probar diferentes nombres de entrada
      List<OrtValue?>? outputs;
      final inputNames = ['input', 'images', 'x', 'input.1', 'data'];

      for (final name in inputNames) {
        try {
          outputs = _session!.run(OrtRunOptions(), {name: inputOrt});
          debugPrint(
            '[EmotionOnnxService] Inference succeeded with input name: "$name"',
          );
          break;
        } catch (e) {
          debugPrint('[EmotionOnnxService] Failed with "$name": $e');
          if (name == inputNames.last) {
            rethrow;
          }
        }
      }

      debugPrint(
        '[EmotionOnnxService] Inference completed, outputs: ${outputs?.length}',
      );

      if (outputs == null || outputs.isEmpty) {
        debugPrint('[EmotionOnnxService] ERROR: No outputs from model');
        inputOrt.release();
        throw Exception('No outputs from model');
      }

      // Obtener resultados
      final outputValue = outputs[0]?.value;
      debugPrint(
        '[EmotionOnnxService] Output value type: ${outputValue.runtimeType}',
      );
      debugPrint('[EmotionOnnxService] Output value: $outputValue');

      final outputTensor = outputValue as List<List<dynamic>>;
      final List<double> probabilities = List<double>.from(outputTensor[0]);
      debugPrint('[EmotionOnnxService] Probabilities: $probabilities');

      // Buscar el índice de la mayor probabilidad
      final maxIdx = probabilities.indexOf(
        probabilities.reduce((a, b) => a > b ? a : b),
      );
      debugPrint(
        '[EmotionOnnxService] Max probability index: $maxIdx, emotion: ${labels[maxIdx]}',
      );

      inputOrt.release();
      outputs.forEach((element) => element?.release());

      return labels[maxIdx];
    } catch (e, stackTrace) {
      debugPrint('[EmotionOnnxService] predict error: $e');
      debugPrint('[EmotionOnnxService] Stack trace: $stackTrace');
      rethrow;
    }
  }

  List<double> _preprocess(img.Image image) {
    // Redimensionar a 48x48
    final resized = img.copyResize(image, width: 48, height: 48);

    // Convertir a escala de grises y normalizar a [0,1]
    // Formato: [1, 1, 48, 48] (NCHW con 1 canal)
    final List<double> input = [];

    for (int y = 0; y < 48; y++) {
      for (int x = 0; x < 48; x++) {
        final pixel = resized.getPixel(x, y);
        // Convertir a escala de grises usando promedio RGB
        final gray = (pixel.r + pixel.g + pixel.b) / 3.0;
        input.add(gray / 255.0);
      }
    }

    return input;
  }

  void dispose() {
    _session?.release();
    OrtEnv.instance.release();
  }
}
