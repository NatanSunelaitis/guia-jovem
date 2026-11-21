import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/gj_spacing.dart';
import '../../../../core/theme/gj_typography.dart';
import '../../../../shared/widgets/gj_empty_state.dart';
import '../../../../shared/widgets/gj_lista_paginada.dart';
import '../../../../shared/widgets/gj_skeleton.dart';

/// Estados comuns das seções do perfil e do painel: carregando, erro com
/// "Tentar novamente", vazio e a lista.
///
/// Com [porPagina], mostra a lista em páginas, com a paginação embaixo, e
/// [construir] recebe só os itens da página atual. Para remover um item,
/// a seção altera a lista completa (o resultado do próprio [future]) e chama
/// setState; a página volta uma se ficar vazia.
class SecaoCarregavel<T> extends StatefulWidget {
  const SecaoCarregavel({
    super.key,
    required this.future,
    required this.onTentarNovamente,
    required this.vazio,
    required this.construir,
    this.porPagina,
    this.descreverTotal,
  });

  final Future<List<T>> future;
  final VoidCallback onTentarNovamente;
  final Widget vazio;
  final Widget Function(List<T> itens) construir;
  final int? porPagina;

  /// Texto do total acima da lista (ex.: "30 faculdades salvas"), só quando
  /// há mais de uma página.
  final String Function(int total)? descreverTotal;

  @override
  State<SecaoCarregavel<T>> createState() => _SecaoCarregavelState<T>();
}

class _SecaoCarregavelState<T> extends State<SecaoCarregavel<T>> {
  int _pagina = 1;

  @override
  void didUpdateWidget(covariant SecaoCarregavel<T> antigo) {
    super.didUpdateWidget(antigo);
    if (!identical(antigo.future, widget.future)) _pagina = 1;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<T>>(
      future: widget.future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Column(
            children: [
              for (var i = 0; i < 3; i++)
                const Padding(padding: EdgeInsets.only(bottom: GJSpace.s3), child: GJSkeleton(height: GJSpace.s24)),
            ],
          );
        }

        if (snapshot.hasError) {
          final erro = snapshot.error;
          return GJEmptyState(
            titulo: 'Não foi possível carregar',
            texto: erro is ApiException ? erro.message : 'Tente novamente.',
            icone: Symbols.wifi_off,
            acaoLabel: 'Tentar novamente',
            onAcao: widget.onTentarNovamente,
          );
        }

        final itens = snapshot.data!;
        if (itens.isEmpty) return widget.vazio;
        final porPagina = widget.porPagina;
        if (porPagina == null || itens.length <= porPagina) return widget.construir(itens);

        final totalPaginas = (itens.length / porPagina).ceil();
        final pagina = _pagina.clamp(1, totalPaginas);
        final inicio = (pagina - 1) * porPagina;
        final fatia = itens.sublist(inicio, (inicio + porPagina).clamp(0, itens.length));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.descreverTotal != null) ...[
              Text(widget.descreverTotal!(itens.length), style: GJTypography.bodySm()),
              const SizedBox(height: GJSpace.s3),
            ],
            widget.construir(fatia),
            const SizedBox(height: GJSpace.s4),
            GJPaginacao(pagina: pagina, totalPaginas: totalPaginas, onMudar: (nova) => setState(() => _pagina = nova)),
          ],
        );
      },
    );
  }
}
