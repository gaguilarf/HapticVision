import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:hapticvision/features/main/data/emotion_tflite_service.dart';

class HapticCameraController {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isRearCamera = true;
  bool _isDetecting = false;
  FaceDetector? _faceDetector;
  EmotionTFLiteService? _emotionService;

  // Callbacks
  Function(List<Face>)? onFacesDetected;
  Function(String)? onEmotionDetected;

  bool get isInitialized => _controller?.value.isInitialized ?? false;
  double get aspectRatio => _controller?.value.aspectRatio ?? 1.0;
  Size? get previewSize => _controller?.value.previewSize;

  Future<void> initialize() async {
    try {
      _cameras = await availableCameras();

      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableContours: false,
          enableClassification: false,
        ),
      );

      _emotionService = EmotionTFLiteService();
      await _emotionService!.loadModel();

      await _startCamera();
    } catch (e) {
      // Error silencioso para UI limpia
    }
  }

  Future<void> _startCamera() async {
    if (_cameras.isEmpty) return;

    final camera = _isRearCamera
        ? _cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.back,
            orElse: () => _cameras.first,
          )
        : _cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.front,
            orElse: () => _cameras.first,
          );

    _controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      _controller!.startImageStream(_processCameraImage);
    } catch (e) {
      // Error silencioso
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isDetecting || !isInitialized) return;

    _isDetecting = true;

    try {
      // Crear InputImage para ML Kit
      final inputImage = _convertToInputImage(image);
      if (inputImage == null) return;

      // Detectar rostros
      final faces = await _faceDetector!.processImage(inputImage);
      onFacesDetected?.call(faces);

      // Si hay rostros, detectar emoción del primer rostro
      if (faces.isNotEmpty) {
        // Por ahora usamos una emoción por defecto
        // En el futuro aquí iría la lógica de TensorFlow Lite
        onEmotionDetected?.call('happy');
      } else {
        // Sin rostros = sin emoción detectada
        onEmotionDetected?.call('');
      }
    } catch (e) {
      // Error silencioso, continuar funcionando
      onEmotionDetected?.call('');
    } finally {
      _isDetecting = false;
    }
  }

  InputImage? _convertToInputImage(CameraImage image) {
    try {
      return InputImage.fromBytes(
        bytes: image.planes[0].bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.nv21,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );
    } catch (e) {
      return null;
    }
  }

  void switchCamera() {
    _isRearCamera = !_isRearCamera;
    _controller?.dispose();
    _startCamera();
  }

  Widget buildPreview() {
    if (!isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.deepPurple),
        ),
      );
    }

    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: _controller!.value.previewSize!.height,
        height: _controller!.value.previewSize!.width,
        child: CameraPreview(_controller!),
      ),
    );
  }

  void dispose() {
    _controller?.dispose();
    _faceDetector?.close();
  }
}
