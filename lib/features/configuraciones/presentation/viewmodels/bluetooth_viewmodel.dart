import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import '../../data/models/ble_device_model.dart';
import '../../data/models/bluetooth_state.dart';
import '../../data/repositories/bluetooth_repository.dart';

/// Provider del repository
final bluetoothRepositoryProvider = Provider<BluetoothRepository>((ref) {
  return BluetoothRepository();
});

/// Provider del ViewModel
final bluetoothViewModelProvider =
    StateNotifierProvider<BluetoothViewModel, BluetoothState>((ref) {
  final repository = ref.watch(bluetoothRepositoryProvider);
  return BluetoothViewModel(repository);
});

/// ViewModel para manejar la lógica de Bluetooth BLE
class BluetoothViewModel extends StateNotifier<BluetoothState> {
  final BluetoothRepository _repository;
  StreamSubscription<List<BleDeviceModel>>? _scanSubscription;
  StreamSubscription<fbp.BluetoothConnectionState>? _connectionSubscription;
  StreamSubscription<fbp.BluetoothAdapterState>? _adapterSubscription;

  BluetoothViewModel(this._repository) : super(BluetoothState.initial()) {
    _initialize();
  }

  /// Inicializa el ViewModel
  Future<void> _initialize() async {
    await checkPermissions();
    await checkBluetoothStatus();
    _listenToAdapterState();
  }

  /// Escucha cambios en el estado del adaptador Bluetooth
  void _listenToAdapterState() {
    _adapterSubscription = _repository.adapterStateStream.listen((adapterState) {
      final status = _mapAdapterState(adapterState);
      state = state.copyWith(bluetoothStatus: status);
    });
  }

  BluetoothStatus _mapAdapterState(fbp.BluetoothAdapterState adapterState) {
    switch (adapterState) {
      case fbp.BluetoothAdapterState.on:
        return BluetoothStatus.on;
      case fbp.BluetoothAdapterState.off:
        return BluetoothStatus.off;
      case fbp.BluetoothAdapterState.turningOn:
        return BluetoothStatus.turningOn;
      case fbp.BluetoothAdapterState.turningOff:
        return BluetoothStatus.turningOff;
      case fbp.BluetoothAdapterState.unavailable:
        return BluetoothStatus.unavailable;
      case fbp.BluetoothAdapterState.unauthorized:
        return BluetoothStatus.unauthorized;
      default:
        return BluetoothStatus.unknown;
    }
  }

  /// Verifica el estado de Bluetooth
  Future<void> checkBluetoothStatus() async {
    try {
      final status = await _repository.checkBluetoothStatus();
      state = state.copyWith(bluetoothStatus: status);
    } catch (e) {
      state = state.copyWith(
        bluetoothStatus: BluetoothStatus.unknown,
        errorMessage: 'Error al verificar Bluetooth: $e',
      );
    }
  }

  /// Verifica los permisos necesarios
  Future<void> checkPermissions() async {
    final hasLocation = await _repository.hasLocationPermission();
    final hasBluetooth = await _repository.hasBluetoothPermissions();

    state = state.copyWith(
      hasLocationPermission: hasLocation,
      hasBluetoothPermission: hasBluetooth,
    );
  }

  /// Solicita todos los permisos necesarios
  Future<bool> requestPermissions() async {
    try {
      final locationGranted = await _repository.requestLocationPermission();
      final bluetoothGranted = await _repository.requestBluetoothPermissions();

      state = state.copyWith(
        hasLocationPermission: locationGranted,
        hasBluetoothPermission: bluetoothGranted,
      );

      if (!locationGranted || !bluetoothGranted) {
        state = state.copyWith(
          errorMessage: 'Se requieren permisos de ubicación y Bluetooth para continuar',
        );
        return false;
      }

      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Error al solicitar permisos: $e',
      );
      return false;
    }
  }

  /// Solicita activar Bluetooth
  Future<void> requestEnableBluetooth() async {
    try {
      await _repository.requestEnableBluetooth();
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Error al activar Bluetooth: $e',
      );
    }
  }

  /// Inicia el escaneo de dispositivos BLE
  Future<void> startScan() async {
    // Verificar permisos
    if (!state.hasAllPermissions) {
      final granted = await requestPermissions();
      if (!granted) return;
    }

    // Verificar estado de Bluetooth
    if (state.bluetoothStatus != BluetoothStatus.on) {
      state = state.copyWith(
        errorMessage: 'Bluetooth debe estar activado para escanear dispositivos',
      );
      return;
    }

    try {
      // Limpiar dispositivos previos y errores
      state = state.copyWith(
        scanStatus: ScanStatus.scanning,
        discoveredDevices: [],
        clearError: true,
      );

      // Cancelar suscripción previa
      await _scanSubscription?.cancel();

      // Iniciar escaneo
      _scanSubscription = _repository.startScan().listen(
        (devices) {
          // Actualizar lista de dispositivos descubiertos
          state = state.copyWith(
            discoveredDevices: devices,
            scanStatus: ScanStatus.scanning,
          );
        },
        onError: (error) {
          state = state.copyWith(
            scanStatus: ScanStatus.error,
            errorMessage: 'Error durante el escaneo: $error',
          );
        },
        onDone: () {
          state = state.copyWith(scanStatus: ScanStatus.idle);
        },
      );
    } catch (e) {
      state = state.copyWith(
        scanStatus: ScanStatus.error,
        errorMessage: 'Error al iniciar escaneo: $e',
      );
    }
  }

  /// Detiene el escaneo de dispositivos
  Future<void> stopScan() async {
    // 1. Cancelar suscripción inmediatamente para evitar que lleguen más eventos
    // que vuelvan a poner el estado en 'scanning'
    await _scanSubscription?.cancel();
    _scanSubscription = null;

    // 2. Actualizar UI inmediatamente a 'idle' para quitar el loading
    state = state.copyWith(scanStatus: ScanStatus.idle);

    // 3. Detener el hardware (ya no importa cuánto tarde)
    try {
      await _repository.stopScan();
    } catch (e) {
      print('Error al detener escaneo: $e');
    }
  }

  /// Conecta a un dispositivo BLE
  Future<void> connectToDevice(BleDeviceModel deviceModel) async {
    try {
      // Detener escaneo antes de conectar
      await stopScan();

      state = state.copyWith(
        connectionStatus: ConnectionStatus.connecting,
        clearError: true,
      );

      // Conectar al dispositivo
      await _repository.connectToDevice(deviceModel.device);

      // Escuchar cambios en el estado de conexión
      _connectionSubscription?.cancel();
      _connectionSubscription = _repository
          .listenConnectionState(deviceModel.device)
          .listen((connectionState) {
        if (connectionState == fbp.BluetoothConnectionState.connected) {
          state = state.copyWith(
            connectionStatus: ConnectionStatus.connected,
            connectedDevice: deviceModel,
          );
        } else if (connectionState == fbp.BluetoothConnectionState.disconnected) {
          state = state.copyWith(
            connectionStatus: ConnectionStatus.disconnected,
            clearConnectedDevice: true,
          );
        }
      });
    } catch (e) {
      state = state.copyWith(
        connectionStatus: ConnectionStatus.error,
        errorMessage: 'Error al conectar: $e',
      );
    }
  }

  /// Desconecta del dispositivo actual
  Future<void> disconnect() async {
    try {
      state = state.copyWith(connectionStatus: ConnectionStatus.disconnecting);
      await _repository.disconnect();
      await _connectionSubscription?.cancel();
      _connectionSubscription = null;

      state = state.copyWith(
        connectionStatus: ConnectionStatus.disconnected,
        clearConnectedDevice: true,
      );
    } catch (e) {
      state = state.copyWith(
        connectionStatus: ConnectionStatus.error,
        errorMessage: 'Error al desconectar: $e',
      );
    }
  }

  /// Limpia el mensaje de error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Descubre servicios del dispositivo conectado
  Future<List<fbp.BluetoothService>> discoverServices() async {
    try {
      if (!state.isConnected) {
        throw Exception('No hay dispositivo conectado');
      }

      final services = await _repository.discoverServices();
      return services;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Error al descubrir servicios: $e',
      );
      rethrow;
    }
  }

  /// Suscribe a notificaciones de una característica
  Future<void> subscribeToCharacteristic(fbp.BluetoothCharacteristic characteristic) async {
    try {
      await _repository.subscribeToCharacteristic(characteristic);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Error al suscribirse: $e',
      );
      rethrow;
    }
  }

  /// Desuscribe de notificaciones de una característica
  Future<void> unsubscribeFromCharacteristic(fbp.BluetoothCharacteristic characteristic) async {
    try {
      await _repository.unsubscribeFromCharacteristic(characteristic);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Error al desuscribirse: $e',
      );
      rethrow;
    }
  }

  /// Lee el valor de una característica
  Future<List<int>> readCharacteristic(fbp.BluetoothCharacteristic characteristic) async {
    try {
      return await _repository.readCharacteristic(characteristic);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Error al leer característica: $e',
      );
      rethrow;
    }
  }

  /// Escribe un valor en una característica
  Future<void> writeCharacteristic(
    fbp.BluetoothCharacteristic characteristic,
    List<int> value,
  ) async {
    try {
      await _repository.writeCharacteristic(characteristic, value);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Error al escribir: $e',
      );
      rethrow;
    }
  }

  /// Escucha notificaciones de una característica
  Stream<List<int>> listenToCharacteristic(fbp.BluetoothCharacteristic characteristic) {
    return _repository.listenToCharacteristic(characteristic);
  }

  /// Selecciona una característica para ser usada globalmente
  void selectCharacteristic(fbp.BluetoothCharacteristic characteristic) {
    state = state.copyWith(selectedCharacteristic: characteristic);
  }

  /// Limpia la característica seleccionada
  void clearSelectedCharacteristic() {
    state = state.copyWith(clearSelectedCharacteristic: true);
  }

  /// Envía un valor a la característica seleccionada
  Future<void> sendValueToSelectedCharacteristic(int value) async {
    try {
      final characteristic = state.selectedCharacteristic;
      if (characteristic == null) {
        throw Exception('No hay ninguna característica seleccionada');
      }

      if (!state.isConnected) {
        throw Exception('Dispositivo no conectado');
      }

      await _repository.writeCharacteristic(characteristic, [value]);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Error al enviar valor: $e',
      );
      rethrow;
    }
  }


  @override
  void dispose() {
    _scanSubscription?.cancel();
    _connectionSubscription?.cancel();
    _adapterSubscription?.cancel();
    _repository.dispose();
    super.dispose();
  }
}
