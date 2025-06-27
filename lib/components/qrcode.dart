import 'dart:io';
import 'package:fileflow/components/header.dart';
import 'package:flutter/material.dart';
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
  MobileScannerController cameraController = MobileScannerController();
  String? _scannedCode;

  ServerSocket? _serverSocket;
  Socket? _clientSocket;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
    _initServer();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      // Permission granted
    } else if (status.isDenied) {
      _showPermissionDeniedDialog('Camera permission is required to scan QR codes.');
    } else if (status.isPermanentlyDenied) {
      _showPermissionDeniedDialog('Camera permission is permanently denied. Please enable it from app settings to scan QR codes.');
      openAppSettings();
    }
  }

  void _showPermissionDeniedDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Denied'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _initServer() async {
    // Start a server socket and encode its address in the QR code
    final addresses = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
    );
    if (addresses.isNotEmpty && addresses.first.addresses.isNotEmpty) {
      final ip = addresses.first.addresses.first.address;
      _serverSocket = await ServerSocket.bind(ip, 0); // 0 = random port
      final port = _serverSocket!.port;
      setState(() {
        _qrData = '$ip:$port';
      });
      _serverSocket!.listen((client) {
        setState(() {
          _isConnected = true;
        });
        _clientSocket = client;
        // You can now send/receive files using _clientSocket
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Device connected! Ready to transfer files.')),
        );
      });
    }
  }

  Future<void> _connectToServer(String data) async {
    try {
      final parts = data.split(':');
      if (parts.length != 2) throw Exception('Invalid QR data');
      final ip = parts[0];
      final port = int.parse(parts[1]);
      final socket = await Socket.connect(ip, port, timeout: const Duration(seconds: 5));
      setState(() {
        _isConnected = true;
        _clientSocket = socket;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connected! Ready to transfer files.')),
      );
      // You can now send/receive files using _clientSocket
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection failed: $e')),
      );
    }
  }

  @override
  void dispose() {
    cameraController.dispose();
    _serverSocket?.close();
    _clientSocket?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppHeader(title: "QR Share", onBack: () => widget.setCurrentScreen('home')),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ... (mode switch buttons, unchanged)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.all(4.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => setState(() {
                            _qrMode = 'generate';
                            cameraController.stop();
                          }),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: _qrMode == 'generate' ? Colors.white : Colors.grey[700],
                            backgroundColor: _qrMode == 'generate' ? Colors.blue[600] : Colors.transparent,
                            elevation: _qrMode == 'generate' ? 4 : 0,
                            shadowColor: _qrMode == 'generate' ? Colors.blue[200] : Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text("Generate QR", style: TextStyle(fontSize: 16)),
                        ),
                      ),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            setState(() => _qrMode = 'scan');
                            await _requestCameraPermission();
                            if (await Permission.camera.isGranted) {
                              cameraController.start();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: _qrMode == 'scan' ? Colors.white : Colors.grey[700],
                            backgroundColor: _qrMode == 'scan' ? Colors.blue[600] : Colors.transparent,
                            elevation: _qrMode == 'scan' ? 4 : 0,
                            shadowColor: _qrMode == 'scan' ? Colors.blue[200] : Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text("Scan QR", style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                if (_qrMode == 'generate') ...[
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: QrImageView(
                        data: _qrData.isEmpty ? 'waiting_for_ip' : _qrData,
                        version: QrVersions.auto,
                        size: 180.0,
                        backgroundColor: Colors.white,
                        gapless: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _isConnected
                        ? "Device connected! Ready to transfer files."
                        : "Share this QR code with another device to connect.",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      // Optionally regenerate QR (restart server)
                      _serverSocket?.close();
                      setState(() {
                        _isConnected = false;
                        _qrData = '';
                      });
                      _initServer();
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white, backgroundColor: Colors.blue[600],
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      elevation: 3,
                    ),
                    child: const Text("Generate New QR",
                        style: TextStyle(fontSize: 16)),
                  ),
                ],
                if (_qrMode == 'scan') ...[
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: MobileScanner(
                        controller: cameraController,
                        onDetect: (capture) async {
                          final List<Barcode> barcodes = capture.barcodes;
                          for (final barcode in barcodes) {
                            if (_isConnected) return;
                            final code = barcode.rawValue;
                            debugPrint('Barcode found! $code');
                            setState(() {
                              _scannedCode = code;
                            });
                            cameraController.stop();
                            if (code != null) {
                              await _connectToServer(code);
                            }
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _isConnected
                        ? "Connected! Ready to transfer files."
                        : (_scannedCode != null
                            ? "Scanned Data: $_scannedCode"
                            : "Point your camera at a QR code to connect."),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () async {
                      await _requestCameraPermission();
                      if (await Permission.camera.isGranted) {
                        cameraController.start();
                        setState(() {
                          _scannedCode = null;
                          _isConnected = false;
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white, backgroundColor: Colors.blue[600],
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      elevation: 3,
                    ),
                    child:
                    const Text("Activate Scanner", style: TextStyle(fontSize: 16)),
                  ),
                ],
                if (_isConnected) ...[
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Implement file picker and send file over _clientSocket
                      // Example: _clientSocket?.add(fileBytes);
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white, backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      elevation: 3,
                    ),
                    child: const Text("Send File", style: TextStyle(fontSize: 16)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}