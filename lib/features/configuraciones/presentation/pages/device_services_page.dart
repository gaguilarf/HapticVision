import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import '../viewmodels/bluetooth_viewmodel.dart';
import '../../data/models/ble_device_model.dart';

/// Página que muestra los servicios y características de un dispositivo BLE conectado
class DeviceServicesPage extends ConsumerStatefulWidget {
  final BleDeviceModel device;

  const DeviceServicesPage({
    super.key,
    required this.device,
  });

  @override
  ConsumerState<DeviceServicesPage> createState() => _DeviceServicesPageState();
}

class _DeviceServicesPageState extends ConsumerState<DeviceServicesPage> {
  List<fbp.BluetoothService>? _services;
  bool _isLoading = true;
  String? _errorMessage;
  fbp.BluetoothCharacteristic? _subscribedCharacteristic;
  List<int>? _lastValue;

  @override
  void initState() {
    super.initState();
    _discoverServices();
  }

  Future<void> _discoverServices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final viewModel = ref.read(bluetoothViewModelProvider.notifier);
      final services = await viewModel.discoverServices();
      
      if (mounted) {
        setState(() {
          _services = services;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleSubscription(fbp.BluetoothCharacteristic characteristic) async {
    final viewModel = ref.read(bluetoothViewModelProvider.notifier);

    try {
      if (_subscribedCharacteristic == characteristic) {
        // Desuscribirse
        await viewModel.unsubscribeFromCharacteristic(characteristic);
        setState(() {
          _subscribedCharacteristic = null;
          _lastValue = null;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Desuscrito de notificaciones'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        // Suscribirse
        await viewModel.subscribeToCharacteristic(characteristic);
        setState(() {
          _subscribedCharacteristic = characteristic;
        });

        // Escuchar notificaciones
        viewModel.listenToCharacteristic(characteristic).listen((value) {
          if (mounted && _subscribedCharacteristic == characteristic) {
            setState(() {
              _lastValue = value;
            });
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Suscrito a notificaciones'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.name),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _discoverServices,
            tooltip: 'Recargar servicios',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Descubriendo servicios...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'Error al descubrir servicios',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _discoverServices,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_services == null || _services!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bluetooth_disabled,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No se encontraron servicios',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Información del valor recibido
        if (_subscribedCharacteristic != null)
          _buildSubscriptionInfo(),
        
        // Lista de servicios
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _services!.length,
            itemBuilder: (context, index) {
              final service = _services![index];
              return _buildServiceCard(service);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionInfo() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notifications_active, color: Colors.green.shade700),
              const SizedBox(width: 8),
              const Text(
                'Suscrito a notificaciones',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'UUID: ${_subscribedCharacteristic!.uuid}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontFamily: 'monospace',
            ),
          ),
          if (_lastValue != null) ...[
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Último valor recibido:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _lastValue!.join(', '),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildServiceCard(fbp.BluetoothService service) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.indigo.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.settings_input_antenna,
            color: Colors.indigo.shade700,
          ),
        ),
        title: const Text(
          'Servicio',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          service.uuid.toString(),
          style: const TextStyle(
            fontSize: 12,
            fontFamily: 'monospace',
          ),
        ),
        children: service.characteristics.isEmpty
            ? [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No hay características disponibles',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              ]
            : service.characteristics
                .map((char) => _buildCharacteristicTile(char))
                .toList(),
      ),
    );
  }

  Widget _buildCharacteristicTile(fbp.BluetoothCharacteristic characteristic) {
    final isSubscribed = _subscribedCharacteristic == characteristic;
    final canNotify = characteristic.properties.notify || characteristic.properties.indicate;
    final canRead = characteristic.properties.read;
    final canWrite = characteristic.properties.write || characteristic.properties.writeWithoutResponse;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSubscribed ? Colors.green.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSubscribed ? Colors.green.shade300 : Colors.grey.shade300,
          width: isSubscribed ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: Icon(
          Icons.bluetooth_connected,
          color: isSubscribed ? Colors.green.shade700 : Colors.indigo,
        ),
        title: const Text(
          'Característica',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              characteristic.uuid.toString(),
              style: const TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                if (canRead) _buildPropertyChip('Read', Colors.blue),
                if (canWrite) _buildPropertyChip('Write', Colors.orange),
                if (canNotify) _buildPropertyChip('Notify', Colors.green),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Botón para seleccionar como favorita (memorizar)
            if (canWrite)
              IconButton(
                icon: Icon(
                  ref.watch(bluetoothViewModelProvider).selectedCharacteristic?.uuid == characteristic.uuid
                      ? Icons.star
                      : Icons.star_border,
                  color: Colors.amber,
                ),
                onPressed: () {
                  final viewModel = ref.read(bluetoothViewModelProvider.notifier);
                  if (ref.read(bluetoothViewModelProvider).selectedCharacteristic?.uuid == characteristic.uuid) {
                    viewModel.clearSelectedCharacteristic();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Característica deseleccionada')),
                    );
                  } else {
                    viewModel.selectCharacteristic(characteristic);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Característica memorizada para control'),
                        backgroundColor: Colors.amber,
                      ),
                    );
                  }
                },
                tooltip: 'Memorizar característica',
              ),
            
            if (canWrite)
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.orange),
                onPressed: () => _showWriteDialog(characteristic),
                tooltip: 'Escribir valor',
              ),
            if (canNotify)
              IconButton(
                icon: Icon(
                  isSubscribed ? Icons.notifications_active : Icons.notifications_none,
                  color: isSubscribed ? Colors.green.shade700 : Colors.grey,
                ),
                onPressed: () => _toggleSubscription(characteristic),
                tooltip: isSubscribed ? 'Desuscribirse' : 'Suscribirse',
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showWriteDialog(fbp.BluetoothCharacteristic characteristic) async {
    final controller = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Escribir Valor (UINT 8)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ingresa un valor entre 0 y 255:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Valor',
                hintText: 'Ej: 100',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final text = controller.text;
              if (text.isEmpty) return;
              
              final value = int.tryParse(text);
              if (value == null || value < 0 || value > 255) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Por favor ingresa un número válido (0-255)'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context);
              await _writeCharacteristic(characteristic, value);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  Future<void> _writeCharacteristic(fbp.BluetoothCharacteristic characteristic, int value) async {
    final viewModel = ref.read(bluetoothViewModelProvider.notifier);
    
    try {
      // Enviar como lista de un solo byte (UINT 8)
      await viewModel.writeCharacteristic(characteristic, [value]);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Valor $value enviado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildPropertyChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color.withOpacity(0.8),
        ),
      ),
    );
  }
}
