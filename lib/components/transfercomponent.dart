import 'dart:io';
import 'dart:convert';
import 'package:fileflow/components/header.dart';
import 'package:fileflow/components/navbar.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart'; 
import 'package:fileflow/services/changenotifier.dart'; 

class TransferScreen extends StatefulWidget {
  final Function(String) setCurrentScreen;

  const TransferScreen({super.key, required this.setCurrentScreen});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  String _transferStatus = 'idle'; // idle, selecting, transferring, complete, error
  double _progress = 0.0;
  String _statusMessage = "Ready to send or receive files securely.";

  // UPDATED: This method now uses the ConnectionService to send files directly.
  Future<void> _handleInitiateTransfer() async {
    // Get the global connection service
    final connectionService = Provider.of<ConnectionService>(context, listen: false);

    // 1. Check if we are actually connected to another device
    if (!connectionService.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not connected to any device. Please connect first.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _transferStatus = 'selecting';
    });

    try {
      // 2. Pick a file (allowing only one for simplicity in this example)
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null && result.files.isNotEmpty) {
        File fileToSend = File(result.files.single.path!);
        
        // 3. Send the file using the active socket from our service
        await _sendFile(connectionService.socket, fileToSend);
      } else {
        // User cancelled the picker
        setState(() {
          _transferStatus = 'idle';
        });
      }
    } catch (e) {
      debugPrint('Error during file transfer initiation: $e');
      setState(() {
        _transferStatus = 'error';
        _statusMessage = 'Failed to pick file. Please try again.';
      });
    }
  }

  // UPDATED: New method to handle the actual socket communication
  Future<void> _sendFile(Socket? clientSocket, File file) async {
    if (clientSocket == null) {
      setState(() {
        _transferStatus = 'error';
        _statusMessage = 'Connection lost. Please reconnect.';
      });
      return;
    }

    final fileName = file.path.split('/').last;
    final fileSize = await file.length();

    try {
      setState(() {
        _transferStatus = 'transferring';
        _progress = 0.0;
      });

      // A. Send metadata (filename and size)
      final metadata = {'filename': fileName, 'filesize': fileSize};
      final metadataJson = jsonEncode(metadata);
      clientSocket.writeln(metadataJson);
      await clientSocket.flush();

      // B. Send file content in chunks and update progress
      int bytesSent = 0;
      await for (var chunk in file.openRead()) {
        clientSocket.add(chunk);
        bytesSent += chunk.length;
        if (mounted) {
          setState(() {
            _progress = (bytesSent / fileSize);
          });
        }
      }

      await clientSocket.flush();
      if (mounted) {
        setState(() {
          _transferStatus = 'complete';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _transferStatus = 'error';
          _statusMessage = 'File transfer failed: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppHeader(
          title: "File Transfer",
          onBack: () => widget.setCurrentScreen('home'),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(), // Pushes content to the center
                if (_transferStatus == 'idle' || _transferStatus == 'selecting') _buildIdleState(),
                if (_transferStatus == 'transferring') _buildTransferringState(),
                if (_transferStatus == 'complete') _buildCompleteState(),
                if (_transferStatus == 'error') _buildErrorState(),
                const Spacer(), // Pushes the navbar to the bottom
                _buildNavbar(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- UI Builder Methods ---

  Widget _buildIdleState() {
    // Get the connection status from the provider to display it
    final connectionService = Provider.of<ConnectionService>(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // UPDATED: Display dynamic status text
          Text(
            connectionService.isConnected ? "Connected to a device." : "No active connection.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18, 
              color: connectionService.isConnected ? Colors.green : Colors.grey,
              fontWeight: FontWeight.bold
            ),
          ),
          const SizedBox(height: 48),
          ElevatedButton.icon(
            onPressed: _transferStatus == 'selecting' ? null : _handleInitiateTransfer,
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.blue[600],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              elevation: 5,
            ),
            icon: _transferStatus == 'selecting'
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.send_rounded, size: 28),
            label: Text(
              _transferStatus == 'selecting' ? "Selecting Files..." : "Send a File",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransferringState() {
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Sending File...",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.blue),
          ),
          const SizedBox(height: 20),
          LinearProgressIndicator(
            value: _progress, // Progress from 0.0 to 1.0
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            minHeight: 10,
            borderRadius: BorderRadius.circular(5),
          ),
          const SizedBox(height: 10),
          Text(
            "${(_progress * 100).toInt()}% Complete",
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildCompleteState() {
    return Column(
       mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.check_circle, color: Colors.green[500], size: 100),
        const SizedBox(height: 20),
        const Text(
          "Transfer Complete!",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green),
        ),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: () => setState(() => _transferStatus = 'idle'),
          child: const Text("Send Another File", style: TextStyle(fontSize: 16)),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Column(
       mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error, color: Colors.red[500], size: 100),
        const SizedBox(height: 20),
        const Text(
          "Transfer Failed!",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.red),
        ),
        const SizedBox(height: 10),
        Text(
          _statusMessage, // Display the specific error message
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: () => setState(() => _transferStatus = 'idle'),
          child: const Text("Try Again", style: TextStyle(fontSize: 16)),
        ),
      ],
    );
  }

  Widget _buildNavbar() {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          NavItem(
              icon: Icons.home,
              label: "Home",
              onPressed: () => widget.setCurrentScreen('home')),
          NavItem(
              icon: Icons.sync_alt,
              label: "Transfer",
              active: true,
              onPressed: () => widget.setCurrentScreen('transfer')),
          NavItem(
              icon: Icons.settings,
              label: "Settings",
              onPressed: () => widget.setCurrentScreen('settings')),
        ],
      ),
    );
  }
}