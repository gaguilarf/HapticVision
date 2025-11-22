import 'package:flutter/material.dart';
import 'package:hapticvision/features/main/presentation/main_camera_page.dart';
import 'package:hapticvision/features/haptic/presentation/pages/haptic_page.dart';
import 'package:hapticvision/features/menu/presentation/pages/main_menu_page.dart'
    show SettingsPage;

/// Main bottom navigation host used as the app's primary entry point.
///
/// This widget replaces the old main menu: it always shows a BottomNavigationBar
/// with three tabs (Cámara, Háptico, Configuración) and keeps the pages mounted
/// via an IndexedStack to preserve state while switching.
class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    MainCameraPage(),
    HapticPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _currentIndex, children: _pages),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey[600],
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt_rounded),
            label: 'Cámara',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.vibration),
            label: 'Háptico',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: 'Configuración',
          ),
        ],
      ),
    );
  }
}
