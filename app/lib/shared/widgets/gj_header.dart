import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/gj_brand.dart';
import '../../core/theme/gj_breakpoints.dart';
import '../../core/theme/gj_colors.dart';
import '../../core/theme/gj_spacing.dart';
import '../../core/theme/gj_typography.dart';
import 'gj_avatar_menu.dart';
import 'gj_button.dart';

class GJHeaderNavItem {
  const GJHeaderNavItem({required this.label, required this.onTap, this.ativo = false});

  final String label;
  final VoidCallback onTap;
  final bool ativo;
}

/// Cabeçalho fixo (seção 3.11), com variantes visitante, logado e painel.
class GJHeader extends StatelessWidget implements PreferredSizeWidget {
  const GJHeader.visitante({super.key, this.navItems = const [], required this.onEntrar})
      : logado = false,
        avatarMenu = null,
        notificationBell = null,
        tituloPainel = null;

  const GJHeader.logado({
    super.key,
    this.navItems = const [],
    required this.avatarMenu,
    this.notificationBell,
  })  : logado = true,
        onEntrar = null,
        tituloPainel = null;

  const GJHeader.painel({
    super.key,
    required this.tituloPainel,
    required this.avatarMenu,
    this.notificationBell,
  })  : logado = true,
        onEntrar = null,
        navItems = const [];

  final List<GJHeaderNavItem> navItems;
  final bool logado;
  final VoidCallback? onEntrar;
  final GJAvatarMenu? avatarMenu;
  /// Um [GJNotificationBell], ou um widget que o monta com dados da API.
  final Widget? notificationBell;
  final String? tituloPainel;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final isMobile = GJBreakpoints.isMobile(context);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: preferredSize.height,
          padding: EdgeInsets.symmetric(horizontal: isMobile ? GJSpace.s4 : GJSpace.s6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 2, offset: Offset(0, 1))],
          ),
          child: Row(
            children: [
              SizedBox(
                height: 32,
                width: 140,
                child: SvgPicture.asset(GJBrand.logoHorizontal, fit: BoxFit.contain, alignment: Alignment.centerLeft),
              ),
              if (tituloPainel != null) ...[
                const SizedBox(width: GJSpace.s4),
                Container(width: 1, height: 24, color: GJColors.border),
                const SizedBox(width: GJSpace.s4),
                if (!isMobile)
                  // Flexible com ellipsis: sem isso, um título de painel
                  // comprido (ex.: "Painel de Administração da
                  // Universidade") tem largura livre num Row sem Expanded
                  // (não há navItems no header de painel), e em janelas
                  // estreitas o Row estoura e o ClipRect externo corta o
                  // que vem depois (sino/avatar/Entrar).
                  Flexible(
                    child: Text(
                      tituloPainel!,
                      style: GJTypography.body().copyWith(color: GJColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              if (!isMobile && navItems.isNotEmpty)
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [for (final item in navItems) _NavLink(item: item)],
                    ),
                  ),
                )
              else
                const Spacer(),
              const SizedBox(width: GJSpace.s4),
              if (notificationBell != null) ...[notificationBell!, const SizedBox(width: GJSpace.s3)],
              if (avatarMenu != null) avatarMenu!,
              if (!logado && onEntrar != null)
                GJButton(label: 'Entrar', size: GJButtonSize.sm, onPressed: onEntrar),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  const _NavLink({required this.item});

  final GJHeaderNavItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: GJSpace.s6),
      child: GestureDetector(
        onTap: item.onTap,
        child: Container(
          padding: const EdgeInsets.only(bottom: 2),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: item.ativo ? GJColors.primary : Colors.transparent, width: 2),
            ),
          ),
          child: Text(
            item.label,
            style: GJTypography.body().copyWith(
              fontSize: 15,
              fontWeight: item.ativo ? FontWeight.w700 : FontWeight.w500,
              color: item.ativo ? GJColors.primary : GJColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
