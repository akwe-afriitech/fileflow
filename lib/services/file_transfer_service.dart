import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:bonsoir/bonsoir.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart' as file_picker;
import 'package:encrypt/encrypt.dart' as encrypt;

// --- DATA MODELS ---

/// Enum to represent different file types for displaying icons.
enum FileType { image, video, audio, document, archive, other }

/// A model representing a single completed transfer.
class Transfer {
  final String id;
  final String fileName;
  final double fileSizeInMB;
  final DateTime transferDate;
  final String sourceDeviceName;
  final FileType fileType;
  final String direction; // "Sent" or "Received"

  Transfer({
    required this.id,
    required this.fileName,
    required this.fileSizeInMB,
    required this.transferDate,
    required this.sourceDeviceName,
    required this.fileType,
    required this.direction,
  });
}

/// A model to represent a discovered service on the network.
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

// --- MAIN SERVICE CLASS ---

class FileTransferService {
  ServerSocket? _serverSocket;
  BonsoirBroadcast? _broadcast;
  BonsoirDiscovery? _discovery;

  static const String _serviceType = '_fileflow._tcp';

  // Streams for consumers
  final _devicesController = StreamController<List<DiscoveredDevice>>.broadcast();
  Stream<List<DiscoveredDevice>> get devicesStream => _devicesController.stream;

  final _serverInfoController = StreamController<String>.broadcast();
  Stream<String> get serverInfoStream => _serverInfoController.stream;

  // ** NEW: Stream for recent transfers **
  final _transfersController = StreamController<List<Transfer>>.broadcast();
  Stream<List<Transfer>> get transfersStream => _transfersController.stream;
  
  // Private lists to hold state
  final List<DiscoveredDevice> _discoveredDevices = [];
  final List<Transfer> _recentTransfers = [];


  // --- DEVICE & NETWORK METHODS ---

  Future<String> _getDeviceName() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.model;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.name;
    }
    return 'Unknown Device';
  }

  Future<void> startServer({required Function(Socket) onFileReceived}) async {
    if (_serverSocket != null) return;
    try {
      _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
      _serverSocket!.listen(onFileReceived);

      final port = _serverSocket!.port;
      final deviceName = await _getDeviceName();
      
      _serverInfoController.add('Hosting on "$deviceName" at port $port...');

      final service = BonsoirService(name: deviceName, type: _serviceType, port: port);
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
    await _serverSocket?.close();
    _broadcast = null;
    _serverSocket = null;
    _serverInfoController.add('Press "Make Visible" to host.');
  }

  Future<void> startDiscovery() async {
    if (_discovery != null) await stopDiscovery();
    
    _discoveredDevices.clear();
    _devicesController.add(_discoveredDevices);

    _discovery = BonsoirDiscovery(type: _serviceType);
    await _discovery!.ready;

    _discovery!.eventStream!.listen((event) {
      if (event.type == BonsoirDiscoveryEventType.discoveryServiceResolved && event.service?.type != null) {
        final service = event.service as BonsoirService;
        final newDevice = DiscoveredDevice(name: service.name, ip: service.type, port: service.port);
        
        if (!_discoveredDevices.contains(newDevice)) {
          _discoveredDevices.add(newDevice);
          _devicesController.add(List.from(_discoveredDevices));
        }
      } else if (event.type == BonsoirDiscoveryEventType.discoveryServiceLost) {
        final service = event.service;
        if (service != null) {
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

  Future<void> connectAndSendFile(DiscoveredDevice device, File file) async {
    try {
      final socket = await Socket.connect(device.ip, device.port);
      final fileName = file.path.split('/').last;
      final fileSize = await file.length();
      final metadata = {'filename': fileName, 'filesize': fileSize};
      
      socket.write(jsonEncode(metadata));
      await socket.flush();
      await Future.delayed(const Duration(milliseconds: 100));

      await socket.addStream(file.openRead());
      await socket.flush();
      socket.destroy();

      // ** NEW: Log the sent file **
      _logTransfer(
        fileName: fileName,
        fileSizeInBytes: fileSize,
        deviceName: device.name,
        direction: "Sent",
      );

      debugPrint('File sent successfully.');
    } catch (e) {
      debugPrint('Error sending file: $e');
    }
  }
  
  // --- TRANSFER LOGGING METHODS ---

  /// **NEW**: Public method to be called from the UI after a file is received.
  void logReceivedFile({
    required String fileName,
    required int fileSizeInBytes,
    required String sourceDeviceName,
  }) {
    _logTransfer(
      fileName: fileName,
      fileSizeInBytes: fileSizeInBytes,
      deviceName: sourceDeviceName,
      direction: "Received",
    );
  }

  /// **NEW**: Internal helper to create and add a transfer record.
  void _logTransfer({
    required String fileName,
    required int fileSizeInBytes,
    required String deviceName,
    required String direction,
  }) {
    final newTransfer = Transfer(
      id: DateTime.now().toIso8601String(),
      fileName: fileName,
      fileSizeInMB: fileSizeInBytes / (1024 * 1024),
      transferDate: DateTime.now(),
      sourceDeviceName: deviceName,
      fileType: _getFileTypeFromExtension(fileName),
      direction: direction,
    );

    _recentTransfers.insert(0, newTransfer);
    _transfersController.add(List.from(_recentTransfers));
  }
  
  FileType _getFileTypeFromExtension(String fileName) {
      final extension = fileName.split('.').last.toLowerCase();
      if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension)) return FileType.image;
      if (['mp4', 'mov', 'avi', 'mkv'].contains(extension)) return FileType.video;
      if (['mp3', 'wav', 'aac'].contains(extension)) return FileType.audio;
      if (['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt'].contains(extension)) return FileType.document;
      if (['zip', 'rar', '7z', 'tar'].contains(extension)) return FileType.archive;
      return FileType.other;
  }
  
  /// **NEW**: Method to remove a transfer from the list.
  void removeTransfer(String transferId) {
    _recentTransfers.removeWhere((t) => t.id == transferId);
    _transfersController.add(List.from(_recentTransfers));
  }

  // --- DISPOSE ---

  void dispose() {
    stopServer();
    stopDiscovery();
    _devicesController.close();
    _serverInfoController.close();
    _transfersController.close(); // ** NEW **
  }


  /// Encrypts the file bytes using AES encryption.
  Future<List<int>> encryptFileBytes(List<int> fileBytes, String password) async {
    final key = encrypt.Key.fromUtf8(password.padRight(32).substring(0, 32));
    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final encrypted = encrypter.encryptBytes(fileBytes, iv: iv);
    return encrypted.bytes;
  }

  /// Decrypts the file bytes using AES decryption.
  Future<List<int>> decryptFileBytes(List<int> encryptedBytes, String password) async {
    final key = encrypt.Key.fromUtf8(password.padRight(32).substring(0, 32));
    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final decrypted = encrypter.decryptBytes(
      encrypt.Encrypted(Uint8List.fromList(encryptedBytes)),
      iv: iv,
    );
    return decrypted;
  }
}