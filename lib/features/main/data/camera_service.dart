import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

      final plane = image.planes.first;
      return InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: inputImageFormat,
          bytesPerRow: plane.bytesPerRow,
        ),
      );
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _faceDetector?.close();
    super.dispose();
  }
}
