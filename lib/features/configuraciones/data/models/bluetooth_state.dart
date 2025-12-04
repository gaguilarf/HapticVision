import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import '../models/ble_device_model.dart';

/// Estados posibles de Bluetooth
enum BluetoothStatus {
  unknown,
  unavailable,
  unauthorized,
  turningOn,
  on,
  turningOff,
  off,
}

/// Estados del proceso de escaneo
enum ScanStatus {
  idle,
  scanning,
  error,
}

/// Estado de conexión con un dispositivo
enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  disconnecting,
  error,
}

/// Estado inmutable para el manejo de Bluetooth BLE
class BluetoothState {
  final BluetoothStatus bluetoothStatus;
  final ScanStatus scanStatus;
  final ConnectionStatus connectionStatus;
  final List<BleDeviceModel> discoveredDevices;
  final BleDeviceModel? connectedDevice;
  final fbp.BluetoothCharacteristic? selectedCharacteristic;
  final String? errorMessage;
  final bool hasLocationPermission;
  final bool hasBluetoothPermission;

  const BluetoothState({
    this.bluetoothStatus = BluetoothStatus.unknown,
    this.scanStatus = ScanStatus.idle,
    this.connectionStatus = ConnectionStatus.disconnected,
    this.discoveredDevices = const [],
    this.connectedDevice,
    this.selectedCharacteristic,
    this.errorMessage,
    this.hasLocationPermission = false,
    this.hasBluetoothPermission = false,
  });

  /// Estado inicial
  factory BluetoothState.initial() => const BluetoothState();

  /// Copia el estado con modificaciones
  BluetoothState copyWith({
    BluetoothStatus? bluetoothStatus,
    ScanStatus? scanStatus,
    ConnectionStatus? connectionStatus,
    List<BleDeviceModel>? discoveredDevices,
    BleDeviceModel? connectedDevice,
    fbp.BluetoothCharacteristic? selectedCharacteristic,
    String? errorMessage,
    bool? hasLocationPermission,
    bool? hasBluetoothPermission,
    bool clearError = false,
    bool clearConnectedDevice = false,
    bool clearSelectedCharacteristic = false,
  }) {
    return BluetoothState(
      bluetoothStatus: bluetoothStatus ?? this.bluetoothStatus,
      scanStatus: scanStatus ?? this.scanStatus,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      discoveredDevices: discoveredDevices ?? this.discoveredDevices,
      connectedDevice: clearConnectedDevice ? null : (connectedDevice ?? this.connectedDevice),
      selectedCharacteristic: clearSelectedCharacteristic ? null : (selectedCharacteristic ?? this.selectedCharacteristic),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      hasLocationPermission: hasLocationPermission ?? this.hasLocationPermission,
      hasBluetoothPermission: hasBluetoothPermission ?? this.hasBluetoothPermission,
    );
  }

  /// Verifica si todos los permisos están concedidos
  bool get hasAllPermissions => hasLocationPermission && hasBluetoothPermission;

  /// Verifica si se puede escanear
  bool get canScan =>
      bluetoothStatus == BluetoothStatus.on &&
      hasAllPermissions &&
      scanStatus != ScanStatus.scanning;

  /// Verifica si hay un dispositivo conectado
  bool get isConnected => connectionStatus == ConnectionStatus.connected;
}
