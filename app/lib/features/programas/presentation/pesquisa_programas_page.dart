import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/paginated_result.dart';
import '../../../core/theme/gj_spacing.dart';
import '../../../core/theme/gj_typography.dart';
import '../../../shared/layouts/gj_page_container.dart';
import '../../../shared/layouts/public_layout.dart';
import '../../../shared/utils/programa_estilo.dart';
import '../../../shared/widgets/gj_aligned_grid.dart';
import '../../../shared/widgets/gj_card.dart';
import '../../../shared/widgets/gj_empty_state.dart';
import '../../../shared/widgets/gj_input.dart';
import '../../../shared/widgets/gj_skeleton.dart';
import '../../../shared/widgets/gj_tabs.dart';
import '../data/programas_repository.dart';
import '../domain/programa.dart';

class PesquisaProgramasPage extends StatefulWidget {
  const PesquisaProgramasPage({super.key});

  @override
  State<PesquisaProgramasPage> createState() => _PesquisaProgramasPageState();
}

class _PesquisaProgramasPageState extends State<PesquisaProgramasPage> {
  final _qController = TextEditingController();
  String? _tipo;
  int _tabIndex = 0;
  late Future<PaginatedResult<ProgramaResumo>> _future;

  static const _tabs = [
    (label: 'Todos', tipo: null),
    (label: 'Programas de Entrada', tipo: 'ENTRADA'),
    (label: 'Financiamento', tipo: 'FINANCIAMENTO'),
    (label: 'Bolsas de Estudo', tipo: 'BOLSA'),
  ];

  @override
  void initState() {
    super.initState();
    _buscar();
  }

  @override
  void dispose() {
    _qController.dispose();
    super.dispose();
  }

  void _buscar() {
    setState(() {
      _future = programasRepository.listar(FiltrosProgramas(tipo: _tipo, q: _qController.text));
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    return PublicLayout(
      rotaAtiva: PublicRota.programas,
      child: GJPageContainer(
        child: Padding(
        padding: const EdgeInsets.symmetric(vertical: GJSpace.s12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Programas de entrada, financiamento e bolsas de estudo', style: GJTypography.h1()),
            const SizedBox(height: GJSpace.s6),
            SizedBox(
              width: isMobile ? double.infinity : 480,
              child: GJInput(
                label: 'Qual programa deseja ver?',
                hint: 'ENEM, SiSU, FIES, ProUni...',
                icon: Symbols.search,
                controller: _qController,
                onChanged: (_) => _buscar(),
              ),
            ),
            const SizedBox(height: GJSpace.s6),
            GJTabs(
              tabs: [for (final aba in _tabs) GJTabItem(label: aba.label)],
              selectedIndex: _tabIndex,
              onChanged: (index) {
                setState(() {
                  _tabIndex = index;
                  _tipo = _tabs[index].tipo;
                });
                _buscar();
              },
            ),
            const SizedBox(height: GJSpace.s6),
            FutureBuilder<PaginatedResult<ProgramaResumo>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return Wrap(
                    spacing: GJSpace.s6,
                    runSpacing: GJSpace.s6,
                    children: List.generate(4, (_) => const SizedBox(width: 280, child: GJSkeletonCard())),
                  );
                }

                if (snapshot.hasError) {
                  return GJEmptyState(
                    titulo: 'Não foi possível carregar',
                    texto: snapshot.error is ApiException ? (snapshot.error as ApiException).message : 'Tente novamente.',
                    icone: Symbols.wifi_off,
                    acaoLabel: 'Tentar novamente',
                    onAcao: _buscar,
                  );
                }

                final programas = snapshot.data!.data;
                if (programas.isEmpty) {
                  return const GJEmptyState(titulo: 'Nenhum programa encontrado', texto: 'Tente outro termo de busca.');
                }

                final cards = [
                  for (final programa in programas)
                    GJCard.programa(
                      imagemUrl: programa.imagemUrl ?? imagemProgramaPadrao,
                      icone: iconePrograma(programa.sigla, programa.tipo),
                      cor: corPrograma(programa.tipo),
                      sigla: programa.sigla ?? programa.tipo,
                      nome: programa.nome,
                      descricao: programa.descricao,
                      onTap: () => context.go('/programas/${programa.id}'),
                    ),
                ];
                if (isMobile) {
                  return Column(
                    children: [
                      for (final card in cards) Padding(padding: const EdgeInsets.only(bottom: GJSpace.s6), child: card),
                    ],
                  );
                }
                // Cards da mesma linha com a mesma altura.
                return GJAlignedGrid(itemWidth: 280, spacing: GJSpace.s6, runSpacing: GJSpace.s6, children: cards);
              },
            ),
          ],
        ),
        ),
      ),
    );
  }
}
