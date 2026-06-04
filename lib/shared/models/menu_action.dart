import 'package:flutter/material.dart';

class MenuAction {
  final String label;
  final IconData icon;
  final bool isDestructive;
  final VoidCallback onTap;

  const MenuAction({
    required this.label,
    required this.icon,
    this.isDestructive = false,
    required this.onTap,
  });
}
