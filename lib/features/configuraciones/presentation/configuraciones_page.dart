import 'package:flutter/material.dart';

class ConfiguracionesPage extends StatelessWidget {
  const ConfiguracionesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        backgroundColor: Colors.indigo,
      ),
      body: const Center(
        child: Text(
          'Aquí irá la configuración de la app',
          style: TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
