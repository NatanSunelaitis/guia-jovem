import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/network/api_exception.dart';
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
import '../../cursos/data/cursos_repository.dart';
import '../../cursos/domain/curso.dart';
import '../../programas/data/programas_repository.dart';
import '../../programas/domain/programa.dart';
import '../../universidades/data/universidades_repository.dart';
import '../../universidades/domain/universidade.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<UniversidadeResumo>> _universidades;
  late Future<List<ProgramaResumo>> _programas;
  late Future<List<CursoDestaque>> _cursos;

  final _cidadeController = TextEditingController();
  final _cursoController = TextEditingController();
  final _universidadeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _universidades = universidadesRepository.destaques();
    _programas = programasRepository.destaques();
    _cursos = cursosRepository.destaques();
  }

  @override
  void dispose() {
    _cidadeController.dispose();
    _cursoController.dispose();
    _universidadeController.dispose();
    super.dispose();
  }

  void _pesquisar() {
    context.go(
      '/universidades',
      extra: {'cidade': _cidadeController.text, 'q': _universidadeController.text, 'areaCurso': _cursoController.text},
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    return PublicLayout(
      rotaAtiva: PublicRota.inicio,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? GJSpace.s4 : GJSpace.s16, vertical: GJSpace.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Encontre seu caminho para a universidade',
              style: (isMobile ? GJTypography.h1() : GJTypography.display()),
            ),
            const SizedBox(height: GJSpace.s6),
            _buscaHero(isMobile),
            const SizedBox(height: GJSpace.s24),
            _SecaoDestaques<UniversidadeResumo>(
              titulo: 'Faculdades',
              future: _universidades,
              onVerTodas: () => context.go('/universidades'),
              itemBuilder: (universidade) => _CardUniversidade(universidade: universidade),
              vazio: 'Nenhuma universidade em destaque no momento.',
            ),
            const SizedBox(height: GJSpace.s16),
            _SecaoDestaques<ProgramaResumo>(
              titulo: 'Programas de Entrada',
              future: _programas,
              onVerTodas: () => context.go('/programas'),
              itemBuilder: (programa) => _CardPrograma(programa: programa),
              vazio: 'Nenhum programa em destaque no momento.',
            ),
            const SizedBox(height: GJSpace.s16),
            _SecaoDestaques<CursoDestaque>(
              titulo: 'Principais Cursos Disponíveis',
              future: _cursos,
              onVerTodas: () => context.go('/cursos'),
              itemBuilder: (curso) => _CardCurso(curso: curso),
              vazio: 'Nenhum curso em destaque no momento.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buscaHero(bool isMobile) {
    final campos = [
      GJInput(label: 'Cidade', hint: 'Escolha uma cidade', controller: _cidadeController, icon: Symbols.location_on),
      GJInput(label: 'Curso', hint: 'Curso que deseja estudar', controller: _cursoController, icon: Symbols.menu_book),
      GJInput(label: 'Faculdade', hint: 'Faculdade que deseja estudar', controller: _universidadeController, icon: Symbols.account_balance),
    ];

    return Container(
      padding: const EdgeInsets.all(GJSpace.s6),
      decoration: BoxDecoration(color: GJColors.surfaceLowest, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isMobile)
            Column(children: [for (final campo in campos) Padding(padding: const EdgeInsets.only(bottom: GJSpace.s3), child: campo)])
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final campo in campos)
                  Expanded(child: Padding(padding: const EdgeInsets.only(right: GJSpace.s4), child: campo)),
              ],
            ),
          const SizedBox(height: GJSpace.s2),
          GJButton(label: 'Pesquisar', icon: Symbols.search, expand: isMobile, onPressed: _pesquisar),
        ],
      ),
    );
  }
}

class _SecaoDestaques<T> extends StatelessWidget {
  const _SecaoDestaques({
    required this.titulo,
    required this.future,
    required this.onVerTodas,
    required this.itemBuilder,
    required this.vazio,
  });

  final String titulo;
  final Future<List<T>> future;
  final VoidCallback onVerTodas;
  final Widget Function(T item) itemBuilder;
  final String vazio;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(titulo, style: GJTypography.h2(), maxLines: 1, overflow: TextOverflow.ellipsis)),
            TextButton(onPressed: onVerTodas, child: const Text('Ver todas')),
          ],
        ),
        const SizedBox(height: GJSpace.s4),
        SizedBox(
          height: 260,
          child: FutureBuilder<List<T>>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 3,
                  separatorBuilder: (_, __) => const SizedBox(width: GJSpace.s4),
                  itemBuilder: (_, __) => const SizedBox(width: 260, child: GJSkeletonCard()),
                );
              }

              if (snapshot.hasError) {
                return GJEmptyState(
                  titulo: 'Não foi possível carregar',
                  texto: (snapshot.error is ApiException) ? (snapshot.error as ApiException).message : 'Tente novamente.',
                  icone: Symbols.wifi_off,
                );
              }

              final itens = snapshot.data ?? [];
              if (itens.isEmpty) {
                return GJEmptyState(titulo: 'Nada por aqui ainda', texto: vazio);
              }

              return ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: itens.length,
                separatorBuilder: (_, __) => const SizedBox(width: GJSpace.s4),
                itemBuilder: (context, index) => SizedBox(width: 260, child: itemBuilder(itens[index])),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CardUniversidade extends StatelessWidget {
  const _CardUniversidade({required this.universidade});

  final UniversidadeResumo universidade;

  @override
  Widget build(BuildContext context) {
    return GJCard(
      onTap: () => context.go('/universidades/${universidade.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(universidade.nomeFantasia, style: GJTypography.h4(), maxLines: 1, overflow: TextOverflow.ellipsis),
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
              for (final programa in universidade.programas.take(2))
                GJTag(label: programa.sigla ?? programa.nome, tone: _tonePorTipo(programa.tipo)),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardPrograma extends StatelessWidget {
  const _CardPrograma({required this.programa});

  final ProgramaResumo programa;

  @override
  Widget build(BuildContext context) {
    return GJCard(
      onTap: () => context.go('/programas/${programa.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GJTag(label: programa.sigla ?? programa.tipo, tone: _tonePorTipo(programa.tipo)),
          const SizedBox(height: GJSpace.s2),
          Text(programa.nome, style: GJTypography.h4(), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: GJSpace.s1),
          Text(programa.descricao, style: GJTypography.bodySm(), maxLines: 3, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _CardCurso extends StatelessWidget {
  const _CardCurso({required this.curso});

  final CursoDestaque curso;

  @override
  Widget build(BuildContext context) {
    return GJCard(
      onTap: () => context.go('/cursos/nome/${Uri.encodeComponent(curso.nome)}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Symbols.menu_book, size: 32, color: GJColors.primary),
          const SizedBox(height: GJSpace.s3),
          Text(curso.nome, style: GJTypography.label().copyWith(fontSize: 16), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: GJSpace.s1),
          Text('${curso.totalOfertas} universidades', style: GJTypography.caption()),
        ],
      ),
    );
  }
}

GJTagTone _tonePorTipo(String tipo) => switch (tipo) {
      'FINANCIAMENTO' => GJTagTone.financiamento,
      'BOLSA' => GJTagTone.bolsa,
      _ => GJTagTone.entrada,
    };
