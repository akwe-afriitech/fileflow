import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:fileflow/components/header.dart';
import 'package:fileflow/services/file_transfer_service.dart'; // Import the service
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class WiFiDirectScreen extends StatefulWidget {
  final void Function(String) setCurrentScreen;
  const WiFiDirectScreen({Key? key, required this.setCurrentScreen})
      : super(key: key);

  @override
  State<WiFiDirectScreen> createState() => _WiFiDirectScreenState();
}

class _WiFiDirectScreenState extends State<WiFiDirectScreen> {
  final _transferService = FileTransferService();
  String _transferStatusText = 'running......';
  String _serverInfo = 'Press "Make Visible" to host.';
  bool _isHosting = false;

   @override
  void initState() {
    super.initState();
    _requestPermissions();
     _transferService.serverInfoStream.listen((info) {
      if (mounted) setState(() => _serverInfo = info);
    });
  }

  Future<void> _requestPermissions() async {
    await Permission.camera.request();
    if (Platform.isAndroid) {
      await Permission.storage.request();
      await Permission.accessMediaLocation.request();
      await Permission.manageExternalStorage.request();
      await Permission.location.request();
      await Permission.bluetooth.request(); 
    }
  }


  @override
  void dispose() {
    // IMPORTANT: Dispose the service to close sockets and stop discovery
    _transferService.dispose();
    super.dispose();
  }

  Future<void> _toggleHosting() async {
    if (_isHosting) {
      // If we are currently hosting, stop it
      await _transferService.stopServer();
      setState(() {
        _isHosting = false;
      });
    } else {
      // If we are not hosting, start it
      await _transferService.startServer(onFileReceived: _handleIncomingFile);
      setState(() {
        _isHosting = true;
      });
    }
  }

  void _handleIncomingFile(Socket clientSocket) {
    debugPrint(
        'Handling incoming file from ${clientSocket.remoteAddress.address}');

    String? fileName;
    int? fileSize;
    File? receivedFile;
    IOSink? fileSink;

    int bytesReceived = 0;

    // Show a dialog that a transfer is starting
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Incoming File'),
        content: Text(
            'Receiving a file from ${clientSocket.remoteAddress.address}...'),
      ),
    );

    // The 'listen' method is the receiving "while loop"
    clientSocket.listen(
      (data) {
        // This is the main callback that receives chunks of bytes
        if (fileName == null) {
          // The first chunk of data is the metadata
          final metadataJson = utf8.decode(data).trim();
          final metadata = jsonDecode(metadataJson);
          fileName = metadata['filename'];
          fileSize = metadata['filesize'];

          // Now that we have the filename, prepare the file sink
          _prepareFileSink(fileName!).then((file) {
            receivedFile = file;
            fileSink = receivedFile?.openWrite();
          });
        } else {
          // These are the subsequent chunks of the actual file
          fileSink?.add(data);
          bytesReceived += data.length;

          // Optional: Update progress
          final progress = (bytesReceived / fileSize!) * 100;
          debugPrint('Receiving progress: ${progress.toStringAsFixed(2)}%');
        }
      },
      onDone: () async {
        debugPrint('Client disconnected. Transfer complete.');
        await fileSink?.flush();
        await fileSink?.close();
        clientSocket.destroy();

        Navigator.of(context).pop(); // Close the "Receiving..." dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$fileName saved successfully!')),
        );
      },
      onError: (error) {
        debugPrint('Error receiving file: $error');
        fileSink?.close();
        clientSocket.destroy();

        Navigator.of(context).pop(); // Close the dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File transfer failed: $error')),
        );
      },
      cancelOnError: true,
    );
  }

  Future<File?> _prepareFileSink(String fileName) async {


    if (Platform.isAndroid) {
      final status = await Permission.storage.status;
      if (!status.isGranted) {
        final result = await Permission.storage.request();
        if (result.isDenied || result.isPermanentlyDenied) {
          throw Exception("Storage permission is required to save files.");
        }
      }
    }

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
      if (mounted)
        setState(() => _transferStatusText = "Error preparing file: $e");
      return null;
    }
  }

// Helper function to get the downloads directory
  Future<Directory?> getExternalStoragePublicDirectory(String type) async {
    if (Platform.isAndroid) {
      final dir =
          await getExternalStorageDirectory(); // Use this to get the base directory
      if (dir != null) {
        // On Android, Downloads is a common subdirectory
        final downloadsDir = Directory('${dir.path}/Download');
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }
        return downloadsDir;
      }
    }
    // For iOS, use getApplicationDocumentsDirectory()
    return getApplicationDocumentsDirectory();
  }

  Future<void> _handleConnectAndSend(DiscoveredDevice device) async {
    // 1. Pick a file to send
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      File file = File(result.files.single.path!);
      // 2. Use the service to send it
      await _transferService.connectAndSendFile(device, file);
    } else {
      // User canceled the picker
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No file selected.')),
      );
    }
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
                Text(
                  _serverInfo,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.blueGrey),
                ),
                const SizedBox(height: 20),
                // == START: UI CHANGES FOR THE BUTTONS ==
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Button to make the device visible
                    ElevatedButton.icon(
                      icon: Icon(
                          _isHosting ? Icons.visibility_off : Icons.visibility),
                      label: Text(
                        _isHosting ? "Stop Hosting" : "Make Visible",
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      onPressed: _toggleHosting,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor:
                            _isHosting ? Colors.red[400] : Colors.green[500],
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 12),
                      ),
                    ),
                    // Button to scan for other devices
                    ElevatedButton.icon(
                      icon: const Icon(Icons.radar),
                      label: const Text(
                        "Scan for Devices",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      onPressed: () => _transferService.startDiscovery(),
                      style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.blue[500],
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 12)),
                    ),
                  ],
                ),
                // == END: UI CHANGES FOR THE BUTTONS ==
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
                        const Text("Discovered Devices",
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87)),
                        const SizedBox(height: 12),
                        // The StreamBuilder for discovered devices remains the same
                        StreamBuilder<List<DiscoveredDevice>>(
                          stream: _transferService.devicesStream,
                          initialData: const [],
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                    ConnectionState.waiting &&
                                snapshot.data!.isEmpty) {
                              return const Center(
                                  child: Text("Press 'Scan' to find devices.",
                                      style: TextStyle(color: Colors.grey)));
                            }
                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return const Center(
                                  child: Text("No devices found.",
                                      style: TextStyle(color: Colors.grey)));
                            }
                            final devices = snapshot.data!;
                            return Expanded(
                              child: ListView.builder(
                                itemCount: devices.length,
                                itemBuilder: (context, index) {
                                  final device = devices[index];
                                  final bool isConnectable =
                                      device.status == 'Available';
                                  final bool isActionable =
                                      device.status == 'Available' ||
                                          device.status == 'Failed';
                                  return Card(
                                    elevation: 2,
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 6),
                                    child: ListTile(
                                      leading: const Icon(Icons.devices,
                                          color: Colors.blueAccent),
                                      title: Text(
                                        device.name ?? device.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600),
                                      ),
                                      subtitle: Text(
                                        'Status: ${device.status}',
                                        style: TextStyle(
                                          color: device.status == 'Available'
                                              ? Colors.green
                                              : (device.status == 'Connected'
                                                  ? Colors.blue
                                                  : Colors.redAccent),
                                        ),
                                      ),
                                      trailing: isActionable
                                          ? ElevatedButton(
                                              onPressed: isConnectable
                                                  ? () => _handleConnectAndSend(
                                                      device)
                                                  : null,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: isConnectable
                                                    ? Colors.blue
                                                    : Colors.grey,
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                              ),
                                              child: const Text("Send File"),
                                            )
                                          : null,
                                    ),
                                  );
                                },
                              ),
                            );
                          },
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
