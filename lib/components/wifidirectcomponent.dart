import 'package:flutter/material.dart';

class WiFiDirectScreen extends StatefulWidget {
  final Function(String) setCurrentScreen;

  const WiFiDirectScreen({super.key, required this.setCurrentScreen});

  @override
  State<WiFiDirectScreen> createState() => _WiFiDirectScreenState();
}

class _WiFiDirectScreenState extends State<WiFiDirectScreen> {
  List<Map<String, String>> _devices = [
    {'id': '1', 'name': 'John\'s Phone', 'status': 'Available'},
    {'id': '2', 'name': 'Office Tablet', 'status': 'Available'},
    {'id': '3', 'name': 'My Laptop', 'status': 'Connected'},
  ];

  void _handleConnect(String deviceId) {
    setState(() {
      _devices = _devices.map((device) {
        if (device['id'] == deviceId) {
          return {...device, 'status': 'Connecting...'};
        }
        return device;
      }).toList();
    });

    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _devices = _devices.map((device) {
          if (device['id'] == deviceId) {
            return {...device, 'status': 'Connected'};
          }
          return device;
        }).toList();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wi-Fi Direct Devices'),
      ),
      body: ListView.builder(
        itemCount: _devices.length,
        itemBuilder: (context, index) {
          final device = _devices[index];
          return ListTile(
            title: Text(device['name'] ?? ''),
            subtitle: Text(device['status'] ?? ''),
            trailing: device['status'] == 'Available'
                ? ElevatedButton(
                    onPressed: () => _handleConnect(device['id'] ?? ''),
                    child: const Text('Connect'),
                  )
                : null,
          );
        },
      ),
    );
  }
}
