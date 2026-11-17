import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../auth/data/session_controller.dart';
import '../../auth/domain/usuario_sessao.dart';
import '../../auth/presentation/perfil_placeholder_page.dart';
import 'perfil_aluno_page.dart';

/// `/perfil`: o aluno vê T16; Universidade (T17) e Administrador seguem na
/// página provisória até os painéis existirem (Pendência 3, docs/DECISOES.md).
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
