import 'package:fileflow/components/header.dart';
import 'package:flutter/material.dart';

// Settings Screen Component
class SettingsScreen extends StatelessWidget {
  final Function(String) setCurrentScreen;

  const SettingsScreen({super.key, required this.setCurrentScreen});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppHeader(title: "Settings", onBack: () => setCurrentScreen('home')),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ListView(
              children: const [
                SettingItem(
                  label: "Encryption Status",
                  description: "File transfers are encrypted by default.",
                ),
                SettingItem(
                  label: "Theme",
                  description: "Light (Default)",
                  action: "Change",
                ),
                SettingItem(
                  label: "Notifications",
                  description: "Enabled",
                  action: "Toggle",
                ),
                SettingItem(
                  label: "About App",
                  description: "Version 1.0.0",
                  action: "View",
                ),
                SettingItem(
                  label: "Privacy Policy",
                  action: "View",
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Reusable Setting Item
class SettingItem extends StatelessWidget {
  final String label;
  final String? description;
  final String? action;
  final VoidCallback? onPressed;

  const SettingItem({
    super.key,
    required this.label,
    this.description,
    this.action,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
              ),
              if (description != null) ...[
                const SizedBox(height: 4),
                Text(
                  description!,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ],
          ),
          if (action != null)
            TextButton(
              onPressed: onPressed,
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue[600],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(action!),
            ),
        ],
      ),
    );
  }
}
