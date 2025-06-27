import 'package:fileflow/components/header.dart';
import 'package:fileflow/components/navbar.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart'; // Import file_picker
import 'package:share_plus/share_plus.dart'; // Import share_plus

// Transfer Screen Component
class TransferScreen extends StatefulWidget {
  final Function(String) setCurrentScreen;

  const TransferScreen({super.key, required this.setCurrentScreen});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  String _transferStatus = 'idle'; // idle, selecting, transferring, complete, error
  double _progress = 0.0; // Progress for the simulated transfer

  // Handles initiating the file transfer process
  Future<void> _handleInitiateTransfer() async {
    setState(() {
      _transferStatus = 'selecting'; // Indicate that file selection is in progress
    });

    try {
      // Pick files using file_picker
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true, // Allow selecting multiple files
      );

      if (result != null && result.files.isNotEmpty) {
        // If files are selected, prepare them for sharing
        final List<XFile> filesToShare = result.files.map((platformFile) {
          return XFile(platformFile.path!); // Create XFile from file path
        }).toList();

        if (filesToShare.isNotEmpty) {
          setState(() {
            _transferStatus = 'transferring'; // Change status to show progress
            _progress = 0.0; // Reset progress
          });

          // Simulate progress quickly since share_plus doesn't provide it
          for (int i = 0; i <= 100; i += 10) {
            await Future.delayed(const Duration(milliseconds: 50));
            setState(() {
              _progress = i.toDouble();
            });
          }

          // Share the selected files using share_plus
          await Share.shareXFiles(filesToShare, text: 'Sharing files from FileFlow');

          setState(() {
            _transferStatus = 'complete'; // Mark as complete after sharing
          });
        } else {
          // No files selected, revert to idle
          setState(() {
            _transferStatus = 'idle';
          });
        }
      } else {
        // User cancelled file picking, revert to idle
        setState(() {
          _transferStatus = 'idle';
        });
      }
    } catch (e) {
      // Handle any errors during file picking or sharing
      debugPrint('Error during file transfer: $e');
      setState(() {
        _transferStatus = 'error'; // Set status to error
      });
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
                if (_transferStatus == 'idle' || _transferStatus == 'selecting') _buildIdleState(),
                if (_transferStatus == 'transferring') _buildTransferringState(),
                if (_transferStatus == 'complete') _buildCompleteState(),
                if (_transferStatus == 'error') _buildErrorState(), // Display error state
                const Spacer(), // Pushes content to the center
                _buildNavbar(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Widget to display when the app is in idle or selecting state
  Widget _buildIdleState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Ready to send or receive files securely.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 48),
          ElevatedButton.icon(
            onPressed: _transferStatus == 'selecting'
                ? null // Disable button while selecting
                : _handleInitiateTransfer,
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.blue[600],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              elevation: 5,
            ),
            icon: _transferStatus == 'selecting'
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded, size: 28),
            label: Text(
              _transferStatus == 'selecting' ? "Selecting Files..." : "Start New Transfer",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // Widget to display when files are being transferred (simulated progress)
  Widget _buildTransferringState() {
    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          const Text(
            "Transferring Files...",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.blue),
          ),
          const SizedBox(height: 20),
          LinearProgressIndicator(
            value: _progress / 100, // Progress from 0.0 to 1.0
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            minHeight: 10,
            borderRadius: BorderRadius.circular(5),
          ),
          const SizedBox(height: 10),
          Text(
            "${_progress.toInt()}% Complete",
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // Widget to display when the transfer is complete
  Widget _buildCompleteState() {
    return Column(
      children: [
        Icon(
          Icons.check_circle,
          color: Colors.green[500],
          size: 100,
        ),
        const SizedBox(height: 20),
        const Text(
          "Transfer Complete!",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green),
        ),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: () => setState(() => _transferStatus = 'idle'),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.blue[600],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            elevation: 3,
          ),
          child: const Text("New Transfer", style: TextStyle(fontSize: 16)),
        ),
      ],
    );
  }

  // Widget to display when an error occurs during transfer
  Widget _buildErrorState() {
    return Column(
      children: [
        Icon(
          Icons.error,
          color: Colors.red[500],
          size: 100,
        ),
        const SizedBox(height: 20),
        const Text(
          "Transfer Failed!",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.red),
        ),
        const SizedBox(height: 10),
        const Text(
          "An error occurred during file selection or sharing. Please try again.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: () => setState(() => _transferStatus = 'idle'),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.blue[600],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            elevation: 3,
          ),
          child: const Text("Try Again", style: TextStyle(fontSize: 16)),
        ),
      ],
    );
  }

  // Navbar widget (retained from original code)
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
            active: true, // This screen is now active
            onPressed: () => widget.setCurrentScreen('transfer'),
          ),
          NavItem(
            icon: Icons.settings,
            label: "Settings",
            onPressed: () => widget.setCurrentScreen('settings'),
          ),
        ],
      ),
    );
  }
}
