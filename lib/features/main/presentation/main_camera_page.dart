import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:hapticvision/features/main/presentation/controllers/camera_controller.dart';
import 'package:hapticvision/features/main/presentation/widgets/face_detection_box.dart';
import 'package:hapticvision/features/haptic/presentation/widgets/haptic_buttons_widget.dart';

class MainCameraPage extends StatefulWidget {
  const MainCameraPage({super.key});

  @override
  State<MainCameraPage> createState() => _MainCameraPageState();
}

class _MainCameraPageState extends State<MainCameraPage> {
  late HapticCameraController _cameraController;
  String _currentEmotion = ''; // Vacío por defecto
  List<Face> _faces = [];
  int _currentIndex = 0; // Índice de la pestaña actual

  @override
  void initState() {
    super.initState();
    _cameraController = HapticCameraController();
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    await _cameraController.initialize();
    _cameraController.onFacesDetected = _onFacesDetected;
    _cameraController.onEmotionDetected = _onEmotionDetected;
    setState(() {});
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

  void _switchCamera() {
    _cameraController.switchCamera();
    setState(() {});
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
          : const Center(
              child: CircularProgressIndicator(color: Colors.deepPurple),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          // Aquí puedes manejar la navegación entre pestañas
          switch (index) {
            case 0:
              // Cámara (ya estás aquí)
              break;
            case 1:
              // Navegación a página háptica
              print('[DEBUG] Navegación a háptico');
              break;
            case 2:
              // Navegación a configuración
              print('[DEBUG] Navegación a configuración');
              break;
          }
        },
        backgroundColor: Colors.deepPurple,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white60,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'Cámara',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.vibration),
            label: 'Háptico',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Configuración',
          ),
        ],
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

          // Botones hápticos cuando la pestaña háptica está seleccionada
          if (_currentIndex == 1) // Pestaña háptica
            Positioned(
              bottom: 120, // Más espacio arriba del BottomNavigationBar
              left: 16,
              right: 16,
              child: AnimatedOpacity(
                opacity: _currentIndex == 1 ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: const HapticButtonsWidget(),
              ),
            ),

          // Información de configuración cuando está seleccionada
          if (_currentIndex == 2) // Pestaña configuración
            Positioned(
              bottom: 120,
              left: 16,
              right: 16,
              child: AnimatedOpacity(
                opacity: _currentIndex == 2 ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 100),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '⚙️ Configuración',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Flexible(
                        child: Text(
                          'Próximamente: Ajustes de cámara, configuración háptica y preferencias',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Información adicional de cámara cuando está seleccionada
          if (_currentIndex == 0) // Pestaña cámara
            Positioned(
              bottom: 120,
              right: 16,
              child: AnimatedOpacity(
                opacity: _currentIndex == 0 ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  constraints: const BoxConstraints(
                    maxHeight: 80,
                    maxWidth: 200,
                  ),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📸 Modo Cámara',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rostros: ${_faces.length}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
