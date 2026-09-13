import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/gj_colors.dart';
import '../../core/theme/gj_radius.dart';
import '../../core/theme/gj_shadows.dart';
import '../../core/theme/gj_spacing.dart';
import '../../core/theme/gj_typography.dart';
import 'gj_button.dart';
import 'gj_input.dart';

class GJDataColumn {
  const GJDataColumn(this.label, {this.flex = 1});

  final String label;
  final int flex;
}

/// Tabela de painel administrativo (seção 3.14): busca + ação primária,
/// cabeçalho, linhas e paginação.
class GJDataTable extends StatelessWidget {
  const GJDataTable({
    super.key,
    required this.colunas,
    required this.linhas,
    this.buscaHint,
    this.onBuscaChanged,
    this.acaoPrimariaLabel,
    this.onAcaoPrimaria,
    this.paginaAtual = 1,
    this.totalPaginas = 1,
    this.onPaginaChanged,
    this.vazio,
  });

  final List<GJDataColumn> colunas;
  final List<List<Widget>> linhas;
  final String? buscaHint;
  final ValueChanged<String>? onBuscaChanged;
  final String? acaoPrimariaLabel;
  final VoidCallback? onAcaoPrimaria;
  final int paginaAtual;
  final int totalPaginas;
  final ValueChanged<int>? onPaginaChanged;
  final Widget? vazio;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GJColors.surfaceLowest,
        borderRadius: GJRadius.borderLg,
        border: GJShadows.borderSubtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (buscaHint != null || acaoPrimariaLabel != null)
            Padding(
              padding: const EdgeInsets.all(GJSpace.s4),
              child: Row(
                children: [
                  if (buscaHint != null)
                    SizedBox(
                      width: 280,
                      child: GJInput(
                        label: '',
                        hint: buscaHint,
                        icon: Symbols.search,
                        onChanged: onBuscaChanged,
                      ),
                    ),
                  const Spacer(),
                  if (acaoPrimariaLabel != null)
                    GJButton(label: acaoPrimariaLabel!, icon: Symbols.add, onPressed: onAcaoPrimaria),
                ],
              ),
            ),
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: GJSpace.s6),
            color: GJColors.surfaceLow,
            child: Row(
              children: [
                for (final coluna in colunas)
                  Expanded(
                    flex: coluna.flex,
                    child: Text(coluna.label, style: GJTypography.label()),
                  ),
              ],
            ),
          ),
          if (linhas.isEmpty)
            Padding(
              padding: const EdgeInsets.all(GJSpace.s8),
              child: vazio ?? Text('Nenhum registro encontrado.', style: GJTypography.bodySm()),
            )
          else
            for (final linha in linhas) _GJDataRow(colunas: colunas, celulas: linha),
          if (totalPaginas > 1)
            Padding(
              padding: const EdgeInsets.all(GJSpace.s4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Página $paginaAtual de $totalPaginas', style: GJTypography.bodySm()),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Symbols.chevron_left),
                        onPressed: paginaAtual > 1 ? () => onPaginaChanged?.call(paginaAtual - 1) : null,
                      ),
                      IconButton(
                        icon: const Icon(Symbols.chevron_right),
                        onPressed:
                            paginaAtual < totalPaginas ? () => onPaginaChanged?.call(paginaAtual + 1) : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _GJDataRow extends StatelessWidget {
  const _GJDataRow({required this.colunas, required this.celulas});

  final List<GJDataColumn> colunas;
  final List<Widget> celulas;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: GJSpace.s6, vertical: GJSpace.s2),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: GJColors.surfaceDim)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < colunas.length; i++)
            Expanded(
              flex: colunas[i].flex,
              child: Align(alignment: Alignment.centerLeft, child: celulas[i]),
            ),
        ],
      ),
    );
  }
}
