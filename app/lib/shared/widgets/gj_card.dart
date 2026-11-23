import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/gj_colors.dart';
import '../../core/theme/gj_radius.dart';
import '../../core/theme/gj_shadows.dart';
import '../../core/theme/gj_spacing.dart';
import '../../core/theme/gj_typography.dart';
import 'gj_button.dart';
import 'gj_remote_or_asset_image.dart';
import '../utils/sigla_instituicao.dart';
import '../utils/texto_formatado.dart';

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
  /// nota com estrelas e tags de programas aceitos. [acao], quando informada
  /// (ex.: botão de salvar faculdade), fica no canto superior direito do logo.
  factory GJCard.universidade({
    Key? key,
    required String nomeFantasia,
    String? logoUrl,
    String? cidade,
    String? estado,
    double? mediaAvaliacao,
    int? totalAvaliacoes,
    List<Widget> tags = const [],
    Widget? acao,
    required VoidCallback onTap,
  }) {
    return GJCard(
      key: key,
      onTap: onTap,
      child: _ConteudoComBotao(
        conteudo: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              _CaixaLogo(logoUrl: logoUrl, nome: nomeFantasia),
              if (acao != null) Positioned(top: 0, right: 0, child: acao),
            ],
          ),
          const SizedBox(height: GJSpace.s4),
          Text(nomeFantasia, style: GJTypography.h4(), maxLines: _linhasTitulo, overflow: TextOverflow.ellipsis),
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
        ],
        ),
        botao: GJButton(label: 'Saiba mais', variant: GJButtonVariant.secondary, expand: true, onPressed: onTap),
      ),
    );
  }

  /// Títulos dos cards em até três linhas: nomes longos (ex.: "Fundo de
  /// Financiamento Estudantil") aparecem inteiros nos carrosséis e grades.
  static const int _linhasTitulo = 3;

  /// Card de um programa (Design System Deck, seção 15): imagem 16:9 (foto do
  /// programa, ver shared/utils/fotos.dart), ícone e sigla na cor da
  /// categoria, título, descrição e "Ver detalhes".
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
      child: _ConteudoComBotao(
        conteudo: Column(
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
              padding: const EdgeInsets.fromLTRB(GJSpace.s6, GJSpace.s6, GJSpace.s6, GJSpace.s3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(icone, size: 20, color: cor, fill: 1),
                      const SizedBox(width: GJSpace.s2),
                      Flexible(
                        child: Text(sigla, style: GJTypography.eyebrow(color: cor), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: GJSpace.s3),
                  Text(nome, style: GJTypography.h4(), maxLines: _linhasTitulo, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: GJSpace.s1),
                  // Resumo em texto puro: a descrição do programa é formatada.
                  Text(
                    resumoTextoFormatado(descricao, limite: 240),
                    style: GJTypography.bodySm(),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        botao: Padding(
          padding: const EdgeInsets.fromLTRB(GJSpace.s6, 0, GJSpace.s6, GJSpace.s6),
          child: GJButton(label: 'Ver detalhes', variant: GJButtonVariant.secondary, color: cor, expand: true, onPressed: onTap),
        ),
      ),
    );
  }

  /// Card de um curso (Design System Deck, seção 15): imagem 16:10 (foto do
  /// curso, ou da área quando o curso não tem foto própria, ver
  /// shared/utils/fotos.dart) e o nome centralizado.
  factory GJCard.curso({
    Key? key,
    required String nome,
    required String ilustracao,
    required VoidCallback onTap,
    Widget? rodape,
    String? subtitulo,
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
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        nome,
                        style: GJTypography.label().copyWith(fontSize: 15, color: GJColors.textPrimary),
                        textAlign: TextAlign.center,
                        maxLines: _linhasTitulo,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitulo != null) ...[
                        const SizedBox(height: GJSpace.s1),
                        Text(subtitulo, style: GJTypography.caption(), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        nome,
                        style: GJTypography.h4(),
                        maxLines: _linhasTitulo,
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

/// Conteúdo do card com o botão no rodapé. Quando o card recebe uma altura
/// fixa (carrossel e grade esticam os cards de uma linha até o mais alto),
/// a sobra fica entre o conteúdo e o botão, e os botões da linha se alinham.
/// Sem altura fixa, os dois ficam colados como antes.
class _ConteudoComBotao extends StatelessWidget {
  const _ConteudoComBotao({required this.conteudo, required this.botao});

  final Widget conteudo;
  final Widget botao;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.min,
      children: [conteudo, botao],
    );
  }
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
      // Sem logo: caixa com a sigla sobre primary.fixed (fallback do design
      // system quando logo_url é nulo).
      decoration: BoxDecoration(
        color: logoUrl != null ? GJColors.surfaceLowest : GJColors.primaryFixed,
        borderRadius: GJRadius.borderMd,
      ),
      child: logoUrl != null
          ? GJRemoteOrAssetImage(url: logoUrl!, fit: BoxFit.contain)
          : Text(
              siglaDaInstituicao(nome),
              style: GJTypography.h3().copyWith(color: GJColors.primary),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
    );
  }
}
