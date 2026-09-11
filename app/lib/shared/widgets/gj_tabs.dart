import 'package:flutter/material.dart';

import '../../core/theme/gj_colors.dart';
import '../../core/theme/gj_spacing.dart';
import '../../core/theme/gj_typography.dart';

class GJTabItem {
  const GJTabItem({required this.label, this.icon});

  final String label;
  final IconData? icon;
}

/// Abas horizontais do Guia Jovem Design System (seção 3.8).
class GJTabs extends StatelessWidget {
  const GJTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<GJTabItem> tabs;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: GJColors.border.withOpacity(0.1))),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < tabs.length; i++) _GJTabButton(
              item: tabs[i],
              selected: i == selectedIndex,
              onTap: () => onChanged(i),
            ),
          ],
        ),
      ),
    );
  }
}

class _GJTabButton extends StatefulWidget {
  const _GJTabButton({required this.item, required this.selected, required this.onTap});

  final GJTabItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_GJTabButton> createState() => _GJTabButtonState();
}

class _GJTabButtonState extends State<_GJTabButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.selected
        ? GJColors.primary
        : (_hovered ? GJColors.primary : GJColors.textSecondary);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: GJSpace.s6, vertical: GJSpace.s4),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: widget.selected ? GJColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.item.icon != null) ...[
                Icon(widget.item.icon, size: 20, color: color),
                const SizedBox(width: GJSpace.s2),
              ],
              Text(
                widget.item.label,
                style: GJTypography.label(color: color).copyWith(
                  fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
