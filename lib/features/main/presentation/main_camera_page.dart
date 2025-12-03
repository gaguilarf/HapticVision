import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:hapticvision/features/main/presentation/controllers/camera_controller.dart';
import 'package:hapticvision/features/main/presentation/widgets/face_detection_box.dart';

class MainCameraPage extends StatefulWidget {
  const MainCameraPage({super.key});

  @override
  State<MainCameraPage> createState() => _MainCameraPageState();
}

class _MainCameraPageState extends State<MainCameraPage>
    with WidgetsBindingObserver {
  late HapticCameraController _cameraController;
  String _currentEmotion = ''; // Vacío por defecto
  List<Face> _faces = [];
  bool _isInitializing = true;
  bool _cameraInitFailed = false;
  // Nota: este page ahora se muestra dentro de `MainMenu` que ya gestiona
  // la navegación inferior. Por eso eliminamos el índice local y la barra
  // inferior para evitar duplicados.

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cameraController = HapticCameraController();
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Asegurarnos de liberar la cámara cuando la app pasa a background
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      try {
        _cameraController.dispose();
      } catch (_) {}
    } else if (state == AppLifecycleState.resumed) {
      // Re-intentar inicializar al volver (si no está inicializada)
      if (!_cameraController.isInitialized) {
        _initializeCamera();
      }
    }
  }

  Future<void> _initializeCamera() async {
    setState(() {
      _isInitializing = true;
      _cameraInitFailed = false;
    });

    final success = await _cameraController.initialize();
    _cameraController.onFacesDetected = _onFacesDetected;
    _cameraController.onEmotionDetected = _onEmotionDetected;

    setState(() {
      _isInitializing = false;
      _cameraInitFailed = !success;
    });
  }

  void _onFacesDetected(List<Face> faces) {
    setState(() {
      _faces = faces;
    });
  }

  void _onEmotionDetected(String emotion) {
    setState(() {
      _currentEmotion = emotion;
    });
  }

  Future<void> _switchCamera() async {
    setState(() {
      _isInitializing = true;
      _cameraInitFailed = false;
    });
    final ok = await _cameraController.switchCamera();
    setState(() {
      _isInitializing = false;
      _cameraInitFailed = !ok;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HapticVision'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.cameraswitch_rounded),
            onPressed: _switchCamera,
            tooltip: 'Cambiar cámara',
          ),
        ],
      ),
      body: _cameraController.isInitialized
          ? _buildCameraView()
          : _isInitializing
          ? const Center(
              child: CircularProgressIndicator(color: Colors.deepPurple),
            )
          : _cameraInitFailed
          ? _buildCameraError()
          : const Center(
              child: CircularProgressIndicator(color: Colors.deepPurple),
            ),
    );
  }

  Widget _buildCameraError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'No se pudo iniciar la cámara.',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _initializeCamera,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _switchCamera,
              child: const Text(
                'Cambiar cámara manualmente',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraView() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Stack(
        children: [
          // Vista de la cámara que ocupa toda la pantalla
          Positioned.fill(child: _cameraController.buildPreview()),

          // TextView flotante para mostrar la emoción
          Positioned(
            top: 60,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.deepPurple, width: 1),
              ),
              child: Text(
                _currentEmotion.isEmpty
                    ? 'Emoción:'
                    : 'Emoción: ${_currentEmotion.toUpperCase()}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Recuadros de detección de rostros
          ..._faces.map(
            (face) => FaceDetectionBox(face: face, emotion: _currentEmotion),
          ),

          // (Se eliminaron los overlays controlados por un BottomNavigation
          // interno porque `MainMenu` ya provee la navegación inferior.)
        ],
      ),
    );
  }
}
