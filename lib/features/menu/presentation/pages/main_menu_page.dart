import 'package:flutter/material.dart';
import 'package:hapticvision/features/main/presentation/main_camera_page.dart';
import 'package:hapticvision/features/haptic/presentation/pages/haptic_page.dart';

class MainMenuPage extends StatelessWidget {
  const MainMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade700,
              Colors.deepPurple.shade500,
              Colors.deepPurple.shade300,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                _buildHeader(),
                const SizedBox(height: 60),
                _buildMenuOptions(context),
                const Spacer(),
                _buildFooter(),
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
          'HapticVision',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Experiencia visual y háptica integrada',
          style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.8)),
        ),
      ],
    );
  }

  Widget _buildMenuOptions(BuildContext context) {
    return Column(
      children: [
        _buildMenuCard(
          context,
          title: 'Detección de Emociones',
          subtitle: 'Cámara con ML para detectar expresiones faciales',
          icon: Icons.camera_alt_rounded,
          color: Colors.blue.shade400,
          onTap: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const MainCameraPage()));
          },
        ),
        const SizedBox(height: 20),
        _buildMenuCard(
          context,
          title: 'Feedback Háptico',
          subtitle: 'Experimenta diferentes patrones de vibración',
          icon: Icons.vibration,
          color: Colors.green.shade400,
          onTap: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const HapticPage()));
          },
        ),
        const SizedBox(height: 20),
        _buildMenuCard(
          context,
          title: 'Configuración',
          subtitle: 'Ajusta preferencias y configuraciones',
          icon: Icons.settings_rounded,
          color: Colors.orange.shade400,
          onTap: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SettingsPage()));
          },
        ),
      ],
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 30, color: color),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 20,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.visibility_rounded,
            size: 32,
            color: Colors.white.withOpacity(0.6),
          ),
          const SizedBox(height: 8),
          Text(
            'Versión 1.0.0',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.orange.shade100,
              Colors.orange.shade50,
              Colors.white,
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSection(
              title: 'Cámara',
              children: [
                _buildSettingTile(
                  icon: Icons.camera_alt,
                  title: 'Resolución de cámara',
                  subtitle: 'Media (recomendado)',
                  onTap: () {},
                ),
                _buildSettingTile(
                  icon: Icons.flip_camera_ios,
                  title: 'Cámara por defecto',
                  subtitle: 'Frontal',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: 'Feedback Háptico',
              children: [
                _buildSettingTile(
                  icon: Icons.vibration,
                  title: 'Intensidad de vibración',
                  subtitle: 'Media',
                  onTap: () {},
                ),
                _buildSettingTile(
                  icon: Icons.timer,
                  title: 'Duración personalizada',
                  subtitle: 'Usar valores por defecto',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: 'General',
              children: [
                _buildSettingTile(
                  icon: Icons.palette,
                  title: 'Tema',
                  subtitle: 'Púrpura (por defecto)',
                  onTap: () {},
                ),
                _buildSettingTile(
                  icon: Icons.info,
                  title: 'Acerca de',
                  subtitle: 'HapticVision v1.0.0',
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'HapticVision',
                      applicationVersion: '1.0.0',
                      applicationIcon: const Icon(Icons.visibility, size: 48),
                      children: [
                        const Text(
                          'Aplicación de detección de emociones con feedback háptico integrado.',
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.orange.shade700,
            ),
          ),
        ),
        Container(
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
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.orange.shade600),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
