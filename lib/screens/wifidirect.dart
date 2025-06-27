import 'package:fileflow/components/header.dart';
import 'package:flutter/material.dart';
// Wi-Fi Direct Screen Component

// WiFiDirectScreen widget implementation
class WiFiDirectScreen extends StatefulWidget {
  final void Function(String) setCurrentScreen;
  const WiFiDirectScreen({Key? key, required this.setCurrentScreen})
      : super(key: key);

  @override
  State<WiFiDirectScreen> createState() => _WiFiDirectScreenState();
}

class _WiFiDirectScreenState extends State<WiFiDirectScreen> {
  List<Map<String, String>> _devices = [];

  void _handleConnect(String deviceId) {
    setState(() {
      final idx = _devices.indexWhere((d) => d['id'] == deviceId);
      if (idx != -1) {
        _devices[idx]['status'] = 'Connecting...';
      }
    });
    // Simulate connection delay
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        final idx = _devices.indexWhere((d) => d['id'] == deviceId);
        if (idx != -1) {
          _devices[idx]['status'] = 'Connected';
        }
      });
    });
  }

  @override
  void initState() {
    super.initState();
    // Simulate discovered devices
    _devices = [
      {'id': '1', 'name': 'Device A', 'status': 'Available'},
      {'id': '2', 'name': 'Device B', 'status': 'Available'},
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppHeader(
            title: "Wi-Fi Direct",
            onBack: () => widget.setCurrentScreen('home')),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Text(
                  "Connect directly to nearby devices.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    // Logic to scan for devices
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue[500],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    elevation: 5,
                  ),
                  child: const Text(
                    "Scan for Devices",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Discovered Devices",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87),
                        ),
                        const SizedBox(height: 12),
                        _devices.isEmpty
                            ? const Center(
                                child: Text("No devices found.",
                                    style: TextStyle(color: Colors.grey)),
                              )
                            : Expanded(
                                child: ListView.builder(
                                  itemCount: _devices.length,
                                  itemBuilder: (context, index) {
                                    final device = _devices[index];
                                    final isConnected =
                                        device['status'] == 'Connected';
                                    final isConnecting =
                                        device['status'] == 'Connecting...';
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  device['name']!,
                                                  style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w500),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  "Status: ${device['status']!}",
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: isConnected
                                                        ? Colors.green[600]
                                                        : Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (!isConnected)
                                              ElevatedButton(
                                                onPressed: isConnecting
                                                    ? null
                                                    : () => _handleConnect(
                                                        device['id']!),
                                                style: ElevatedButton.styleFrom(
                                                  foregroundColor: Colors.white,
                                                  backgroundColor:
                                                      Colors.blue[500],
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20)),
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 16,
                                                      vertical: 8),
                                                ),
                                                child: Text(
                                                  isConnecting
                                                      ? "Connecting..."
                                                      : "Connect",
                                                  style: const TextStyle(
                                                      fontSize: 14),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
