import 'package:flutter/material.dart';
import 'dart:typed_data';
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

  /// Intenta inicializar cámaras, detector y modelo.
  /// Devuelve `true` si la inicialización fue exitosa, `false` en caso contrario.
  Future<bool> initialize() async {
    try {
      _cameras = await availableCameras();

      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableContours: true,
          enableClassification: true,
        ),
      );

      _emotionService = EmotionTFLiteService();
      await _emotionService!.loadModel();

      return await _startCamera();
    } catch (e) {
      return false;
    }
  }

  Future<bool> _startCamera() async {
    if (_cameras.isEmpty) return false;

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
      return true;
    } catch (e) {
      return false;
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
      // Convertir el formato YUV_420_888 (Android) a NV21 que espera ML Kit
      final nv21 = _convertYUV420ToNV21(image);
      return InputImage.fromBytes(
        bytes: nv21,
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

  // Convierte CameraImage (YUV420) a NV21 (Y + VU interleaved)
  Uint8List _convertYUV420ToNV21(CameraImage image) {
    final int width = image.width;
    final int height = image.height;

    final Plane yPlane = image.planes[0];
    final Plane uPlane = image.planes[1];
    final Plane vPlane = image.planes[2];

    // NV21 size = width*height (Y) + 2*(width/2)*(height/2) (VU)
    final int nv21Length = width * height + 2 * ((width ~/ 2) * (height ~/ 2));
    final Uint8List nv21 = Uint8List(nv21Length);

    int pos = 0;
    // Copy Y
    nv21.setRange(0, yPlane.bytes.length, yPlane.bytes);
    pos += yPlane.bytes.length;

    final int chromaRowStride = uPlane.bytesPerRow;
    final int chromaPixelStride = uPlane.bytesPerPixel ?? 1;

    // Interleave V and U (NV21 = Y + VU)
    for (int row = 0; row < height ~/ 2; row++) {
      for (int col = 0; col < width ~/ 2; col++) {
        final int uIndex = row * chromaRowStride + col * chromaPixelStride;
        final int vIndex =
            row * vPlane.bytesPerRow + col * (vPlane.bytesPerPixel ?? 1);
        // V
        nv21[pos++] = vPlane.bytes[vIndex];
        // U
        nv21[pos++] = uPlane.bytes[uIndex];
      }
    }

    return nv21;
  }

  /// Cambia la cámara (frontal/trasera) y reintenta iniciar.
  /// Devuelve `true` si la nueva cámara se inicializó correctamente.
  Future<bool> switchCamera() async {
    _isRearCamera = !_isRearCamera;
    try {
      await _controller?.dispose();
    } catch (_) {}
    return await _startCamera();
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
