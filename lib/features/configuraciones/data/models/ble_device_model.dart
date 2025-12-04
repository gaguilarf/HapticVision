import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;

/// Modelo que representa un dispositivo BLE descubierto
class BleDeviceModel {
  final String id;
  final String name;
  final int rssi; // Señal de intensidad
  final fbp.BluetoothDevice device;

  BleDeviceModel({
    required this.id,
    required this.name,
    required this.rssi,
    required this.device,
  });

  /// Crea un modelo desde un ScanResult de flutter_blue_plus
  factory BleDeviceModel.fromScanResult(fbp.ScanResult result) {
    return BleDeviceModel(
      id: result.device.remoteId.toString(),
      name: result.device.platformName.isEmpty
          ? 'Dispositivo desconocido'
          : result.device.platformName,
      rssi: result.rssi,
      device: result.device,
    );
  }

  /// Obtiene el nivel de señal en formato legible
  String get signalStrength {
    if (rssi >= -50) return 'Excelente';
    if (rssi >= -70) return 'Buena';
    if (rssi >= -85) return 'Regular';
    return 'Débil';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BleDeviceModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
