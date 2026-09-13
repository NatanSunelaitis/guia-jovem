import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/gj_brand.dart';
import '../../core/theme/gj_breakpoints.dart';
import '../../core/theme/gj_colors.dart';
import '../../core/theme/gj_spacing.dart';
import '../../core/theme/gj_typography.dart';

class GJFooterLink {
  const GJFooterLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;
}

/// Rodapé do site público (seção 3.13).
class GJFooter extends StatelessWidget {
  const GJFooter({super.key, required this.links});

  final List<GJFooterLink> links;

  static const _descricao =
      'O Guia Jovem é uma plataforma que ajuda estudantes a encontrar as '
      'melhores faculdades e programas de entrada com bolsas de estudo.';

  @override
  Widget build(BuildContext context) {
    final isMobile = GJBreakpoints.isMobile(context);

    final coluna1 = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 32,
          width: 140,
          child: SvgPicture.asset(GJBrand.logoHorizontalWhite, fit: BoxFit.contain, alignment: Alignment.centerLeft),
        ),
        const SizedBox(height: GJSpace.s3),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Text(
            _descricao,
            style: GJTypography.bodySm(color: Colors.white.withOpacity(0.8)),
          ),
        ),
      ],
    );

    final coluna2 = Column(
      crossAxisAlignment: isMobile ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: GJSpace.s8,
          runSpacing: GJSpace.s2,
          children: [
            for (final link in links)
              GestureDetector(
                onTap: link.onTap,
                child: Text(link.label, style: GJTypography.label(color: Colors.white)),
              ),
          ],
        ),
        const SizedBox(height: GJSpace.s4),
        Text(
          '© 2026 Guia Jovem. O Mentor Dinâmico.',
          style: GJTypography.bodySm(color: Colors.white.withOpacity(0.8)),
        ),
      ],
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? GJSpace.s6 : GJSpace.s16, vertical: GJSpace.s12),
      color: GJColors.primary,
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [coluna1, const SizedBox(height: GJSpace.s8), coluna2],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: coluna1),
                const SizedBox(width: GJSpace.s16),
                Expanded(child: coluna2),
              ],
            ),
    );
  }
}
