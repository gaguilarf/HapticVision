import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:hapticvision/features/main/data/emotion_tflite_service.dart';
import 'package:hapticvision/features/haptic/data/haptic_service.dart';
import 'package:image/image.dart' as img;

class HapticCameraController {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isRearCamera = true;
  bool _isDetecting = false;
  FaceDetector? _faceDetector;
  EmotionOnnxService? _emotionService;
  final HapticService _hapticService = HapticService();

  // Control de tiempo para detección de emoción
  DateTime? _lastEmotionDetectionTime;
  static const Duration _emotionDetectionInterval = Duration(seconds: 3);

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

      _emotionService = EmotionOnnxService();
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

    final camera =
        _isRearCamera
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

      // Detectar rostros (esto se hace siempre para dibujar el recuadro)
      final faces = await _faceDetector!.processImage(inputImage);
      debugPrint('[HapticCameraController] faces detected: ${faces.length}');
      onFacesDetected?.call(faces);

      // Detectar emoción solo cada 3 segundos
      if (faces.isNotEmpty) {
        final now = DateTime.now();
        final shouldDetectEmotion =
            _lastEmotionDetectionTime == null ||
            now.difference(_lastEmotionDetectionTime!) >=
                _emotionDetectionInterval;

        if (shouldDetectEmotion) {
          final face = faces.first;
          final faceImage = await _extractFaceImage(image, face.boundingBox);

          if (faceImage != null) {
            final emotion = await _emotionService!.predict(faceImage);
            debugPrint('[HapticCameraController] emotion detected: $emotion');
            onEmotionDetected?.call(emotion);
            _lastEmotionDetectionTime = now;
          } else {
            debugPrint('[HapticCameraController] could not extract face image');
          }
        }
        // Si no toca detectar emoción, no hacemos nada (mantenemos la última)
      } else {
        // Sin rostros = limpiar emoción
        debugPrint('[HapticCameraController] no faces -> clearing emotion');
        onEmotionDetected?.call('');
        _lastEmotionDetectionTime =
            null; // Resetear para detectar inmediatamente cuando aparezca un rostro
      }
    } catch (e) {
      debugPrint('[HapticCameraController] _processCameraImage error: $e');
      // Error silencioso, continuar funcionando
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

  /// Extrae la región del rostro de la imagen de la cámara
  Future<img.Image?> _extractFaceImage(CameraImage image, Rect faceRect) async {
    try {
      // Convertir CameraImage a img.Image
      final int width = image.width;
      final int height = image.height;

      // Crear imagen desde YUV (aproximación usando solo el plano Y como escala de grises)
      final yPlane = image.planes[0];
      final imgImage = img.Image(width: width, height: height);

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final yIndex =
              y * yPlane.bytesPerRow + x * (yPlane.bytesPerPixel ?? 1);
          if (yIndex < yPlane.bytes.length) {
            final yValue = yPlane.bytes[yIndex];
            imgImage.setPixelRgb(x, y, yValue, yValue, yValue);
          }
        }
      }

      // Recortar la región del rostro con validación de límites
      final left = faceRect.left.toInt().clamp(0, width - 1);
      final top = faceRect.top.toInt().clamp(0, height - 1);
      final right = faceRect.right.toInt().clamp(left + 1, width);
      final bottom = faceRect.bottom.toInt().clamp(top + 1, height);

      final faceWidth = right - left;
      final faceHeight = bottom - top;

      if (faceWidth <= 0 || faceHeight <= 0) {
        debugPrint(
          '[HapticCameraController] invalid face dimensions: ${faceWidth}x$faceHeight',
        );
        return null;
      }

      final croppedFace = img.copyCrop(
        imgImage,
        x: left,
        y: top,
        width: faceWidth,
        height: faceHeight,
      );

      return croppedFace;
    } catch (e) {
      debugPrint('[HapticCameraController] _extractFaceImage error: $e');
      return null;
    }
  }

  /// Cambia la cámara (frontal/trasera) y reintenta iniciar.
  /// Devuelve `true` si la nueva cámara se inicializó correctamente.
  Future<bool> switchCamera() async {
    _isRearCamera = !_isRearCamera;

    // Detener el stream de imágenes antes de dispose
    try {
      if (_controller?.value.isStreamingImages ?? false) {
        await _controller?.stopImageStream();
      }
    } catch (e) {
      debugPrint('[HapticCameraController] error stopping stream: $e');
    }

    // Dispose del controller anterior
    try {
      await _controller?.dispose();
      _controller = null; // Importante: setear a null para evitar uso posterior
    } catch (e) {
      debugPrint('[HapticCameraController] error disposing controller: $e');
    }

    return await _startCamera();
  }

  /// Captura una foto y detecta la emoción en el rostro
  Future<Map<String, String?>> capturePhotoWithEmotion() async {
    if (!isInitialized) {
      return {'photo': null, 'emotion': null};
    }

    try {
      // Tomar la foto
      final XFile photo = await _controller!.takePicture();

      // Leer los bytes de la foto
      final bytes = await photo.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        debugPrint('[HapticCameraController] could not decode captured image');
        return {'photo': photo.path, 'emotion': null};
      }

      // Convertir a InputImage para detección de rostros
      final inputImage = InputImage.fromFilePath(photo.path);
      final faces = await _faceDetector!.processImage(inputImage);

      if (faces.isEmpty) {
        debugPrint('[HapticCameraController] no faces in captured photo');
        return {'photo': photo.path, 'emotion': 'No face detected'};
      }

      // Extraer el primer rostro y predecir emoción
      final face = faces.first;
      final faceRect = face.boundingBox;
      debugPrint('[HapticCameraController] Face bounding box: $faceRect');

      // Recortar rostro de la imagen decodificada
      final left = faceRect.left.toInt().clamp(0, image.width - 1);
      final top = faceRect.top.toInt().clamp(0, image.height - 1);
      final right = faceRect.right.toInt().clamp(left + 1, image.width);
      final bottom = faceRect.bottom.toInt().clamp(top + 1, image.height);

      debugPrint(
        '[HapticCameraController] Cropping face from ($left,$top) to ($right,$bottom)',
      );

      final croppedFace = img.copyCrop(
        image,
        x: left,
        y: top,
        width: right - left,
        height: bottom - top,
      );

      debugPrint(
        '[HapticCameraController] Cropped face size: ${croppedFace.width}x${croppedFace.height}',
      );
      debugPrint('[HapticCameraController] Calling emotion service predict...');

      final emotion = await _emotionService!.predict(croppedFace);
      debugPrint('[HapticCameraController] captured photo emotion: $emotion');

      // Vibrar según la emoción detectada
      await _hapticService.vibrateForEmotionString(emotion);

      return {'photo': photo.path, 'emotion': emotion};
    } catch (e, stackTrace) {
      debugPrint('[HapticCameraController] capturePhotoWithEmotion error: $e');
      debugPrint('[HapticCameraController] Stack trace: $stackTrace');
      return {'photo': null, 'emotion': null};
    }
  }

  Widget buildPreview() {
    // Verificar que el controller existe, está inicializado y no ha sido disposed
    if (_controller == null || !(_controller?.value.isInitialized ?? false)) {
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
    try {
      if (_controller?.value.isStreamingImages ?? false) {
        _controller?.stopImageStream();
      }
    } catch (e) {
      debugPrint(
        '[HapticCameraController] error stopping stream in dispose: $e',
      );
    }

    try {
      _controller?.dispose();
      _controller = null;
    } catch (e) {
      debugPrint('[HapticCameraController] error disposing controller: $e');
    }

    try {
      _faceDetector?.close();
    } catch (e) {
      debugPrint('[HapticCameraController] error closing face detector: $e');
    }

    try {
      _emotionService?.dispose();
    } catch (e) {
      debugPrint(
        '[HapticCameraController] error disposing emotion service: $e',
      );
    }
  }
}
