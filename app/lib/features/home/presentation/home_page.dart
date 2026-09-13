import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/gj_colors.dart';
import '../../../core/theme/gj_illustrations.dart';
import '../../../core/theme/gj_spacing.dart';
import '../../../core/theme/gj_typography.dart';
import '../../../shared/layouts/public_layout.dart';
import '../../../shared/utils/programa_estilo.dart';
import '../../../shared/widgets/gj_button.dart';
import '../../../shared/widgets/gj_card.dart';
import '../../../shared/widgets/gj_carousel.dart';
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

  // Toggle da barra de busca (Design System Deck, T01): filtra a natureza
  // já ao ir para a pesquisa de universidades.
  String _natureza = 'P';

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
      extra: {
        'cidade': _cidadeController.text,
        'q': _universidadeController.text,
        'areaCurso': _cursoController.text,
        'natureza': _natureza,
      },
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
            _SecaoCarousel<UniversidadeResumo>(
              titulo: 'Faculdades',
              future: _universidades,
              onVerTodas: () => context.go('/universidades'),
              itemBuilder: (universidade) => GJCard.universidade(
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
                onTap: () => context.go('/universidades/${universidade.id}'),
              ),
              vazio: 'Nenhuma universidade em destaque no momento.',
            ),
            const SizedBox(height: GJSpace.s16),
            _SecaoCarousel<ProgramaResumo>(
              titulo: 'Programas de Entrada',
              future: _programas,
              onVerTodas: () => context.go('/programas'),
              itemBuilder: (programa) => GJCard.programa(
                imagemUrl: programa.imagemUrl ?? imagemProgramaPadrao,
                icone: iconePrograma(programa.sigla, programa.tipo),
                cor: corPrograma(programa.tipo),
                sigla: programa.sigla ?? programa.tipo,
                nome: programa.nome,
                descricao: programa.descricao,
                onTap: () => context.go('/programas/${programa.id}'),
              ),
              vazio: 'Nenhum programa em destaque no momento.',
            ),
            const SizedBox(height: GJSpace.s16),
            _SecaoCarousel<CursoDestaque>(
              titulo: 'Principais cursos disponíveis',
              future: _cursos,
              onVerTodas: () => context.go('/cursos'),
              itemWidth: 220,
              itemBuilder: (curso) => GJCard.curso(
                nome: curso.nome,
                ilustracao: GJIllustrations.porAreaCurso(curso.areaCurso),
                onTap: () => context.go('/cursos/nome/${Uri.encodeComponent(curso.nome)}'),
              ),
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
          const SizedBox(height: GJSpace.s4),
          Align(
            alignment: Alignment.centerLeft,
            child: _toggleNatureza(),
          ),
        ],
      ),
    );
  }

  Widget _toggleNatureza() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: GJColors.surfaceLow, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _opcaoNatureza(label: 'Públicas / Federais', valor: 'P'),
          _opcaoNatureza(label: 'Privadas', valor: 'V'),
        ],
      ),
    );
  }

  Widget _opcaoNatureza({required String label, required String valor}) {
    final selecionado = _natureza == valor;
    return GestureDetector(
      onTap: () => setState(() => _natureza = valor),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: GJSpace.s5),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selecionado ? GJColors.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: GJTypography.label(color: selecionado ? GJColors.primaryOn : GJColors.textSecondary),
        ),
      ),
    );
  }
}

class _SecaoCarousel<T> extends StatelessWidget {
  const _SecaoCarousel({
    required this.titulo,
    required this.future,
    required this.onVerTodas,
    required this.itemBuilder,
    required this.vazio,
    this.itemWidth = 260,
  });

  final String titulo;
  final Future<List<T>> future;
  final VoidCallback onVerTodas;
  final Widget Function(T item) itemBuilder;
  final String vazio;
  final double itemWidth;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<T>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _cabecalhoEstatico(
            Row(
              children: [
                for (var i = 0; i < 3; i++) ...[
                  if (i > 0) const SizedBox(width: GJSpace.s6),
                  SizedBox(width: itemWidth, child: const GJSkeletonCard()),
                ],
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return _cabecalhoEstatico(
            GJEmptyState(
              titulo: 'Não foi possível carregar',
              texto: snapshot.error is ApiException ? (snapshot.error as ApiException).message : 'Tente novamente.',
              icone: Symbols.wifi_off,
            ),
          );
        }

        final itens = snapshot.data ?? [];
        if (itens.isEmpty) {
          return _cabecalhoEstatico(GJEmptyState(titulo: 'Nada por aqui ainda', texto: vazio));
        }

        return GJCarousel(
          titulo: titulo,
          onVerTodas: onVerTodas,
          itemWidth: itemWidth,
          itemCount: itens.length,
          itemBuilder: (context, index) => itemBuilder(itens[index]),
        );
      },
    );
  }

  Widget _cabecalhoEstatico(Widget corpo) {
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
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: corpo),
      ],
    );
  }
}
