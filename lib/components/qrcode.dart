import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:fileflow/components/header.dart';
import 'package:fileflow/services/changenotifier.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

class QRCodeScreen extends StatefulWidget {
  final Function(String) setCurrentScreen;
  const QRCodeScreen({super.key, required this.setCurrentScreen});

  @override
  State<QRCodeScreen> createState() => _QRCodeScreenState();
}

class _QRCodeScreenState extends State<QRCodeScreen> {
  String _qrMode = 'generate';
  String _qrData = '';
  final MobileScannerController cameraController = MobileScannerController();

  ServerSocket? _serverSocket;

  String _transferStatusText = '';
  bool _isTransferring = false;
  double _transferProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _initServer();
  }

    Future<void> _requestPermissions() async {
    await Permission.camera.request();
    if (Platform.isAndroid) {
      await Permission.storage.request();
    }
  }


  Future<void> _initServer() async {
    // UPDATED: Get the service instance. `listen: false` is crucial in initState.
    final connectionService = Provider.of<ConnectionService>(context, listen: false);

    try {
      final addresses = await NetworkInterface.list(type: InternetAddressType.IPv4, includeLoopback: false);
      if (addresses.isNotEmpty && addresses.first.addresses.isNotEmpty) {
        final ip = addresses.first.addresses.first.address;
        // Close any existing server before starting a new one
        await _serverSocket?.close();
        _serverSocket = await ServerSocket.bind(ip, 0);
        final port = _serverSocket!.port;
        if (mounted) setState(() => _qrData = '$ip:$port');

        _serverSocket!.listen((client) {
          // UPDATED: When a client connects, we tell the global service about it.
          // The service will then notify all other screens.
          connectionService.setConnection(client);
          _listenForData(client);
        });
      }
    } catch (e) {
      if (mounted) setState(() => _transferStatusText = 'Error starting server: $e');
    }
  }

   Future<void> _connectToServer(String data) async {
    // UPDATED: Get the service instance.
    final connectionService = Provider.of<ConnectionService>(context, listen: false);
    try {
      final parts = data.split(':');
      if (parts.length != 2) throw Exception('Invalid QR data');
      final ip = parts[0];
      final port = int.parse(parts[1]);
      final socket = await Socket.connect(ip, port, timeout: const Duration(seconds: 5));
      
      // UPDATED: When we successfully connect, update the global service.
      connectionService.setConnection(socket);
      _listenForData(socket);

    } catch (e) {
      if (mounted) setState(() => _transferStatusText = 'Connection failed: $e');
    }
  }


 Future<void> _sendFile(Socket? clientSocket) async {
    if (clientSocket == null || _isTransferring) return;

    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      File file = File(result.files.single.path!);
      final fileName = result.files.single.name;
      final fileSize = await file.length();
      
      try {
        setState(() {
          _isTransferring = true;
          _transferStatusText = 'Sending: $fileName';
          _transferProgress = 0.0;
        });

        final metadata = {'filename': fileName, 'filesize': fileSize};
        final metadataJson = jsonEncode(metadata);
        clientSocket.writeln(metadataJson);
        await clientSocket.flush();

        int bytesSent = 0;
        await for (var chunk in file.openRead()) {
          clientSocket.add(chunk);
          bytesSent += chunk.length;
          if (mounted) setState(() => _transferProgress = bytesSent / fileSize);
        }
        await clientSocket.flush();
        if (mounted) setState(() => _transferStatusText = 'File sent successfully!');
      } catch (e) {
        if (mounted) setState(() => _transferStatusText = 'Error sending file: $e');
      } finally {
        if (mounted) setState(() => _isTransferring = false);
      }
    }
  }


 // In your _QRCodeScreenState class

void _listenForData(Socket socket) {
  List<int> buffer = [];
  String? fileName;
  int? fileSize;
  IOSink? fileSink;
  int bytesReceived = 0;
  final completer = Completer<void>();

  socket.listen(
    (data) {
      if (fileName == null) {
        buffer.addAll(data);
        int newlineIndex = buffer.indexOf(10); // 10 is the byte value for '\n'
        if (newlineIndex != -1) {
          final metadataJson = utf8.decode(buffer.sublist(0, newlineIndex)).trim();
          final remainingData = buffer.sublist(newlineIndex + 1);
          buffer.clear();

          final metadata = jsonDecode(metadataJson);
          fileName = metadata['filename'];
          fileSize = metadata['filesize'];

          if (mounted) {
            setState(() {
              _isTransferring = true;
              _transferStatusText = 'Receiving: $fileName';
              _transferProgress = 0.0;
            });
          }
          _prepareFileSink(fileName!).then((file) {
            if (file != null) {
              fileSink = file.openWrite();
              // Write any data that came in the same chunk as the metadata
              if (remainingData.isNotEmpty) {
                fileSink?.add(remainingData);
                bytesReceived += remainingData.length;
              }
            }
            // IMPORTANT: Complete the completer even if the file is null to prevent deadlocks
            completer.complete();
          });
        }
      } else {
        fileSink?.add(data);
        bytesReceived += data.length;
        if (fileSize != null && fileSize! > 0 && mounted) {
          setState(() => _transferProgress = bytesReceived / fileSize!);
        }
      }
    },
    onDone: () async {
      await completer.future; // This is crucial and you already had it - great job!
      await fileSink?.flush();
      await fileSink?.close();
      
      // FIX: Use the context if it's still mounted
      if(mounted) {
        Provider.of<ConnectionService>(context, listen: false).disconnect();
        setState(() {
          _transferStatusText = 'File received successfully!';
          _isTransferring = false;
        });
      }
      socket.destroy();
    },
    onError: (error) {
      fileSink?.close();
      if(mounted) {
        Provider.of<ConnectionService>(context, listen: false).disconnect();
        setState(() {
          _transferStatusText = 'Error receiving file: $error';
          _isTransferring = false;
        });
      }
      socket.destroy();
    },
    cancelOnError: true,
  );
}

Future<File?> _prepareFileSink(String fileName) async {
  try {
    // 1. Get the app's private external storage directory
    final directory = await getExternalStorageDirectory();
    if (directory == null) {
      throw Exception("Could not get external storage directory");
    }

    // 2. Create a custom folder inside it if you want
    final saveDir = Directory('${directory.path}/downloads');
    if (!await saveDir.exists()) {
      await saveDir.create(recursive: true);
    }

    // 3. Create the file path and return the File object
    final filePath = '${saveDir.path}/$fileName';
    
    // Log the path so you know exactly where to find the file
    debugPrint('File will be saved to: $filePath');
    
    return File(filePath);

  } catch (e) {
    if (mounted) setState(() => _transferStatusText = "Error preparing file: $e");
    return null;
  }
}

  @override
  void dispose() {
    cameraController.dispose();
    _serverSocket?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    
    return Consumer<ConnectionService>(
      builder: (context, connectionService, child) {
        // 'connectionService' is the instance of our global state.
        return Column(
          children: [
            AppHeader(
                title: "QR Share",
                onBack: () => widget.setCurrentScreen('home')),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildModeSwitcher(),
                      const SizedBox(height: 32),

                      if (_qrMode == 'generate')
                        _buildGenerateUIContent(connectionService)
                      else
                        _buildScanUIContent(connectionService),

                      if (_isTransferring) ...[
                        const SizedBox(height: 24),
                        Text(_transferStatusText,
                            style: const TextStyle(
                                fontSize: 16, color: Colors.blueAccent)),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: _transferProgress,
                          backgroundColor: Colors.grey[300],
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Colors.green),
                        ),
                      ],
                      // UPDATED: This button's visibility is now controlled by the global service.
                      if (connectionService.isConnected &&
                          !_isTransferring) ...[
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.send),
                          label: const Text("Send File",
                              style: TextStyle(fontSize: 16)),
                          // UPDATED: We pass the socket from the service to the send function.
                          onPressed: () => _sendFile(connectionService.socket),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildModeSwitcher() {
    return Container(
      decoration: BoxDecoration(
          color: Colors.grey[200], borderRadius: BorderRadius.circular(30)),
      padding: const EdgeInsets.all(4.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildModeButton('generate', 'Generate QR'),
          _buildModeButton('scan', 'Scan QR'),
        ],
      ),
    );
  }

  Widget _buildModeButton(String mode, String text) {
    bool isActive = _qrMode == mode;
    return Expanded(
      child: ElevatedButton(
        onPressed: () {
          setState(() => _qrMode = mode);
          if (mode == 'generate') {
            cameraController.stop();
          } else {
            Permission.camera.isGranted.then((granted) {
              if (granted) {
                cameraController.start();
              }
            });
          }
        },
        style: ElevatedButton.styleFrom(
          foregroundColor: isActive ? Colors.white : Colors.grey[700],
          backgroundColor: isActive ? Colors.blue[600] : Colors.transparent,
          elevation: isActive ? 4 : 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(text, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _buildGenerateUIContent(ConnectionService connectionService) {
    return Column(
      children: [
        SizedBox(
          width: 200,
          height: 200,
          child: QrImageView(
            data: _qrData.isEmpty ? 'waiting_for_ip' : _qrData,
            version: QrVersions.auto,
            size: 200.0,
            backgroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          // UPDATED: Text reads directly from the global service's status.
          connectionService.isConnected
              ? connectionService.status
              : "Share this QR code to connect.",
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 16,
              color:
                  connectionService.isConnected ? Colors.green : Colors.grey),
        ),
      ],
    );
  }

  Widget _buildScanUIContent(ConnectionService connectionService) {
    return Column(
      children: [
        SizedBox(
          width: 200,
          height: 200,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: MobileScanner(
              controller: cameraController,
              onDetect: (capture) {
                // UPDATED: Check the global service to see if we're already connected.
                if (connectionService.isConnected) return;
                final code = capture.barcodes.first.rawValue;
                if (code != null) {
                  cameraController.stop();
                  _connectToServer(code);
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          // UPDATED: Text reads directly from the global service's status.
          connectionService.isConnected
              ? connectionService.status
              : "Point camera at a QR code.",
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 16,
              color:
                  connectionService.isConnected ? Colors.green : Colors.grey),
        ),
      ],
    );
  }
}
