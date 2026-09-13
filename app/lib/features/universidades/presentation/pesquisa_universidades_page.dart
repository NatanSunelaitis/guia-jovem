import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/paginated_result.dart';
import '../../../core/theme/gj_colors.dart';
import '../../../core/theme/gj_spacing.dart';
import '../../../core/theme/gj_typography.dart';
import '../../../shared/layouts/public_layout.dart';
import '../../../shared/widgets/gj_button.dart';
import '../../../shared/widgets/gj_card.dart';
import '../../../shared/widgets/gj_empty_state.dart';
import '../../../shared/widgets/gj_input.dart';
import '../../../shared/widgets/gj_skeleton.dart';
import '../../../shared/widgets/gj_tag.dart';
import '../data/universidades_repository.dart';
import '../domain/universidade.dart';

class PesquisaUniversidadesPage extends StatefulWidget {
  const PesquisaUniversidadesPage({super.key, this.filtrosIniciais});

  final Map<String, String>? filtrosIniciais;

  @override
  State<PesquisaUniversidadesPage> createState() => _PesquisaUniversidadesPageState();
}

class _PesquisaUniversidadesPageState extends State<PesquisaUniversidadesPage> {
  late FiltrosUniversidades _filtros;
  late Future<PaginatedResult<UniversidadeResumo>> _future;
  final _qController = TextEditingController();
  final _cidadeController = TextEditingController();
  String? _natureza;
  String _sort = 'nome';
  int? _programaId;

  @override
  void initState() {
    super.initState();
    final iniciais = widget.filtrosIniciais ?? const {};
    _qController.text = iniciais['q'] ?? '';
    _cidadeController.text = iniciais['cidade'] ?? '';
    _programaId = int.tryParse(iniciais['programaId'] ?? '');
    _filtros = FiltrosUniversidades(q: _qController.text, cidade: _cidadeController.text);
    _buscar();
  }

  @override
  void dispose() {
    _qController.dispose();
    _cidadeController.dispose();
    super.dispose();
  }

  void _buscar({int page = 1}) {
    setState(() {
      _filtros = FiltrosUniversidades(
        q: _qController.text,
        cidade: _cidadeController.text,
        natureza: _natureza,
        programaId: _programaId,
        sort: _sort,
        page: page,
      );
      _future = universidadesRepository.listar(_filtros);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    return PublicLayout(
      rotaAtiva: PublicRota.universidades,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? GJSpace.s4 : GJSpace.s16, vertical: GJSpace.s12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pesquisa de universidades', style: GJTypography.h1()),
            const SizedBox(height: GJSpace.s6),
            _filtrosCard(isMobile),
            const SizedBox(height: GJSpace.s8),
            FutureBuilder<PaginatedResult<UniversidadeResumo>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return _grade(isMobile, List.generate(6, (_) => const GJSkeletonCard()));
                }

                if (snapshot.hasError) {
                  return GJEmptyState(
                    titulo: 'Não foi possível carregar',
                    texto: snapshot.error is ApiException ? (snapshot.error as ApiException).message : 'Tente novamente.',
                    icone: Symbols.wifi_off,
                    acaoLabel: 'Tentar novamente',
                    onAcao: () => _buscar(page: _filtros.page),
                  );
                }

                final resultado = snapshot.data!;
                if (resultado.data.isEmpty) {
                  return const GJEmptyState(
                    titulo: 'Nenhuma universidade encontrada',
                    texto: 'Tente remover alguns filtros ou pesquisar por outra cidade.',
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${resultado.total} universidade(s) encontrada(s)', style: GJTypography.bodySm()),
                    const SizedBox(height: GJSpace.s4),
                    _grade(isMobile, [for (final u in resultado.data) _CardUniversidadeGrid(universidade: u)]),
                    const SizedBox(height: GJSpace.s6),
                    if (resultado.totalPages > 1) _paginacao(resultado),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _paginacao(PaginatedResult<UniversidadeResumo> resultado) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Symbols.chevron_left),
          onPressed: resultado.page > 1 ? () => _buscar(page: resultado.page - 1) : null,
        ),
        Text('Página ${resultado.page} de ${resultado.totalPages}', style: GJTypography.bodySm()),
        IconButton(
          icon: const Icon(Symbols.chevron_right),
          onPressed: resultado.page < resultado.totalPages ? () => _buscar(page: resultado.page + 1) : null,
        ),
      ],
    );
  }

  Widget _grade(bool isMobile, List<Widget> cards) {
    return Wrap(
      spacing: GJSpace.s4,
      runSpacing: GJSpace.s4,
      children: [for (final card in cards) SizedBox(width: isMobile ? double.infinity : 300, child: card)],
    );
  }

  Widget _filtrosCard(bool isMobile) {
    final campos = [
      GJInput(label: 'Universidade', hint: 'Nome da universidade', controller: _qController, icon: Symbols.search),
      GJInput(label: 'Cidade', hint: 'Cidade', controller: _cidadeController, icon: Symbols.location_on),
    ];

    return Container(
      padding: const EdgeInsets.all(GJSpace.s6),
      decoration: BoxDecoration(color: GJColors.surfaceLow, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          isMobile
              ? Column(children: [for (final campo in campos) Padding(padding: const EdgeInsets.only(bottom: GJSpace.s3), child: campo)])
              : Row(
                  children: [
                    for (final campo in campos)
                      Expanded(child: Padding(padding: const EdgeInsets.only(right: GJSpace.s4), child: campo)),
                  ],
                ),
          const SizedBox(height: GJSpace.s3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Spacer só existe dentro de Row/Column (Flex); dentro de um
              // Wrap ele derruba a tela (ParentData incompatível). O botão
              // fica de fora do Wrap, como irmão dele nesta Row.
              Expanded(
                child: Wrap(
                  spacing: GJSpace.s2,
                  runSpacing: GJSpace.s2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ChoiceChip(label: const Text('Todas'), selected: _natureza == null, onSelected: (_) => setState(() { _natureza = null; _buscar(); })),
                    ChoiceChip(label: const Text('Públicas/Federais'), selected: _natureza == 'P', onSelected: (_) => setState(() { _natureza = 'P'; _buscar(); })),
                    ChoiceChip(label: const Text('Privadas'), selected: _natureza == 'V', onSelected: (_) => setState(() { _natureza = 'V'; _buscar(); })),
                    const SizedBox(width: GJSpace.s4),
                    DropdownButton<String>(
                      value: _sort,
                      underline: const SizedBox.shrink(),
                      items: const [
                        DropdownMenuItem(value: 'nome', child: Text('Ordenar por nome')),
                        DropdownMenuItem(value: 'media', child: Text('Ordenar por média')),
                        DropdownMenuItem(value: 'avaliacoes', child: Text('Ordenar por avaliações')),
                      ],
                      onChanged: (valor) => setState(() { _sort = valor ?? 'nome'; _buscar(); }),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: GJSpace.s4),
              GJButton(label: 'Pesquisar', icon: Symbols.search, onPressed: () => _buscar()),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardUniversidadeGrid extends StatelessWidget {
  const _CardUniversidadeGrid({required this.universidade});

  final UniversidadeResumo universidade;

  @override
  Widget build(BuildContext context) {
    return GJCard(
      onTap: () => context.go('/universidades/${universidade.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(universidade.nomeFantasia, style: GJTypography.h4()),
          const SizedBox(height: GJSpace.s1),
          Text(
            [universidade.cidade, universidade.estado].where((v) => v != null).join('/'),
            style: GJTypography.bodySm(),
          ),
          const SizedBox(height: GJSpace.s2),
          Row(
            children: [
              const Icon(Symbols.star, size: 16, color: GJColors.rating, fill: 1),
              const SizedBox(width: GJSpace.s1),
              Text(
                universidade.mediaAvaliacao != null
                    ? '${universidade.mediaAvaliacao!.toStringAsFixed(1)} (${universidade.totalAvaliacoes})'
                    : 'Sem avaliações',
                style: GJTypography.bodySm(),
              ),
            ],
          ),
          const SizedBox(height: GJSpace.s2),
          Wrap(
            spacing: GJSpace.s1,
            children: [
              for (final programa in universidade.programas.take(3))
                GJTag(
                  label: programa.sigla ?? programa.nome,
                  tone: switch (programa.tipo) {
                    'FINANCIAMENTO' => GJTagTone.financiamento,
                    'BOLSA' => GJTagTone.bolsa,
                    _ => GJTagTone.entrada,
                  },
                ),
            ],
          ),
          const SizedBox(height: GJSpace.s3),
          GJButton(label: 'Saiba mais', variant: GJButtonVariant.secondary, expand: true, onPressed: () => context.go('/universidades/${universidade.id}')),
        ],
      ),
    );
  }
}
