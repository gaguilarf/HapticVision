import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:hapticvision/features/main/data/emotion_tflite_service.dart';

class CameraService extends ChangeNotifier {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isRearCamera = true;
  bool _isDetecting = false;
  bool _isInitialized = false;

  FaceDetector? _faceDetector;
  List<Face> _faces = [];
  late EmotionTFLiteService _emotionService;
  Map<int, String> _faceEmotions = {};
  String? _currentEmotion;

  // Getters
  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;
  bool get isRearCamera => _isRearCamera;
  List<Face> get faces => _faces;
  Map<int, String> get faceEmotions => _faceEmotions;
  String? get currentEmotion => _currentEmotion;

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
      await _emotionService.loadModel();
      await _startCamera();
    } catch (e) {
      // Error handled silently
    }
  }

  Future<void> _startCamera() async {
    try {
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

      await _controller!.initialize();
      _isInitialized = true;
      notifyListeners();

      _controller!.startImageStream(_processCameraImage);
    } catch (e) {
      // Error handled silently
    }
  }

  void switchCamera() {
    _isRearCamera = !_isRearCamera;
    _controller?.dispose();
    _isInitialized = false;
    notifyListeners();
    _startCamera();
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isDetecting || _faceDetector == null) return;

    _isDetecting = true;

    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) return;

      final faces = await _faceDetector!.processImage(inputImage);

      if (faces.isNotEmpty) {
        final face = faces.first;
        // TODO: Aquí se implementaría la detección real de emociones
        // Por ahora usamos una emoción placeholder
        final emotion = await _detectEmotion(image, face);

        _faces = faces;
        _faceEmotions = {face.trackingId ?? face.hashCode: emotion};
        _currentEmotion = emotion;
      } else {
        _faces = [];
        _faceEmotions = {};
        _currentEmotion = null;
      }

      notifyListeners();
    } catch (e) {
      // Error handled silently
    } finally {
      _isDetecting = false;
    }
  }

  Future<String> _detectEmotion(CameraImage image, Face face) async {
    try {
      // TODO: Implementar la detección real de emociones usando TensorFlow Lite
      // Por ahora retornamos 'neutral' como placeholder
      return 'neutral';
    } catch (e) {
      return 'neutral';
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    try {
      final camera = _controller!.description;

      InputImageRotation? rotation;
      if (camera.lensDirection == CameraLensDirection.front) {
        rotation = InputImageRotation.rotation270deg;
      } else {
        rotation = InputImageRotation.rotation90deg;
      }

      final inputImageFormat = InputImageFormatValue.fromRawValue(
        image.format.raw,
      );
      if (inputImageFormat == null) return null;

      // Convertir a NV21 concatenando las planes correctamente para evitar
      // inconsistencias entre dimensiones y tamaño de buffer.
      final nv21 = _convertYUV420ToNV21(image);
      return InputImage.fromBytes(
        bytes: nv21,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: inputImageFormat,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );
    } catch (e) {
      return null;
    }
  }

  Uint8List _convertYUV420ToNV21(CameraImage image) {
    final int width = image.width;
    final int height = image.height;

    final Plane yPlane = image.planes[0];
    final Plane uPlane = image.planes[1];
    final Plane vPlane = image.planes[2];

    final int nv21Length = width * height + 2 * ((width ~/ 2) * (height ~/ 2));
    final Uint8List nv21 = Uint8List(nv21Length);

    int pos = 0;
    nv21.setRange(0, yPlane.bytes.length, yPlane.bytes);
    pos += yPlane.bytes.length;

    final int chromaRowStride = uPlane.bytesPerRow;
    final int chromaPixelStride = uPlane.bytesPerPixel ?? 1;

    for (int row = 0; row < height ~/ 2; row++) {
      for (int col = 0; col < width ~/ 2; col++) {
        final int uIndex = row * chromaRowStride + col * chromaPixelStride;
        final int vIndex =
            row * vPlane.bytesPerRow + col * (vPlane.bytesPerPixel ?? 1);
        nv21[pos++] = vPlane.bytes[vIndex];
        nv21[pos++] = uPlane.bytes[uIndex];
      }
    }

    return nv21;
  }

  @override
  void dispose() {
    _controller?.dispose();
    _faceDetector?.close();
    super.dispose();
  }
}
