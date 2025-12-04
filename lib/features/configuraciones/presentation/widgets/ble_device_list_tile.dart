import 'package:flutter/material.dart';
import '../../data/models/ble_device_model.dart';

/// Widget que muestra un dispositivo BLE en una lista
class BleDeviceListTile extends StatelessWidget {
  final BleDeviceModel device;
  final VoidCallback onTap;
  final bool isConnected;
  final bool isLoading;

  const BleDeviceListTile({
    super.key,
    required this.device,
    required this.onTap,
    this.isConnected = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isConnected
            ? BorderSide(color: Colors.green.shade400, width: 2)
            : BorderSide.none,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isConnected ? Colors.green.shade50 : Colors.indigo.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.bluetooth,
            color: isConnected ? Colors.green.shade700 : Colors.indigo.shade700,
            size: 28,
          ),
        ),
        title: Text(
          device.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'ID: ${device.id}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.signal_cellular_alt,
                  size: 14,
                  color: _getSignalColor(device.rssi),
                ),
                const SizedBox(width: 4),
                Text(
                  '${device.signalStrength} (${device.rssi} dBm)',
                  style: TextStyle(
                    fontSize: 12,
                    color: _getSignalColor(device.rssi),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: _buildTrailing(),
        onTap: isLoading ? null : onTap,
      ),
    );
  }

  Widget _buildTrailing() {
    if (isLoading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
        ),
      );
    }

    if (isConnected) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'Conectado',
          style: TextStyle(
            color: Colors.green.shade700,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      );
    }

    return Icon(
      Icons.arrow_forward_ios,
      size: 16,
      color: Colors.grey.shade400,
    );
  }

  Color _getSignalColor(int rssi) {
    if (rssi >= -50) return Colors.green;
    if (rssi >= -70) return Colors.orange;
    if (rssi >= -85) return Colors.deepOrange;
    return Colors.red;
  }
}
