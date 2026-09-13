import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/session_controller.dart';
import '../../features/auth/domain/usuario_sessao.dart';
import '../../features/auth/presentation/aviso_cadastro_universidade_page.dart';
import '../../features/auth/presentation/cadastro_aluno_page.dart';
import '../../features/auth/presentation/cadastro_universidade_passo1_page.dart';
import '../../features/auth/presentation/cadastro_universidade_passo2_page.dart';
import '../../features/auth/presentation/cadastro_universidade_passo3_page.dart';
import '../../features/auth/presentation/cadastro_universidade_sucesso_page.dart';
import '../../features/auth/presentation/esqueci_senha_page.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/painel_placeholder_page.dart';
import '../../features/auth/presentation/perfil_placeholder_page.dart';
import '../../features/auth/presentation/redefinir_senha_page.dart';
import '../../features/auth/presentation/tipo_cadastro_page.dart';
import '../../features/campus/presentation/detalhe_campus_page.dart';
import '../../features/cursos/presentation/detalhe_curso_page.dart';
import '../../features/cursos/presentation/lista_cursos_page.dart';
import '../../features/dev_components/dev_components_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/programas/presentation/detalhe_programa_page.dart';
import '../../features/programas/presentation/pesquisa_programas_page.dart';
import '../../features/universidades/presentation/detalhe_universidade_page.dart';
import '../../features/universidades/presentation/pesquisa_universidades_page.dart';

const _rotasSomenteVisitante = {
  '/login',
  '/cadastro',
  '/cadastro/aluno',
  '/cadastro/universidade',
  '/cadastro/universidade/dados',
  '/cadastro/universidade/programas',
  '/cadastro/universidade/campus',
};

const _rotasAutenticadas = {'/perfil', '/painel-universidade', '/admin'};

/// Rotas do app (seção 8 da especificação). Fase 2: catálogo público
/// (T01-T08). Fase 1: sessão e cadastro (T09-T15, T25, T26).
final appRouter = GoRouter(
  initialLocation: '/',
  refreshListenable: sessionController,
  redirect: (context, state) {
    // Enquanto o bootstrap (restaurar sessão do storage) não terminou, não
    // redireciona: a sessão ainda pode virar "autenticada" a qualquer momento.
    if (sessionController.carregando) return null;

    final autenticado = sessionController.autenticado;
    final destino = state.uri.path;

    if (!autenticado && _rotasAutenticadas.contains(destino)) {
      return '/login';
    }

    if (autenticado && _rotasSomenteVisitante.contains(destino)) {
      return '/';
    }

    if (destino == '/painel-universidade' &&
        autenticado &&
        sessionController.usuario!.tipoUsuario != TipoUsuario.universidade) {
      return '/perfil';
    }

    if (destino == '/admin' && autenticado && sessionController.usuario!.tipoUsuario != TipoUsuario.admin) {
      return '/perfil';
    }

    return null;
  },
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

    // Fase 1: sessão (T09, T25, T26).
    GoRoute(
      path: '/login',
      builder: (context, state) {
        final extra = state.extra as Map<String, String>?;
        return LoginPage(redirecionarPara: extra?['redirect']);
      },
    ),
    GoRoute(path: '/recuperar-senha', builder: (context, state) => const EsqueciSenhaPage()),
    GoRoute(
      path: '/redefinir-senha',
      builder: (context, state) => RedefinirSenhaPage(token: state.uri.queryParameters['token']),
    ),

    // Fase 1: cadastro (T10 a T15).
    GoRoute(path: '/cadastro', builder: (context, state) => const TipoCadastroPage()),
    GoRoute(path: '/cadastro/aluno', builder: (context, state) => const CadastroAlunoPage()),
    GoRoute(path: '/cadastro/universidade', builder: (context, state) => const AvisoCadastroUniversidadePage()),
    GoRoute(
      path: '/cadastro/universidade/dados',
      builder: (context, state) => const CadastroUniversidadePasso1Page(),
    ),
    GoRoute(
      path: '/cadastro/universidade/programas',
      builder: (context, state) => const CadastroUniversidadePasso2Page(),
    ),
    GoRoute(
      path: '/cadastro/universidade/campus',
      builder: (context, state) => const CadastroUniversidadePasso3Page(),
    ),
    GoRoute(
      path: '/cadastro/universidade/sucesso',
      builder: (context, state) => const CadastroUniversidadeSucessoPage(),
    ),

    // Fase 1: perfil e painéis (placeholders até a Pendência 3).
    GoRoute(path: '/perfil', builder: (context, state) => const PerfilPlaceholderPage()),
    GoRoute(
      path: '/painel-universidade',
      builder: (context, state) => const PainelPlaceholderPage(titulo: 'Painel de Administração da Universidade'),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const PainelPlaceholderPage(titulo: 'Painel de Administração'),
    ),

    GoRoute(path: '/dev/components', builder: (context, state) => const DevComponentsPage()),
  ],
);
