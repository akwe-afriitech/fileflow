import 'package:fileflow/components/header.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart'; // Import for QR code generation
import 'package:mobile_scanner/mobile_scanner.dart'; // Import for QR code scanning
import 'package:permission_handler/permission_handler.dart'; // Import for camera permissions

// QR Code Screen Component
class QRCodeScreen extends StatefulWidget {
  final Function(String) setCurrentScreen;

  const QRCodeScreen({super.key, required this.setCurrentScreen});

  @override
  State<QRCodeScreen> createState() => _QRCodeScreenState();
}

class _QRCodeScreenState extends State<QRCodeScreen> {
  String _qrMode = 'generate'; // 'generate' or 'scan'
  String _qrData = 'fileflow_qr_data_example'; // Data to be encoded in the QR code
  MobileScannerController cameraController = MobileScannerController();
  String? _scannedCode;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      // Permission granted, nothing to do here specifically for initial load
    } else if (status.isDenied) {
      // Permission denied
      _showPermissionDeniedDialog('Camera permission is required to scan QR codes.');
    } else if (status.isPermanentlyDenied) {
      // Permission permanently denied, open app settings
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

  @override
  void dispose() {
    cameraController.dispose();
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
                            cameraController.stop(); // Stop scanner when switching to generate
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
                            await _requestCameraPermission(); // Request permission when switching to scan
                            if (await Permission.camera.isGranted) {
                              cameraController.start(); // Start scanner if permission granted
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
                        data: _qrData, // Your data to be encoded
                        version: QrVersions.auto,
                        size: 180.0,
                        backgroundColor: Colors.white,
                        gapless: true,
                        // You can customize colors further
                        // dataModuleStyle: const QrDataModuleStyle(
                        //   dataModuleShape: QrDataModuleShape.square,
                        //   color: Colors.black,
                        // ),
                        // eyeStyle: const QrEyeStyle(
                        //   eyeShape: QrEyeShape.square,
                        //   color: Colors.black,
                        // ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Share this QR code with another device to receive files.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      // Logic to generate new QR.
                      // For example, you might update _qrData with new information.
                      // setState(() {
                      //   _qrData = 'new_data_${DateTime.now().millisecondsSinceEpoch}';
                      // });
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
                    child: ClipRRect( // Clip to apply border radius to camera view
                      borderRadius: BorderRadius.circular(12),
                      child: MobileScanner(
                        controller: cameraController,
                        onDetect: (capture) {
                          final List<Barcode> barcodes = capture.barcodes;
                          for (final barcode in barcodes) {
                            debugPrint('Barcode found! ${barcode.rawValue}');
                            setState(() {
                              _scannedCode = barcode.rawValue;
                            });
                            // You can add logic here to navigate or process the scanned data
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Scanned: ${barcode.rawValue}')),
                            );
                            cameraController.stop(); // Stop scanning after first detection
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _scannedCode != null
                        ? "Scanned Data: $_scannedCode"
                        : "Point your camera at a QR code to initiate a transfer.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () async {
                      await _requestCameraPermission();
                      if (await Permission.camera.isGranted) {
                        cameraController.start(); // Restart scanner
                        setState(() {
                          _scannedCode = null; // Clear previous scan
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
              ],
            ),
          ),
        ),
      ],
    );
  }
}