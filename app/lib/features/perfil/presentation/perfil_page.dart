import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../auth/data/session_controller.dart';
import '../../auth/domain/usuario_sessao.dart';
import '../../auth/presentation/perfil_placeholder_page.dart';
import 'perfil_aluno_page.dart';

/// `/perfil`: o aluno vê T16. A universidade (T17) é levada pelo router à
/// seção Conta do painel dela; o administrador segue na página provisória.
class PerfilPage extends StatelessWidget {
  const PerfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ehAluno = sessionController.usuario?.tipoUsuario == TipoUsuario.aluno;
    if (!ehAluno) return const PerfilPlaceholderPage();
    final aba = GoRouterState.of(context).uri.queryParameters['aba'];
    return PerfilAlunoPage(abaInicial: PerfilAlunoPage.abaDe(aba));
  }
}
