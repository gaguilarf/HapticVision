import 'package:flutter/material.dart';
import '../../data/models/bluetooth_state.dart';

/// Widget que muestra el estado actual de Bluetooth
class BluetoothStatusCard extends StatelessWidget {
  final BluetoothStatus status;
  final VoidCallback? onEnableBluetooth;

  const BluetoothStatusCard({
    super.key,
    required this.status,
    this.onEnableBluetooth,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getStatusIcon(status),
                    color: _getStatusColor(status),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Estado de Bluetooth',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getStatusText(status),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(status),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (status == BluetoothStatus.off && onEnableBluetooth != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onEnableBluetooth,
                  icon: const Icon(Icons.bluetooth),
                  label: const Text('Activar Bluetooth'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(BluetoothStatus status) {
    switch (status) {
      case BluetoothStatus.on:
        return Icons.bluetooth_connected;
      case BluetoothStatus.off:
        return Icons.bluetooth_disabled;
      case BluetoothStatus.turningOn:
      case BluetoothStatus.turningOff:
        return Icons.bluetooth_searching;
      case BluetoothStatus.unavailable:
        return Icons.bluetooth_disabled;
      case BluetoothStatus.unauthorized:
        return Icons.block;
      default:
        return Icons.bluetooth;
    }
  }

  Color _getStatusColor(BluetoothStatus status) {
    switch (status) {
      case BluetoothStatus.on:
        return Colors.green;
      case BluetoothStatus.off:
        return Colors.red;
      case BluetoothStatus.turningOn:
      case BluetoothStatus.turningOff:
        return Colors.orange;
      case BluetoothStatus.unavailable:
      case BluetoothStatus.unauthorized:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(BluetoothStatus status) {
    switch (status) {
      case BluetoothStatus.on:
        return 'Activado';
      case BluetoothStatus.off:
        return 'Desactivado';
      case BluetoothStatus.turningOn:
        return 'Activando...';
      case BluetoothStatus.turningOff:
        return 'Desactivando...';
      case BluetoothStatus.unavailable:
        return 'No disponible';
      case BluetoothStatus.unauthorized:
        return 'Sin autorización';
      default:
        return 'Desconocido';
    }
  }
}
