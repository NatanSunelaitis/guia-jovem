import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/gj_colors.dart';
import '../../core/theme/gj_spacing.dart';
import '../../core/theme/gj_typography.dart';

/// Carrossel horizontal do Design System Deck (seção 15, usado em "Faculdades"
/// e "Programas de Entrada" da home): título + link "Ver todas" + setas na
/// mesma linha, e uma faixa rolável abaixo cuja altura acompanha o conteúdo
/// dos cards (sem SizedBox de altura fixa "cortando" cards maiores).
class GJCarousel extends StatefulWidget {
  const GJCarousel({
    super.key,
    required this.titulo,
    this.onVerTodas,
    this.verTodasLabel = 'Ver todas',
    required this.itemCount,
    required this.itemBuilder,
    this.itemWidth = 280,
    this.gap = GJSpace.s6,
  });

  final String titulo;
  final VoidCallback? onVerTodas;
  final String verTodasLabel;
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final double itemWidth;
  final double gap;

  @override
  State<GJCarousel> createState() => _GJCarouselState();
}

class _GJCarouselState extends State<GJCarousel> {
  final _controller = ScrollController();
  bool _podeVoltar = false;
  bool _podeAvancar = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_atualizarSetas);
    WidgetsBinding.instance.addPostFrameCallback((_) => _atualizarSetas());
  }

  @override
  void dispose() {
    _controller.removeListener(_atualizarSetas);
    _controller.dispose();
    super.dispose();
  }

  void _atualizarSetas() {
    if (!_controller.hasClients) return;
    final posicao = _controller.position;
    setState(() {
      _podeVoltar = posicao.pixels > 0;
      _podeAvancar = posicao.pixels < posicao.maxScrollExtent - 1;
    });
  }

  void _rolar(double delta) {
    if (!_controller.hasClients) return;
    final alvo = (_controller.offset + delta).clamp(0.0, _controller.position.maxScrollExtent);
    _controller.animateTo(alvo, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final passo = widget.itemWidth + widget.gap;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(widget.titulo, style: GJTypography.h2(), maxLines: 1, overflow: TextOverflow.ellipsis)),
            if (widget.onVerTodas != null) ...[
              TextButton(onPressed: widget.onVerTodas, child: Text(widget.verTodasLabel)),
              const SizedBox(width: GJSpace.s4),
            ],
            _SetaCarousel(icone: Symbols.chevron_left, ativa: _podeVoltar, preenchida: false, onTap: () => _rolar(-passo)),
            const SizedBox(width: GJSpace.s2),
            _SetaCarousel(icone: Symbols.chevron_right, ativa: _podeAvancar, preenchida: true, onTap: () => _rolar(passo)),
          ],
        ),
        const SizedBox(height: GJSpace.s4),
        SingleChildScrollView(
          controller: _controller,
          scrollDirection: Axis.horizontal,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < widget.itemCount; i++) ...[
                  if (i > 0) SizedBox(width: widget.gap),
                  SizedBox(width: widget.itemWidth, child: widget.itemBuilder(context, i)),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SetaCarousel extends StatelessWidget {
  const _SetaCarousel({required this.icone, required this.ativa, required this.preenchida, required this.onTap});

  final IconData icone;
  final bool ativa;
  final bool preenchida;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final corFundo = preenchida ? GJColors.primary : GJColors.surfaceLowest;
    final corIcone = preenchida ? GJColors.primaryOn : GJColors.textSecondary;

    return Opacity(
      opacity: ativa ? 1 : 0.4,
      child: MouseRegion(
        cursor: ativa ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          onTap: ativa ? onTap : null,
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: corFundo,
              shape: BoxShape.circle,
              border: preenchida ? null : Border.all(color: GJColors.border),
            ),
            child: Icon(icone, size: 20, color: corIcone),
          ),
        ),
      ),
    );
  }
}
