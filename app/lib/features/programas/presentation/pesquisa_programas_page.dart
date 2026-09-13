import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/paginated_result.dart';
import '../../../core/theme/gj_colors.dart';
import '../../../core/theme/gj_spacing.dart';
import '../../../core/theme/gj_typography.dart';
import '../../../shared/layouts/public_layout.dart';
import '../../../shared/widgets/gj_card.dart';
import '../../../shared/widgets/gj_empty_state.dart';
import '../../../shared/widgets/gj_input.dart';
import '../../../shared/widgets/gj_skeleton.dart';
import '../../../shared/widgets/gj_tabs.dart';
import '../../../shared/widgets/gj_tag.dart';
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
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? GJSpace.s4 : GJSpace.s16, vertical: GJSpace.s12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Escolha o Programa de Entrada que deseja ver', style: GJTypography.h1()),
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
                    spacing: GJSpace.s4,
                    runSpacing: GJSpace.s4,
                    children: List.generate(6, (_) => const SizedBox(width: 280, child: GJSkeletonCard())),
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

                return Wrap(
                  spacing: GJSpace.s4,
                  runSpacing: GJSpace.s4,
                  children: [
                    for (final programa in programas)
                      SizedBox(width: isMobile ? double.infinity : 280, child: _CardPrograma(programa: programa)),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CardPrograma extends StatelessWidget {
  const _CardPrograma({required this.programa});

  final ProgramaResumo programa;

  @override
  Widget build(BuildContext context) {
    final tone = switch (programa.tipo) {
      'FINANCIAMENTO' => GJTagTone.financiamento,
      'BOLSA' => GJTagTone.bolsa,
      _ => GJTagTone.entrada,
    };
    final cor = switch (programa.tipo) {
      'FINANCIAMENTO' => GJColors.tertiary,
      'BOLSA' => GJColors.secondary,
      _ => GJColors.primary,
    };

    return GJCard(
      onTap: () => context.go('/programas/${programa.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Symbols.school, color: cor, size: 28),
          const SizedBox(height: GJSpace.s3),
          GJTag(label: programa.sigla ?? programa.tipo, tone: tone),
          const SizedBox(height: GJSpace.s2),
          Text(programa.nome, style: GJTypography.h4(), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: GJSpace.s1),
          Text(programa.descricao, style: GJTypography.bodySm(), maxLines: 3, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
