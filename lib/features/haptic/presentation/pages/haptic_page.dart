import 'package:flutter/material.dart';
import 'package:hapticvision/features/haptic/data/haptic_service.dart';

class HapticPage extends StatelessWidget {
  const HapticPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback Háptico'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepPurple.shade100,
              Colors.deepPurple.shade50,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildInfoSection(),
                const SizedBox(height: 30),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildEmotionButtons(context),
                        const SizedBox(height: 20),
                        _buildTestSection(context),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Experiencia Háptica',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Experimenta diferentes patrones de vibración para cada emoción',
          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Patrones de Vibración:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 12),
          _buildPatternInfo(
            '😐 Neutral',
            '1 vibración corta (300ms)',
            Colors.grey,
          ),
          _buildPatternInfo('😊 Feliz', '2 vibraciones rápidas', Colors.green),
          _buildPatternInfo('😡 Enojado', '3 vibraciones intensas', Colors.red),
          _buildPatternInfo('😢 Triste', '1 vibración larga (2s)', Colors.blue),
        ],
      ),
    );
  }

  Widget _buildPatternInfo(String emotion, String pattern, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$emotion: $pattern',
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Prueba las Emociones:',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.deepPurple,
          ),
        ),
        const SizedBox(height: 16),

        LayoutBuilder(
          builder: (context, constraints) {
            const int crossAxisCount = 2;
            const double spacing = 12.0;
            final double totalSpacing = (crossAxisCount - 1) * spacing;
            final double itemWidth =
                (constraints.maxWidth - totalSpacing) / crossAxisCount;

            double itemHeight = 140.0;

            final double availHeight = MediaQuery.of(context).size.height;
            if (availHeight < 700) {
              itemHeight = 120.0;
            }
            if (availHeight < 600) {
              itemHeight = 100.0;
            }

            final double childAspect = (itemWidth > 0 && itemHeight > 0)
                ? itemWidth / itemHeight
                : 1.0; // Evitar valores <= 0 que lanzan assertion

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                childAspectRatio: childAspect,
              ),
              itemCount: 4,
              itemBuilder: (context, index) {
                switch (index) {
                  case 0:
                    return _buildLargeEmotionButton(
                      context,
                      emotion: EmotionType.neutral,
                      label: 'Neutral',
                      icon: Icons.sentiment_neutral,
                      color: Colors.grey,
                      description: '1 vib. corta',
                    );
                  case 1:
                    return _buildLargeEmotionButton(
                      context,
                      emotion: EmotionType.happy,
                      label: 'Feliz',
                      icon: Icons.sentiment_very_satisfied,
                      color: Colors.green,
                      description: '2 vib. rápidas',
                    );
                  case 2:
                    return _buildLargeEmotionButton(
                      context,
                      emotion: EmotionType.angry,
                      label: 'Enojado',
                      icon: Icons.sentiment_very_dissatisfied,
                      color: Colors.red,
                      description: '3 vib. intensas',
                    );
                  default:
                    return _buildLargeEmotionButton(
                      context,
                      emotion: EmotionType.sad,
                      label: 'Triste',
                      icon: Icons.sentiment_dissatisfied,
                      color: Colors.blue,
                      description: '1 vib. larga',
                    );
                }
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildLargeEmotionButton(
    BuildContext context, {
    required EmotionType emotion,
    required String label,
    required IconData icon,
    required Color color,
    required String description,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      child: InkWell(
        onTap: () async {
          await HapticService().vibrateForEmotion(emotion);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✨ Vibración $label activada'),
              duration: const Duration(milliseconds: 1000),
              behavior: SnackBarBehavior.floating,
              backgroundColor: color,
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 2),
              Flexible(
                fit: FlexFit.loose,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 2),
              // Reducimos la altura de la descripción para que quepa en celdas
              // pequeñas y permitimos ellipsis cuando haga falta.
              SizedBox(
                height: 20,
                child: Text(
                  description,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTestSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepPurple.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.vibration, size: 28, color: Colors.deepPurple.shade300),
          const SizedBox(height: 6),
          Text(
            'Prueba Rápida',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.deepPurple.shade700,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () async {
              // Secuencia de prueba: todas las emociones
              await HapticService().vibrateForEmotion(EmotionType.neutral);
              await Future.delayed(const Duration(milliseconds: 500));
              await HapticService().vibrateForEmotion(EmotionType.happy);
              await Future.delayed(const Duration(milliseconds: 800));
              await HapticService().vibrateForEmotion(EmotionType.angry);
              await Future.delayed(const Duration(milliseconds: 1000));
              await HapticService().vibrateForEmotion(EmotionType.sad);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🎵 Secuencia completa ejecutada'),
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.play_circle_filled),
            label: const Text('Probar Secuencia Completa'),
          ),
        ],
      ),
    );
  }
}
