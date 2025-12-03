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

      final started = await _startCamera();
      debugPrint(
        '[HapticCameraController] initialize -> startCamera: $started',
      );
      return started;
    } catch (e) {
      debugPrint('[HapticCameraController] initialize error: $e');
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
      debugPrint('[HapticCameraController] _startCamera error: $e');
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
      debugPrint('[HapticCameraController] faces detected: ${faces.length}');
      onFacesDetected?.call(faces);

      // Si hay rostros, detectar emoción del primer rostro
      if (faces.isNotEmpty) {
        // Por ahora usamos una emoción por defecto
        // En el futuro aquí iría la lógica de TensorFlow Lite
        debugPrint('[HapticCameraController] calling onEmotionDetected: happy');
        onEmotionDetected?.call('happy');
      } else {
        // Sin rostros = sin emoción detectada
        debugPrint('[HapticCameraController] no faces -> clearing emotion');
        onEmotionDetected?.call('');
      }
    } catch (e) {
      debugPrint('[HapticCameraController] _processCameraImage error: $e');
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
      final int bpr =
          image.width; // NV21 buffer we created is tightly packed per row
      debugPrint(
        '[HapticCameraController] InputImage metadata -> size=${image.width}x${image.height} bytesPerRow=$bpr rotation=0',
      );
      return InputImage.fromBytes(
        bytes: nv21,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.nv21,
          bytesPerRow: bpr,
        ),
      );
    } catch (e) {
      debugPrint('[HapticCameraController] _convertToInputImage error: $e');
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

    debugPrint(
      '[HapticCameraController] convertYUV: w=$width h=$height y.len=${yPlane.bytes.length} u.len=${uPlane.bytes.length} v.len=${vPlane.bytes.length} y.row=${yPlane.bytesPerRow} u.row=${uPlane.bytesPerRow} v.row=${vPlane.bytesPerRow} u.pix=${uPlane.bytesPerPixel} v.pix=${vPlane.bytesPerPixel}',
    );

    final int chromaHeight = (height + 1) ~/ 2;
    final int chromaWidth = (width + 1) ~/ 2;
    final int nv21Length = width * height + 2 * (chromaWidth * chromaHeight);
    final Uint8List nv21 = Uint8List(nv21Length);

    int pos = 0;

    // Copy Y plane per row to account for row stride/padding
    final int yRowStride = yPlane.bytesPerRow;
    final int yPixelStride = yPlane.bytesPerPixel ?? 1;
    for (int row = 0; row < height; row++) {
      final int rowStart = row * yRowStride;
      for (int col = 0; col < width; col++) {
        final int yIndex = rowStart + col * yPixelStride;
        if (yIndex < yPlane.bytes.length && pos < nv21Length) {
          nv21[pos++] = yPlane.bytes[yIndex];
        } else {
          // Out-of-bounds safety: fill with zero
          if (pos < nv21Length) nv21[pos++] = 0;
        }
      }
    }

    // Interleave V and U (NV21 = Y + VU)
    final int uRowStride = uPlane.bytesPerRow;
    final int uPixelStride = uPlane.bytesPerPixel ?? 1;
    final int vRowStride = vPlane.bytesPerRow;
    final int vPixelStride = vPlane.bytesPerPixel ?? 1;

    for (int row = 0; row < chromaHeight; row++) {
      final int uRowStart = row * uRowStride;
      final int vRowStart = row * vRowStride;
      for (int col = 0; col < chromaWidth; col++) {
        final int uIndex = uRowStart + col * uPixelStride;
        final int vIndex = vRowStart + col * vPixelStride;

        // V
        if (vIndex < vPlane.bytes.length && pos < nv21Length) {
          nv21[pos++] = vPlane.bytes[vIndex];
        } else {
          if (pos < nv21Length) nv21[pos++] = 0;
        }

        // U
        if (uIndex < uPlane.bytes.length && pos < nv21Length) {
          nv21[pos++] = uPlane.bytes[uIndex];
        } else {
          if (pos < nv21Length) nv21[pos++] = 0;
        }
      }
    }

    if (pos != nv21Length) {
      debugPrint(
        '[HapticCameraController] nv21 length mismatch: expected=$nv21Length pos=$pos',
      );
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
