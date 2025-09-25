import 'package:vibration/vibration.dart';

enum EmotionType { neutral, happy, angry, sad }

class HapticService {
  static final HapticService _instance = HapticService._internal();
  factory HapticService() => _instance;
  HapticService._internal();

  /// Ejecuta el patrón de vibración correspondiente a la emoción
  Future<void> vibrateForEmotion(EmotionType emotion) async {
    // Verificar si el dispositivo soporta vibración
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator != true) return;

    switch (emotion) {
      case EmotionType.neutral:
        await _vibrateNeutral();
        break;
      case EmotionType.happy:
        await _vibrateHappy();
        break;
      case EmotionType.angry:
        await _vibrateAngry();
        break;
      case EmotionType.sad:
        await _vibrateSad();
        break;
    }
  }

  /// Neutral: 1 vibración corta (300ms)
  Future<void> _vibrateNeutral() async {
    await Vibration.vibrate(duration: 300);
  }

  /// Feliz: 2 vibraciones cortas (200ms cada una con pausa de 100ms)
  Future<void> _vibrateHappy() async {
    await Vibration.vibrate(duration: 300);
    await Future.delayed(const Duration(milliseconds: 600));
    await Vibration.vibrate(duration: 300);
  }

  /// Enojado: 3 vibraciones cortas (150ms cada una con pausa de 80ms)
  Future<void> _vibrateAngry() async {
    for (int i = 0; i < 3; i++) {
      await Vibration.vibrate(duration: 300);
      if (i < 2) {
        await Future.delayed(const Duration(milliseconds: 600));
      }
    }
  }

  /// Triste: 1 vibración larga (2 segundos)
  Future<void> _vibrateSad() async {
    await Vibration.vibrate(duration: 1500);
  }

  /// Método directo por nombre de emoción (string)
  Future<void> vibrateForEmotionString(String emotion) async {
    switch (emotion.toLowerCase()) {
      case 'neutral':
        await vibrateForEmotion(EmotionType.neutral);
        break;
      case 'happy':
      case 'feliz':
        await vibrateForEmotion(EmotionType.happy);
        break;
      case 'angry':
      case 'enojado':
        await vibrateForEmotion(EmotionType.angry);
        break;
      case 'sad':
      case 'triste':
        await vibrateForEmotion(EmotionType.sad);
        break;
      default:
        await vibrateForEmotion(EmotionType.neutral);
        break;
    }
  }
}
