import 'package:flutter/material.dart';
import '../../../configuraciones/presentation/configuraciones_page.dart';

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
                _buildSettingTile(
                  icon: Icons.bluetooth,
                  title: 'Dispositivos Bluetooth',
                  subtitle: 'Conectar dispositivo háptico',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ConfiguracionesPage(),
                      ),
                    );
                  },
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
