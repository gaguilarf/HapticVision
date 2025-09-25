import 'package:flutter/material.dart';
import 'package:hapticvision/features/haptic/data/haptic_service.dart';

class HapticButtonsWidget extends StatelessWidget {
  const HapticButtonsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        maxHeight: 120,
      ), // Limita la altura máxima
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Vibraciones Hápticas',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Flexible(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildEmotionButton(
                  context,
                  emotion: EmotionType.neutral,
                  label: 'Neutral',
                  icon: Icons.sentiment_neutral,
                  color: Colors.grey,
                ),
                _buildEmotionButton(
                  context,
                  emotion: EmotionType.happy,
                  label: 'Feliz',
                  icon: Icons.sentiment_very_satisfied,
                  color: Colors.green,
                ),
                _buildEmotionButton(
                  context,
                  emotion: EmotionType.angry,
                  label: 'Enojado',
                  icon: Icons.sentiment_very_dissatisfied,
                  color: Colors.red,
                ),
                _buildEmotionButton(
                  context,
                  emotion: EmotionType.sad,
                  label: 'Triste',
                  icon: Icons.sentiment_dissatisfied,
                  color: Colors.blue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionButton(
    BuildContext context, {
    required EmotionType emotion,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2.0),
        constraints: const BoxConstraints(
          maxHeight: 60,
        ), // Limita altura del botón
        child: ElevatedButton(
          onPressed: () async {
            await HapticService().vibrateForEmotion(emotion);

            // Feedback visual opcional
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Vibración: $label'),
                duration: const Duration(milliseconds: 800),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.only(bottom: 100),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            elevation: 3,
            minimumSize: Size.zero, // Permite tamaños más pequeños
            tapTargetSize:
                MaterialTapTargetSize.shrinkWrap, // Reduce el área de toque
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18),
              const SizedBox(height: 2),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget compacto para usar en espacios reducidos
class CompactHapticButtons extends StatelessWidget {
  const CompactHapticButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCompactButton(EmotionType.neutral, '😐', Colors.grey),
          const SizedBox(width: 8),
          _buildCompactButton(EmotionType.happy, '😊', Colors.green),
          const SizedBox(width: 8),
          _buildCompactButton(EmotionType.angry, '😡', Colors.red),
          const SizedBox(width: 8),
          _buildCompactButton(EmotionType.sad, '😢', Colors.blue),
        ],
      ),
    );
  }

  Widget _buildCompactButton(EmotionType emotion, String emoji, Color color) {
    return GestureDetector(
      onTap: () => HapticService().vibrateForEmotion(emotion),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20))),
      ),
    );
  }
}
