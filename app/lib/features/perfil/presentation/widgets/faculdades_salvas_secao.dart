import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/gj_colors.dart';
import '../../../../core/theme/gj_spacing.dart';
import '../../../../shared/utils/programa_estilo.dart';
import '../../../../shared/widgets/gj_aligned_grid.dart';
import '../../../../shared/widgets/gj_card.dart';
import '../../../../shared/widgets/gj_empty_state.dart';
import '../../../../shared/widgets/gj_tag.dart';
import '../../../favoritos/data/favoritos_repository.dart';
import '../../../universidades/domain/universidade.dart';
import 'secao_carregavel.dart';
import '../../../../shared/widgets/gj_aviso.dart';

/// T19 Faculdades salvas (Figura 25, RF24): cards com acesso ao detalhe e
/// opção de remover.
class FaculdadesSalvasSecao extends StatefulWidget {
  const FaculdadesSalvasSecao({super.key});

  @override
  State<FaculdadesSalvasSecao> createState() => _FaculdadesSalvasSecaoState();
}

class _FaculdadesSalvasSecaoState extends State<FaculdadesSalvasSecao> {
  late Future<List<UniversidadeResumo>> _future = favoritosRepository.listarUniversidades();
  final _removendo = <int>{};

  Future<void> _remover(List<UniversidadeResumo> lista, UniversidadeResumo universidade) async {
    setState(() => _removendo.add(universidade.id));
    final mensageiro = ScaffoldMessenger.of(context);
    try {
      await favoritosRepository.removerUniversidade(universidade.id);
      if (!mounted) return;
      // Remove da lista completa (a página mostrada é só uma fatia dela).
      final todas = await _future;
      if (!mounted) return;
      setState(() => todas.remove(universidade));
      mensageiro.aviso('Faculdade removida das salvas.');
    } on ApiException catch (erro) {
      mensageiro.aviso(erro.message, tipo: GJAvisoTipo.erro);
    } finally {
      if (mounted) setState(() => _removendo.remove(universidade.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SecaoCarregavel<UniversidadeResumo>(
      future: _future,
      porPagina: 6,
      descreverTotal: (total) => '$total faculdades salvas',
      // Bloco (não arrow): setState não aceita callback que devolve Future.
      onTentarNovamente: () => setState(() {
        _future = favoritosRepository.listarUniversidades();
      }),
      vazio: GJEmptyState(
        titulo: 'Nenhuma faculdade salva ainda',
        texto: 'Use o ícone de salvar na página de uma universidade para acompanhar as que interessam a você.',
        icone: Symbols.bookmark,
        acaoLabel: 'Pesquisar universidades',
        onAcao: () => context.go('/universidades'),
      ),
      construir: (lista) {
        final cards = [
          for (final universidade in lista)
            GJCard.universidade(
              key: ValueKey('salva-${universidade.id}'),
              nomeFantasia: universidade.nomeFantasia,
              logoUrl: universidade.logoUrl,
              cidade: universidade.cidade,
              estado: universidade.estado,
              mediaAvaliacao: universidade.mediaAvaliacao,
              totalAvaliacoes: universidade.totalAvaliacoes,
              tags: [
                for (final programa in universidade.programas.take(3))
                  GJTag(label: programa.sigla ?? programa.nome, tone: tonePrograma(programa.tipo)),
              ],
              acao: IconButton(
                tooltip: 'Remover das salvas',
                onPressed: _removendo.contains(universidade.id) ? null : () => _remover(lista, universidade),
                icon: const Icon(Symbols.bookmark_remove, color: GJColors.primary),
              ),
              onTap: () => context.go('/universidades/${universidade.id}'),
            ),
        ];

        if (MediaQuery.sizeOf(context).width < 600) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [for (final card in cards) Padding(padding: const EdgeInsets.only(bottom: GJSpace.s4), child: card)],
          );
        }
        return GJAlignedGrid(itemWidth: 280, spacing: GJSpace.s4, runSpacing: GJSpace.s4, children: cards);
      },
    );
  }
}
