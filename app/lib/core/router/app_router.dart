import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/campus/presentation/detalhe_campus_page.dart';
import '../../features/cursos/presentation/detalhe_curso_page.dart';
import '../../features/cursos/presentation/lista_cursos_page.dart';
import '../../features/dev_components/dev_components_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/programas/presentation/detalhe_programa_page.dart';
import '../../features/programas/presentation/pesquisa_programas_page.dart';
import '../../features/universidades/presentation/detalhe_universidade_page.dart';
import '../../features/universidades/presentation/pesquisa_universidades_page.dart';

/// Rotas do app (seção 8 da especificação). Fase 2: T01 a T08, públicas,
/// sem sessão de usuário (Fase 1 do frontend ainda não existe).
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomePage()),
    GoRoute(
      path: '/universidades',
      builder: (context, state) {
        final filtros = (state.extra as Map<String, String>?) ?? state.uri.queryParameters;
        final chaveFiltros = filtros.entries.map((entrada) => '${entrada.key}=${entrada.value}').join('&');
        return PesquisaUniversidadesPage(
          key: ValueKey('universidades-$chaveFiltros'),
          filtrosIniciais: filtros,
        );
      },
    ),
    GoRoute(
      path: '/universidades/:id',
      // Key por id: sem isso, ir direto de /universidades/1 para
      // /universidades/2 reaproveitaria o mesmo State (o StatefulWidget não
      // seria remontado) e a busca feita em initState não rodaria de novo.
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return DetalheUniversidadePage(key: ValueKey('universidade-$id'), id: id);
      },
    ),
    GoRoute(
      path: '/campus/:id',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return DetalheCampusPage(key: ValueKey('campus-$id'), id: id);
      },
    ),
    GoRoute(path: '/programas', builder: (context, state) => const PesquisaProgramasPage()),
    GoRoute(
      path: '/programas/:id',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return DetalheProgramaPage(key: ValueKey('programa-$id'), id: id);
      },
    ),
    GoRoute(path: '/cursos', builder: (context, state) => const ListaCursosPage()),
    GoRoute(
      path: '/cursos/nome/:nome',
      builder: (context, state) {
        final nome = state.pathParameters['nome']!;
        return DetalheCursoPage.porNome(key: ValueKey('curso-nome-$nome'), nome: nome);
      },
    ),
    GoRoute(
      path: '/cursos/:id',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return DetalheCursoPage.porId(key: ValueKey('curso-$id'), id: id);
      },
    ),
    GoRoute(path: '/dev/components', builder: (context, state) => const DevComponentsPage()),
  ],
);
