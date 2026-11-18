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
import '../../features/auth/presentation/redefinir_senha_page.dart';
import '../../features/auth/presentation/tipo_cadastro_page.dart';
import '../../features/campus/presentation/detalhe_campus_page.dart';
import '../../features/cursos/presentation/detalhe_curso_page.dart';
import '../../features/cursos/presentation/lista_cursos_page.dart';
import '../../features/dev_components/dev_components_page.dart';
import '../../features/admin/presentation/painel_admin_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/painel_universidade/presentation/painel_universidade_page.dart';
import '../../features/perfil/presentation/perfil_page.dart';
import '../../features/programas/presentation/detalhe_programa_page.dart';
import '../../features/programas/presentation/pesquisa_programas_page.dart';
import '../../features/sugestoes/presentation/detalhe_sugestao_page.dart';
import '../../features/sugestoes/presentation/sugestoes_recebidas_page.dart';
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

const _rotasAutenticadas = {'/perfil', '/painel-universidade', '/admin', '/sugestoes-recebidas'};

bool _ehPainelAdmin(String destino) => destino == '/admin' || destino.startsWith('/admin/');

bool _ehPainelUniversidade(String destino) =>
    destino == '/painel-universidade' || destino.startsWith('/painel-universidade/');

/// `/sugestoes/:id` (detalhe aberto pela notificação) e as seções dos painéis
/// (`/admin/...` e `/painel-universidade/...`) também exigem sessão.
bool _exigeSessao(String destino) =>
    _rotasAutenticadas.contains(destino) ||
    destino.startsWith('/sugestoes/') ||
    _ehPainelAdmin(destino) ||
    _ehPainelUniversidade(destino);

/// Guardas de rota pela sessão e pelo perfil; separado do [appRouter] para
/// ser testado sem montar o app.
String? redirecionarPelaSessao(String destino) {
  // Enquanto o bootstrap (restaurar sessão do storage) não terminou, não
  // redireciona: a sessão ainda pode virar "autenticada" a qualquer momento.
  if (sessionController.carregando) return null;

  final autenticado = sessionController.autenticado;

  if (!autenticado && _exigeSessao(destino)) {
    return '/login';
  }

  if (autenticado && _rotasSomenteVisitante.contains(destino)) {
    return '/';
  }

  // T17: o perfil da universidade (alterar senha, sair, excluir conta)
  // fica na seção Conta do painel dela.
  if (destino == '/perfil' && autenticado && sessionController.usuario!.tipoUsuario == TipoUsuario.universidade) {
    return '/painel-universidade/conta';
  }

  // O perfil do administrador (editar nome, alterar senha, sair) é a seção
  // Conta do painel dele.
  if (destino == '/perfil' && autenticado && sessionController.usuario!.tipoUsuario == TipoUsuario.admin) {
    return '/admin/${SecaoAdmin.conta.caminho}';
  }

  if (_ehPainelUniversidade(destino) &&
      autenticado &&
      sessionController.usuario!.tipoUsuario != TipoUsuario.universidade) {
    return '/perfil';
  }

  if (_ehPainelAdmin(destino) && autenticado && sessionController.usuario!.tipoUsuario != TipoUsuario.admin) {
    return '/perfil';
  }

  // Sugestões recebidas: só administrador e universidade (RF15).
  if (destino == '/sugestoes-recebidas' &&
      autenticado &&
      sessionController.usuario!.tipoUsuario == TipoUsuario.aluno) {
    return '/perfil';
  }

  return null;
}

/// Rotas do app (seção 8 da especificação). Fase 2: catálogo público
/// (T01-T08). Fase 1: sessão e cadastro (T09-T15, T25, T26).
final appRouter = GoRouter(
  initialLocation: '/',
  refreshListenable: sessionController,
  redirect: (context, state) => redirecionarPelaSessao(state.uri.path),
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

    // Perfil: T16 para o aluno. A universidade e o administrador são levados
    // pelo redirect à seção Conta do painel de cada um.
    GoRoute(path: '/perfil', builder: (context, state) => const PerfilPage()),
    // T23 Painel da universidade: uma URL por seção, como o do administrador.
    GoRoute(
      path: '/painel-universidade',
      redirect: (context, state) => '/painel-universidade/${SecaoUniversidade.dados.caminho}',
    ),
    GoRoute(
      path: '/painel-universidade/:secao',
      builder: (context, state) => PainelUniversidadePage(
        key: ValueKey('painel-universidade-${state.pathParameters['secao']}'),
        secao: SecaoUniversidade.doCaminho(state.pathParameters['secao']),
      ),
    ),

    // T24 Painel do administrador: uma URL por seção (abas do protótipo).
    GoRoute(path: '/admin', redirect: (context, state) => '/admin/${SecaoAdmin.dashboard.caminho}'),
    GoRoute(
      path: '/admin/universidades/:id',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return PainelAdminPage(secao: SecaoAdmin.universidades, universidadeId: id);
      },
    ),
    GoRoute(
      path: '/admin/:secao',
      builder: (context, state) => PainelAdminPage(
        key: ValueKey('admin-${state.pathParameters['secao']}'),
        secao: SecaoAdmin.doCaminho(state.pathParameters['secao']),
      ),
    ),

    // Sugestões (RF08, RF14, RF15). A lista de recebidas também é a seção
    // Sugestões do painel do administrador; a rota segue para a universidade
    // e para links antigos.
    GoRoute(path: '/sugestoes-recebidas', builder: (context, state) => const SugestoesRecebidasPage()),
    GoRoute(
      path: '/sugestoes/:id',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return DetalheSugestaoPage(key: ValueKey('sugestao-$id'), id: id);
      },
    ),

    GoRoute(path: '/dev/components', builder: (context, state) => const DevComponentsPage()),
  ],
);
