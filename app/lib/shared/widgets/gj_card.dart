import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/gj_colors.dart';
import '../../core/theme/gj_radius.dart';
import '../../core/theme/gj_shadows.dart';
import '../../core/theme/gj_spacing.dart';
import '../../core/theme/gj_typography.dart';
import 'gj_button.dart';
import 'gj_remote_or_asset_image.dart';

enum GJCardVariant { base, elevated }

/// Card base do Guia Jovem Design System (seção 3.4), com as variantes de
/// domínio do Design System Deck compostas como factory constructors:
/// `GJCard.universidade`, `GJCard.programa` e `GJCard.curso`.
class GJCard extends StatefulWidget {
  const GJCard({
    super.key,
    required this.child,
    this.variant = GJCardVariant.base,
    this.onTap,
    this.padding,
  });

  /// Card de uma universidade (Design System Deck, seção 15): logo (ou
  /// iniciais sobre `primaryFixed` quando `logoUrl` é nulo), nome, cidade/UF,
  /// nota com estrelas e tags de programas aceitos.
  factory GJCard.universidade({
    Key? key,
    required String nomeFantasia,
    String? logoUrl,
    String? cidade,
    String? estado,
    double? mediaAvaliacao,
    int? totalAvaliacoes,
    List<Widget> tags = const [],
    required VoidCallback onTap,
  }) {
    return GJCard(
      key: key,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _CaixaLogo(logoUrl: logoUrl, nome: nomeFantasia),
          const SizedBox(height: GJSpace.s4),
          Text(nomeFantasia, style: GJTypography.h4(), maxLines: 2, overflow: TextOverflow.ellipsis),
          if (cidade != null) ...[
            const SizedBox(height: GJSpace.s1),
            Text([cidade, estado].whereType<String>().join('/'), style: GJTypography.bodySm()),
          ],
          const SizedBox(height: GJSpace.s2),
          Row(
            children: [
              const Icon(Symbols.star, size: 16, color: GJColors.rating, fill: 1),
              const SizedBox(width: GJSpace.s1),
              Text(
                mediaAvaliacao != null ? '${mediaAvaliacao.toStringAsFixed(1)} (${totalAvaliacoes ?? 0})' : 'Sem avaliações',
                style: GJTypography.bodySm(),
              ),
            ],
          ),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: GJSpace.s2),
            Wrap(spacing: GJSpace.s1, runSpacing: GJSpace.s1, children: tags),
          ],
          const SizedBox(height: GJSpace.s3),
          GJButton(label: 'Saiba mais', variant: GJButtonVariant.secondary, expand: true, onPressed: onTap),
        ],
      ),
    );
  }

  /// Card de um programa (Design System Deck, seção 15): imagem 16:9, ícone
  /// e sigla na cor da categoria, título, descrição e "Ver detalhes".
  factory GJCard.programa({
    Key? key,
    required String imagemUrl,
    required IconData icone,
    required Color cor,
    required String sigla,
    required String nome,
    required String descricao,
    required VoidCallback onTap,
  }) {
    return GJCard(
      key: key,
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(GJRadius.xl)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: GJRemoteOrAssetImage(url: imagemUrl),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(GJSpace.s6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(icone, size: 20, color: cor, fill: 1),
                    const SizedBox(width: GJSpace.s2),
                    Text(sigla, style: GJTypography.eyebrow(color: cor)),
                  ],
                ),
                const SizedBox(height: GJSpace.s3),
                Text(nome, style: GJTypography.h4(), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: GJSpace.s1),
                Text(descricao, style: GJTypography.bodySm(), maxLines: 3, overflow: TextOverflow.ellipsis),
                const SizedBox(height: GJSpace.s3),
                GJButton(label: 'Ver detalhes', variant: GJButtonVariant.secondary, color: cor, expand: true, onPressed: onTap),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Card de um curso (Design System Deck, seção 15): ilustração 16:10 por
  /// área do curso (a especificação não define uma imagem própria por
  /// curso) e o nome centralizado.
  factory GJCard.curso({
    Key? key,
    required String nome,
    required String ilustracao,
    required VoidCallback onTap,
    Widget? rodape,
  }) {
    return GJCard(
      key: key,
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: rodape != null ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(GJRadius.lg)),
            child: AspectRatio(aspectRatio: 16 / 10, child: GJRemoteOrAssetImage(url: ilustracao)),
          ),
          Padding(
            padding: const EdgeInsets.all(GJSpace.s4),
            child: rodape == null
                ? Text(
                    nome,
                    style: GJTypography.label().copyWith(fontSize: 15, color: GJColors.textPrimary),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        nome,
                        style: GJTypography.h4(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: GJSpace.s2),
                      rodape,
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  final Widget child;
  final GJCardVariant variant;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  @override
  State<GJCard> createState() => _GJCardState();
}

class _GJCardState extends State<GJCard> {
  bool _hovered = false;

  Color get _background {
    if (widget.variant == GJCardVariant.elevated) return GJColors.surfaceLowest;
    return _hovered ? GJColors.surface : GJColors.surfaceLow;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final defaultPadding = EdgeInsets.all(isMobile ? GJSpace.s6 : GJSpace.s8);

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: widget.padding ?? defaultPadding,
      decoration: BoxDecoration(
        color: _background,
        borderRadius: GJRadius.borderLg,
        border: widget.variant == GJCardVariant.elevated ? GJShadows.borderSubtle : null,
        boxShadow: widget.variant == GJCardVariant.elevated ? GJShadows.sm : GJShadows.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: widget.child,
    );

    if (widget.onTap == null) return card;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(onTap: widget.onTap, child: card),
    );
  }
}

const _palavrasIgnoradasIniciais = {'de', 'da', 'do', 'dos', 'das', 'e'};

String _iniciais(String nome) {
  final palavras = nome
      .split(RegExp(r'\s+'))
      .where((palavra) => palavra.isNotEmpty && !_palavrasIgnoradasIniciais.contains(palavra.toLowerCase()));
  final letras = palavras.take(3).map((palavra) => palavra[0].toUpperCase()).join();
  return letras.isNotEmpty ? letras : nome.isNotEmpty ? nome[0].toUpperCase() : '?';
}

class _CaixaLogo extends StatelessWidget {
  const _CaixaLogo({required this.logoUrl, required this.nome});

  final String? logoUrl;
  final String nome;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      width: double.infinity,
      padding: const EdgeInsets.all(GJSpace.s4),
      alignment: Alignment.center,
      // Sem logo: caixa com iniciais sobre primary.fixed (fallback do design
      // system quando logo_url é nulo).
      decoration: BoxDecoration(
        color: logoUrl != null ? GJColors.surfaceLowest : GJColors.primaryFixed,
        borderRadius: GJRadius.borderMd,
      ),
      child: logoUrl != null
          ? GJRemoteOrAssetImage(url: logoUrl!, fit: BoxFit.contain)
          : Text(
              _iniciais(nome),
              style: GJTypography.h3().copyWith(color: GJColors.primary),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
    );
  }
}
