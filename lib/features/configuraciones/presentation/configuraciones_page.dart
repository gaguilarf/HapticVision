import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'viewmodels/bluetooth_viewmodel.dart';
import 'widgets/bluetooth_status_card.dart';
import 'widgets/ble_device_list_tile.dart';
import '../data/models/bluetooth_state.dart';
import 'pages/device_services_page.dart';

class ConfiguracionesPage extends ConsumerWidget {
  const ConfiguracionesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bluetoothState = ref.watch(bluetoothViewModelProvider);
    final bluetoothViewModel = ref.read(bluetoothViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sección de Feedback Háptico
            _buildSectionHeader('Feedback Háptico'),
            
            // Estado de Bluetooth
            BluetoothStatusCard(
              status: bluetoothState.bluetoothStatus,
              onEnableBluetooth: () {
                bluetoothViewModel.requestEnableBluetooth();
              },
            ),

            // Estado de Permisos
            _buildPermissionsCard(context, bluetoothState, bluetoothViewModel),

            // Botón de Conectar Dispositivo
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: bluetoothState.canScan
                          ? () => _showDeviceScanner(context, ref)
                          : null,
                      icon: const Icon(Icons.bluetooth_searching),
                      label: const Text('Conectar Dispositivo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                    ),
                  ),
                  if (!bluetoothState.canScan) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _getDisabledReason(bluetoothState),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Dispositivo conectado
            if (bluetoothState.isConnected && bluetoothState.connectedDevice != null)
              _buildConnectedDeviceCard(context, bluetoothState, bluetoothViewModel),

            // Mensaje de error
            if (bluetoothState.errorMessage != null)
              _buildErrorCard(bluetoothState.errorMessage!, bluetoothViewModel),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.indigo,
        ),
      ),
    );
  }

  String _getDisabledReason(BluetoothState state) {
    if (state.bluetoothStatus != BluetoothStatus.on) {
      return 'Activa Bluetooth para continuar';
    }
    if (!state.hasAllPermissions) {
      return 'Concede los permisos necesarios para continuar';
    }
    if (state.scanStatus == ScanStatus.scanning) {
      return 'Escaneo en progreso...';
    }
    return 'No disponible';
  }


  Widget _buildPermissionsCard(
    BuildContext context,
    BluetoothState state,
    BluetoothViewModel viewModel,
  ) {
    final hasAllPermissions = state.hasAllPermissions;
    final needsPermissions = !hasAllPermissions;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: hasAllPermissions ? Colors.green.shade300 : Colors.orange.shade300,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasAllPermissions ? Icons.check_circle : Icons.warning_amber_rounded,
                  color: hasAllPermissions ? Colors.green : Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Permisos',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildPermissionRow(
              'Ubicación',
              state.hasLocationPermission,
              Icons.location_on,
            ),
            const SizedBox(height: 8),
            _buildPermissionRow(
              'Bluetooth',
              state.hasBluetoothPermission,
              Icons.bluetooth,
            ),
            if (needsPermissions) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => viewModel.requestPermissions(),
                  icon: const Icon(Icons.lock_open),
                  label: const Text('Solicitar Permisos'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
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

  Widget _buildPermissionRow(String label, bool granted, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: granted ? Colors.green : Colors.grey,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 14),
        ),
        const Spacer(),
        Icon(
          granted ? Icons.check_circle : Icons.cancel,
          size: 18,
          color: granted ? Colors.green : Colors.red.shade300,
        ),
        const SizedBox(width: 4),
        Text(
          granted ? 'Concedido' : 'Requerido',
          style: TextStyle(
            fontSize: 12,
            color: granted ? Colors.green : Colors.red.shade300,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }


  Widget _buildConnectedDeviceCard(
    BuildContext context,
    BluetoothState state,
    BluetoothViewModel viewModel,
  ) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.green.shade400, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.green.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Dispositivo Conectado',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              state.connectedDevice!.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'ID: ${state.connectedDevice!.id}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DeviceServicesPage(device: state.connectedDevice!),
                        ),
                      );
                    },
                    icon: const Icon(Icons.settings_input_antenna),
                    label: const Text('Ver Servicios'),
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
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => viewModel.disconnect(),
                    icon: const Icon(Icons.bluetooth_disabled),
                    label: const Text('Desconectar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(String errorMessage, BluetoothViewModel viewModel) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              errorMessage,
              style: TextStyle(
                color: Colors.red.shade900,
                fontSize: 14,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => viewModel.clearError(),
            color: Colors.red.shade700,
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  void _showDeviceScanner(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DeviceScannerSheet(),
    );
  }
}

/// Sheet modal para escanear y seleccionar dispositivos
class _DeviceScannerSheet extends ConsumerStatefulWidget {
  @override
  ConsumerState<_DeviceScannerSheet> createState() => _DeviceScannerSheetState();
}

class _DeviceScannerSheetState extends ConsumerState<_DeviceScannerSheet> {
  String? _connectingDeviceId;

  @override
  void initState() {
    super.initState();
    // Iniciar escaneo al abrir el sheet
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bluetoothViewModelProvider.notifier).startScan();
    });
  }

  @override
  void dispose() {
    // Detener escaneo al cerrar el sheet
    ref.read(bluetoothViewModelProvider.notifier).stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bluetoothState = ref.watch(bluetoothViewModelProvider);
    final bluetoothViewModel = ref.read(bluetoothViewModelProvider.notifier);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle del sheet
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Dispositivos Disponibles',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(),

          // Estado del escaneo
          if (bluetoothState.scanStatus == ScanStatus.scanning)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Buscando dispositivos...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

          // Lista de dispositivos
          Expanded(
            child: bluetoothState.discoveredDevices.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bluetooth_searching,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          bluetoothState.scanStatus == ScanStatus.scanning
                              ? 'Buscando dispositivos...'
                              : 'No se encontraron dispositivos',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: bluetoothState.discoveredDevices.length,
                    itemBuilder: (context, index) {
                      final device = bluetoothState.discoveredDevices[index];
                      final isConnecting = _connectingDeviceId == device.id;
                      
                      return BleDeviceListTile(
                        device: device,
                        isConnected: bluetoothState.connectedDevice?.id == device.id,
                        isLoading: isConnecting,
                        onTap: _connectingDeviceId != null 
                            ? () {} // Deshabilitar si ya hay uno conectando
                            : () async {
                                setState(() {
                                  _connectingDeviceId = device.id;
                                });

                                try {
                                  // 1. DETENER ESCANEO EXPLÍCITAMENTE PRIMERO
                                  // Esto es crítico: debemos asegurar que el escaneo paró visual y lógicamente
                                  await bluetoothViewModel.stopScan();
                                  
                                  // 2. Esperar un momento para que el chip Bluetooth cambie de modo
                                  // Esto ayuda a que desaparezca el loading de "Buscando..." y libera recursos
                                  await Future.delayed(const Duration(milliseconds: 500));

                                  // 3. Conectar al dispositivo
                                  await bluetoothViewModel.connectToDevice(device);
                                  
                                  if (context.mounted) {
                                    // Cerrar el modal de escaneo
                                    Navigator.pop(context);
                                    
                                    // Navegar a la página de servicios
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => DeviceServicesPage(device: device),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    setState(() {
                                      _connectingDeviceId = null;
                                    });
                                    
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error al conectar: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    
                                    // Si falló, reiniciamos el escaneo para que el usuario pueda intentar de nuevo
                                    bluetoothViewModel.startScan();
                                  }
                                }
                              },
                      );
                    },
                  ),
          ),

          // Botón de reescanear
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: bluetoothState.scanStatus != ScanStatus.scanning
                    ? () => bluetoothViewModel.startScan()
                    : null,
                icon: const Icon(Icons.refresh),
                label: const Text('Reescanear'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
