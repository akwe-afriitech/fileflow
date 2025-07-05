import 'package:fileflow/components/header.dart';
import 'package:fileflow/components/navbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // UPDATED: Import provider
import 'package:fileflow/services/changenotifier.dart';

class HomeScreen extends StatelessWidget {
  final Function(String) setCurrentScreen;

  const HomeScreen({super.key, required this.setCurrentScreen});

  @override
  Widget build(BuildContext context) {
    // Use Consumer to listen to changes in ConnectionService
    // This allows us to rebuild the widget when the connection state changes.
    return Consumer<ConnectionService>(
      builder: (context, connectionService, child) {
        // 'connectionService' is the global instance holding our connection state.
        return Column(
          children: [
            AppHeader(title: "FileFlow Pro"),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  
                  children: [
                    const Text(
                      "Seamlessly transfer files between devices securely and efficiently.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                 // This Text widget now gets its state directly from the service.
                    Text(
                      connectionService.status, // Reading from the service
                      style: TextStyle(
                        color: connectionService.isConnected ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(), // Disable scrolling inside SingleChildScrollView
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: [
                        FeatureButton(
                          icon: Icons.sync_alt,
                          label: "Transfer Files",
                          onPressed: () {
                            // UPDATED: Check the connection status from the service.
                            if (connectionService.isConnected) {
                              setCurrentScreen('transfer');
                            } else {
                              // If not connected, guide the user to connect first.
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please connect to a device first using QR Share or Wi-Fi Direct.')),
                              );
                            }
                          },
                        ),
                        FeatureButton(
                          icon: Icons.qr_code_scanner,
                          label: "QR Share",
                          onPressed: () => setCurrentScreen('qrCode'),
                        ),
                        FeatureButton(
                          icon: Icons.wifi_sharp,
                          label: "Wi-Fi Direct",
                          onPressed: () => setCurrentScreen('wifiDirect'),
                        ),
                        FeatureButton(
                          icon: Icons.settings,
                          label: "Settings",
                          onPressed: () => setCurrentScreen('settings'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // The Nav Bar remains the same
            Container(
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
                      onPressed: () => setCurrentScreen('transfer')),
                  NavItem(
                      icon: Icons.settings,
                      label: "Settings",
                      onPressed: () => setCurrentScreen('settings')),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// Reusable Feature Button for Home Screen (This widget is unchanged)
class FeatureButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const FeatureButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.blue[800], backgroundColor: Colors.blue[50], // Text/icon color
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 2,
        shadowColor: Colors.blue[100],
        padding: const EdgeInsets.all(16),
      ).copyWith(
        overlayColor: MaterialStateProperty.resolveWith<Color?>(
              (Set<MaterialState> states) {
            if (states.contains(MaterialState.hovered) || states.contains(MaterialState.pressed)) {
              return Colors.blue[100];
            }
            return null; // Defer to the widget's default.
          },
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}