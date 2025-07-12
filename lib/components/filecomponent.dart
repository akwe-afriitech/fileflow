import 'package:fileflow/components/header.dart';
import 'package:flutter/material.dart';

// File Select Screen Component
class FileSelectScreen extends StatefulWidget {
  final Function(String) setCurrentScreen;

  const FileSelectScreen({super.key, required this.setCurrentScreen});

  @override
  State<FileSelectScreen> createState() => _FileSelectScreenState();
}

class _FileSelectScreenState extends State<FileSelectScreen> {
  final List<String> _selectedFiles = [];
  final List<String> _mockFiles = [
    'Document.pdf',
    'Vacation.jpg',
    'ProjectPlan.docx',
    'Music.mp3',
    'Video.mp4',
    'Archive.zip'
  ];

  void _handleSelectFile(String fileName) {
    setState(() {
      if (_selectedFiles.contains(fileName)) {
        _selectedFiles.remove(fileName);
      } else {
        _selectedFiles.add(fileName);
      }
    });
  }

  void _handleConfirmSelection() {
    if (_selectedFiles.isNotEmpty) {
      // Handle file transfer logic here
      print("Selected files for transfer: $_selectedFiles");
      widget.setCurrentScreen('transfer'); // Navigate to transfer screen
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppHeader(
            title: "Select Files",
            onBack: () => widget.setCurrentScreen('transfer')),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Text(
                  "Tap to select files for transfer.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListView.builder(
                      itemCount: _mockFiles.length,
                      itemBuilder: (context, index) {
                        final file = _mockFiles[index];
                        final isSelected = _selectedFiles.contains(file);
                        return ListTile(
                          title: Text(file,
                              style: TextStyle(
                                  color: isSelected ? Colors.blue : Colors.black)),
                          trailing: isSelected
                              ? Icon(Icons.check_circle, color: Colors.green[500])
                              : null,
                          onTap: () => _handleSelectFile(file),
                          tileColor: isSelected ? Colors.blue[50] : null,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _selectedFiles.isEmpty ? null : _handleConfirmSelection,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: _selectedFiles.isEmpty ? Colors.grey : Colors.blue[600],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    elevation: 5,
                  ),
                  child: Text(
                    "Confirm Selection (${_selectedFiles.length})",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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