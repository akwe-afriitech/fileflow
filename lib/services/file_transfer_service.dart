import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:bonsoir/bonsoir.dart';
import 'package:device_info_plus/device_info_plus.dart';

// A simple model to represent a discovered service on the network.
class DiscoveredDevice {
  final String name;
  final String ip;
  final int port;
  String status; 

  DiscoveredDevice({
    required this.name,
    required this.ip,
    required this.port,
    this.status = 'Available',
  });

  // Optional: For easy debugging and checking for duplicates.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiscoveredDevice &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          ip == other.ip &&
          port == other.port;

  @override
  int get hashCode => name.hashCode ^ ip.hashCode ^ port.hashCode;
}

class FileTransferService {
  ServerSocket? _serverSocket;
  BonsoirBroadcast? _broadcast;
  BonsoirDiscovery? _discovery;

  // This will be the unique service type for your app
  static const String _serviceType = '_fileflow._tcp';

  final _devicesController = StreamController<List<DiscoveredDevice>>.broadcast();
  Stream<List<DiscoveredDevice>> get devicesStream => _devicesController.stream;

  final _serverInfoController = StreamController<String>.broadcast();
  Stream<String> get serverInfoStream => _serverInfoController.stream;

  final List<DiscoveredDevice> _discoveredDevices = [];

  // Get a unique device name for broadcasting
  Future<String> _getDeviceName() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.model; // "Pixel 5"
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.name; // "My iPhone"
    }
    return 'Unknown Device';
  }

  // == BROADCASTING (WHEN YOU HOST A SERVER) ==
  Future<void> startServer({required Function(Socket) onFileReceived}) async {
    if (_serverSocket != null) return; // Already running

    try {
      _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
      _serverSocket!.listen(onFileReceived);

      final int port = _serverSocket!.port;
      final String deviceName = await _getDeviceName();
      
      _serverInfoController.add('Hosting on "$deviceName" at port $port...');

      // Start broadcasting with Bonsoir
      final service = BonsoirService(
        name: deviceName,
        type: _serviceType,
        port: port,
      );
      _broadcast = BonsoirBroadcast(service: service);
      await _broadcast!.ready;
      await _broadcast!.start();
      
      _serverInfoController.add('Visible to others on the network!');

    } catch (e) {
      _serverInfoController.add('Error starting server: $e');
      await stopServer();
    }
  }

  Future<void> stopServer() async {
    await _broadcast?.stop();
    _broadcast = null;
    await _serverSocket?.close();
    _serverSocket = null;
    _serverInfoController.add('Press "Make Visible" to host.');
  }


  // == DISCOVERY (WHEN YOU SCAN FOR DEVICES) ==
  Future<void> startDiscovery() async {
    if (_discovery != null) {
      await stopDiscovery(); 
    }
    
    _discoveredDevices.clear();
    _devicesController.add(_discoveredDevices);

    _discovery = BonsoirDiscovery(type: _serviceType);
    await _discovery!.ready;

    _discovery!.eventStream!.listen((event) {
      if (event.type == BonsoirDiscoveryEventType.discoveryServiceFound ||
          event.type == BonsoirDiscoveryEventType.discoveryServiceResolved) {
        if (event.service?.type != null && event.service is BonsoirService) {
            final service = event.service as BonsoirService;
            final newDevice = DiscoveredDevice(
              name: service.name,
              ip: service.type,
              port: service.port,
            );
            
            // Avoid adding duplicates
            if (!_discoveredDevices.contains(newDevice)) {
              _discoveredDevices.add(newDevice);
              _devicesController.add(List.from(_discoveredDevices));
            }
        }
      } else if (event.type == BonsoirDiscoveryEventType.discoveryServiceLost) {
        if (event.service is BonsoirService) {
           final service = event.service as BonsoirService;
           _discoveredDevices.removeWhere((d) => d.name == service.name && d.port == service.port);
           _devicesController.add(List.from(_discoveredDevices));
        }
      }
    });

    await _discovery!.start();
  }
  
  Future<void> stopDiscovery() async {
     await _discovery?.stop();
     _discovery = null;
  }

  // == CONNECTING AND SENDING ==
  Future<void> connectAndSendFile(DiscoveredDevice device, File file) async {
    try {
      // Use the IP and Port from the discovered device
      final socket = await Socket.connect(device.ip, device.port);

      // 1. Prepare metadata
      final fileName = file.path.split('/').last;
      final fileSize = await file.length();
      final metadata = {'filename': fileName, 'filesize': fileSize};
      final metadataJson = jsonEncode(metadata);

      // 2. Send metadata first
      socket.write(metadataJson);
      await socket.flush(); 
      await Future.delayed(const Duration(milliseconds: 100)); // Small delay

      // 3. Send the actual file content
      final fileStream = file.openRead();
      await socket.addStream(fileStream);

      // 4. Clean up
      await socket.flush();
      socket.destroy();
      debugPrint('File sent successfully.');

    } catch (e) {
      debugPrint('Error sending file: $e');
    }
  }
  
  void dispose() {
    stopServer();
    stopDiscovery();
    _devicesController.close();
    _serverInfoController.close();
  }
}
