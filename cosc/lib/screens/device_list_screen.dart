import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/local_storage_service.dart';

class DeviceListScreen extends StatefulWidget {
  const DeviceListScreen({Key? key}) : super(key: key);

  @override
  State<DeviceListScreen> createState() => _DeviceListScreenState();
}

class _DeviceListScreenState extends State<DeviceListScreen> {
  late Future<List<PairedDevice>> _pairedDevices;

  @override
  void initState() {
    super.initState();
    _refreshDevices();
  }

  void _refreshDevices() {
    setState(() {
      _pairedDevices = LocalStorageService.getPairedDevices();
    });
  }

  Future<void> _unpairDevice(PairedDevice device) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unpair Device'),
        content: Text('Are you sure you want to unpair ${device.deviceName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Unpair'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await LocalStorageService.removePairedDevice(device.id);
      _refreshDevices();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${device.deviceName} unpaired')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paired Devices'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<PairedDevice>>(
        future: _pairedDevices,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          final devices = snapshot.data ?? [];

          if (devices.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.devices,
                    size: 48,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No paired devices yet',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.of(context).pushNamed('/pairing-request'),
                    icon: const Icon(Icons.add),
                    label: const Text('Pair New Device'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: (_) async => _refreshDevices(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final device = devices[index];
                return Card(
                  child: ListTile(
                    leading: Icon(
                      device.deviceType == 'ios'
                          ? Icons.phone_iphone
                          : Icons.phone_android,
                      color: device.isConnected ? Colors.green : Colors.grey,
                    ),
                    title: Text(device.deviceName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Serial: ${device.deviceSerial}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          device.isConnected ? 'Connected' : 'Offline',
                          style: TextStyle(
                            fontSize: 12,
                            color: device.isConnected
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          child: const Text('Edit'),
                          onTap: () {
                            // TODO: Implement edit device screen
                          },
                        ),
                        PopupMenuItem(
                          child: const Text('Unpair'),
                          onTap: () => _unpairDevice(device),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).pushNamed('/pairing-request'),
        icon: const Icon(Icons.add),
        label: const Text('Pair Device'),
      ),
    );
  }
}
