import 'dart:async';
import 'dart:io';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:permission_handler/permission_handler.dart';
import '../models/ble_device_model.dart';
import '../models/bluetooth_state.dart';

/// Repository para manejar todas las operaciones de Bluetooth BLE
class BluetoothRepository {
  static final BluetoothRepository _instance = BluetoothRepository._internal();
  factory BluetoothRepository() => _instance;
  BluetoothRepository._internal();

  StreamSubscription<List<fbp.ScanResult>>? _scanSubscription;
  StreamSubscription<fbp.BluetoothConnectionState>? _connectionSubscription;
  fbp.BluetoothDevice? _connectedDevice;

  /// Stream para escuchar cambios en el estado de Bluetooth
  Stream<fbp.BluetoothAdapterState> get adapterStateStream =>
      fbp.FlutterBluePlus.adapterState;

  /// Verifica el estado actual de Bluetooth
  Future<BluetoothStatus> checkBluetoothStatus() async {
    try {
      final state = await fbp.FlutterBluePlus.adapterState.first;
      return _mapAdapterState(state);
    } catch (e) {
      return BluetoothStatus.unknown;
    }
  }

  /// Mapea el estado del adaptador a nuestro enum
  BluetoothStatus _mapAdapterState(fbp.BluetoothAdapterState state) {
    switch (state) {
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

  /// Solicita activar Bluetooth (solo Android)
  Future<void> requestEnableBluetooth() async {
    try {
      if (await fbp.FlutterBluePlus.isSupported == false) {
        throw Exception('Bluetooth no soportado en este dispositivo');
      }
      await fbp.FlutterBluePlus.turnOn();
    } catch (e) {
      throw Exception('Error al activar Bluetooth: $e');
    }
  }

  /// Verifica y solicita permisos de ubicación
  Future<bool> requestLocationPermission() async {
    try {
      final status = await Permission.locationWhenInUse.request();
      return status.isGranted;
    } catch (e) {
      return false;
    }
  }

  /// Verifica y solicita permisos de Bluetooth
  Future<bool> requestBluetoothPermissions() async {
    try {
      // Android 12+ requiere permisos específicos
      final Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
      ].request();

      return statuses.values.every((status) => status.isGranted);
    } catch (e) {
      // En versiones anteriores de Android o iOS, estos permisos no existen
      return true;
    }
  }

  /// Verifica si los permisos ya están concedidos
  Future<bool> hasLocationPermission() async {
    final status = await Permission.locationWhenInUse.status;
    return status.isGranted;
  }

  Future<bool> hasBluetoothPermissions() async {
    try {
      final scanStatus = await Permission.bluetoothScan.status;
      final connectStatus = await Permission.bluetoothConnect.status;
      return scanStatus.isGranted && connectStatus.isGranted;
    } catch (e) {
      return true; // En plataformas que no requieren estos permisos
    }
  }

  /// Inicia el escaneo de dispositivos BLE
  Stream<List<BleDeviceModel>> startScan({Duration timeout = const Duration(seconds: 15)}) async* {
    try {
      // Detener escaneo previo si existe
      await stopScan();

      // Iniciar escaneo
      await fbp.FlutterBluePlus.startScan(
        timeout: timeout,
        androidUsesFineLocation: true,
      );

      // Escuchar resultados del escaneo
      await for (final results in fbp.FlutterBluePlus.scanResults) {
        final devices = results
            .map((result) => BleDeviceModel.fromScanResult(result))
            .toList();
        yield devices;
      }
    } catch (e) {
      throw Exception('Error al escanear dispositivos: $e');
    }
  }

  /// Detiene el escaneo de dispositivos
  Future<void> stopScan() async {
    try {
      await fbp.FlutterBluePlus.stopScan();
      await _scanSubscription?.cancel();
      _scanSubscription = null;
    } catch (e) {
      // Ignorar errores al detener escaneo
    }
  }

  /// Conecta a un dispositivo BLE
  Future<void> connectToDevice(fbp.BluetoothDevice device) async {
    try {
      // Asegurar que el escaneo está detenido
      await stopScan();
      
      // Pequeña pausa para permitir que el stack de Bluetooth se estabilice (crucial en algunos Android)
      await Future.delayed(const Duration(milliseconds: 200));

      // Intentar conectar
      await device.connect(
        timeout: const Duration(seconds: 10), // Reducir timeout para fallar más rápido si no responde
        autoConnect: false, // false es más rápido para conexiones directas
        mtu: null, // Dejar que negocie automáticamente
      );
      
      _connectedDevice = device;
      
      // Solicitar MTU más alto para mejorar velocidad de transferencia (opcional pero recomendado)
      if (Platform.isAndroid) {
        try {
          await device.requestMtu(512);
        } catch (e) {
          // Ignorar si falla, no es crítico
        }
      }
    } catch (e) {
      throw Exception('Error al conectar con el dispositivo: $e');
    }
  }

  /// Desconecta del dispositivo actual
  Future<void> disconnect() async {
    try {
      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
        await _connectionSubscription?.cancel();
        _connectionSubscription = null;
        _connectedDevice = null;
      }
    } catch (e) {
      throw Exception('Error al desconectar: $e');
    }
  }

  /// Escucha cambios en el estado de conexión
  Stream<fbp.BluetoothConnectionState> listenConnectionState(fbp.BluetoothDevice device) {
    return device.connectionState;
  }

  /// Obtiene el dispositivo conectado actualmente
  fbp.BluetoothDevice? get connectedDevice => _connectedDevice;

  /// Descubre servicios y características del dispositivo conectado
  Future<List<fbp.BluetoothService>> discoverServices() async {
    try {
      if (_connectedDevice == null) {
        throw Exception('No hay dispositivo conectado');
      }
      
      // Descubrir servicios
      final services = await _connectedDevice!.discoverServices();
      return services;
    } catch (e) {
      throw Exception('Error al descubrir servicios: $e');
    }
  }

  /// Suscribe a notificaciones de una característica
  Future<void> subscribeToCharacteristic(fbp.BluetoothCharacteristic characteristic) async {
    try {
      if (!characteristic.properties.notify && !characteristic.properties.indicate) {
        throw Exception('Esta característica no soporta notificaciones');
      }

      // Habilitar notificaciones
      await characteristic.setNotifyValue(true);
    } catch (e) {
      throw Exception('Error al suscribirse a la característica: $e');
    }
  }

  /// Desuscribe de notificaciones de una característica
  Future<void> unsubscribeFromCharacteristic(fbp.BluetoothCharacteristic characteristic) async {
    try {
      await characteristic.setNotifyValue(false);
    } catch (e) {
      throw Exception('Error al desuscribirse de la característica: $e');
    }
  }

  /// Lee el valor de una característica
  Future<List<int>> readCharacteristic(fbp.BluetoothCharacteristic characteristic) async {
    try {
      if (!characteristic.properties.read) {
        throw Exception('Esta característica no soporta lectura');
      }
      
      final value = await characteristic.read();
      return value;
    } catch (e) {
      throw Exception('Error al leer característica: $e');
    }
  }

  /// Escribe un valor en una característica
  Future<void> writeCharacteristic(
    fbp.BluetoothCharacteristic characteristic,
    List<int> value,
    {bool withResponse = true}
  ) async {
    try {
      if (!characteristic.properties.write && !characteristic.properties.writeWithoutResponse) {
        throw Exception('Esta característica no soporta escritura');
      }

      await characteristic.write(value, withoutResponse: !withResponse);
    } catch (e) {
      throw Exception('Error al escribir en característica: $e');
    }
  }

  /// Escucha notificaciones de una característica
  Stream<List<int>> listenToCharacteristic(fbp.BluetoothCharacteristic characteristic) {
    return characteristic.lastValueStream;
  }


  /// Limpia recursos
  Future<void> dispose() async {
    await stopScan();
    await disconnect();
  }
}
