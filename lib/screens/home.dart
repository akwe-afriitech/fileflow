// lib/screens/home_screen.dart

import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fileflow/components/header.dart';
import 'package:fileflow/components/navbar.dart';
import 'package:fileflow/services/changenotifier.dart';
import 'package:fileflow/components/recentTransfers.dart';
import 'package:fileflow/models/transfers.dart';
import 'package:path_provider/path_provider.dart'; // NEW: Import path_provider
import 'package:fileflow/models/transfers.dart'; // Ensure this import is correct


class HomeScreen extends StatefulWidget {
  final Function(String) setCurrentScreen;

  const HomeScreen({super.key, required this.setCurrentScreen});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoadingTransfers = true;
  List<Transfer> _transfers = [];

  @override
  void initState() {
    super.initState();
    _fetchTransfers();
  }

Future<void> _fetchTransfers() async {
  setState(() => _isLoadingTransfers = true);

  List<Transfer> fetchedTransfers = [];
  try {
    // Get the external storage directory
    final directories = await getExternalStorageDirectories();
    if (directories != null && directories.isNotEmpty) {
      // Assuming you want to use the first directory for downloads
      final downloadDir = Directory('${directories.first.path}/Downloads');

      // Check if the Downloads directory exists
      if (await downloadDir.exists()) {
        final files = downloadDir.listSync(recursive: true, followLinks: false);

        for (var entity in files) {
          if (entity is File) {
            try {
              final file = entity;
              final fileStat = await file.stat();
              final fileName = file.path.split('/').last;
              final fileSizeInMB = fileStat.size / (1024 * 1024); // Convert bytes to MB
              final transferDate = fileStat.modified;

              // Determine file type from extension
              FileType fileType = FileType.other;
              final extension = fileName.split('.').last.toLowerCase();
              if (['jpg', 'jpeg', 'png', 'gif'].contains(extension)) {
                fileType = FileType.image;
              } else if (['mp4', 'mov', 'avi'].contains(extension)) {
                fileType = FileType.video;
              } else if (['mp3', 'wav', 'aac'].contains(extension)) {
                fileType = FileType.audio;
              } else if (extension == 'pdf') {
                fileType = FileType.document;
              } else if (['zip', 'rar', '7z'].contains(extension)) {
                fileType = FileType.archive;
              } else if (['txt', 'docx', 'xlsx', 'pptx'].contains(extension)) {
                fileType = FileType.document;
              }

              fetchedTransfers.add(
                Transfer(
                  id: file.path, // Using file path as a unique ID
                  fileName: fileName,
                  fileSizeInMB: double.parse(fileSizeInMB.toStringAsFixed(2)),
                  transferDate: transferDate,
                  sourceDeviceName: "This Device", // Since it's from local app dir
                  fileType: fileType,
                ),
              );
            } catch (e) {
              // Handle errors for individual files
              print("Error reading file ${entity.path}: $e");
            }
          }
        }
      } else {
        print("Downloads directory does not exist.");
      }
    }
    // Sort files by modification date (most recent first)
    fetchedTransfers.sort((a, b) => b.transferDate.compareTo(a.transferDate));

  } catch (e) {
    print("Error fetching files from Downloads directory: $e");
    // Optionally show an error message to the user
  }

  if (mounted) {
    setState(() {
      _transfers = fetchedTransfers;
      _isLoadingTransfers = false;
    });
  }
}

// Handle tapping on a transfer item
void _handleTap(Transfer transfer) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("Viewing details for ${transfer.fileName}")),
  );
}

// Handle dismissing a transfer item
void _handleDismiss(Transfer transfer) {
  setState(() {
    _transfers.removeWhere((t) => t.id == transfer.id);
  });
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("${transfer.fileName} was removed.")),
  );
}
  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectionService>(
      builder: (context, connectionService, child) {
        return Column(
          children: [
            AppHeader(title: "FileFlow Pro"),
            Expanded(
              // Use a SingleChildScrollView to prevent overflow when the list is added
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const Text(
                        "Seamlessly transfer files between devices securely and efficiently.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 20),
                      _buildConnectionStatusWidget(context, connectionService),
                      const SizedBox(height: 20),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        children: [
                          FeatureButton(
                            icon: Icons.sync_alt,
                            label: "Transfer Files",
                            onPressed: () {
                              if (connectionService.isConnected) {
                                widget.setCurrentScreen('transfer');
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please connect to a device first.')),
                                );
                              }
                            },
                          ),
                          FeatureButton(
                            icon: Icons.qr_code_scanner,
                            label: "QR Share",
                            onPressed: () => widget.setCurrentScreen('qrCode'),
                          ),
                          FeatureButton(
                            icon: Icons.wifi_sharp,
                            label: "Wi-Fi Direct",
                            onPressed: () => widget.setCurrentScreen('wifiDirect'),
                          ),
                          FeatureButton(
                            icon: Icons.settings,
                            label: "Settings",
                            onPressed: () => widget.setCurrentScreen('settings'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ## IMPLEMENTED RECENT TRANSFERS COMPONENT ##
                      // Wrapped in a SizedBox to constrain its height within the SingleChildScrollView
                      SizedBox(
                        height: 350, // Adjust height as needed
                        child: RecentTransfers(
                          isLoading: _isLoadingTransfers,
                          transfers: _transfers,
                          onTap: _handleTap,
                          onDismissed: _handleDismiss,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
                      onPressed: () => widget.setCurrentScreen('transfer')),
                  NavItem(
                      icon: Icons.settings,
                      label: "Settings",
                      onPressed: () => widget.setCurrentScreen('settings')),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // This helper widget remains unchanged
  Widget _buildConnectionStatusWidget(
      BuildContext context, ConnectionService connectionService) {
    if (connectionService.isConnected) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            connectionService.status,
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.link_off, size: 18),
              label: const Text("Disconnect"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[50],
                foregroundColor: Colors.red[800],
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                textStyle: const TextStyle(fontSize: 14),
                elevation: 0,
              ),
              onPressed: () {
                connectionService.disconnect();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Disconnected')),
                );
              },
            ),
          ),
        ],
      );
    } else {
      return ElevatedButton.icon(
        icon: const Icon(Icons.wifi_find_rounded),
        label: const Text("Tap to Connect"),
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.blue,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        onPressed: () => widget.setCurrentScreen('wifiDirect'),
      );
    }
  }
}

// This reusable widget remains unchanged
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
        foregroundColor: Colors.blue[800],
        backgroundColor: Colors.blue[50],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 2,
        shadowColor: Colors.blue[100],
        padding: const EdgeInsets.all(16),
      ).copyWith(
        overlayColor: MaterialStateProperty.resolveWith<Color?>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.hovered) ||
                states.contains(MaterialState.pressed)) {
              return Colors.blue[100];
            }
            return null;
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