import 'package:flutter/material.dart';

// Header Component for all screens
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBack;

  const AppHeader({super.key, required this.title, this.onBack});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.blue[600],
      elevation: 4,
      leading: onBack != null
          ? IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: onBack,
      )
          : null,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
      centerTitle: onBack == null, // Center title only if no back button
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

