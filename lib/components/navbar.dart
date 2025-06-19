import 'package:flutter/material.dart';

// Reusable Nav Item for Bottom Navigation
class NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onPressed;

  const NavItem({
    super.key,
    required this.icon,
    required this.label,
    this.active = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: active ? Colors.blue[600] : Colors.grey[500],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: active ? Colors.blue[600] : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}