import 'package:flutter/material.dart';

import '../../core/theme/gj_colors.dart';
import '../../core/theme/gj_radius.dart';
import '../../core/theme/gj_spacing.dart';
import '../../core/theme/gj_typography.dart';

class GJAvatarMenuItem {
  const GJAvatarMenuItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.destructivo = false,
    this.dividerAcima = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool destructivo;
  final bool dividerAcima;
}

/// Menu do avatar do usuário no header (seção 3.12).
class GJAvatarMenu extends StatelessWidget {
  const GJAvatarMenu({super.key, required this.itens, this.fotoUrl, this.iniciais = '?'});

  final List<GJAvatarMenuItem> itens;
  final String? fotoUrl;
  final String iniciais;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<void>(
      tooltip: 'Menu do perfil',
      offset: const Offset(0, 48),
      color: GJColors.surfaceLowest,
      shape: RoundedRectangleBorder(borderRadius: GJRadius.borderLg),
      constraints: const BoxConstraints(minWidth: 240, maxWidth: 240),
      padding: EdgeInsets.zero,
      itemBuilder: (context) => [
        for (final item in itens)
          PopupMenuItem<void>(
            padding: EdgeInsets.zero,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item.dividerAcima) const Divider(height: 1, color: GJColors.surfaceHigh),
                InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                    item.onTap();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: GJSpace.s4, vertical: GJSpace.s3),
                    child: Row(
                      children: [
                        Icon(
                          item.icon,
                          size: 20,
                          color: item.destructivo ? GJColors.error : GJColors.textSecondary,
                        ),
                        const SizedBox(width: GJSpace.s3),
                        Text(
                          item.label,
                          style: GJTypography.body().copyWith(
                            fontSize: 14,
                            color: item.destructivo ? GJColors.error : GJColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
      child: CircleAvatar(
        radius: 20,
        backgroundColor: GJColors.primaryContainer,
        backgroundImage: fotoUrl != null ? NetworkImage(fotoUrl!) : null,
        child: fotoUrl == null
            ? Text(iniciais, style: GJTypography.label(color: GJColors.primaryOn))
            : null,
      ),
    );
  }
}
