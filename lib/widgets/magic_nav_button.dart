// lib/widgets/magic_nav_button.dart
import 'package:flutter/material.dart';

class MagicNavButton extends StatefulWidget {
  final int index;
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final IconData icon;
  final String label;
  final bool isDarkMode;

  const MagicNavButton({
    super.key,
    required this.index,
    required this.selectedIndex,
    required this.onTap,
    required this.icon,
    required this.label,
    required this.isDarkMode,
  });

  @override
  State<MagicNavButton> createState() => _MagicNavButtonState();
}

class _MagicNavButtonState extends State<MagicNavButton>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.index == widget.selectedIndex;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => widget.onTap(widget.index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? (widget.isDarkMode
                ? Colors.white.withOpacity(0.15)
                : Colors.blue.withOpacity(0.10))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                color: isSelected
                    ? (widget.isDarkMode ? Colors.white : Colors.blue.shade700)
                    : (widget.isDarkMode
                    ? Colors.grey.shade400
                    : Colors.grey.shade600),
                size: 28,
              ),
              const SizedBox(height: 4),
              Text(
                widget.label,
                style: TextStyle(
                  color: isSelected
                      ? (widget.isDarkMode ? Colors.white : Colors.blue.shade700)
                      : (widget.isDarkMode
                      ? Colors.grey.shade400
                      : Colors.grey.shade600),
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}