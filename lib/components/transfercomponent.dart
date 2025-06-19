import 'package:fileflow/components/header.dart';
import 'package:fileflow/components/navbar.dart';
import 'package:flutter/material.dart';

// Transfer Screen Component
class TransferScreen extends StatefulWidget {
  final Function(String) setCurrentScreen;

  const TransferScreen({super.key, required this.setCurrentScreen});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  String _transferStatus = 'idle'; // idle, selecting, transferring, complete, error
  double _progress = 0.0;

  void _handleInitiateTransfer() {
    setState(() {
      _transferStatus = 'selecting';
    });
    widget.setCurrentScreen('fileSelect'); // Navigate to file select screen
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
                if (_transferStatus == 'idle') _buildIdleState(),
                if (_transferStatus == 'transferring') _buildTransferringState(),
                if (_transferStatus == 'complete') _buildCompleteState(),
                const Spacer(),
                _buildNavbar(),
              ],
            ),
          ),
        ),
      ],
    );
  }

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
            onPressed: _handleInitiateTransfer,
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.blue[600],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              elevation: 5,
            ),
            icon: const Icon(Icons.send_rounded, size: 28),
            label: const Text(
              "Start New Transfer",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
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
        children: [
          const Text(
            "Transferring Files...",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.blue),
          ),
          const SizedBox(height: 20),
          LinearProgressIndicator(
            value: _progress / 100,
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

  Widget _buildNavbar() {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          NavItem(icon: Icons.home, label: "Home", active: true),
          NavItem(
            icon: Icons.sync_alt,
            label: "Transfer",
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