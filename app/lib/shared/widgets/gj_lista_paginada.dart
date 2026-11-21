import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/network/api_exception.dart';
import '../../core/network/paginated_result.dart';
import '../../core/theme/gj_colors.dart';
import '../../core/theme/gj_radius.dart';
import '../../core/theme/gj_spacing.dart';
import '../../core/theme/gj_typography.dart';
import 'gj_empty_state.dart';
import 'gj_input.dart';
import 'gj_skeleton.dart';

/// "‹ Página 2 de 8 ›", com os botões desligados nas pontas.
class GJPaginacao extends StatelessWidget {
  const GJPaginacao({super.key, required this.pagina, required this.totalPaginas, required this.onMudar});

  final int pagina;
  final int totalPaginas;
  final ValueChanged<int> onMudar;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          tooltip: 'Página anterior',
          icon: const Icon(Symbols.chevron_left),
          onPressed: pagina > 1 ? () => onMudar(pagina - 1) : null,
        ),
        Text('Página $pagina de $totalPaginas', style: GJTypography.bodySm()),
        IconButton(
          tooltip: 'Próxima página',
          icon: const Icon(Symbols.chevron_right),
          onPressed: pagina < totalPaginas ? () => onMudar(pagina + 1) : null,
        ),
      ],
    );
  }
}

/// Carrega uma página. [busca] e [filtro] chegam nulos quando vazios.
typedef CarregarPagina<T> = Future<PaginatedResult<T>> Function({required int pagina, String? busca, String? filtro});

/// Lista paginada pela API com campo de busca e, opcionalmente, um filtro de
/// opções (ex.: área do curso). Mostra o total, carregamento, erro com
/// "Tentar novamente", estado vazio e a paginação. Feita para listas que
/// podem crescer (dezenas de itens), no lugar de carregar tudo de uma vez.
class GJListaPaginada<T> extends StatefulWidget {
  const GJListaPaginada({
    super.key,
    required this.carregar,
    required this.construirItens,
    required this.dicaBusca,
    required this.descreverTotal,
    required this.textoVazio,
    this.rotuloFiltro,
    this.opcoesFiltro = const [],
  });

  final CarregarPagina<T> carregar;
  final Widget Function(BuildContext context, List<T> itens) construirItens;
  final String dicaBusca;
  final String Function(int total) descreverTotal;
  final String textoVazio;

  /// Filtro opcional (lista de opções), mostrado ao lado da busca.
  final String? rotuloFiltro;
  final List<String> opcoesFiltro;

  @override
  State<GJListaPaginada<T>> createState() => _GJListaPaginadaState<T>();
}

class _GJListaPaginadaState<T> extends State<GJListaPaginada<T>> {
  final _busca = TextEditingController();
  Timer? _espera;
  String? _filtro;
  int _pagina = 1;
  late Future<PaginatedResult<T>> _future = _buscar();

  Future<PaginatedResult<T>> _buscar() {
    final termo = _busca.text.trim();
    return widget.carregar(pagina: _pagina, busca: termo.isEmpty ? null : termo, filtro: _filtro);
  }

  void _recarregar({int pagina = 1}) {
    setState(() {
      _pagina = pagina;
      _future = _buscar();
    });
  }

  void _aoDigitar(String _) {
    _espera?.cancel();
    _espera = Timer(const Duration(milliseconds: 400), () {
      if (mounted) _recarregar();
    });
  }

  @override
  void dispose() {
    _espera?.cancel();
    _busca.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final celular = MediaQuery.sizeOf(context).width < 600;
    final campoBusca = GJInput(
      label: '',
      hint: widget.dicaBusca,
      icon: Symbols.search,
      controller: _busca,
      onChanged: _aoDigitar,
    );
    final filtro = widget.rotuloFiltro == null || widget.opcoesFiltro.isEmpty
        ? null
        : Container(
            padding: const EdgeInsets.symmetric(horizontal: GJSpace.s4),
            decoration: BoxDecoration(color: GJColors.surfaceLowest, borderRadius: GJRadius.borderMd),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                key: const Key('lista-paginada-filtro'),
                value: _filtro,
                isExpanded: true,
                hint: Text(widget.rotuloFiltro!, style: GJTypography.body()),
                items: [
                  DropdownMenuItem<String?>(value: null, child: Text('${widget.rotuloFiltro}: todas', style: GJTypography.body())),
                  for (final opcao in widget.opcoesFiltro)
                    DropdownMenuItem<String?>(value: opcao, child: Text(opcao, style: GJTypography.body())),
                ],
                onChanged: (valor) {
                  _filtro = valor;
                  _recarregar();
                },
              ),
            ),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (celular || filtro == null) ...[
          campoBusca,
          if (filtro != null) ...[const SizedBox(height: GJSpace.s3), filtro],
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(flex: 3, child: campoBusca),
              const SizedBox(width: GJSpace.s4),
              Expanded(flex: 2, child: filtro),
            ],
          ),
        const SizedBox(height: GJSpace.s4),
        FutureBuilder<PaginatedResult<T>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) return const GJSkeletonCard();
            if (snapshot.hasError) {
              final erro = snapshot.error;
              return GJEmptyState(
                titulo: 'Não foi possível carregar a lista',
                texto: erro is ApiException ? erro.message : 'Tente novamente.',
                icone: Symbols.wifi_off,
                acaoLabel: 'Tentar novamente',
                onAcao: () => _recarregar(pagina: _pagina),
              );
            }
            final resultado = snapshot.data!;
            if (resultado.data.isEmpty) return GJEmptyState(titulo: widget.textoVazio, icone: Symbols.search_off);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(widget.descreverTotal(resultado.total), style: GJTypography.bodySm()),
                const SizedBox(height: GJSpace.s3),
                widget.construirItens(context, resultado.data),
                if (resultado.totalPages > 1) ...[
                  const SizedBox(height: GJSpace.s4),
                  GJPaginacao(
                    pagina: resultado.page,
                    totalPaginas: resultado.totalPages,
                    onMudar: (pagina) => _recarregar(pagina: pagina),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Tira acentos e caixa, para a busca local achar "tatui" em "Tatuí".
String normalizarBusca(String texto) {
  const de = 'áàâãäéèêëíìîïóòôõöúùûüçÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ';
  const para = 'aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC';
  final buffer = StringBuffer();
  for (final c in texto.split('')) {
    final i = de.indexOf(c);
    buffer.write(i >= 0 ? para[i] : c);
  }
  return buffer.toString().toLowerCase();
}

/// Pagina na memória uma lista que já veio inteira da API, para usar o
/// [GJListaPaginada] do mesmo jeito. [texto] diz onde buscar e [categoria]
/// o valor comparado com o filtro.
Future<PaginatedResult<T>> paginarLocal<T>(
  List<T> itens, {
  required int pagina,
  required int porPagina,
  String? busca,
  String? filtro,
  required String Function(T item) texto,
  String? Function(T item)? categoria,
}) async {
  final termo = busca == null ? null : normalizarBusca(busca);
  final filtrados = [
    for (final item in itens)
      if ((termo == null || normalizarBusca(texto(item)).contains(termo)) && (filtro == null || categoria?.call(item) == filtro)) item,
  ];
  final totalPaginas = filtrados.isEmpty ? 1 : (filtrados.length / porPagina).ceil();
  final atual = pagina.clamp(1, totalPaginas);
  final inicio = (atual - 1) * porPagina;
  return PaginatedResult(
    data: filtrados.sublist(inicio.clamp(0, filtrados.length), (inicio + porPagina).clamp(0, filtrados.length)),
    page: atual,
    pageSize: porPagina,
    total: filtrados.length,
    totalPages: totalPaginas,
  );
}
