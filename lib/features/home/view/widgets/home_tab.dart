import 'package:flutter/material.dart';

class HomeTab {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget page;

  const HomeTab(this.label, this.icon, this.selectedIcon, this.page);
}
